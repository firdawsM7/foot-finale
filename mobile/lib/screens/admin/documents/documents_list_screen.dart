import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../../../providers/document_provider.dart';
import '../../../widgets/theme_mode_toggle.dart';
import 'document_upload_screen.dart';
import 'document_detail_screen.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  String? _selectedType;
  bool _onlyExpiring = false;

  final List<String> _types = [
    'CERTIFICAT_MEDICAL',
    'LICENCE',
    'ASSURANCE',
    'CONTRAT',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    await context.read<DocumentProvider>().loadDocuments(
      type: _selectedType,
      expirant: _onlyExpiring,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GESTION DOCUMENTAIRE'),
        actions: AppBarActions.withTheme(
          extra: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentUploadScreen()),
              ).then((_) => _refresh()),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: Consumer<DocumentProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Erreur: ${provider.error}', style: const TextStyle(color: Colors.red)),
                          ElevatedButton(onPressed: _refresh, child: const Text('Réessayer')),
                        ],
                      ),
                    );
                  }
                  if (provider.documents.isEmpty) {
                    return const Center(child: Text('Aucun document trouvé'));
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.documents.length,
                      itemBuilder: (context, index) {
                        return _buildDocumentCard(provider.documents[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type de document'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous les types')),
                    ..._types.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value);
                    _refresh();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const Text('Expirant', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _onlyExpiring,
                    onChanged: (value) {
                      setState(() => _onlyExpiring = value);
                      _refresh();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Document doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  doc.type == 'CERTIFICAT_MEDICAL' ? Icons.medical_services : Icons.description,
                  color: AppTheme.masYellow,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.type.replaceAll('_', ' '),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${doc.userNom} ${doc.userPrenom}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(doc),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expire le: ${doc.dateExpiration != null ? DateFormat('dd/MM/yyyy').format(doc.dateExpiration!) : 'N/A'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      doc.isExpired 
                          ? 'EXPIRÉ' 
                          : '${doc.joursRestants} jours restants',
                      style: TextStyle(
                        fontSize: 12,
                        color: doc.isExpired ? Colors.red : (doc.isExpiringSoon ? Colors.orange : Colors.green),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
                      ),
                    ),
                    if (!doc.valide)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        onPressed: () => _showValidateDialog(doc),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteDialog(doc),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Document doc) {
    Color color;
    String text;

    if (doc.isExpired) {
      color = Colors.red;
      text = 'EXPIRÉ';
    } else if (doc.isExpiringSoon) {
      color = Colors.orange;
      text = 'EXPIRANT';
    } else if (doc.valide) {
      color = Colors.green;
      text = 'VALIDÉ';
    } else {
      color = Colors.grey;
      text = 'À VALIDER';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _showValidateDialog(Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider le document'),
        content: Text('Voulez-vous valider le document "${doc.nom}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('VALIDER', style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<DocumentProvider>().validateDocument(doc.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document validé')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _showDeleteDialog(Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: Text('Voulez-vous vraiment supprimer le document "${doc.nom}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SUPPRIMER', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<DocumentProvider>().deleteDocument(doc.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document supprimé')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
