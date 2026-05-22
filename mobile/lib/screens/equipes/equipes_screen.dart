import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/themed_app_bar.dart';
import '../../widgets/empty_state.dart';
import '../chat_screen.dart';

class EquipesScreen extends StatefulWidget {
  const EquipesScreen({super.key});

  @override
  State<EquipesScreen> createState() => _EquipesScreenState();
}

class _EquipesScreenState extends State<EquipesScreen> {
  List<Equipe> equipes = [];
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
      
      // Récupérer le rôle de l'utilisateur connecté
      final auth = context.read<AuthProvider>();
      final userRole = auth.user?.role ?? 'ADHERENT';
      
      final loaded = await ApiService.getAllEquipes(userRole);
      setState(() => equipes = loaded);
    } catch (e) {
      setState(()=> error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildEquipeTile(Equipe e) {
    final role = context.read<AuthProvider>().user?.role;
    final isAdmin = role == 'ADMIN';
    final showTeamChat = role != 'ENCADRANT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.containerDecoration(context),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.masYellow,
          child: Icon(Icons.groups, color: AppTheme.masBlack),
        ),
        title: Text(
          e.nom,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          e.categorie ?? '',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTeamChat)
              IconButton(
                icon: const Icon(Icons.chat, color: AppTheme.masYellow),
                onPressed: e.id == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(teamId: e.id!, teamName: e.nom),
                          ),
                        ),
              ),
            if (isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: AppTheme.masYellow),
                onPressed: e.id == null ? null : () => _showEdit(e),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: e.id == null ? null : () => _delete(e),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'Équipes'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: isLoading ? const LoadingWidget(message: 'Chargement des équipes...') :
        error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error, size: 48, color: AppTheme.masYellow), const SizedBox(height:8), Text('Erreur: $error', style: const TextStyle(color: Colors.white)), const SizedBox(height:8), ElevatedButton(onPressed: _load, child: const Text('Réessayer'))])) :
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(style: const TextStyle(color: Colors.white), decoration: const InputDecoration(prefixIcon: Icon(Icons.search, color: AppTheme.masYellow), hintText: 'Rechercher équipe', hintStyle: TextStyle(color: Colors.white38)), onChanged: (v)=> setState(()=> search = v)),
              const SizedBox(height:12),
              if (_filtered().isEmpty)
                const EmptyState(title: 'Aucune équipe')
              else
                Column(children: _filtered().map(_buildEquipeTile).toList())
            ],
          ),
        ),
      ),
      floatingActionButton: context.read<AuthProvider>().user?.role == 'ADMIN' || context.read<AuthProvider>().user?.role == 'ENCADRANT' ? FloatingActionButton(onPressed: _showAdd, child: const Icon(Icons.add)) : null,
    );
  }

  List<Equipe> _filtered(){
    if(search.isEmpty) return equipes;
    return equipes.where((e)=> ('${e.nom} ${e.categorie}').toLowerCase().contains(search.toLowerCase())).toList();
  }

  void _showAdd(){
    final authProvider = context.read<AuthProvider>();
    final userRole = authProvider.user?.role;
    
    if (userRole != 'ADMIN' && userRole != 'ENCADRANT') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accès refusé: Seuls les administrateurs et encadrants peuvent créer des équipes')));
      return;
    }
    
    final form = GlobalKey<FormState>();
    String nom = '';
    String cat = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Créer équipe'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                onSaved: (v) => nom = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Catégorie'),
                onSaved: (v) => cat = v ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!(form.currentState?.validate() ?? false)) return;
              form.currentState?.save();
              if (nom.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom est obligatoire')),
                );
                return;
              }

              try {
                await ApiService.createEquipe({
                  'nom': nom.trim(),
                  'categorie': cat.trim().isEmpty ? null : cat.trim(),
                  'active': true,
                }, userRole!);
                if (!mounted) return;
                Navigator.pop(context);
                await _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Équipe créée')),
                );
              } catch (err) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $err'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEdit(Equipe e) {
    if (e.id == null) return;

    final form = GlobalKey<FormState>();
    String nom = e.nom;
    String cat = e.categorie ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier équipe'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: nom,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                onSaved: (v) => nom = v?.trim() ?? '',
              ),
              TextFormField(
                initialValue: cat,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                onSaved: (v) => cat = v?.trim() ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!(form.currentState?.validate() ?? false)) return;
              form.currentState?.save();

              try {
                final body = <String, dynamic>{
                  'nom': nom,
                  'categorie': cat.isEmpty ? null : cat,
                  'active': e.active,
                };
                if (e.description != null) body['description'] = e.description;
                if (e.encadrantId != null) body['encadrant'] = {'id': e.encadrantId};

                await ApiService.updateEquipe(e.id!, body);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Équipe mise à jour')),
                );
              } catch (err) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $err'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _delete(Equipe e) {
    if (e.id == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer équipe'),
        content: Text('Supprimer l\'équipe « ${e.nom} » ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteEquipe(e.id!);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Équipe supprimée')),
                );
              } catch (err) {
                if (!mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $err'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
