import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/user_document_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../../widgets/themed_app_bar.dart';
import '../user_documents_screen.dart';
import '../../widgets/document_upload_card.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users = [];
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  String selectedRole = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      final loadedUsers = await ApiService.getAllUsers();

      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'Gestion des Utilisateurs'),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(context),
        ),
        child: isLoading
            ? const LoadingWidget(message: 'Chargement des utilisateurs...')
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppTheme.masYellow),
                        const SizedBox(height: 16),
                        Text('Erreur: $error', style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    color: AppTheme.masYellow,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredUsers().length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers()[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AppTheme.containerDecoration(context),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            onTap: () async {
                              if (user.id == null) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserDetailScreen(userId: user.id!),
                                ),
                              );
                              _loadUsers();
                            },
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.masYellow,
                              child: Text(
                                (user.nom.isNotEmpty ? user.nom[0] : '?').toUpperCase(),
                                style: const TextStyle(color: AppTheme.masBlack, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              '${user.nom} ${user.prenom}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(user.email, style: const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.masYellow.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.masYellow, width: 1),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.masYellow, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.masYellow),
                                  onPressed: () async {
                                    if (user.id == null) return;
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserEditScreen(userId: user.id!),
                                      ),
                                    );
                                    if (changed == true) _loadUsers();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Confirmer', style: TextStyle(color: AppTheme.masYellow)),
                                        content: const Text('Supprimer cet utilisateur ?', style: TextStyle(color: Colors.white)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      // Afficher le chargement
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.masYellow)),
                                      );

                                      try {
                                        await ApiService.deleteUser(user.id!);
                                        Navigator.pop(context); // Fermer le chargement
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur supprimé avec succès')));
                                        _loadUsers();
                                      } catch (e) {
                                        Navigator.pop(context); // Fermer le chargement
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-user').then((_) {
            // Reload users when returning from add-user screen
            _loadUsers();
          });
        },
        backgroundColor: AppTheme.masYellow,
        foregroundColor: AppTheme.masBlack,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  List<User> _filteredUsers() {
    var list = users;
    if (selectedRole != 'ALL') list = list.where((u) => u.role == selectedRole).toList();
    if (searchQuery.isNotEmpty) {
      list = list.where((u) => ('${u.nom} ${u.prenom} ${u.email}').toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    String prenom = '';
    String email = '';
    String role = 'ADHERENT';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter utilisateur', style: TextStyle(color: AppTheme.masYellow)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(decoration: const InputDecoration(labelText: 'Nom'), onSaved: (v) => nom = v ?? '', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                TextFormField(decoration: const InputDecoration(labelText: 'Prénom'), onSaved: (v) => prenom = v ?? '', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                TextFormField(decoration: const InputDecoration(labelText: 'Email'), onSaved: (v) => email = v ?? '', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: AppTheme.masGray,
                  style: const TextStyle(color: Colors.white),
                  items: ['ADMIN','ENCADRANT','ADHERENT','JOUEUR'].map((r)=>DropdownMenuItem(value: r,child: Text(r))).toList(), 
                  onChanged: (v){role=v!;}
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(onPressed: () async {
            formKey.currentState?.save();
            
            // Afficher le chargement
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.masYellow)),
            );

            try {
              final newUser = User(
                email: email, 
                nom: nom, 
                prenom: prenom, 
                role: role,
              );
              await ApiService.createUser(newUser);
              
              // Fermer le dialogue de chargement
              Navigator.pop(context);
              // Fermer le dialogue d'ajout
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur ajouté avec succès')));
              _loadUsers();
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
            }
          }, child: const Text('Ajouter')),
        ],
      ),
    );
  }

  void _showEditUserDialog(User user) {
    final formKey = GlobalKey<FormState>();
    String nom = user.nom;
    String prenom = user.prenom;
    String email = user.email;
    String role = user.role;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Éditer utilisateur', style: TextStyle(color: AppTheme.masYellow)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(initialValue: nom, decoration: const InputDecoration(labelText: 'Nom'), onSaved: (v) => nom = v ?? '', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                TextFormField(initialValue: prenom, decoration: const InputDecoration(labelText: 'Prénom'), onSaved: (v) => prenom = v ?? '', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                TextFormField(initialValue: email, decoration: const InputDecoration(labelText: 'Email'), onSaved: (v) => email = v ?? '', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: AppTheme.masGray,
                  style: const TextStyle(color: Colors.white),
                  items: ['ADMIN','ENCADRANT','ADHERENT','JOUEUR'].map((r)=>DropdownMenuItem(value: r,child: Text(r))).toList(), 
                  onChanged: (v){role=v!;}
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(onPressed: () async {
            formKey.currentState?.save();

            // Afficher le chargement
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.masYellow)),
            );

            try {
              final updatedUser = User(
                id: user.id,
                email: email, 
                nom: nom, 
                prenom: prenom, 
                role: role,
              );
              await ApiService.updateUser(updatedUser);
              
              // Fermer le dialogue de chargement
              Navigator.pop(context);
              // Fermer le dialogue d'édition
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur mis à jour avec succès')));
              _loadUsers();
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
            }
          }, child: const Text('Enregistrer')),
        ],
      ),
    );
  }
}
