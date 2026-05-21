import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_document_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/document_upload_card.dart';
import '../widgets/theme_mode_toggle.dart';
import '../core/theme/app_theme.dart';

class UserDocumentsScreen extends StatefulWidget {
  final int userId;

  const UserDocumentsScreen({super.key, required this.userId});

  @override
  State<UserDocumentsScreen> createState() => _UserDocumentsScreenState();
}

class _UserDocumentsScreenState extends State<UserDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docProvider = Provider.of<UserDocumentProvider>(context, listen: false);
    await docProvider.loadDocuments(widget.userId);
  }

  Future<void> _activateUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final ok = await userProvider.updateUserStatus(widget.userId, UserStatus.ACTIVE);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur activé'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadDocuments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Erreur activation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents de l\'utilisateur'),
        actions: AppBarActions.withTheme(
          extra: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDocuments,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: Consumer<UserDocumentProvider>(
          builder: (context, docProvider, child) {
            if (docProvider.isLoading && docProvider.documents.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.masYellow));
            }

            if (docProvider.error != null && docProvider.documents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.masYellow),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur: ${docProvider.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDocuments,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final showActivate = docProvider.isComplete &&
                docProvider.registrationStatus == UserStatus.PENDING &&
                (docProvider.userActif == false);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.containerDecoration(context),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progression des documents',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.masYellow,
                              ),
                            ),
                            Text(
                              '${docProvider.documentsCompleted}/${docProvider.documentsRequired}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.masYellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: docProvider.completionPercentage / 100,
                          backgroundColor: Colors.white.withOpacity(0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.masYellow),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${docProvider.completionPercentage}% complété',
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
                        ),
                        if (docProvider.isComplete) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.masYellow.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.masYellow, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: AppTheme.masYellow),
                                const SizedBox(width: 8),
                                Text(
                                  'Tous les documents obligatoires sont approuvés',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: docProvider.documents.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune exigence documentaire pour ce rôle',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: docProvider.documents.length,
                          itemBuilder: (context, index) {
                            final document = docProvider.documents[index];
                            return DocumentUploadCard(
                              document: document,
                              userId: widget.userId,
                              onUploadComplete: _loadDocuments,
                            );
                          },
                        ),
                ),
                if (showActivate)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _activateUser,
                        icon: const Icon(Icons.verified_user),
                        label: const Text('Activer l\'utilisateur'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
