import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/user_model.dart';
import '../models/document_model.dart';
import '../models/models.dart';
import '../providers/user_provider.dart';
import '../providers/user_document_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../core/theme/app_theme.dart';
import '../widgets/themed_app_bar.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  UserRole? _selectedRole;
  bool _isSubmitting = false;
  
  // JOUEUR-specific fields
  Equipe? _selectedEquipe;
  String? _selectedPoste;
  List<Equipe> _equipes = [];
  bool _isLoadingEquipes = false;
  
  // Step management
  int _currentStep = 0; // 0 = user info, 1 = documents
  int? _createdUserId;
  
  // Document uploads
  Map<DocumentType, File?> _documentFiles = {};
  Map<DocumentType, Uint8List?> _documentBytes = {}; // For web
  Map<DocumentType, String?> _documentFileNames = {}; // File names
  Map<DocumentType, bool> _uploadingDocuments = {};

  @override
  void initState() {
    super.initState();
    _loadEquipes();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEquipes() async {
    setState(() => _isLoadingEquipes = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final equipes = await ApiService.getAllEquipes(authProvider.user?.role ?? 'USER');
      setState(() {
        _equipes = equipes;
        _isLoadingEquipes = false;
      });
    } catch (e) {
      setState(() => _isLoadingEquipes = false);
    }
  }

  void _initializeDocumentTypes(UserRole role) {
    _documentFiles.clear();
    _documentBytes.clear();
    _documentFileNames.clear();
    _uploadingDocuments.clear();
    
    // Add required document types based on role
    if (role == UserRole.JOUEUR) {
      _documentFiles[DocumentType.CIN_OR_BIRTH_CERTIFICATE] = null;
      _documentBytes[DocumentType.CIN_OR_BIRTH_CERTIFICATE] = null;
      _documentFileNames[DocumentType.CIN_OR_BIRTH_CERTIFICATE] = null;
      _documentFiles[DocumentType.IDENTITY_PHOTO] = null;
      _documentBytes[DocumentType.IDENTITY_PHOTO] = null;
      _documentFileNames[DocumentType.IDENTITY_PHOTO] = null;
      _documentFiles[DocumentType.MEDICAL_CERTIFICATE] = null;
      _documentBytes[DocumentType.MEDICAL_CERTIFICATE] = null;
      _documentFileNames[DocumentType.MEDICAL_CERTIFICATE] = null;
      _documentFiles[DocumentType.FEDERAL_LICENSE] = null;
      _documentBytes[DocumentType.FEDERAL_LICENSE] = null;
      _documentFileNames[DocumentType.FEDERAL_LICENSE] = null;
      _documentFiles[DocumentType.REGISTRATION_FORM] = null;
      _documentBytes[DocumentType.REGISTRATION_FORM] = null;
      _documentFileNames[DocumentType.REGISTRATION_FORM] = null;
      _documentFiles[DocumentType.PROOF_OF_ADDRESS] = null;
      _documentBytes[DocumentType.PROOF_OF_ADDRESS] = null;
      _documentFileNames[DocumentType.PROOF_OF_ADDRESS] = null;
      // Check if minor (add parental authorization)
      if (_dateOfBirth != null && _isMinor(_dateOfBirth!)) {
        _documentFiles[DocumentType.PARENTAL_AUTHORIZATION] = null;
        _documentBytes[DocumentType.PARENTAL_AUTHORIZATION] = null;
        _documentFileNames[DocumentType.PARENTAL_AUTHORIZATION] = null;
      }
    } else if (role == UserRole.ENCADRANT) {
      _documentFiles[DocumentType.CIN] = null;
      _documentBytes[DocumentType.CIN] = null;
      _documentFileNames[DocumentType.CIN] = null;
      _documentFiles[DocumentType.IDENTITY_PHOTO] = null;
      _documentBytes[DocumentType.IDENTITY_PHOTO] = null;
      _documentFileNames[DocumentType.IDENTITY_PHOTO] = null;
      _documentFiles[DocumentType.SPORT_DIPLOMA] = null;
      _documentBytes[DocumentType.SPORT_DIPLOMA] = null;
      _documentFileNames[DocumentType.SPORT_DIPLOMA] = null;
      _documentFiles[DocumentType.CV] = null;
      _documentBytes[DocumentType.CV] = null;
      _documentFileNames[DocumentType.CV] = null;
      _documentFiles[DocumentType.CRIMINAL_RECORD] = null;
      _documentBytes[DocumentType.CRIMINAL_RECORD] = null;
      _documentFileNames[DocumentType.CRIMINAL_RECORD] = null;
      _documentFiles[DocumentType.CONTRACT] = null;
      _documentBytes[DocumentType.CONTRACT] = null;
      _documentFileNames[DocumentType.CONTRACT] = null;
      _documentFiles[DocumentType.FEDERAL_LICENSE_COACH] = null;
      _documentBytes[DocumentType.FEDERAL_LICENSE_COACH] = null;
      _documentFileNames[DocumentType.FEDERAL_LICENSE_COACH] = null;
    } else if (role == UserRole.ADHERENT) {
      _documentFiles[DocumentType.CIN_OR_BIRTH_CERTIFICATE] = null;
      _documentBytes[DocumentType.CIN_OR_BIRTH_CERTIFICATE] = null;
      _documentFileNames[DocumentType.CIN_OR_BIRTH_CERTIFICATE] = null;
      _documentFiles[DocumentType.IDENTITY_PHOTO] = null;
      _documentBytes[DocumentType.IDENTITY_PHOTO] = null;
      _documentFileNames[DocumentType.IDENTITY_PHOTO] = null;
      _documentFiles[DocumentType.MEMBERSHIP_FORM] = null;
      _documentBytes[DocumentType.MEMBERSHIP_FORM] = null;
      _documentFileNames[DocumentType.MEMBERSHIP_FORM] = null;
      _documentFiles[DocumentType.PAYMENT_PROOF] = null;
      _documentBytes[DocumentType.PAYMENT_PROOF] = null;
      _documentFileNames[DocumentType.PAYMENT_PROOF] = null;
      if (_dateOfBirth != null && _isMinor(_dateOfBirth!)) {
        _documentFiles[DocumentType.PARENTAL_AUTHORIZATION] = null;
        _documentBytes[DocumentType.PARENTAL_AUTHORIZATION] = null;
        _documentFileNames[DocumentType.PARENTAL_AUTHORIZATION] = null;
      }
    }
    
    _documentFiles.forEach((key, value) => _uploadingDocuments[key] = false);
  }

  bool _isMinor(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age < 18;
  }

  Future<void> _pickDocument(DocumentType docType) async {
    try {
      final isImage = docType == DocumentType.IDENTITY_PHOTO;
      final allowedExts = _allowedExtensionsForDocumentType(docType);
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: isImage ? FileType.image : FileType.custom,
        // IMPORTANT: doit correspondre aux règles backend (DocumentTypeConfig.allowedFileTypes)
        allowedExtensions: isImage ? null : allowedExts,
      );

      if (result != null) {
        final platformFile = result.files.single;
        setState(() {
          _documentFileNames[docType] = platformFile.name;
          
          // For web, store bytes; for mobile, use path
          if (kIsWeb && platformFile.bytes != null) {
            _documentBytes[docType] = platformFile.bytes;
            _documentFiles[docType] = null;
          } else if (platformFile.path != null) {
            _documentFiles[docType] = File(platformFile.path!);
            _documentBytes[docType] = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  List<String> _allowedExtensionsForDocumentType(DocumentType docType) {
    switch (docType) {
      case DocumentType.IDENTITY_PHOTO:
        return ['jpg', 'jpeg', 'png'];
      case DocumentType.MEDICAL_CERTIFICATE:
      case DocumentType.FEDERAL_LICENSE:
      case DocumentType.REGISTRATION_FORM:
      case DocumentType.PARENTAL_AUTHORIZATION:
      case DocumentType.SPORT_DIPLOMA:
      case DocumentType.CV:
      case DocumentType.CRIMINAL_RECORD:
      case DocumentType.CONTRACT:
      case DocumentType.FEDERAL_LICENSE_COACH:
      case DocumentType.MEMBERSHIP_FORM:
        return ['pdf'];
      default:
        return ['pdf', 'jpg', 'jpeg', 'png'];
    }
  }

  Future<void> _uploadAllDocuments() async {
    if (_createdUserId == null) return;

    final docProvider = Provider.of<UserDocumentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    int successCount = 0;
    int failCount = 0;

    for (var entry in _documentFiles.entries) {
      final docType = entry.key;
      final hasFile = entry.value != null;
      final hasBytes = _documentBytes[docType] != null;
      
      if (hasFile || hasBytes) {
        setState(() => _uploadingDocuments[docType] = true);
        
        bool success;
        if (kIsWeb && hasBytes) {
          // Direct upload for web using bytes
          success = await _uploadDocumentBytes(
            authProvider,
            _createdUserId!,
            docType,
            _documentBytes[docType]!,
            _documentFileNames[docType]!,
          );
        } else {
          // Mobile upload using File
          success = await docProvider.uploadDocument(
            userId: _createdUserId!,
            documentType: docType,
            file: entry.value!,
          );
        }

        if (success) {
          successCount++;
        } else {
          failCount++;
        }

        setState(() => _uploadingDocuments[docType] = false);
      }
    }

    if (failCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tous les documents ont été uploadés avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Return to previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount réussis, $failCount échoués'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Direct upload for web using bytes
  Future<bool> _uploadDocumentBytes(
    AuthProvider authProvider,
    int userId,
    DocumentType docType,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/admin/users/$userId/documents');
      
      print('=== UPLOAD DEBUG ===');
      print('URL: $url');
      print('Token: ${authProvider.token?.substring(0, 20)}...');
      print('DocumentType: $docType');
      print('FileName: $fileName');
      print('Bytes size: ${bytes.length}');
      
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer ${authProvider.token}';
      
      request.fields['documentType'] = docType.toString().split('.').last;
      
      // Determine MIME type from file extension
      String extension = fileName.split('.').last.toLowerCase();
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
      
      print('MimeType: $mimeType');
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');
      print('===================');
      
      return response.statusCode == 201;
    } catch (e, stackTrace) {
      print('Upload bytes error for $docType: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  String _getDocumentLabel(DocumentType docType) {
    switch (docType) {
      case DocumentType.CIN_OR_BIRTH_CERTIFICATE:
        return 'CIN ou Acte de Naissance';
      case DocumentType.IDENTITY_PHOTO:
        return 'Photo d\'identité';
      case DocumentType.MEDICAL_CERTIFICATE:
        return 'Certificat Médical';
      case DocumentType.FEDERAL_LICENSE:
        return 'Licence Fédérale';
      case DocumentType.REGISTRATION_FORM:
        return 'Formulaire d\'Inscription';
      case DocumentType.PARENTAL_AUTHORIZATION:
        return 'Autorisation Parentale';
      case DocumentType.PROOF_OF_ADDRESS:
        return 'Justificatif de Domicile';
      case DocumentType.CIN:
        return 'CIN';
      case DocumentType.SPORT_DIPLOMA:
        return 'Diplôme Sportif';
      case DocumentType.CV:
        return 'CV';
      case DocumentType.CRIMINAL_RECORD:
        return 'Casier Judiciaire';
      case DocumentType.CONTRACT:
        return 'Contrat';
      case DocumentType.FEDERAL_LICENSE_COACH:
        return 'Licence Fédérale Encadrant';
      case DocumentType.MEMBERSHIP_FORM:
        return 'Formulaire d\'Adhésion';
      case DocumentType.PAYMENT_PROOF:
        return 'Preuve de Paiement';
    }
    return docType.toString().split('.').last;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner un rôle')),
      );
      return;
    }
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner une date de naissance')),
      );
      return;
    }
    if (_passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un mot de passe')),
      );
      return;
    }
    if (_selectedRole == UserRole.JOUEUR) {
      if (_selectedEquipe == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez sélectionner une équipe')),
        );
        return;
      }
      if (_selectedPoste == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez sélectionner un poste')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final user = await userProvider.createUser(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      dateOfBirth: _dateOfBirth!,
      role: _selectedRole!,
      address: _addressCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      equipeId: _selectedRole == UserRole.JOUEUR ? _selectedEquipe?.id : null,
      poste: _selectedRole == UserRole.JOUEUR ? _selectedPoste : null,
    );

    setState(() => _isSubmitting = false);

    if (user != null) {
      setState(() {
        _createdUserId = user.id;
        _currentStep = 1; // Move to document upload step
        _initializeDocumentTypes(user.role);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur créé! Maintenant, ajoutez les documents.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${userProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemedAppBar(
        titleText: _currentStep == 0 ? 'Ajouter un Utilisateur' : 'Ajouter les Documents',
        automaticallyImplyLeading: _currentStep == 0,
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 0),
              )
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: _currentStep == 0 ? _buildUserForm() : _buildDocumentUpload(),
      ),
    );
  }

  Widget _buildUserForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Role Selection
          const Text(
            'Sélectionnez le rôle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.masYellow,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRoleCard(
                role: UserRole.JOUEUR,
                icon: Icons.sports_soccer,
                label: 'Joueur',
              ),
              const SizedBox(width: 12),
              _buildRoleCard(
                role: UserRole.ENCADRANT,
                icon: Icons.support_agent,
                label: 'Encadrant',
              ),
              const SizedBox(width: 12),
              _buildRoleCard(
                role: UserRole.ADHERENT,
                icon: Icons.group,
                label: 'Adhérent',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // First Name
          TextFormField(
            controller: _firstNameCtrl,
            decoration: AppTheme.inputDecoration('Prénom', Icons.person_outline),
            validator: (value) =>
                value!.isEmpty ? 'Veuillez entrer le prénom' : null,
          ),
          const SizedBox(height: 16),

          // Last Name
          TextFormField(
            controller: _lastNameCtrl,
            decoration: AppTheme.inputDecoration('Nom', Icons.badge_outlined),
            validator: (value) =>
                value!.isEmpty ? 'Veuillez entrer le nom' : null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: AppTheme.inputDecoration('Email', Icons.email_outlined),
            validator: (value) {
              if (value!.isEmpty) return 'Veuillez entrer l\'email';
              if (!value.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: AppTheme.inputDecoration('Téléphone', Icons.phone_outlined),
            validator: (value) =>
                value!.isEmpty ? 'Veuillez entrer le téléphone' : null,
          ),
          const SizedBox(height: 16),

          // Date of Birth
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: AppTheme.inputDecoration('Date de naissance', Icons.calendar_today),
              child: Text(
                _dateOfBirth == null
                    ? 'Sélectionner une date'
                    : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Address
          TextFormField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: AppTheme.inputDecoration('Adresse', Icons.location_on_outlined),
            validator: (value) =>
                value!.isEmpty ? 'Veuillez entrer l\'adresse' : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: AppTheme.inputDecoration('Mot de passe', Icons.lock_outlined),
            validator: (value) =>
                value!.isEmpty ? 'Veuillez entrer un mot de passe' : null,
          ),
          const SizedBox(height: 16),

          // JOUEUR-specific fields
          if (_selectedRole == UserRole.JOUEUR) ...[
            // Equipe Dropdown
            _isLoadingEquipes
                ? const Center(child: CircularProgressIndicator(color: AppTheme.masYellow))
                : DropdownButtonFormField<Equipe>(
                    decoration: AppTheme.inputDecoration('Équipe', Icons.group),
                    value: _selectedEquipe,
                    items: _equipes.map((equipe) {
                      return DropdownMenuItem<Equipe>(
                        value: equipe,
                        child: Text(equipe.nom),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedEquipe = value),
                    validator: (value) =>
                        value == null ? 'Veuillez sélectionner une équipe' : null,
                  ),
            const SizedBox(height: 16),

            // Poste Dropdown
            DropdownButtonFormField<String>(
              decoration: AppTheme.inputDecoration('Poste', Icons.sports_soccer),
              value: _selectedPoste,
              items: const [
                DropdownMenuItem(value: 'Gardien', child: Text('Gardien')),
                DropdownMenuItem(value: 'Défenseur', child: Text('Défenseur')),
                DropdownMenuItem(value: 'Milieu', child: Text('Milieu')),
                DropdownMenuItem(value: 'Attaquant', child: Text('Attaquant')),
              ],
              onChanged: (value) => setState(() => _selectedPoste = value),
              validator: (value) =>
                  value == null ? 'Veuillez sélectionner un poste' : null,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.masBlack),
                  )
                : const Text('Créer l\'utilisateur'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.containerDecoration(context, borderRadius: 16, borderWidth: 1.5),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.masYellow, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ajoutez maintenant les documents nécessaires pour cet utilisateur. Vous pouvez en ajouter plusieurs avant de finaliser.',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Document list
        Text(
          'Documents requis (${_documentFiles.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.masYellow,
          ),
        ),
        const SizedBox(height: 12),

        ..._documentFiles.entries.map((entry) {
          final docType = entry.key;
          final file = entry.value;
          final isUploading = _uploadingDocuments[docType] ?? false;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: AppTheme.containerDecoration(context, borderRadius: 16, borderWidth: 1),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document name
                  Row(
                    children: [
                      Icon(
                        docType == DocumentType.IDENTITY_PHOTO 
                            ? Icons.photo 
                            : Icons.description,
                        color: AppTheme.masYellow,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getDocumentLabel(docType),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppTheme.masBlack,
                          ),
                        ),
                      ),
                      _RequiredChip(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // File selected or pick button
                  if (file != null || _documentBytes[docType] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.masYellow.withOpacity(0.08),
                        border: Border.all(color: AppTheme.masYellow.withOpacity(0.8)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.masYellow, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _documentFileNames[docType] ?? 'Fichier sélectionné',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : AppTheme.masBlack,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            onPressed: () => setState(() {
                              _documentFiles[docType] = null;
                              _documentBytes[docType] = null;
                              _documentFileNames[docType] = null;
                            }),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: isUploading ? null : () => _pickDocument(docType),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Sélectionner un fichier'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: AppTheme.masYellow, width: 1),
                        foregroundColor: AppTheme.masYellow,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 24),

        // Upload all button
        ElevatedButton.icon(
          onPressed: _uploadAllDocuments,
          icon: const Icon(Icons.cloud_upload),
          label: const Text('Créer et uploader tous les documents'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
        ),
        const SizedBox(height: 12),

        // Skip button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Passer cette étape',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.containerDecoration(context, borderRadius: 16, borderWidth: isSelected ? 2 : 1),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected ? AppTheme.masYellow : Colors.white70,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.masYellow : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredChip extends StatelessWidget {
  const _RequiredChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.red.withOpacity(0.8), width: 1),
      ),
      child: const Text(
        'OBLIGATOIRE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.red,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

