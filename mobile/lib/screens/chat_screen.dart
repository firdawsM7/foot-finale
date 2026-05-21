import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/theme_mode_toggle.dart';
import '../models/models.dart';
import '../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int teamId;
  final String teamName;

  const ChatScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isUploading = false;
  PlatformFile? _pendingAttachment;
  int? _privateRecipientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.connect(widget.teamId, user.id!, '${user.prenom} ${user.nom}');
        chatProvider.loadHistory(widget.teamId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty && _pendingAttachment == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _sendWithOptionalAttachment(
        senderId: user.id!,
        senderName: '${user.prenom} ${user.nom}',
      );
    }
  }

  Future<void> _sendWithOptionalAttachment({
    required int senderId,
    required String senderName,
  }) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    Map<String, dynamic>? uploaded;
    if (_pendingAttachment != null) {
      uploaded = await chatProvider.uploadAttachment(teamId: widget.teamId, file: _pendingAttachment!);
      if (uploaded == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec upload pièce jointe')),
        );
        setState(() => _isUploading = false);
        return;
      }
    }

    final content = _messageController.text.trim();
    final recipientId = _privateRecipientId;
    if (recipientId != null) {
      final dynamic rawSize = uploaded?['size'];
      final int? attachmentSize = rawSize is int ? rawSize : int.tryParse('${rawSize ?? ''}');
      chatProvider.sendPrivateMessage(
        content: content.isEmpty ? '(pièce jointe)' : content,
        teamId: widget.teamId,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        attachmentUrl: uploaded?['url'] as String?,
        attachmentName: (uploaded?['originalName'] ?? uploaded?['fileName']) as String?,
        attachmentContentType: uploaded?['contentType'] as String?,
        attachmentSize: attachmentSize,
      );
    } else {
      // Team message: send text, and if we have an attachment, send the link as a second message
      if (content.isNotEmpty) {
        chatProvider.sendMessage(content, widget.teamId, senderId, senderName);
      }
      if (uploaded != null) {
        chatProvider.sendMessage(uploaded['url']?.toString() ?? 'Pièce jointe envoyée', widget.teamId, senderId, senderName);
      }
    }

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _pendingAttachment = null;
      _messageController.clear();
    });
    _scrollToBottom();
  }

  Future<void> _pickAttachment() async {
    if (_isUploading) return;
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _pendingAttachment = result.files.single);
  }

  Future<void> _choosePrivateRecipient(List<dynamic> allMessages, int myUserId) async {
    final users = <int, String>{};
    for (final m in allMessages) {
      try {
        final senderId = (m.senderId as int);
        final senderName = (m.senderName as String);
        if (senderId != myUserId) {
          users[senderId] = senderName;
        }
      } catch (_) {}
    }
    if (users.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun utilisateur détecté dans l’historique')),
      );
      return;
    }
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Message privé à...'),
          content: SizedBox(
            width: 380,
            child: ListView(
              shrinkWrap: true,
              children: users.entries
                  .map(
                    (e) => ListTile(
                      title: Text(e.value),
                      onTap: () => Navigator.pop(ctx, e.key),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ],
        );
      },
    );
    if (picked == null) return;
    setState(() => _privateRecipientId = picked);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    // Defines MAS Colors
    const Color masYellow = Color(0xFFE8D21D);
    const Color masBlack = Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teamName),
        actions: AppBarActions.withTheme(
          extra: [
            Consumer<ChatProvider>(
              builder: (context, chat, child) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    chat.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: chat.isConnected ? Colors.green : Colors.red,
                    size: 20,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final filteredMessages = chatProvider.messages.where((message) {
            if (_searchQuery.trim().isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return message.content.toLowerCase().contains(query) ||
                message.senderName.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans les messages',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.masYellow),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        chatProvider.isConnected ? 'Connecté' : 'Reconnexion...',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: (chatProvider.isConnected ? Colors.green : Colors.orange).withOpacity(0.18),
                      side: BorderSide(
                        color: chatProvider.isConnected ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('${filteredMessages.length} message(s)'),
                      backgroundColor: AppTheme.masYellow.withOpacity(0.15),
                      side: BorderSide(color: AppTheme.masYellow.withOpacity(0.4)),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: _privateRecipientId == null ? 'Message privé' : 'Message privé activé',
                      onPressed: currentUser?.id == null
                          ? null
                          : () => _choosePrivateRecipient(filteredMessages, currentUser!.id!),
                      icon: Icon(
                        Icons.lock,
                        color: _privateRecipientId == null ? Colors.white70 : AppTheme.masYellow,
                      ),
                    ),
                    if (_privateRecipientId != null)
                      IconButton(
                        tooltip: 'Désactiver privé',
                        onPressed: () => setState(() => _privateRecipientId = null),
                        icon: const Icon(Icons.lock_open, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: chatProvider.isLoading
                    ? Center(child: CircularProgressIndicator(color: masBlack))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredMessages.length,
                        itemBuilder: (context, index) {
                          final message = filteredMessages[index];
                          final isMe = message.senderId == currentUser?.id;
                          return _buildMessageBubble(message, isMe, masYellow, masBlack);
                        },
                      ),
              ),
              _buildMessageComposer(masYellow, masBlack),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(var message, bool isMe, Color masYellow, Color masBlack) {
    final isPrivate = message.recipientId != null;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe ? masBlack : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe ? Border.all(color: masYellow, width: 1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            if (isPrivate)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Message privé',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (message.attachmentUrl != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(message.attachmentUrl);
                  await launchUrl(uri, webOnlyWindowName: '_blank');
                },
                icon: const Icon(Icons.attach_file),
                label: Text(message.attachmentName ?? 'Pièce jointe'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isMe ? masYellow : Colors.black87,
                  side: BorderSide(color: isMe ? masYellow : Colors.black45),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(Color masYellow, Color masBlack) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo),
            color: masBlack,
            onPressed: _isUploading ? null : _pickAttachment,
          ),
          if (_pendingAttachment != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_pendingAttachment!.name),
                onDeleted: _isUploading ? null : () => setState(() => _pendingAttachment = null),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration.collapsed(hintText: 'Envoyer un message...'),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isUploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            color: masBlack,
            onPressed: _isUploading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
