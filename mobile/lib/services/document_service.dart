import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/document.dart';
import 'api_service.dart';

class DocumentService {
  static Future<Document> uploadDocument({
    required File file,
    required int userId,
    required String type,
    DateTime? dateExpiration,
  }) async {
    final token = await ApiService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.adminDocumentsUpload));
    
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.fields['userId'] = userId.toString();
    request.fields['type'] = type;
    if (dateExpiration != null) {
      request.fields['dateExpiration'] = dateExpiration.toIso8601String().split('T')[0];
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('application', 'octet-stream'),
    ));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Document.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Échec de l\'upload du document: ${response.body}');
    }
  }

  static Future<List<Document>> getAllDocuments({int? userId, String? type, bool? expirant}) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['userId'] = userId.toString();
    if (type != null) queryParams['type'] = type;
    if (expirant != null) queryParams['expirant'] = expirant.toString();

    final uri = Uri.parse(ApiConfig.adminDocuments).replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Document.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de chargement des documents');
    }
  }

  static Future<List<Document>> getExpiringDocuments() async {
    final response = await http.get(
      Uri.parse(ApiConfig.adminDocumentsExpiring),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Document.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de chargement des documents expirants');
    }
  }

  static Future<Document> validateDocument(int id) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminDocuments}/$id/validate'),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      return Document.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Échec de la validation du document');
    }
  }

  static Future<void> deleteDocument(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.adminDocuments}/$id'),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la suppression du document');
    }
  }
}
