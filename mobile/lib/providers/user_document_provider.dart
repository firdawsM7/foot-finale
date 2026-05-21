import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import '../models/user_model.dart';
import '../services/document_service_api.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';

/// Documents par utilisateur + stats (checklist fusionnée côté API)
class UserDocumentProvider with ChangeNotifier {
  final AuthProvider _authProvider;

  List<DocumentModel> _documents = [];
  int _completionPercentage = 0;
  int _documentsCompleted = 0;
  int _documentsRequired = 0;
  bool _isLoading = false;
  String? _error;
  int? _currentUserId;
  UserStatus? _registrationStatus;
  bool? _userActif;

  List<DocumentModel> get documents => _documents;
  int get completionPercentage => _completionPercentage;
  int get documentsCompleted => _documentsCompleted;
  int get documentsRequired => _documentsRequired;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isComplete => _completionPercentage == 100;
  UserStatus? get registrationStatus => _registrationStatus;
  bool? get userActif => _userActif;

  UserDocumentProvider(this._authProvider);

  DocumentService _createService() {
    return DocumentService(
      baseUrl: ApiConfig.serverBaseUrl,
      token: _authProvider.token,
    );
  }

  Future<void> loadDocuments(int userId) async {
    _currentUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bundle = await _createService().fetchAdminUserWithDocuments(userId);
      final raw = bundle['documents'] as List<dynamic>? ?? [];
      _documents = raw
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _completionPercentage = (bundle['completionPercentage'] is int)
          ? bundle['completionPercentage'] as int
          : int.tryParse('${bundle['completionPercentage']}') ?? 0;
      _documentsCompleted = (bundle['documentsCompleted'] is int)
          ? bundle['documentsCompleted'] as int
          : int.tryParse('${bundle['documentsCompleted']}') ?? 0;
      _documentsRequired = (bundle['documentsRequired'] is int)
          ? bundle['documentsRequired'] as int
          : int.tryParse('${bundle['documentsRequired']}') ?? 0;

      final rs = bundle['registrationStatus'];
      if (rs != null) {
        _registrationStatus = UserStatus.values.firstWhere(
          (e) => e.name == rs.toString(),
          orElse: () => UserStatus.PENDING,
        );
      } else {
        _registrationStatus = null;
      }
      _userActif = bundle['actif'] as bool?;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadDocument({
    required int userId,
    required DocumentType documentType,
    required File file,
    bool forceReplace = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _createService().uploadDocument(
        userId: userId,
        documentType: documentType,
        file: file,
        forceReplace: forceReplace,
      );
      await loadDocuments(userId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDocument({
    required int userId,
    required int documentId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _createService().deleteDocument(userId: userId, documentId: documentId);
      await loadDocuments(userId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveDocument(int documentId) async {
    return _updateDocumentStatus(
      documentId: documentId,
      status: DocumentStatus.APPROVED,
    );
  }

  Future<bool> rejectDocument(int documentId, String reason) async {
    return _updateDocumentStatus(
      documentId: documentId,
      status: DocumentStatus.REJECTED,
      rejectionReason: reason,
    );
  }

  Future<bool> _updateDocumentStatus({
    required int documentId,
    required DocumentStatus status,
    String? rejectionReason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _createService().updateDocumentStatus(
        documentId: documentId,
        status: status,
        rejectionReason: rejectionReason,
      );
      if (_currentUserId != null) {
        await loadDocuments(_currentUserId!);
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DocumentModel>> getMissingDocuments(int userId) async {
    try {
      return await _createService().getMissingDocuments(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  DocumentModel? getDocumentByType(DocumentType type) {
    try {
      return _documents.firstWhere((doc) => doc.documentType == type);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _documents = [];
    _completionPercentage = 0;
    _documentsCompleted = 0;
    _documentsRequired = 0;
    _error = null;
    _currentUserId = null;
    _registrationStatus = null;
    _userActif = null;
    notifyListeners();
  }
}
