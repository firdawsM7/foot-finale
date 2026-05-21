import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../config/api_config.dart';
import '../core/theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/theme_mode_toggle.dart';
import '../widgets/empty_state.dart';

class AdminPrivateChatScreen extends StatefulWidget {
  final bool isEmbedded;
  const AdminPrivateChatScreen({super.key, this.isEmbedded = false});

  @override
  State<AdminPrivateChatScreen> createState() => _AdminPrivateChatScreenState();
}

class _AdminPrivateChatScreenState extends State<AdminPrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  // Premium predefined quick questions
  final List<String> _quickReplies = [
    "Question sur ma cotisation 💳",
    "Horaires d'entraînement 🕒",
    "Problème d'accès à l'application 📱",
    "Demande de document administratif 📄",
  ];

  @override
  void initState() {
    super.initState();
    _loadHistoryAndConnect();
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryAndConnect() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception("Utilisateur non connecté");
      }

      // 1. Load history via REST
      final historyRaw = await ApiService.getUserAdminConversation();
      final List<ChatMessage> history = historyRaw.map((json) => ChatMessage.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _messages = _dedupeMessages(history);
        });
        _scrollToBottom(animate: false);
      }

      // 2. Connect WebSocket STOMP
      _chatService.connect(
        url: ApiConfig.webSocketUrl,
        onConnect: (frame) {
          if (!mounted) return;
          setState(() {}); // trigger rebuild to show connected state

          // Subscribe to private notifications
          _chatService.subscribe('/topic/user-${currentUser.id}/messages', (frame) {
            if (frame.body != null && mounted) {
              final messageJson = json.decode(frame.body!);
              final message = ChatMessage.fromJson(messageJson);
              setState(() {
                _messages = _dedupeMessages([..._messages, message]);
              });
              _scrollToBottom();
            }
          });
        },
        onWebSocketError: (error) {
          print('WebSocket Admin Chat Error: $error');
          if (mounted) setState(() {});
        },
      );

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ChatMessage> _dedupeMessages(List<ChatMessage> input) {
    final seen = <String>{};
    final result = <ChatMessage>[];
    for (final message in input) {
      final key = '${message.senderId}|${message.recipientId ?? 0}|${message.timestamp.toIso8601String()}|${message.content.trim()}';
      if (seen.add(key)) {
        result.add(message);
      }
    }
    // Sort chronologically
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    if (customText == null) {
      _messageController.clear();
    }

    try {
      final result = await ApiService.sendUserMessageToAdmin(content: text);
      final data = result['data'];
      if (data is Map<String, dynamic> && mounted) {
        final sent = ChatMessage.fromJson(data);
        setState(() {
          _messages = _dedupeMessages([..._messages, sent]);
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de l'envoi : $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    const Color masYellow = AppTheme.masYellow;
    const Color masBlack = AppTheme.masBlack;

    final chatBody = Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getGradient(context),
      ),
      child: _isLoading
          ? const LoadingWidget(message: "Chargement de la discussion administrative...")
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: masYellow),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur lors du chargement : $_error',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadHistoryAndConnect,
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          label: const Text('Réessayer', style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: masYellow,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Alert Banner stating response window
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: masYellow.withOpacity(0.08),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: masYellow, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Cette discussion est privée. L'administration répondra dans les plus brefs délais.",
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Message Stream list
                    Expanded(
                      child: _messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMe = message.senderId == currentUser?.id;
                                return _buildMessageBubble(message, isMe);
                              },
                            ),
                    ),

                    // Quick responses carousel (only shown when conversation is fresh or simple)
                    if (_messages.length < 10) _buildQuickRepliesWidget(),

                    // Input Bar
                    _buildMessageComposer(),
                  ],
                ),
    );

    if (widget.isEmbedded) {
      return chatBody;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: masYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, color: masYellow, size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Administration MAS",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "Secrétariat général",
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: AppBarActions.withTheme(
          extra: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: _chatService.isConnected ? "Temps réel actif" : "Connexion...",
                child: Icon(
                  _chatService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _chatService.isConnected ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
      body: chatBody,
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.masYellow.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.masYellow.withOpacity(0.1)),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppTheme.masYellow,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun message privé',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Commencez à discuter avec l\'administration pour toute question, réclamation ou document.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    const Color masYellow = AppTheme.masYellow;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe
              ? Border.all(color: masYellow.withOpacity(0.4), width: 1)
              : Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, color: masYellow, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: masYellow,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('dd/MM HH:mm').format(message.timestamp.toLocal()),
                style: const TextStyle(
                  fontSize: 9.5,
                  color: Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesWidget() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: const Color(0xFF1E1E1E),
              surfaceTintColor: Colors.transparent,
              side: BorderSide(color: AppTheme.masYellow.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: Text(
                reply,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              onPressed: () => _sendMessage(reply),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Écrire un message à l\'admin...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : () => _sendMessage(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.masYellow,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
