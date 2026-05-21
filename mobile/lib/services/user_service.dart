import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  final String baseUrl;
  final String? token;

  UserService({required this.baseUrl, this.token});

  Map<String, String> get headers {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Create a new user (admin only)
  Future<UserModel> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required DateTime dateOfBirth,
    required UserRole role,
    required String address,
    required String password,
    int? equipeId,
    String? poste,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/users');
    
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth.toIso8601String().split('T')[0],
      'role': role.toString().split('.').last,
      'address': address,
      'password': password,
    };
    
    // Only include equipe and poste for JOUEUR role
    if (role == UserRole.JOUEUR) {
      if (equipeId != null) body['equipeId'] = equipeId.toString();
      if (poste != null) body['poste'] = poste;
    }
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      // Backend renvoie souvent un JSON { message, status, ... }
      String message = 'Erreur lors de la création de l\'utilisateur';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final m = decoded['message'];
          if (m != null && m.toString().trim().isNotEmpty) {
            message = m.toString();
          }
        }
      } catch (_) {
        if (response.body.trim().isNotEmpty) {
          message = response.body;
        }
      }

      throw Exception(message);
    }
  }

  /// Get all users
  Future<List<UserModel>> getAllUsers({UserRole? role}) async {
    String url = '$baseUrl/api/admin/users';
    if (role != null) {
      url += '?role=${role.toString().split('.').last}';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  /// Get user by ID with documents
  Future<Map<String, dynamic>> getUserWithDocuments(int userId) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/dossier');
    
    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  /// Get a user by ID (admin)
  Future<UserModel> getUserById(int userId) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Impossible de charger l’utilisateur: ${response.body}');
  }

  /// Update editable user fields (admin)
  ///
  /// Backend currently updates: nom, prenom, telephone, adresse, dateNaissance, photo (and password if provided).
  Future<UserModel> updateUser({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    DateTime? dateOfBirth,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId');

    final payload = <String, dynamic>{
      // Backend expects these legacy keys
      'prenom': firstName,
      'nom': lastName,
      // Email is not updated by backend, but keeping it avoids accidental blanking in some serializers.
      'email': email,
      'telephone': phone,
      'adresse': address,
      if (dateOfBirth != null) 'dateNaissance': dateOfBirth.toIso8601String().split('T')[0],
    };

    final response = await http.put(url, headers: headers, body: jsonEncode(payload));
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Échec de modification: ${response.body}');
  }

  /// Change user role (admin)
  Future<void> changeUserRole({
    required int userId,
    required UserRole role,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/role');
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(role.toString().split('.').last),
    );
    if (response.statusCode == 200) return;
    throw Exception('Échec changement rôle: ${response.body}');
  }

  /// Update user status
  Future<UserModel> updateUserStatus(int userId, UserStatus status) async {
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/status');
    
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        'status': status.toString().split('.').last,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user status: ${response.body}');
    }
  }
}
