import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class AddCotisationScreen extends StatefulWidget {
  final List<User> users;
  final String currentUserRole;
  
  const AddCotisationScreen({super.key, required this.users, required this.currentUserRole});

  @override
  State<AddCotisationScreen> createState() => _AddCotisationScreenState();
}

class _AddCotisationScreenState extends State<AddCotisationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  
  User? _selectedUser;
  String _selectedSaison = '2024-2025';
  String _selectedModePaiement = 'ESPECES';
  String _selectedStatut = 'EN_ATTENTE';
  
  XFile? _recuImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _error;

  final List<String> _saisons = ['2023-2024', '2024-2025', '2025-2026', '2026-2027'];
  final Map<String, String> _modePaiementLabels = {
    'ESPECES': 'Espèces',
    'CARTE_BANCAIRE': 'Carte bancaire',
    'VIREMENT': 'Virement',
    'CHEQUE': 'Chèque',
  };

  @override
  void initState() {
    super.initState();
    // For JOUEUR, automatically select the only user (themselves)
    if (widget.currentUserRole == 'JOUEUR' && widget.users.length == 1) {
      _selectedUser = widget.users[0];
    }
  }

  @override
  void dispose() {
    _montantController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? selected = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      
      if (selected != null) {
        final bytes = await selected.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          setState(() => _error = "L'image dépasse 5MB. Veuillez en choisir une autre.");
          return;
        }

        setState(() {
          _recuImage = selected;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = "Erreur lors de la sélection de l'image: $e");
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.masYellow),
              title: const Text('Appareil photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.masYellow),
              title: const Text('Galerie', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUser == null) {
      setState(() => _error = 'Veuillez sélectionner un utilisateur');
      return;
    }
    if (_selectedUser!.id == null) {
      setState(() => _error = 'Erreur: ID utilisateur invalide');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Create cotisation data
      final cotisationData = {
        'user': {'id': _selectedUser!.id},
        'montant': double.parse(_montantController.text),
        'datePaiement': DateTime.now().toIso8601String(),
        'saison': _selectedSaison,
        'modePaiement': _selectedModePaiement,
        'statut': _selectedStatut,
        'reference': _referenceController.text.isEmpty ? null : _referenceController.text,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      print('=== Creating Cotisation ===');
      print('Selected User ID: ${_selectedUser!.id}');
      print('Request data: $cotisationData');

      // Create cotisation
      final createdCotisation = await ApiService.createCotisation(cotisationData, widget.currentUserRole);
      print('Cotisation created successfully with ID: ${createdCotisation.id}');

      // Upload receipt if image is selected
      if (_recuImage != null) {
        print('Uploading receipt for cotisation ID: ${createdCotisation.id}');
        if (kIsWeb) {
          final bytes = await _recuImage!.readAsBytes();
          await ApiService.uploadRecuCotisation(createdCotisation.id, bytes);
        } else {
          await ApiService.uploadRecuCotisation(createdCotisation.id, _recuImage);
        }
        print('Receipt uploaded successfully');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotisation créée avec succès !')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('=== ERROR Creating Cotisation ===');
      print('Error: $e');
      setState(() {
        _isSubmitting = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une Cotisation'),
        actions: AppBarActions.withTheme(
          extra: [
            IconButton(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: const Icon(Icons.check),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Show user selector only for ADMIN and ENCADRANT
                if (widget.currentUserRole != 'JOUEUR') _buildUserSelector(),
                if (widget.currentUserRole == 'JOUEUR') _buildCurrentUserDisplay(),
                const SizedBox(height: 20),
                _buildMontantField(),
                const SizedBox(height: 20),
                _buildSaisonSelector(),
                const SizedBox(height: 20),
                _buildModePaiementSelector(),
                const SizedBox(height: 20),
                _buildStatutSelector(),
                const SizedBox(height: 20),
                _buildReferenceField(),
                const SizedBox(height: 20),
                _buildNotesField(),
                const SizedBox(height: 24),
                _buildRecuUploadArea(),
                const SizedBox(height: 24),
                if (_error != null) _buildErrorArea(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.containerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Utilisateur *',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<User>(
            value: _selectedUser,
            decoration: const InputDecoration(
              hintText: 'Sélectionner un utilisateur',
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(),
            ),
            dropdownColor: Colors.grey[900],
            items: widget.users.map((user) {
              return DropdownMenuItem<User>(
                value: user,
                child: Text('${user.nom} ${user.prenom}', style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (user) => setState(() => _selectedUser = user),
            validator: (value) => value == null ? 'Requis' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserDisplay() {
    if (_selectedUser == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.containerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Utilisateur',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.masYellow.withOpacity(0.2),
                  child: Icon(Icons.person, color: AppTheme.masYellow),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedUser!.nom} ${_selectedUser!.prenom}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMontantField() {
    return TextFormField(
      controller: _montantController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Montant (MAD) *',
        hintText: 'Ex: 500',
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Requis';
        if (double.tryParse(value) == null) return 'Montant invalide';
        return null;
      },
    );
  }

  Widget _buildSaisonSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedSaison,
      decoration: const InputDecoration(
        labelText: 'Saison *',
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(),
      ),
      dropdownColor: Colors.grey[900],
      items: _saisons.map((saison) {
        return DropdownMenuItem<String>(
          value: saison,
          child: Text(saison, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (saison) => setState(() => _selectedSaison = saison!),
    );
  }

  Widget _buildModePaiementSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedModePaiement,
      decoration: const InputDecoration(
        labelText: 'Mode de paiement *',
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(),
      ),
      dropdownColor: Colors.grey[900],
      items: _modePaiementLabels.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (mode) => setState(() => _selectedModePaiement = mode!),
    );
  }

  Widget _buildStatutSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedStatut,
      decoration: const InputDecoration(
        labelText: 'Statut *',
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(),
      ),
      dropdownColor: Colors.grey[900],
      items: [
        const DropdownMenuItem<String>(
          value: 'EN_ATTENTE',
          child: Text('En attente', style: TextStyle(color: Colors.white)),
        ),
        const DropdownMenuItem<String>(
          value: 'VALIDEE',
          child: Text('Validée', style: TextStyle(color: Colors.white)),
        ),
      ],
      onChanged: (statut) => setState(() => _selectedStatut = statut!),
    );
  }

  Widget _buildReferenceField() {
    return TextFormField(
      controller: _referenceController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Référence',
        hintText: 'Ex: VIR-12345',
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Notes',
        hintText: 'Commentaires ou observations...',
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRecuUploadArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.containerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reçu de paiement',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isSubmitting ? null : _showPickerOptions,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.masYellow.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _recuImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 64, color: AppTheme.masYellow),
                        SizedBox(height: 16),
                        Text(
                          'Prendre ou choisir une photo du reçu',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Formats acceptés: JPG, PNG (< 5MB)',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          kIsWeb
                              ? Image.network(_recuImage!.path, fit: BoxFit.cover)
                              : Image.file(File(_recuImage!.path), fit: BoxFit.cover),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => setState(() => _recuImage = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.masYellow,
        foregroundColor: AppTheme.masBlack,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : const Text(
              'CRÉER LA COTISATION',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }
}
