import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../providers/user_document_provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';

class DocumentUploadCard extends StatefulWidget {
  final DocumentModel document;
  final int userId;
  final VoidCallback onUploadComplete;

  DocumentUploadCard({
    required this.document,
    required this.userId,
    required this.onUploadComplete,
  });

  @override
  _DocumentUploadCardState createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  File? _selectedFile;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes; // For web
  bool _isUploading = false;

  String? get _fileUrl {
    final name = widget.document.fileName;
    if (name == null || name.isEmpty) return null;
    final docType = widget.document.documentType.toString().split('.').last;
    // Backend is mounted under `/api`, and static handlers are relative to that context.
    // So public files are available at: `${ApiConfig.apiBaseUrl}/uploads/...`
    final base = Uri.parse(ApiConfig.apiBaseUrl);
    // Build via pathSegments to ensure proper encoding (spaces, unicode, etc.).
    return base
        .replace(pathSegments: [
          ...base.pathSegments.where((s) => s.isNotEmpty),
          'uploads',
          widget.userId.toString(),
          docType,
          name,
        ])
        .toString();
  }

  Future<void> _pickFile() async {
    try {
      final isImage = widget.document.documentType == DocumentType.IDENTITY_PHOTO;
      
      final exts = widget.document.allowedFileTypes
          .split(RegExp(r'[,\s]+'))
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .map((e) => e.replaceAll('.', ''))
          .toList();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: isImage ? FileType.image : FileType.custom,
        allowedExtensions: isImage ? null : exts,
      );

      if (result != null) {
        final platformFile = result.files.single;
        
        setState(() {
          _selectedFileName = platformFile.name;
          
          // For web, store bytes; for mobile, use path
          if (kIsWeb && platformFile.bytes != null) {
            _selectedFileBytes = platformFile.bytes;
            _selectedFile = null;
          } else if (platformFile.path != null) {
            _selectedFile = File(platformFile.path!);
            _selectedFileBytes = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection: $e')),
      );
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null && _selectedFileBytes == null) return;

    // Check file size (5MB max)
    if (_selectedFile != null && _selectedFile!.lengthSync() > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le fichier dépasse 5MB')),
      );
      return;
    }
    
    if (_selectedFileBytes != null && _selectedFileBytes!.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le fichier dépasse 5MB')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final docProvider = Provider.of<UserDocumentProvider>(context, listen: false);
      
      bool success;
      if (kIsWeb && _selectedFileBytes != null) {
        // Direct upload for web using bytes
        success = await _uploadBytesDirect(docProvider);
      } else {
        // Mobile upload using File
        success = await docProvider.uploadDocument(
          userId: widget.userId,
          documentType: widget.document.documentType,
          file: _selectedFile!,
          // Admin may need to replace even if pending/approved
          forceReplace: true,
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document uploadé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedFile = null;
          _selectedFileBytes = null;
          _selectedFileName = null;
        });
        widget.onUploadComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${docProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Direct upload for web using bytes
  Future<bool> _uploadBytesDirect(UserDocumentProvider docProvider) async {
    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/admin/users/${widget.userId}/documents?force=true');
      
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer ${authProvider.token}';
      
      request.fields['documentType'] = widget.document.documentType.toString().split('.').last;
      
      // Determine MIME type from file extension
      String extension = _selectedFileName!.split('.').last.toLowerCase();
      String mimeType;
      if (extension == 'pdf') {
        mimeType = 'application/pdf';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (extension == 'png') {
        mimeType = 'image/png';
      } else {
        mimeType = 'application/octet-stream';
      }
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFileBytes!,
          filename: _selectedFileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
      
      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Upload bytes error: $e');
      return false;
    }
  }

  Future<void> _deleteDocument() async {
    final id = widget.document.id;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: const Text('Confirmer la suppression de ce document ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isUploading = true);
    final docProvider = context.read<UserDocumentProvider>();
    final success = await docProvider.deleteDocument(userId: widget.userId, documentId: id);
    if (!mounted) return;
    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document supprimé')),
      );
      widget.onUploadComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(docProvider.error ?? 'Erreur'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _previewDocument() async {
    final url = _fileUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    final ok = kIsWeb
        ? (await launchUrl(uri, webOnlyWindowName: '_blank') ||
            await launchUrl(uri, webOnlyWindowName: '_self'))
        : await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aperçu indisponible. Lien: $url'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Color _getStatusColor() {
    switch (widget.document.status) {
      case DocumentStatus.APPROVED:
        return AppTheme.masYellow;
      case DocumentStatus.PENDING:
        return AppTheme.masYellow;
      case DocumentStatus.REJECTED:
        return Colors.red;
      case DocumentStatus.MISSING:
        return Colors.white54;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.document.status) {
      case DocumentStatus.APPROVED:
        return Icons.check_circle;
      case DocumentStatus.PENDING:
        return Icons.pending;
      case DocumentStatus.REJECTED:
        return Icons.cancel;
      case DocumentStatus.MISSING:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Admin capabilities: allow add missing, replace existing, delete existing.
    final canUpload = true;
    final hasRemoteFile = widget.document.fileName != null && widget.document.fileName!.isNotEmpty;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(
          _getStatusIcon(),
          color: _getStatusColor(),
          size: 32,
        ),
        title: Text(
          widget.document.documentLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    widget.document.statusLabel,
                    style: TextStyle(color: _getStatusColor()),
                  ),
                  backgroundColor: _getStatusColor().withOpacity(0.12),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                SizedBox(width: 8),
                if (widget.document.isRequired)
                  Chip(
                    label: Text(
                      'OBLIGATOIRE',
                      style: TextStyle(color: Colors.red),
                    ),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (widget.document.isConditional) ...[
                  SizedBox(width: 8),
                  Chip(
                    label: Text(
                      'CONDITIONNEL',
                      style: TextStyle(color: Colors.deepPurple[800]!),
                    ),
                    backgroundColor: Colors.deepPurple.withOpacity(0.08),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document info
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Formats acceptés: ${widget.document.allowedFileTypes}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Rejection reason
                if (widget.document.status == DocumentStatus.REJECTED &&
                    widget.document.rejectionReason != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Raison du rejet:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.document.rejectionReason!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                // File name
                if (widget.document.fileName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 16, color: AppTheme.masYellow),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fichier: ${widget.document.fileName}',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading || !hasRemoteFile ? null : _previewDocument,
                          icon: const Icon(Icons.visibility),
                          label: const Text('Aperçu'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.masYellow,
                            side: const BorderSide(color: AppTheme.masYellow),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading || widget.document.id == null ? null : _deleteDocument,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],

                // Selected file
                if (_selectedFile != null || _selectedFileBytes != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.masYellow.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                      border: Border.all(color: AppTheme.masYellow.withOpacity(isDark ? 0.8 : 0.6)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: AppTheme.masYellow),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFileName!,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: () => setState(() {
                            _selectedFile = null;
                            _selectedFileBytes = null;
                            _selectedFileName = null;
                          }),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                // Action buttons
                Row(
                  children: [
                    if (canUpload) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickFile,
                          icon: Icon(Icons.folder_open),
                          label: Text(hasRemoteFile ? 'Remplacer' : 'Ajouter'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: AppTheme.masYellow,
                            side: const BorderSide(color: AppTheme.masYellow),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (_selectedFile != null || _selectedFileBytes != null) && !_isUploading ? _uploadDocument : null,
                          icon: _isUploading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.cloud_upload),
                          label: Text(_isUploading ? 'Upload...' : 'Uploader'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.document.id != null &&
                    widget.document.status == DocumentStatus.PENDING) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUploading
                              ? null
                              : () async {
                                  final docProvider = Provider.of<UserDocumentProvider>(
                                      context,
                                      listen: false);
                                  final ok = await docProvider.approveDocument(widget.document.id!);
                                  if (!context.mounted) return;
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Document approuvé'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    widget.onUploadComplete();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(docProvider.error ?? 'Erreur'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          child: Text('Approuver'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUploading ? null : _promptReject,
                          child: Text('Rejeter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptReject() async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Motif du rejet'),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(hintText: 'Obligatoire'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler')),
          TextButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final docProvider = Provider.of<UserDocumentProvider>(context, listen: false);
    final success = await docProvider.rejectDocument(widget.document.id!, reasonCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document rejeté'), backgroundColor: Colors.orange),
      );
      widget.onUploadComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(docProvider.error ?? 'Erreur'), backgroundColor: Colors.red),
      );
    }
  }
}
