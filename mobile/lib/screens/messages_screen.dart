import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/theme_mode_toggle.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';
import 'admin_private_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _tabsInitialized = false;

  bool get _isEncadrant =>
      context.read<AuthProvider>().user?.role == 'ENCADRANT';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabsInitialized) {
      final tabCount = _isEncadrant ? 2 : 3;
      _tabController = TabController(length: tabCount, vsync: this);
      _tabsInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color masYellow = AppTheme.masYellow;
    const Color masBlack = AppTheme.masBlack;
    final isEncadrant = _isEncadrant;
    final tabController = _tabController;

    if (tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.masYellow)),
      );
    }

    final tabs = isEncadrant
        ? const [
            Tab(
              icon: Icon(Icons.campaign_outlined, size: 20),
              text: 'Annonces Admin',
            ),
            Tab(
              icon: Icon(Icons.mail_outline, size: 20),
              text: 'Live Chat Admin',
            ),
          ]
        : const [
            Tab(
              icon: Icon(Icons.groups_outlined, size: 20),
              text: 'Mes Équipes',
            ),
            Tab(
              icon: Icon(Icons.campaign_outlined, size: 20),
              text: 'Annonces Admin',
            ),
            Tab(
              icon: Icon(Icons.mail_outline, size: 20),
              text: 'Live Chat Admin',
            ),
          ];

    final tabViews = isEncadrant
        ? const [
            _AdminAnnouncementsTab(),
            AdminPrivateChatScreen(isEmbedded: true),
          ]
        : const [
            _MyTeamsTab(),
            _AdminAnnouncementsTab(),
            AdminPrivateChatScreen(isEmbedded: true),
          ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messagerie MAS Fès',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [ThemeModeToggle()],
        bottom: TabBar(
          controller: tabController,
          indicatorColor: masYellow,
          labelColor: masYellow,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          indicatorWeight: 3,
          tabs: tabs,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(context),
        ),
        child: TabBarView(
          controller: tabController,
          children: tabViews,
        ),
      ),
    );
  }
}

// ==================== TAB 1: MY TEAMS ====================
class _MyTeamsTab extends StatefulWidget {
  const _MyTeamsTab();

  @override
  State<_MyTeamsTab> createState() => _MyTeamsTabState();
}

class _MyTeamsTabState extends State<_MyTeamsTab> {
  List<Equipe> equipes = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEquipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipes() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.user?.role ?? 'ADHERENT';
      
      final loaded = await ApiService.getAllEquipes(role);
      if (mounted) {
        setState(() => equipes = loaded);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<Equipe> _filteredEquipes() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return equipes;
    return equipes.where((equipe) {
      final nom = equipe.nom.toLowerCase();
      final categorie = (equipe.categorie ?? '').toLowerCase();
      return nom.contains(query) || categorie.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEquipes();

    if (isLoading) {
      return const LoadingWidget(message: 'Chargement de vos équipes...');
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.masYellow),
            const SizedBox(height: 16),
            Text('Erreur: $error', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEquipes,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.masYellow),
              child: const Text('Réessayer', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher une équipe ou catégorie',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: AppTheme.masYellow),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Chip(
                label: Text('${filtered.length} équipe(s)'),
                backgroundColor: AppTheme.masYellow.withOpacity(0.15),
                side: BorderSide(color: AppTheme.masYellow.withOpacity(0.4)),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: equipes.isEmpty
              ? const EmptyState(
                  title: 'Aucune discussion',
                  subtitle: 'Vous n\'êtes membre d\'aucune équipe pour le moment.',
                  icon: Icons.groups_outlined,
                )
              : filtered.isEmpty
                  ? const EmptyState(
                      title: 'Aucun résultat',
                      subtitle: 'Essayez une autre recherche.',
                      icon: Icons.search_off,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final equipe = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTeamCard(equipe),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(Equipe equipe) {
    return Container(
      decoration: AppTheme.containerDecoration(context).copyWith(
        border: Border.all(color: AppTheme.masYellow.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                teamId: equipe.id!,
                teamName: equipe.nom,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.masYellow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups, size: 28, color: AppTheme.masYellow),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipe.nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      equipe.categorie ?? 'Discussion d\'équipe',
                      style: TextStyle(
                        color: AppTheme.masYellow.withOpacity(0.7),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.masYellow, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TAB 2: ADMIN ANNOUNCEMENTS ====================
class _AdminAnnouncementsTab extends StatefulWidget {
  const _AdminAnnouncementsTab();

  @override
  State<_AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();
}

class _AdminAnnouncementsTabState extends State<_AdminAnnouncementsTab> {
  final ChatService _chatService = ChatService();
  List<ChatMessage> _announcements = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAnnouncementsAndConnect();
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncementsAndConnect() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception("Utilisateur non connecté");
      }

      // 1. Fetch initial announcements from API
      final historyRaw = await ApiService.getUserAnnouncements();
      final List<ChatMessage> announcementsList = historyRaw.map((json) => ChatMessage.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _announcements = _dedupeAnnouncements(announcementsList);
        });
      }

      // 2. Connect WebSocket to dynamic updates
      _chatService.connect(
        url: ApiConfig.webSocketUrl,
        onConnect: (frame) {
          if (!mounted) return;
          
          // Subscribe to Broadcasts (Everyone)
          _chatService.subscribe('/topic/broadcast/messages', (frame) {
            if (frame.body != null && mounted) {
              final message = ChatMessage.fromJson(json.decode(frame.body!));
              setState(() {
                _announcements = _dedupeAnnouncements([message, ..._announcements]);
              });
            }
          });

          // Subscribe to Group Messages (By specific user role)
          final userRole = currentUser.role;
          _chatService.subscribe('/topic/role-$userRole/messages', (frame) {
            if (frame.body != null && mounted) {
              final message = ChatMessage.fromJson(json.decode(frame.body!));
              setState(() {
                _announcements = _dedupeAnnouncements([message, ..._announcements]);
              });
            }
          });
        },
        onWebSocketError: (err) {
          print("WS Announcements connection issue: $err");
        },
      );

    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<ChatMessage> _dedupeAnnouncements(List<ChatMessage> input) {
    final seen = <String>{};
    final result = <ChatMessage>[];
    for (final m in input) {
      final key = '${m.senderId}|${m.recipientRole ?? ''}|${m.timestamp.toIso8601String()}|${m.content.trim()}';
      if (seen.add(key)) {
        result.add(m);
      }
    }
    // Sort descending chronologically (Newest first for announcements!)
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  List<ChatMessage> _filteredAnnouncements() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _announcements;
    return _announcements.where((ann) {
      return ann.content.toLowerCase().contains(query) ||
             (ann.recipientRole ?? 'Tous').toLowerCase().contains(query) ||
             ann.senderName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAnnouncements();

    if (isLoading) {
      return const LoadingWidget(message: 'Chargement des annonces...');
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.masYellow),
              const SizedBox(height: 16),
              Text(
                'Erreur : $error',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAnnouncementsAndConnect,
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text('Réessayer', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.masYellow),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher une annonce...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: AppTheme.masYellow),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Chip(
                label: Text('${filtered.length} annonce(s)'),
                backgroundColor: AppTheme.masYellow.withOpacity(0.15),
                side: BorderSide(color: AppTheme.masYellow.withOpacity(0.4)),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Spacer(),
              if (_chatService.isConnected)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Temps réel actif",
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _announcements.isEmpty
              ? const EmptyState(
                  title: 'Aucune annonce',
                  subtitle: 'L\'administration n\'a pas encore publié d\'annonces.',
                  icon: Icons.campaign_outlined,
                )
              : filtered.isEmpty
                  ? const EmptyState(
                      title: 'Aucune correspondance',
                      subtitle: 'Essayez un autre mot-clé.',
                      icon: Icons.search_off,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final announcement = filtered[index];
                        return _buildAnnouncementCard(announcement);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(ChatMessage ann) {
    final isBroadcast = ann.recipientRole == null;
    final typeLabel = isBroadcast ? "📢 ANNONCE GÉNÉRALE" : "👥 GROUPE : ${ann.recipientRole}";
    final Color accentColor = isBroadcast ? Colors.orangeAccent : AppTheme.masYellow;
    final formattedDate = DateFormat('dd MMM yyyy à HH:mm').format(ann.timestamp.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.35)),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ann.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                "Publié par : ${ann.senderName}",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
