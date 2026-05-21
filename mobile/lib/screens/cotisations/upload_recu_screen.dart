import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/themed_app_bar.dart';
import '../../services/api_service.dart';
import '../../models/cotisation.dart';

class UploadRecuScreen extends StatefulWidget {
  final Cotisation cotisation;

  const UploadRecuScreen({super.key, required this.cotisation});

  @override
  State<UploadRecuScreen> createState() => _UploadRecuScreenState();
}

class _UploadRecuScreenState extends State<UploadRecuScreen> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? selected = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      
      if (selected != null) {
        // Simple client-side size check (approximative)
        final bytes = await selected.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          setState(() => _error = "L'image dépasse 5MB. Veuillez en choisir une autre.");
          return;
        }

        setState(() {
          _image = selected;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = "Erreur lors de la sélection de l'image: $e");
    }
  }

  Future<void> _upload() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
      _uploadProgress = 0.1; // Start progress
    });

    try {
      if (kIsWeb) {
        final bytes = await _image!.readAsBytes();
        await ApiService.uploadRecuCotisation(widget.cotisation.id, bytes);
      } else {
        await ApiService.uploadRecuCotisation(widget.cotisation.id, _image);
      }
      
      setState(() => _uploadProgress = 1.0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reçu uploadé avec succès !')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'Uploader Reçu'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCotisationSummary(),
              const SizedBox(height: 32),
              _buildImagePickerArea(),
              const SizedBox(height: 32),
              if (_error != null) _buildErrorArea(),
              if (_isUploading) _buildProgressArea(),
              const SizedBox(height: 24),
              _buildUploadButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCotisationSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.containerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cotisation - Saison ${widget.cotisation.saison}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Montant:', style: TextStyle(color: Colors.white70)),
              Text(
                '${widget.cotisation.montant.toStringAsFixed(2)} MAD',
                style: const TextStyle(color: AppTheme.masYellow, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerArea() {
    return GestureDetector(
      onTap: _isUploading ? null : () => _showPickerOptions(),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.masYellow.withOpacity(0.3), width: 2),
        ),
        child: _image == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 64, color: AppTheme.masYellow),
                  SizedBox(height: 16),
                  Text('Prendre ou choisir une photo du reçu', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text('Formats acceptés: JPG, PNG (< 5MB)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb 
                      ? Image.network(_image!.path, fit: BoxFit.cover)
                      : Image.file(File(_image!.path), fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _image = null),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Widget _buildProgressArea() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: Colors.white12,
          color: AppTheme.masYellow,
        ),
        const SizedBox(height: 8),
        const Text('Upload en cours...', style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: (_image == null || _isUploading) ? null : _upload,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.masYellow,
        foregroundColor: AppTheme.masBlack,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isUploading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : const Text('UPLOADER LE REÇU', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
