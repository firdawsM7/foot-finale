import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../../widgets/empty_state.dart';
import 'upload_recu_screen.dart';
import 'add_cotisation_screen.dart';

class CotisationsScreen extends StatefulWidget {
  const CotisationsScreen({super.key});

  @override
  State<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends State<CotisationsScreen> {
  List<Cotisation> cotisations = [];
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? stats;

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
      
      final auth = context.read<AuthProvider>();
      final role = auth.user?.role ?? 'ADHERENT';
      
      final loaded = await ApiService.getAllCotisations(role);
      
      if (role == 'ADMIN') {
        stats = await ApiService.getCotisationsStats();
      }
      
      setState(() {
        cotisations = loaded;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().user?.role ?? 'ADHERENT';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotisations'),
        actions: AppBarActions.withTheme(
          extra: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: isLoading 
            ? const LoadingWidget(message: 'Chargement des cotisations...')
            : error != null 
                ? _buildErrorArea()
                : _buildContent(role),
      ),
      floatingActionButton: role == 'ADMIN' || role == 'ENCADRANT' || role == 'JOUEUR' || role == 'ADHERENT'
          ? FloatingActionButton(onPressed: _showAdd, child: const Icon(Icons.add))
          : null,
    );
  }

  Widget _buildErrorArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: AppTheme.masYellow),
          const SizedBox(height: 16),
          Text('Erreur: $error', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildContent(String role) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (role == 'ADMIN' && stats != null) _buildAdminStats(),
          if (cotisations.isEmpty)
            const EmptyState(title: 'Aucune cotisation trouvée', icon: Icons.payment_outlined)
          else
            ...cotisations.map((c) => _buildCotisationCard(c, role)),
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.containerDecoration(context),
      child: Column(
        children: [
          const Text('Aperçu Global', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats!['total'].toString(), Icons.assignment),
              _buildStatItem('En attente', stats!['enAttente'].toString(), Icons.pending, color: Colors.orange),
              _buildStatItem('Montant total', '${stats!['montantTotal']} MAD', Icons.euro_symbol, color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.masYellow, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildCotisationCard(Cotisation c, String role) {
    Color statusColor = Colors.grey;
    if (c.statut == 'VALIDEE') statusColor = Colors.green;
    if (c.statut == 'REJETEE') statusColor = Colors.red;
    if (c.statut == 'EN_ATTENTE') statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.containerDecoration(context),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.payment, color: statusColor),
        ),
        title: Text(
          role == 'ADMIN' ? '${c.userNom} ${c.userPrenom}' : 'Cotisation ${c.saison}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c.montant} MAD - ${c.modePaiementLabel}', style: const TextStyle(color: Colors.white70)),
            if (role == 'ADMIN') Text('Saison: ${c.saison}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                c.statutLabel,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            if (c.recuPhoto != null)
              const Icon(Icons.attachment, color: Colors.white38, size: 16),
          ],
        ),
        onTap: () => _showOptions(c, role),
      ),
    );
  }

  void _showOptions(Cotisation c, String role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (c.recuPhoto != null)
              ListTile(
                leading: const Icon(Icons.visibility, color: AppTheme.masYellow),
                title: const Text('Voir le reçu', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showRecuImage(c.recuPhoto!);
                },
              ),
            if (role != 'ADMIN' && c.statut != 'VALIDEE')
              ListTile(
                leading: const Icon(Icons.upload_file, color: AppTheme.masYellow),
                title: Text(c.recuPhoto == null ? 'Uploader reçu' : 'Modifier le reçu', style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UploadRecuScreen(cotisation: c)),
                  );
                  if (success == true) _load();
                },
              ),
            if (role == 'ADMIN') ...[
              if (c.statut == 'EN_ATTENTE') ...[
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Valider le paiement', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await ApiService.validerCotisation(c.id);
                    _load();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Rejeter avec motif', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showRejetDialog(c);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.grey),
                title: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await ApiService.deleteCotisation(c.id);
                  _load();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRecuImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ),
            Expanded(child: InteractiveViewer(child: Image.network(url))),
          ],
        ),
      ),
    );
  }

  void _showRejetDialog(Cotisation c) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motif du rejet'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Ex: Photo floue, montant incorrect')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () async {
            await ApiService.rejeterCotisation(c.id, controller.text);
            Navigator.pop(context);
            _load();
          }, child: const Text('Confirmer')),
        ],
      ),
    );
  }

  void _showAdd() async {
    try {
      // Get current user and role from auth provider
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      final role = currentUser?.role ?? 'ADHERENT';
      
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Load users based on role
      List<User> users;
      if (role == 'ADMIN' || role == 'ENCADRANT') {
        // Load all users for ADMIN and ENCADRANT
        final dynamicUsers = await ApiService.getAllJoueurs(role);
        // Convert to User objects
        users = dynamicUsers.map((u) {
          if (u is User) {
            return u;
          } else if (u is Joueur) {
            // Convert Joueur to User - Joueur doesn't have email, use empty string
            return User(
              id: u.id,
              email: '', // Joueur doesn't have email field
              nom: u.nom,
              prenom: u.prenom,
              role: 'JOUEUR', // Joueur objects are players
              telephone: null, // Joueur doesn't have telephone
              adresse: null, // Joueur doesn't have adresse
              dateNaissance: u.dateNaissance,
              photo: u.photo,
              actif: u.actif,
              dateInscription: null, // Joueur doesn't have dateInscription
              derniereConnexion: null, // Joueur doesn't have derniereConnexion
              equipeId: u.equipeId,
            );
          } else {
            // Fallback for any other type
            return User(
              id: u.id,
              email: u.email ?? '',
              nom: u.nom ?? '',
              prenom: u.prenom ?? '',
              role: u.role ?? 'JOUEUR',
              telephone: u.telephone,
              adresse: u.adresse,
              dateNaissance: u.dateNaissance,
              photo: u.photo,
              actif: u.actif ?? true,
              dateInscription: u.dateInscription,
              derniereConnexion: u.derniereConnexion,
              equipeId: u.equipeId,
            );
          }
        }).toList();
      } else {
        // For JOUEUR, ADHERENT - only show current user
        users = [currentUser];
      }

      // Navigate to add cotisation screen
      final success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddCotisationScreen(users: users, currentUserRole: role),
        ),
      );

      // Reload if successful
      if (success == true && mounted) {
        _load();
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

