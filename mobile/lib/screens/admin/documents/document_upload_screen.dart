import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/themed_app_bar.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../providers/document_provider.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  
  User? _selectedUser;
  String? _selectedType = 'CERTIFICAT_MEDICAL';
  DateTime? _expirationDate;
  File? _selectedFile;
  String? _fileName;
  
  List<User> _users = [];
  bool _isLoadingUsers = true;

  final List<String> _types = [
    'CERTIFICAT_MEDICAL',
    'LICENCE',
    'ASSURANCE',
    'CONTRAT',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.getAllUsers();
      setState(() {
        _users = users.where((u) => u.role != 'ADMIN').toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur utilisateurs: $e')));
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un fichier')));
      return;
    }
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un joueur')));
      return;
    }

    try {
      await context.read<DocumentProvider>().uploadDocument(
        file: _selectedFile!,
        userId: _selectedUser!.id!,
        type: _selectedType!,
        dateExpiration: _expirationDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploader avec succès')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur upload: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'AJOUTER UN DOCUMENT'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUserSelector(),
                const SizedBox(height: 24),
                _buildTypeSelector(),
                const SizedBox(height: 24),
                _buildDatePicker(),
                const SizedBox(height: 32),
                _buildFilePicker(),
                const SizedBox(height: 48),
                Consumer<DocumentProvider>(
                  builder: (context, provider, child) {
                    return provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submit,
                            child: const Text('UPLOADER'),
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelector() {
    if (_isLoadingUsers) return const CircularProgressIndicator();
    return DropdownButtonFormField<User>(
      initialValue: _selectedUser,
      decoration: const InputDecoration(labelText: 'Sélectionner le joueur'),
      items: _users.map((u) => DropdownMenuItem(
        value: u,
        child: Text('${u.nom} ${u.prenom}'),
      )).toList(),
      onChanged: (value) => setState(() => _selectedUser = value),
      validator: (v) => v == null ? 'Requis' : null,
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedType,
      decoration: const InputDecoration(labelText: 'Type de document'),
      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
      onChanged: (value) => setState(() => _selectedType = value),
      validator: (v) => v == null ? 'Requis' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date d\'expiration',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _expirationDate == null 
              ? 'Sélectionner une date' 
              : DateFormat('dd/MM/yyyy').format(_expirationDate!),
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fichier (PDF ou Image)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.masYellow.withOpacity(0.3), style: BorderStyle.solid),
            ),
            child: Center(
              child: _selectedFile == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: AppTheme.masYellow),
                        SizedBox(height: 8),
                        Text('Cliquez pour choisir'),
                        Text('.pdf, .jpg, .png (max 5MB)', style: TextStyle(fontSize: 10, color: Colors.white54)),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _fileName!.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                          size: 40,
                          color: AppTheme.masYellow,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(_fileName!, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                        ),
                        TextButton(onPressed: _pickFile, child: const Text('Changer')),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
