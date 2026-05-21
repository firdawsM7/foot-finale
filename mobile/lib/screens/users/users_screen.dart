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
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
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
                  initialValue: role, 
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
                  initialValue: role, 
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

// ============================================================================
// Inline screens (avoid import resolution issues on some setups)
// ============================================================================

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dossier;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userProvider = context.read<UserProvider>();
    final dossier = await userProvider.getUserWithDocuments(widget.userId);
    if (!mounted) return;

    setState(() {
      _dossier = dossier;
      _error = dossier == null ? (userProvider.error ?? 'Erreur de chargement') : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dossier = _dossier;
    final user = dossier != null ? UserModel.fromJson(dossier) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails utilisateur'),
        actions: AppBarActions.withTheme(
          extra: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.masYellow))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: AppTheme.masYellow),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _UserHeaderCard(user: user!),
                      const SizedBox(height: 12),
                      _UserSection(
                        title: 'Informations',
                        child: Column(
                          children: [
                            _UserRowItem(label: 'Email', value: user.email),
                            _UserRowItem(label: 'Téléphone', value: user.phone),
                            _UserRowItem(label: 'Adresse', value: user.address),
                            _UserRowItem(label: 'Date de naissance', value: _formatDate(user.dateOfBirth)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _UserSection(
                        title: 'Statut',
                        child: Column(
                          children: [
                            _UserRowItem(label: 'Rôle', value: user.role.toString().split('.').last),
                            _UserRowItem(label: 'Compte', value: user.accountStatus.toString().split('.').last),
                            _UserRowItem(label: 'Inscription', value: user.registrationStatus.toString().split('.').last),
                            _UserRowItem(label: 'Actif', value: user.actif ? 'Oui' : 'Non'),
                            _UserRowItem(label: 'Créé le', value: _formatDateTime(user.dateInscription)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _UserSection(
                        title: 'Documents',
                        child: Column(
                          children: [
                            _UserRowItem(
                              label: 'Progression',
                              value:
                                  '${dossier!['documentsCompleted'] ?? 0}/${dossier['documentsRequired'] ?? 0} (${dossier['completionPercentage'] ?? 0}%)',
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: ((dossier['completionPercentage'] ?? 0) as num).toDouble() / 100.0,
                              minHeight: 10,
                              backgroundColor: Colors.white.withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.masYellow),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserEditScreen(userId: widget.userId),
                                  ),
                                );
                                if (changed == true) _load();
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Modifier'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.masYellow,
                                side: const BorderSide(color: AppTheme.masYellow),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserDocumentsScreen(userId: widget.userId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Documents'),
                              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatDateTime(DateTime d) {
    return '${_formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class UserEditScreen extends StatefulWidget {
  final int userId;

  const UserEditScreen({super.key, required this.userId});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  UserRole? _role;

  bool _loading = true;
  String? _error;
  bool _docsLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userProvider = context.read<UserProvider>();
    final user = await userProvider.getUserById(widget.userId);
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _error = userProvider.error ?? 'Erreur de chargement';
        _loading = false;
      });
      return;
    }

    setState(() {
      _firstNameCtrl.text = user.firstName;
      _lastNameCtrl.text = user.lastName;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone;
      _addressCtrl.text = user.address;
      _dateOfBirth = user.dateOfBirth;
      _role = user.role;
      _loading = false;
    });

    // Load documents section
    final docProvider = context.read<UserDocumentProvider>();
    await docProvider.loadDocuments(widget.userId);
    if (mounted) {
      setState(() => _docsLoaded = true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un rôle')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final ok = await userProvider.updateUserProfile(
      userId: widget.userId,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      dateOfBirth: _dateOfBirth,
      role: _role,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur mis à jour')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userProvider.error ?? 'Erreur'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<UserDocumentProvider>();
    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'Modifier utilisateur'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.masYellow))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: AppTheme.masYellow),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                        ],
                      ),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          decoration: AppTheme.containerDecoration(context),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _firstNameCtrl,
                                decoration: AppTheme.inputDecoration('Prénom', Icons.person_outline),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _lastNameCtrl,
                                decoration: AppTheme.inputDecoration('Nom', Icons.badge_outlined),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailCtrl,
                                decoration: AppTheme.inputDecoration('Email', Icons.email_outlined),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                                  if (!v.contains('@')) return 'Email invalide';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneCtrl,
                                decoration: AppTheme.inputDecoration('Téléphone', Icons.phone_outlined),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addressCtrl,
                                decoration: AppTheme.inputDecoration('Adresse', Icons.location_on_outlined),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: AppTheme.inputDecoration('Date de naissance', Icons.calendar_today),
                                  child: Text(
                                    _dateOfBirth == null
                                        ? 'Sélectionner une date'
                                        : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<UserRole>(
                                initialValue: _role,
                                items: UserRole.values
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r.toString().split('.').last),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _role = v),
                                decoration: AppTheme.inputDecoration('Rôle', Icons.admin_panel_settings),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Enregistrer'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: AppTheme.containerDecoration(context),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Documents',
                                style: TextStyle(
                                  color: AppTheme.masYellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (!_docsLoaded || (docProvider.isLoading && docProvider.documents.isEmpty))
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(color: AppTheme.masYellow),
                                  ),
                                )
                              else if (docProvider.error != null && docProvider.documents.isEmpty)
                                Text(
                                  docProvider.error!,
                                  style: const TextStyle(color: Colors.white),
                                )
                              else if (docProvider.documents.isEmpty)
                                const Text('Aucun document requis', style: TextStyle(color: Colors.white70))
                              else
                                ...docProvider.documents.map(
                                  (d) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: DocumentUploadCard(
                                      document: d,
                                      userId: widget.userId,
                                      onUploadComplete: () => docProvider.loadDocuments(widget.userId),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _UserHeaderCard extends StatelessWidget {
  final UserModel user;

  const _UserHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.containerDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.masYellow,
            child: Text(
              (user.lastName.isNotEmpty ? user.lastName[0] : '?').toUpperCase(),
              style: const TextStyle(color: AppTheme.masBlack, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _UserSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.containerDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.masYellow, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _UserRowItem extends StatelessWidget {
  final String label;
  final String value;

  const _UserRowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value.isEmpty ? '-' : value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
