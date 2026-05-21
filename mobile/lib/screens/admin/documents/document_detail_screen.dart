import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/themed_app_bar.dart';
import '../../../models/document.dart';
import '../../../config/api_config.dart';
import '../../../providers/document_provider.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late Document _document;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  String get _fullUrl => '${ApiConfig.baseUrl}/uploads/documents/${_document.url}';
  bool get _isPdf => _document.url.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemedAppBar(titleText: _document.type.replaceAll('_', ' ')),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: Column(
          children: [
            Expanded(child: _buildPreview()),
            _buildDetails(),
          ],
        ),
      ),
      bottomNavigationBar: _buildActions(),
    );
  }

  Widget _buildPreview() {
    if (_isPdf) {
      // In a real app we might need to download the PDF to a temp file first for PDFView
      // For this implementation, we'll try showing it or provide a placeholder
      return Container(
        color: Colors.white10,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 80, color: AppTheme.masYellow),
              SizedBox(height: 16),
              Text('Prévisualisation PDF'),
              Text('Le fichier peut être téléchargé pour lecture complète', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    } else {
      return Image.network(
        _fullUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 80, color: Colors.white24),
                Text('Image non disponible'),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.masBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.masYellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoRow('Joueur', '${_document.userNom} ${_document.userPrenom}'),
          _buildInfoRow('Type', _document.type.replaceAll('_', ' ')),
          _buildInfoRow('Expiration', _document.dateExpiration != null 
              ? DateFormat('dd/MM/yyyy').format(_document.dateExpiration!) 
              : 'N/A'),
          _buildInfoRow('Statut', _document.valide ? 'VALIDÉ' : 'EN ATTENTE', 
              color: _document.valide ? Colors.green : AppTheme.masYellow),
          _buildInfoRow('Ajouté le', DateFormat('dd/MM/yyyy HH:mm').format(_document.uploadDate)),
          _buildInfoRow('Par', _document.uploadedBy),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.masBlack,
      child: Row(
        children: [
          if (!_document.valide)
            Expanded(
              child: ElevatedButton(
                onPressed: _validate,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('VALIDER'),
              ),
            ),
          if (!_document.valide) const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Future implementation: Download and open
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Téléchargement lancé...')));
              },
              child: const Text('TÉLÉCHARGER'),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _validate() async {
    try {
      await context.read<DocumentProvider>().validateDocument(_document.id);
      setState(() {
        _document = context.read<DocumentProvider>().documents.firstWhere((d) => d.id == _document.id);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document validé')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous supprimer ce document ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NON')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OUI')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<DocumentProvider>().deleteDocument(_document.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document supprimé')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
