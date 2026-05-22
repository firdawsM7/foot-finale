import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/api_error_utils.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? _token;
  String? get token => _token;

  Future<dynamic> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      
      // Check if account needs activation
      if (response['needsActivation'] == true) {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'needsActivation': true,
          'activationToken': response['activationToken'],
          'email': response['email'],
          'message': response['message'],
        };
      }
      
      // Normal login success
      _user = User.fromJson(response['user']);
      _token = response['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _user!.id.toString());
      await prefs.setString('userRole', _user!.role);
      await prefs.setString('token', _token!);
      if (_user!.equipeId != null) {
        await prefs.setString('userEquipeId', _user!.equipeId.toString());
      }
      
      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } catch (e) {
      _error = ApiErrorUtils.sanitizeForDisplay(e, fallback: ApiErrorUtils.authFailed);
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': _error};
    }
  }

  // Activate account with new password
  Future<bool> activateAccount({
    required String email,
    required String password,
    required String activationToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.activateAccount(
        email: email,
        password: password,
        activationToken: activationToken,
      );
      
      _user = User.fromJson(response['user']);
      _token = response['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _user!.id.toString());
      await prefs.setString('userRole', _user!.role);
      await prefs.setString('token', _token!);
      if (_user!.equipeId != null) {
        await prefs.setString('userEquipeId', _user!.equipeId.toString());
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiErrorUtils.sanitizeForDisplay(e, fallback: ApiErrorUtils.generic);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(User user, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.register(user, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiErrorUtils.sanitizeForDisplay(e, fallback: ApiErrorUtils.generic);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<void> checkAuthentication() async {
    final token = await ApiService.getToken();
    if (token != null) {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userRole = prefs.getString('userRole');
      final userEquipeId = prefs.getString('userEquipeId');
      
      if (userId != null && userRole != null) {
        _user = User(
          id: int.parse(userId),
          email: '',
          nom: '',
          prenom: '',
          role: userRole,
          equipeId: userEquipeId != null ? int.tryParse(userEquipeId) : null,
        );
        notifyListeners();
      }
    }
  }

  // Update local user fields (used by Profile screen for local edits)
  void updateLocalUser({String? nom, String? prenom, String? email}) {
    if (_user == null) return;
    _user = User(
      id: _user!.id,
      email: email ?? _user!.email,
      nom: nom ?? _user!.nom,
      prenom: prenom ?? _user!.prenom,
      telephone: _user!.telephone,
      adresse: _user!.adresse,
      dateNaissance: _user!.dateNaissance,
      photo: _user!.photo,
      role: _user!.role,
      actif: _user!.actif,
      dateInscription: _user!.dateInscription,
      derniereConnexion: _user!.derniereConnexion,
      equipeId: _user!.equipeId,
    );
    notifyListeners();
  }

  Future<bool> uploadProfilePhoto(File imageFile) async {
    if (_user == null || _token == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/users/me/photo'),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse response to get photoUrl
        final responseData = response.body;
        // Assuming response is JSON with photoUrl field
        // For simplicity, we'll extract it manually or use json.decode
        // Let's use a simple approach: assume backend returns {"photoUrl": "..."}
        
        // Update local user with new photo
        final photoUrlMatch = RegExp(r'"photoUrl"\s*:\s*"([^"]+)"').firstMatch(responseData);
        if (photoUrlMatch != null) {
          final photoUrl = photoUrlMatch.group(1);
          _user = User(
            id: _user!.id,
            email: _user!.email,
            nom: _user!.nom,
            prenom: _user!.prenom,
            telephone: _user!.telephone,
            adresse: _user!.adresse,
            dateNaissance: _user!.dateNaissance,
            photo: photoUrl,
            role: _user!.role,
            actif: _user!.actif,
            dateInscription: _user!.dateInscription,
            derniereConnexion: _user!.derniereConnexion,
            equipeId: _user!.equipeId,
          );
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = ApiErrorUtils.generic;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ApiErrorUtils.sanitizeForDisplay(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
