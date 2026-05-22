import 'package:club_mobile/screens/users/user_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/themed_app_bar.dart';
import '../../widgets/empty_state.dart';
import 'joueur_detail_screen.dart';
import '../users/users_screen.dart';

class JoueursScreen extends StatefulWidget {
  const JoueursScreen({super.key});

  @override
  State<JoueursScreen> createState() => _JoueursScreenState();
}

class _JoueursScreenState extends State<JoueursScreen> {
  List<dynamic> items = [];
  bool isLoading = true;
  String? error;
  String search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final loaded = await ApiService.getAllJoueurs(authProvider.user?.role ?? 'USER');
      setState(() => items = loaded);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteJoueur(User user) async {
    if (user.id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer joueur'),
        content: Text(
          'Supprimer le joueur ${user.prenom} ${user.nom} ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await ApiService.deleteUser(user.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joueur supprimé')),
      );
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $err'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.role == 'ADMIN';

    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'Joueurs'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: isLoading
            ? const LoadingWidget(message: 'Chargement des joueurs...')
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: AppTheme.masYellow),
                        const SizedBox(height: 8),
                        Text('Erreur: $error', style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search, color: AppTheme.masYellow),
                            hintText: 'Rechercher un joueur',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                          onChanged: (v) => setState(() => search = v),
                        ),
                        const SizedBox(height: 12),
                        if (_filtered().isEmpty)
                          const EmptyState(title: 'Aucun joueur trouvé')
                        else
                          Column(
                            children: _filtered()
                                .map((item) => Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: AppTheme.containerDecoration(context),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppTheme.masYellow,
                                          child: item is User
                                              ? (item.photo != null && item.photo!.isNotEmpty
                                                  ? ClipOval(
                                                      child: Image.network(
                                                        item.photo!,
                                                        errorBuilder: (context, error, stackTrace) =>
                                                            const Icon(Icons.person, color: AppTheme.masBlack),
                                                      ),
                                                    )
                                                  : const Icon(Icons.person, color: AppTheme.masBlack))
                                              : const Icon(Icons.person, color: AppTheme.masBlack),
                                        ),
                                        title: Text(
                                          item is User
                                              ? '${item.prenom} ${item.nom}'
                                              : '${item.prenom} ${item.nom}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          item is User
                                              ? 'JOUEUR - ${item.email}'
                                              : item.poste,
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isAdmin && item is User) ...[
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: AppTheme.masYellow),
                                                onPressed: item.id == null
                                                    ? null
                                                    : () async {
                                                        final changed = await Navigator.push<bool>(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => UserEditScreen(userId: item.id!),
                                                          ),
                                                        );
                                                        if (changed == true) _load();
                                                      },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                onPressed: item.id == null ? null : () => _deleteJoueur(item),
                                              ),
                                            ],
                                            const Icon(Icons.chevron_right, color: Colors.white54),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => JoueurDetailScreen(item: item),
                                            ),
                                          );
                                        },
                                      ),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  List<dynamic> _filtered() {
    if (search.isEmpty) return items;
    return items
        .where((item) {
          if (item is User) {
            return '${item.prenom} ${item.nom} ${item.email}'
                .toLowerCase()
                .contains(search.toLowerCase());
          } else {
            return '${item.prenom} ${item.nom} ${item.poste}'
                .toLowerCase()
                .contains(search.toLowerCase());
          }
        })
        .toList();
  }
}

