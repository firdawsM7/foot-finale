import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/document_model.dart';

class DocumentService {
  final String baseUrl;
  final String? token;

  DocumentService({required this.baseUrl, this.token});

  Map<String, String> get authHeaders {
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Dossier complet : utilisateur + checklist documents + stats (GET /admin/users/{id})
  Future<Map<String, dynamic>> fetchAdminUserWithDocuments(int userId) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/dossier');
    final response = await http.get(url, headers: authHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Chargement utilisateur: ${response.body}');
  }

  /// Get all documents for a user
  Future<List<DocumentModel>> getUserDocuments(int userId) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/documents');
    
    final response = await http.get(
      url,
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load documents: ${response.body}');
    }
  }

  /// Upload a document
  Future<DocumentModel> uploadDocument({
    required int userId,
    required DocumentType documentType,
    required File file,
    bool forceReplace = false,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/documents?force=$forceReplace');
    
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(authHeaders);
    
    request.fields['documentType'] = documentType.toString().split('.').last;
    
    // Determine file type
    String fileType = file.path.split('.').last.toLowerCase();
    String mimeType;
    if (fileType == 'pdf') {
      mimeType = 'application/pdf';
    } else if (fileType == 'jpg' || fileType == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (fileType == 'png') {
      mimeType = 'image/png';
    } else {
      mimeType = 'application/octet-stream';
    }
    
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return DocumentModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to upload document: ${response.body}');
    }
  }

  /// Delete a document by id
  Future<void> deleteDocument({
    required int userId,
    required int documentId,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/documents/$documentId');
    final response = await http.delete(url, headers: authHeaders);
    if (response.statusCode == 204) return;
    throw Exception('Failed to delete document: ${response.body}');
  }

  /// Get missing documents for a user
  Future<List<DocumentModel>> getMissingDocuments(int userId) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/documents/missing');
    
    final response = await http.get(
      url,
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load missing documents: ${response.body}');
    }
  }

  /// Update document status (approve/reject)
  Future<DocumentModel> updateDocumentStatus({
    required int documentId,
    required DocumentStatus status,
    String? rejectionReason,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/documents/$documentId/status');
    
    final body = {
      'status': status.toString().split('.').last,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };

    final response = await http.put(
      url,
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return DocumentModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update document status: ${response.body}');
    }
  }

  /// Get document configuration for a role
  Future<List<Map<String, dynamic>>> getDocumentConfig(String role) async {
    final url = Uri.parse('$baseUrl/api/admin/document-config/$role');
    
    final response = await http.get(
      url,
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load document config: ${response.body}');
    }
  }

  /// Get completion status for a user
  Future<Map<String, dynamic>> getCompletionStatus(int userId) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/documents/completion');
    
    final response = await http.get(
      url,
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load completion status: ${response.body}');
    }
  }
}
