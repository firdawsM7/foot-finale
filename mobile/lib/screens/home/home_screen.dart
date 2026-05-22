import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_notification_provider.dart';
import '../../widgets/notification_badge_icon.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../messages_screen.dart';
import '../admin_messages_screen.dart';
import '../equipes/equipes_screen.dart';
import '../joueurs/joueurs_screen.dart';
import '../users/users_screen.dart';
import '../profile/profile_screen.dart';
import '../encadrant/encadrant_dashboard.dart';
import '../adherent/adherent_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.id != null) {
        context.read<MessageNotificationProvider>().initialize(user!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final role = user?.role ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('MAS de Fès - $role'),
        actions: [
          const ThemeModeToggle(),
          const NotificationBadgeIcon(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              context.read<MessageNotificationProvider>().disconnect();
              await authProvider.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(context),
        ),
        child: _buildBody(role),
      ),
      bottomNavigationBar: _buildBottomNav(role),
    );
  }

  Widget _buildBody(String role) {
    // Redirect to role-specific dashboard on first tab
    if (_currentIndex == 0) {
      switch (role) {
        case 'ADMIN':
          return _buildDashboard(role);
        case 'ENCADRANT':
          return const EncadrantDashboard();
        case 'ADHERENT':
          return const AdherentDashboard();
        default:
          return _buildDashboard(role);
      }
    }
    
    switch (_currentIndex) {
      case 1:
        return const EquipesScreen();
      case 2:
        return const JoueursScreen();
      case 3:
        // Admin voit l'écran de messagerie admin, les autres voient les messages d'équipe
        if (role == 'ADMIN') {
          return const AdminMessagesScreen();
        }
        return const MessagesScreen();
      case 4:
        if (role == 'ADMIN') {
          return const UsersScreen();
        }
        return const ProfileScreen();
      default:
        return _buildDashboard(role);
    }
  }

  Widget _buildDashboard(String role) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.containerDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      color: AppTheme.masYellow,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bienvenue',
                            style: TextStyle(
                              color: AppTheme.masYellow,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRoleDescription(role),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Actions disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.masYellow,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionGrid(role),
        ],
      ),
    );
  }

  Widget _buildActionGrid(String role) {
    List<ActionCard> actions = [];
    
    if (role == 'ADMIN') {
      actions = [
        ActionCard(
          title: 'Stats Dashboard',
          icon: Icons.dashboard_customize,
          onTap: () {
            Navigator.pushNamed(context, '/admin/dashboard');
          },
        ),
        ActionCard(
          title: 'Utilisateurs',
          icon: Icons.people,
          onTap: () {
            Navigator.pushNamed(context, '/users');
          },
        ),
        ActionCard(
          title: 'Équipes',
          icon: Icons.groups,
          onTap: () {
            Navigator.pushNamed(context, '/equipes');
          },
        ),
        ActionCard(
          title: 'Joueurs',
          icon: Icons.sports_soccer,
          onTap: () {
            Navigator.pushNamed(context, '/joueurs');
          },
        ),
        ActionCard(
          title: 'Entraînements',
          icon: Icons.fitness_center,
          onTap: () {
            Navigator.pushNamed(context, '/entrainements');
          },
        ),
        ActionCard(
          title: 'Matchs',
          icon: Icons.stadium,
          onTap: () {
            Navigator.pushNamed(context, '/matchs');
          },
        ),
        ActionCard(
          title: 'Cotisations',
          icon: Icons.payment,
          onTap: () {
            Navigator.pushNamed(context, '/cotisations');
          },
        ),
        ActionCard(
          title: 'Messages',
          icon: Icons.chat,
          onTap: () {
            Navigator.pushNamed(context, '/messages');
          },
        ),
      ];
    } else if (role == 'ENCADRANT') {
      actions = [
        ActionCard(
          title: 'Mes Équipes',
          icon: Icons.groups,
          onTap: () {
            Navigator.pushNamed(context, '/equipes');
          },
        ),
        ActionCard(
          title: 'Joueurs',
          icon: Icons.sports_soccer,
          onTap: () {
            Navigator.pushNamed(context, '/joueurs');
          },
        ),
        ActionCard(
          title: 'Entraînements',
          icon: Icons.fitness_center,
          onTap: () {
            Navigator.pushNamed(context, '/entrainements');
          },
        ),
        ActionCard(
          title: 'Matchs',
          icon: Icons.stadium,
          onTap: () {
            Navigator.pushNamed(context, '/matchs');
          },
        ),
        ActionCard(
          title: 'Mes Alertes',
          icon: Icons.notifications_active,
          onTap: () {
            Navigator.pushNamed(context, '/calendar'); // Using calendar for now or a dedicated alerts route if exists
          },
        ),
        ActionCard(
          title: 'Messages',
          icon: Icons.chat,
          onTap: () {
            Navigator.pushNamed(context, '/messages');
          },
        ),
      ];
    } else {
      actions = [
        ActionCard(
          title: 'Équipes',
          icon: Icons.groups,
          onTap: () {
            Navigator.pushNamed(context, '/equipes');
          },
        ),
        ActionCard(
          title: 'Mes Entraînements',
          icon: Icons.fitness_center,
          onTap: () {
            Navigator.pushNamed(context, '/mes-entrainements');
          },
        ),
        ActionCard(
          title: 'Calendrier',
          icon: Icons.calendar_today,
          onTap: () {
            Navigator.pushNamed(context, '/calendar');
          },
        ),
        ActionCard(
          title: 'Mes Cotisations',
          icon: Icons.payment,
          onTap: () {
            Navigator.pushNamed(context, '/cotisations');
          },
        ),
        ActionCard(
          title: 'Mon Profil',
          icon: Icons.person,
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        ActionCard(
          title: 'Messages',
          icon: Icons.chat,
          onTap: () {
            Navigator.pushNamed(context, '/messages');
          },
        ),
      ];
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: AppTheme.containerDecoration(context),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  size: 48,
                  color: AppTheme.masYellow,
                ),
                const SizedBox(height: 12),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNav(String role) {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Accueil',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups),
        label: 'Équipes',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.sports_soccer),
        label: 'Joueurs',
      ),
      BottomNavigationBarItem(
        icon: MessagesNavIcon(isSelected: _currentIndex == 3),
        activeIcon: const MessagesNavIcon(isSelected: true),
        label: 'Messages',
      ),
    ];

    if (role == 'ADMIN') {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Utilisateurs',
        ),
      );
    } else {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      );
    }

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        if (index == 3) {
          context.read<MessageNotificationProvider>().markAllAsRead();
        }
      },
      items: items,
    );
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Vous avez accès à toutes les fonctionnalités de gestion';
      case 'ENCADRANT':
        return 'Gérez vos équipes, joueurs et entraînements';
      case 'ADHERENT':
        return 'Consultez les informations du club';
      default:
        return '';
    }
  }
}

class ActionCard {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
