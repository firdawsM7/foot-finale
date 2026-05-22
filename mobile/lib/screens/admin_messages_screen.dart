import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../utils/api_error_utils.dart';
import '../services/chat_service.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/themed_app_bar.dart';
import '../widgets/theme_mode_toggle.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _adminChatService = ChatService();
  
  List<dynamic> _announcements = [];
  List<User> _users = [];
  Map<String, dynamic> _stats = {
    'totalMessages': 0,
    'broadcastMessages': 0,
    'privateMessages': 0,
    'groupMessages': 0,
  };
  
  bool _isLoading = true;
  String? _error;

  // Private Chat state
  User? _selectedUser;
  List<ChatMessage> _activePrivateMessages = [];
  bool _isMessagesLoading = false;
  final Map<int, bool> _unreadIndicators = {};
  final TextEditingController _privateMessageInputController = TextEditingController();
  final ScrollController _privateScrollController = ScrollController();
  final TextEditingController _userSearchController = TextEditingController();
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDataAndConnect();
  }

  @override
  void dispose() {
    _adminChatService.disconnect();
    _tabController.dispose();
    _privateMessageInputController.dispose();
    _privateScrollController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadDataAndConnect() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // 1. Fetch initial records
      final futures = await Future.wait([
        ApiService.getAllAdminMessages(),
        ApiService.getAllUsers(),
        ApiService.getMessageStats().catchError((e) => {
          'totalMessages': 0,
          'broadcastMessages': 0,
          'privateMessages': 0,
          'groupMessages': 0,
        }),
      ]);

      final List<dynamic> rawAllMessages = futures[0] as List<dynamic>;
      final List<User> rawUsers = futures[1] as List<User>;
      final Map<String, dynamic> rawStats = futures[2] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          // Filter announcements only (teamId == 0 and recipientId == null)
          _announcements = rawAllMessages.where((m) {
            final isPrivate = m['recipientId'] != null;
            return !isPrivate;
          }).toList();
          
          // Sort announcements: newest first
          _announcements.sort((a, b) {
            final aTime = a['timestamp'] != null ? DateTime.parse(a['timestamp']) : DateTime.now();
            final bTime = b['timestamp'] != null ? DateTime.parse(b['timestamp']) : DateTime.now();
            return bTime.compareTo(aTime);
          });

          // Keep non-admin users only or all users
          _users = rawUsers.where((u) => u.role != 'ADMIN').toList();
          _stats = rawStats;
        });
      }

      // 2. Connect Admin WebSocket (SockJS)
      _adminChatService.connect(
        url: ApiConfig.webSocketUrl,
        onConnect: (frame) {
          if (!mounted) return;
          setState(() {}); // trigger rebuild to show connection indicator

          // Subscribe to general admin messaging topic (receives ALL admin events in real-time)
          _adminChatService.subscribe('/topic/admin-messages', (frame) {
            if (frame.body != null && mounted) {
              final Map<String, dynamic> messageJson = json.decode(frame.body!);
              final ChatMessage message = ChatMessage.fromJson(messageJson);

              // Update statistics metrics locally
              setState(() {
                _stats['totalMessages'] = (_stats['totalMessages'] ?? 0) + 1;
                if (message.recipientId != null) {
                  _stats['privateMessages'] = (_stats['privateMessages'] ?? 0) + 1;
                } else if (message.recipientRole != null) {
                  _stats['groupMessages'] = (_stats['groupMessages'] ?? 0) + 1;
                } else {
                  _stats['broadcastMessages'] = (_stats['broadcastMessages'] ?? 0) + 1;
                }
              });

              // Check if message is announcement
              if (message.recipientId == null) {
                setState(() {
                  _announcements = _dedupeAnnouncements([messageJson, ..._announcements]);
                });
                return;
              }

              // Message is private
              final senderId = message.senderId;
              final recipientId = message.recipientId;

              if (_selectedUser != null && 
                  (senderId == _selectedUser!.id || recipientId == _selectedUser!.id)) {
                // Belongs to currently open discussion
                setState(() {
                  _activePrivateMessages = _dedupePrivateMessages([..._activePrivateMessages, message]);
                });
                _scrollPrivateToBottom();
              } else {
                // Belongs to another user, trigger unread indicator
                final userWhoSent = (senderId == 0 || senderId == 1) // wait, if admin sent it, no indicator
                    ? recipientId 
                    : senderId;
                
                if (userWhoSent != null && userWhoSent > 0) {
                  setState(() {
                    _unreadIndicators[userWhoSent] = true;
                  });
                }
              }
            }
          });
        },
        onWebSocketError: (err) {
          print("Admin WebSocket Hub Error: $err");
          if (mounted) setState(() {});
        },
      );

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiErrorUtils.sanitizeForDisplay(e);
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

  List<dynamic> _dedupeAnnouncements(List<dynamic> input) {
    final seen = <String>{};
    final result = [];
    for (final m in input) {
      final key = '${m['senderId']}|${m['recipientRole'] ?? ''}|${m['timestamp']}|${m['content']?.trim()}';
      if (seen.add(key)) {
        result.add(m);
      }
    }
    return result;
  }

  List<ChatMessage> _dedupePrivateMessages(List<ChatMessage> input) {
    final seen = <String>{};
    final result = <ChatMessage>[];
    for (final m in input) {
      final key = '${m.senderId}|${m.recipientId ?? 0}|${m.timestamp.toIso8601String()}|${m.content.trim()}';
      if (seen.add(key)) {
        result.add(m);
      }
    }
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  Future<void> _loadPrivateConversation(int userId) async {
    setState(() {
      _isMessagesLoading = true;
    });

    try {
      final raw = await ApiService.getAdminConversationPrivateHistory(userId);
      final List<ChatMessage> list = raw.map((json) => ChatMessage.fromJson(json)).toList();
      
      setState(() {
        _activePrivateMessages = _dedupePrivateMessages(list);
      });
      _scrollPrivateToBottom(animate: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible de charger l'historique : $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isMessagesLoading = false;
      });
    }
  }

  void _scrollPrivateToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_privateScrollController.hasClients) {
        if (animate) {
          _privateScrollController.animateTo(
            _privateScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _privateScrollController.jumpTo(_privateScrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _sendPrivateReply() async {
    final text = _privateMessageInputController.text.trim();
    if (text.isEmpty || _selectedUser == null) return;

    _privateMessageInputController.clear();

    try {
      await ApiService.sendPrivateMessage(
        userId: _selectedUser!.id!,
        content: text,
      );
      _scrollPrivateToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'envoi : $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAnnouncementDialog() async {
    final TextEditingController contentCtrl = TextEditingController();
    String currentType = "BROADCAST"; // BROADCAST, ROLE_ENCADRANT, ROLE_JOUEUR, ROLE_ADHERENT
    bool isPublishing = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.masYellow.withOpacity(0.2))),
          title: const Row(
            children: [
              Icon(Icons.campaign, color: AppTheme.masYellow),
              SizedBox(width: 8),
              Text('Nouvelle Annonce Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Type de diffusion :", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: currentType,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: "BROADCAST", child: Text("📢 Broadcast (Tous les membres)")),
                    DropdownMenuItem(value: "ROLE_ENCADRANT", child: Text("👥 Groupe : Encadrants")),
                    DropdownMenuItem(value: "ROLE_JOUEUR", child: Text("👥 Groupe : Joueurs")),
                    DropdownMenuItem(value: "ROLE_ADHERENT", child: Text("👥 Groupe : Adhérents")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => currentType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text("Contenu du message :", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  maxLength: 800,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Saisissez les détails de l'annonce ici...",
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    counterText: "",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isPublishing ? null : () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: isPublishing
                  ? null
                  : () async {
                      final content = contentCtrl.text.trim();
                      if (content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Le contenu ne peut pas être vide')),
                        );
                        return;
                      }

                      setDialogState(() => isPublishing = true);

                      try {
                        if (currentType == "BROADCAST") {
                          await ApiService.sendBroadcastMessage(content: content);
                        } else {
                          // Extract role from type (ROLE_ENCADRANT -> ENCADRANT)
                          final role = currentType.replaceFirst("ROLE_", "");
                          await ApiService.sendGroupMessage(role: role, content: content);
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Annonce publiée avec succès !'), backgroundColor: Colors.green),
                          );
                        }
                        _loadDataAndConnect();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Échec de la publication : $e'), backgroundColor: Colors.red),
                        );
                      } finally {
                        setDialogState(() => isPublishing = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.masYellow,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isPublishing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Publier', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  List<User> _filteredUsers() {
    final query = _userSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((u) {
      final fullname = '${u.prenom} ${u.nom}'.toLowerCase();
      final email = u.email.toLowerCase();
      final role = u.role.toLowerCase();
      return fullname.contains(query) || email.contains(query) || role.contains(query);
    }).toList();
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ENCADRANT':
        return Colors.orangeAccent;
      case 'JOUEUR':
        return Colors.greenAccent;
      case 'ADHERENT':
        return Colors.blueAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color masYellow = AppTheme.masYellow;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ThemedAppBar(
        title: const Text('Console Administrative', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: masYellow,
          labelColor: masYellow,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.campaign_outlined, size: 20), text: 'Annonces'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 20), text: 'Chats Privés'),
            Tab(icon: Icon(Icons.bar_chart_outlined, size: 20), text: 'Statistiques'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: masYellow),
              onPressed: _loadDataAndConnect,
              tooltip: 'Actualiser',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              _adminChatService.isConnected ? Icons.wifi : Icons.wifi_off,
              color: _adminChatService.isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(context),
        ),
        child: _isLoading
            ? const LoadingWidget(message: 'Chargement des messages...')
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: masYellow),
                        const SizedBox(height: 16),
                        Text('Erreur: $_error', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDataAndConnect,
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          label: const Text('Réessayer', style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(backgroundColor: masYellow),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(), // disable swipe for split screen
                    children: [
                      _buildAnnoncesTab(),
                      _buildChatsPrivesTab(),
                      _buildStatsTab(),
                    ],
                  ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAnnouncementDialog,
              backgroundColor: masYellow,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Nouvelle annonce', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ==================== TAB 1: ANNONCES ====================
  Widget _buildAnnoncesTab() {
    if (_announcements.isEmpty) {
      return const EmptyState(
        title: 'Aucune annonce',
        subtitle: 'Cliquez sur le bouton pour diffuser votre premier message',
        icon: Icons.campaign_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final ann = _announcements[index];
        final isBroadcast = ann['recipientRole'] == null;
        final typeLabel = isBroadcast ? "📢 BROADCAST GLOBAL" : "👥 GROUPE : ${ann['recipientRole']}";
        final accent = isBroadcast ? Colors.orangeAccent : AppTheme.masYellow;
        final date = ann['timestamp'] != null ? DateTime.parse(ann['timestamp']).toLocal() : DateTime.now();
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withOpacity(0.3)),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text(formattedDate, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ann['content'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.35),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Text(
                    'Par : ${ann['senderName'] ?? 'Admin'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== TAB 2: CHATS PRIVES (RESPONSIVE SPLIT) ====================
  Widget _buildChatsPrivesTab() {
    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      // Side-by-side Dual Panel for Tablet/Desktop/Web
      return Row(
        children: [
          SizedBox(
            width: 340,
            child: _buildUserListPanel(),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),
          Expanded(
            child: _buildChatConsolePanel(),
          ),
        ],
      );
    } else {
      // Navigation stack for mobile
      if (_selectedUser != null) {
        return WillPopScope(
          onWillPop: () async {
            setState(() => _selectedUser = null);
            return false;
          },
          child: _buildChatConsolePanel(),
        );
      } else {
        return _buildUserListPanel();
      }
    }
  }

  Widget _buildUserListPanel() {
    final filtered = _filteredUsers();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _userSearchController,
            onChanged: (value) => setState(() => _userSearchQuery = value),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher un membre...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppTheme.masYellow, size: 20),
              suffixIcon: _userSearchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 16),
                      onPressed: () {
                        _userSearchController.clear();
                        setState(() => _userSearchQuery = '');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: _users.isEmpty
              ? const EmptyState(
                  title: "Aucun membre",
                  subtitle: "Aucun membre n'est inscrit dans le club.",
                  icon: Icons.people_outline,
                )
              : filtered.isEmpty
                  ? const EmptyState(
                      title: "Aucun résultat",
                      subtitle: "Essayez un autre mot-clé.",
                      icon: Icons.search_off,
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        final isSelected = _selectedUser?.id == user.id;
                        final hasUnread = _unreadIndicators[user.id] == true;
                        final roleColor = _getRoleColor(user.role);

                        return Container(
                          color: isSelected ? Colors.white.withOpacity(0.06) : Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                                _unreadIndicators[user.id!] = false;
                              });
                              _loadPrivateConversation(user.id!);
                            },
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: roleColor.withOpacity(0.2),
                                  child: Text(
                                    '${user.prenom[0].toUpperCase()}${user.nom[0].toUpperCase()}',
                                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                if (hasUnread)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF141414), width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              '${user.prenom} ${user.nom}',
                              style: TextStyle(
                                color: isSelected ? AppTheme.masYellow : Colors.white,
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14.5,
                              ),
                            ),
                            subtitle: Text(
                              user.email,
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: roleColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                user.role,
                                style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildChatConsolePanel() {
    if (_selectedUser == null) {
      return const EmptyState(
        title: "Sélectionnez un membre",
        subtitle: "Choisissez un membre dans la liste pour démarrer la discussion en temps réel.",
        icon: Icons.chat_bubble_outline,
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;
    const Color masYellow = AppTheme.masYellow;

    return Column(
      children: [
        // Console Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
          ),
          child: Row(
            children: [
              if (!isWide)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: masYellow),
                  onPressed: () => setState(() => _selectedUser = null),
                ),
              CircleAvatar(
                radius: 18,
                backgroundColor: _getRoleColor(_selectedUser!.role).withOpacity(0.15),
                child: Text(
                  '${_selectedUser!.prenom[0].toUpperCase()}${_selectedUser!.nom[0].toUpperCase()}',
                  style: TextStyle(color: _getRoleColor(_selectedUser!.role), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedUser!.prenom} ${_selectedUser!.nom}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Discussion privée • ${_selectedUser!.role}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Private Chat Stream list
        Expanded(
          child: _isMessagesLoading
              ? const Center(child: CircularProgressIndicator(color: masYellow))
              : _activePrivateMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: masYellow.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text("Aucun message", style: TextStyle(color: Colors.white38, fontSize: 14)),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              "Envoyez un message pour initier la discussion privée avec ce membre.",
                              style: TextStyle(color: Colors.white24, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _privateScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _activePrivateMessages.length,
                      itemBuilder: (context, index) {
                        final message = _activePrivateMessages[index];
                        final isMe = message.senderId == 0 || message.senderId == 1 || message.senderName.toLowerCase().contains("admin");
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                              ),
                              border: Border.all(
                                color: isMe ? masYellow.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.content,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    DateFormat('HH:mm').format(message.timestamp.toLocal()),
                                    style: const TextStyle(color: Colors.white30, fontSize: 9.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Console Composer
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E1E1E),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _privateMessageInputController,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Écrire une réponse privée...',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendPrivateReply(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendPrivateReply,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: masYellow, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.black, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 3: STATISTIQUES ====================
  Widget _buildStatsTab() {
    final total = _stats['totalMessages'] ?? 0;
    final broadcast = _stats['broadcastMessages'] ?? 0;
    final private = _stats['privateMessages'] ?? 0;
    final groups = _stats['groupMessages'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Indicateurs d'activité",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildMetricCard("Total Messages", total.toString(), Icons.all_inbox, Colors.blueAccent),
              _buildMetricCard("Broadcasts", broadcast.toString(), Icons.campaign, Colors.orangeAccent),
              _buildMetricCard("Groupes Ciblés", groups.toString(), Icons.groups, AppTheme.masYellow),
              _buildMetricCard("Fils Privés", private.toString(), Icons.question_answer, Colors.greenAccent),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text(
            "Actions de Messagerie",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildQuickActionTile(
            title: "Envoyer un message broadcast à tous",
            subtitle: "Diffusez une annonce prioritaire à l'ensemble du club",
            icon: Icons.campaign,
            color: Colors.orangeAccent,
            onTap: () {
              _tabController.animateTo(0);
              _showAnnouncementDialog();
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildQuickActionTile(
            title: "Répondre à un membre en privé",
            subtitle: "Consulter la boîte de réception des discussions directes",
            icon: Icons.question_answer,
            color: Colors.greenAccent,
            onTap: () {
              _tabController.animateTo(1);
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.masYellow),
      ),
    );
  }
}
