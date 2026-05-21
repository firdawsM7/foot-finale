import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool edit = false;
  final _form = GlobalKey<FormState>();
  String? nom;
  String? prenom;
  String? email;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    nom ??= user?.nom;
    prenom ??= user?.prenom;
    email ??= user?.email;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: AppBarActions.withTheme(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 100),
              _buildHeader(user),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    if (edit) _buildEditForm(auth, user) else _buildInfoCards(user),
                    const SizedBox(height: 24),
                    _buildRoleSpecificSection(user),
                    const SizedBox(height: 24),

                    _buildSecuritySection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    final auth = context.read<AuthProvider>();
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: () => _pickAndUploadPhoto(auth),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.masYellow, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.masYellow.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.masBlack,
                  backgroundImage: user?.photo != null && user!.photo!.isNotEmpty
                      ? NetworkImage(user.photo!)
                      : null,
                  child: user?.photo == null || user!.photo!.isEmpty
                      ? const Icon(Icons.person, size: 70, color: AppTheme.masYellow)
                      : null,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _pickAndUploadPhoto(auth),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.masYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 20, color: AppTheme.masBlack),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${user?.prenom ?? ''} ${user?.nom ?? ''}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.masYellow.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.masYellow.withOpacity(0.5)),
          ),
          child: Text(
            user?.role ?? 'MEMBRE',
            style: const TextStyle(
              color: AppTheme.masYellow,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.containerDecoration(context),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email', user?.email ?? ''),
          const Divider(color: Colors.white12, height: 32),
          _buildInfoRow(Icons.calendar_today_outlined, 'Membre depuis', 'Janvier 2024'),
        ],
      ),
    );
  }



  Widget _buildSectionContainer(String title, IconData icon, List<Widget> children, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.containerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color ?? AppTheme.masYellow, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color ?? AppTheme.masYellow, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.masYellow, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm(AuthProvider auth, User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.containerDecoration(context),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              initialValue: nom,
              decoration: AppTheme.inputDecoration('Nom', Icons.person_outline),
              onSaved: (v) => nom = v,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: prenom,
              decoration: AppTheme.inputDecoration('Prénom', Icons.person_outline),
              onSaved: (v) => prenom = v,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: email,
              decoration: AppTheme.inputDecoration('Email', Icons.email_outlined),
              onSaved: (v) => email = v,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => edit = false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _form.currentState?.save();
                      if (user != null) {
                        auth.updateLocalUser(nom: nom, prenom: prenom, email: email);
                      }
                      setState(() => edit = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.masYellow,
                      foregroundColor: AppTheme.masBlack,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificSection(User? user) {
    switch (user?.role) {
      case 'ADMIN':
        return _buildAdminSection();
      case 'ENCADRANT':
        return _buildEncadrantSection();
      case 'ADHERENT':
        return _buildAdherentSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAdminSection() {
    return _buildSectionContainer(
      'Administration',
      Icons.admin_panel_settings_outlined,
      [
        _buildStatRow('Utilisateurs Actifs', '124'),
        _buildStatRow('Équipes Total', '12'),
        _buildStatRow('Derniers rapports', '3 nouveaux'),
      ],
    );
  }

  Widget _buildEncadrantSection() {
    return _buildSectionContainer(
      'Mes Équipes',
      Icons.groups_outlined,
      [
        _buildStatRow('Équipes coachées', '2'),
        _buildStatRow('Joueurs sous responsabilité', '45'),
        _buildStatRow('Prochain entraînement', 'Demain 18:00'),
      ],
    );
  }

  Widget _buildAdherentSection() {
    return _buildSectionContainer(
      'Ma Cotisation',
      Icons.payment_outlined,
      [
        _buildStatRow('Statut', 'À jour', valueColor: Colors.green),
        _buildStatRow('Dernier paiement', '01 Janvier 2024'),
        _buildStatRow('Prochaine échéance', '01 Février 2024'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _buildSectionContainer(
      'Sécurité & Thème',
      Icons.security_outlined,
      [
        const ThemeModeSwitchTile(),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_reset),
          title: const Text('Changer le mot de passe', style: TextStyle(fontSize: 15)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showChangePasswordDialog,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent, fontSize: 15)),
          onTap: () async {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            await auth.logout();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ],
      color: Colors.blue,
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.masBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sécurité', style: TextStyle(color: AppTheme.masYellow)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pour changer votre mot de passe, un lien de réinitialisation vous sera envoyé par email.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: AppTheme.inputDecoration('Votre Email', Icons.email_outlined),
              style: const TextStyle(color: Colors.white),
              readOnly: true,
              controller: TextEditingController(text: email),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lien envoyé avec succès')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.masYellow),
            child: const Text('Envoyer le lien', style: TextStyle(color: AppTheme.masBlack, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(AuthProvider auth) async {
    final ImagePicker picker = ImagePicker();
    
    // Show dialog to choose between camera and gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Caméra'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source);
    
    if (image != null) {
      final File imageFile = File(image.path);
      final success = await auth.uploadProfilePhoto(imageFile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Photo mise à jour avec succès' 
                  : 'Erreur lors de la mise à jour: ${auth.error}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
