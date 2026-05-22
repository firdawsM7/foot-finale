import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/api_error_utils.dart';
import '../models/models.dart';

// Pour Flutter Web, on configure les requêtes pour éviter les problèmes CORS
dynamic getHttpClient() {
  return http.Client();
}

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTH ====================
  
  // Check if account needs activation
  static Future<Map<String, dynamic>> checkActivationStatus(String email) async {
    print('Vérification du statut d\'activation pour: $email');
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/check-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Réponse check-status: Status=${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(ApiErrorUtils.fromHttpResponse(
          response.statusCode,
          response.body,
          fallback: 'Échec de vérification du compte',
        ));
      }
    } catch (e) {
      print('Exception lors de la vérification: $e');
      rethrow;
    }
  }

  // Activate account with new password
  static Future<Map<String, dynamic>> activateAccount({
    required String email,
    required String password,
    required String activationToken,
  }) async {
    print('Activation du compte pour: $email');
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/activate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'activationToken': activationToken,
        }),
      );

      print('Réponse activation: Status=${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        return data;
      } else {
        throw Exception(ApiErrorUtils.fromHttpResponse(
          response.statusCode,
          response.body,
          fallback: 'Échec d\'activation du compte',
        ));
      }
    } catch (e) {
      print('Exception lors de l\'activation: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('Tentative de connexion à: ${ApiConfig.login} pour: $email');
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Réponse de connexion: Status=${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        return data;
      } else if (response.statusCode == 403) {
        // Account needs activation
        final data = jsonDecode(response.body);
        if (data['needsActivation'] == true) {
          // Return activation data to frontend
          return {
            'needsActivation': true,
            'activationToken': data['activationToken'],
            'email': email,
            'message': data['message'] ?? 'Compte non activé',
          };
        }
        throw Exception(ApiErrorUtils.fromHttpResponse(
          response.statusCode,
          response.body,
          fallback: ApiErrorUtils.authFailed,
        ));
      } else {
        throw Exception(ApiErrorUtils.fromHttpResponse(
          response.statusCode,
          response.body,
          fallback: ApiErrorUtils.authFailed,
        ));
      }
    } catch (e) {
      print('Exception lors de la connexion: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register(User user, String password) async {
    final userData = user.toJson();
    userData['password'] = password;
    
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec d\'inscription');
    }
  }

  static Future<void> logout() async {
    await removeToken();
  }

  // ==================== USERS ====================
  
  static Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse(ApiConfig.adminUsers),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception(ApiErrorUtils.fromHttpResponse(
        response.statusCode,
        response.body,
        fallback: 'Erreur de chargement des utilisateurs',
      ));
    }
  }

  static Future<User> createUser(User user) async {
    final userData = user.toJson();
    // Don't send password - admin creates users without password
    userData.remove('password');
    
    final response = await http.post(
      Uri.parse(ApiConfig.adminUsers),
      headers: await getHeaders(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de création de l\'utilisateur (Status: ${response.statusCode})');
    }
  }

  static Future<User> updateUser(User user) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminUsers}/${user.id}'),
      headers: await getHeaders(),
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de modification de l\'utilisateur');
    }
  }

  static Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.adminUsers}/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur de suppression de l\'utilisateur');
    }
  }

  // ==================== JOUEURS ====================

  static Future<List<dynamic>> getAllJoueurs(String role) async {
    String url;
    if (role == 'ADMIN') {
      url = ApiConfig.adminJoueurs;
    } else if (role == 'ENCADRANT') {
      url = ApiConfig.encadrantJoueurs;
    } else {
      url = ApiConfig.adherentJoueurs;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      // ADMIN & ENCADRANT: users with role JOUEUR; ADHERENT: legacy joueurs table
      if (role == 'ADMIN' || role == 'ENCADRANT') {
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        return data.map((json) => Joueur.fromJson(json)).toList();
      }
    } else {
      throw Exception('Erreur de chargement des joueurs');
    }
  }

  // ==================== ÉQUIPES ====================
  
  static Future<List<Equipe>> getAllEquipes(String role) async {
    String url;
    if (role == 'ADMIN') {
      url = ApiConfig.adminEquipes;
    } else if (role == 'ENCADRANT') {
      url = ApiConfig.encadrantEquipes;
    } else {
      url = ApiConfig.adherentEquipes;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Equipe.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de chargement des équipes');
    }
  }

  static Future<Equipe> createEquipe(Map<String, dynamic> equipeData, String role) async {
    final url = role == 'ENCADRANT'
        ? ApiConfig.encadrantEquipes
        : ApiConfig.adminEquipes;

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(equipeData),
    );

    if (response.statusCode == 200) {
      return Equipe.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de création de l\'équipe (${response.statusCode})');
    }
  }

  static Future<Equipe> updateEquipe(int id, Map<String, dynamic> equipeData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminEquipes}/$id'),
      headers: await getHeaders(),
      body: jsonEncode(equipeData),
    );

    if (response.statusCode == 200) {
      return Equipe.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de modification de l\'équipe');
    }
  }

  static Future<void> deleteEquipe(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.adminEquipes}/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur de suppression de l\'équipe');
    }
  }

  // ==================== ENTRAÎNEMENTS ====================
  
  static Future<List<Entrainement>> getAllEntrainements(String role, {int? encadrantId}) async {
    String url;
    if (role == 'ADMIN') {
      url = ApiConfig.adminEntrainements;
    } else if (role == 'ENCADRANT' && encadrantId != null) {
      // Use the new endpoint for encadrant-specific trainings
      url = ApiConfig.encadrantEntrainementsByEncadrant(encadrantId);
    } else if (role == 'ENCADRANT') {
      url = ApiConfig.encadrantEntrainements;
    } else {
      url = ApiConfig.adherentEntrainements;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Entrainement.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de chargement des entraînements');
    }
  }

  static Future<List<Entrainement>> getEntrainementsByEquipe(int equipeId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.adherentEntrainements}/equipe/$equipeId'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Entrainement.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de chargement des entraînements de l\'équipe');
    }
  }

  static Future<Entrainement> createEntrainement(Map<String, dynamic> entrainementData) async {
    final response = await http.post(
      Uri.parse(ApiConfig.adminEntrainements),
      headers: await getHeaders(),
      body: jsonEncode(entrainementData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Entrainement.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de création de l\'entraînement');
    }
  }

  static Future<Entrainement> updateEntrainement(int id, Map<String, dynamic> entrainementData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminEntrainements}/$id'),
      headers: await getHeaders(),
      body: jsonEncode(entrainementData),
    );

    if (response.statusCode == 200) {
      return Entrainement.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de modification de l\'entraînement');
    }
  }

  static Future<void> deleteEntrainement(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.adminEntrainements}/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur de suppression de l\'entraînement');
    }
  }

  // ==================== MATCHS ====================
  
  static Future<List<Match>> getAllMatchs(String role) async {
    String url;
    if (role == 'ADMIN') {
      url = ApiConfig.adminMatchs;
    } else if (role == 'ENCADRANT') {
      url = ApiConfig.encadrantMatchs;
    } else {
      url = ApiConfig.adherentMatchs;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Match.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de chargement des matchs');
    }
  }

  static Future<Match> createMatch(Map<String, dynamic> matchData) async {
    final response = await http.post(
      Uri.parse(ApiConfig.adminMatchs),
      headers: await getHeaders(),
      body: jsonEncode(matchData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Match.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de création du match');
    }
  }

  static Future<Match> updateMatch(int id, Map<String, dynamic> matchData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminMatchs}/$id'),
      headers: await getHeaders(),
      body: jsonEncode(matchData),
    );

    if (response.statusCode == 200) {
      return Match.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de modification du match');
    }
  }

  static Future<void> deleteMatch(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.adminMatchs}/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur de suppression du match');
    }
  }

  // ==================== COTISATIONS ====================
  
  static Future<List<Cotisation>> getAllCotisations(String role, {String? userId, String? saison, String? statut}) async {
    String url;
    Map<String, String> queryParams = {};
    
    if (role == 'ADMIN') {
      url = ApiConfig.adminCotisations;
      if (userId != null) queryParams['userId'] = userId;
      if (saison != null) queryParams['saison'] = saison;
      if (statut != null) queryParams['statut'] = statut;
    } else if (role == 'ENCADRANT') {
      url = '${ApiConfig.baseUrl}/encadrant/cotisations';
      if (saison != null) queryParams['saison'] = saison;
    } else {
      url = ApiConfig.adherentCotisations;
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(uri, headers: await getHeaders());

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Cotisation.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de chargement des cotisations');
    }
  }

  static Future<Cotisation> getCotisationById(int id, String role) async {
    String url;
    if (role == 'ADMIN') {
      url = '${ApiConfig.adminCotisations}/$id';
    } else if (role == 'ENCADRANT') {
      url = '${ApiConfig.baseUrl}/encadrant/cotisations/$id';
    } else {
      url = '${ApiConfig.adherentCotisations}/$id';
    }

    final response = await http.get(Uri.parse(url), headers: await getHeaders());

    if (response.statusCode == 200) {
      return Cotisation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de chargement de la cotisation');
    }
  }

  static Future<Cotisation> createCotisation(Map<String, dynamic> cotisationData, String role) async {
    final headers = await getHeaders();
    print('Request headers: $headers');
    print('Request body: ${jsonEncode(cotisationData)}');
    print('User role: $role');
    
    String url;
    if (role == 'ADMIN') {
      url = ApiConfig.adminCotisations;
    } else if (role == 'ENCADRANT') {
      url = ApiConfig.encadrantCotisations;
    } else {
      url = ApiConfig.adherentCotisations;
    }
    
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(cotisationData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cotisation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(ApiErrorUtils.fromHttpResponse(
        response.statusCode,
        response.body,
        fallback: 'Erreur de création de la cotisation',
      ));
    }
  }

  static Future<Cotisation> updateCotisation(int id, Map<String, dynamic> cotisationData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminCotisations}/$id'),
      headers: await getHeaders(),
      body: jsonEncode(cotisationData),
    );

    if (response.statusCode == 200) {
      return Cotisation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de modification de la cotisation');
    }
  }

  static Future<Cotisation> validerCotisation(int id) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminCotisations}/$id/valider'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return Cotisation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de validation de la cotisation');
    }
  }

  static Future<Cotisation> rejeterCotisation(int id, String motif) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.adminCotisations}/$id/rejeter'),
      headers: await getHeaders(),
      body: jsonEncode({'motif': motif}),
    );

    if (response.statusCode == 200) {
      return Cotisation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur de rejet de la cotisation');
    }
  }

  static Future<void> deleteCotisation(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.adminCotisations}/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur de suppression de la cotisation');
    }
  }

  static Future<Map<String, dynamic>> getCotisationsStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.adminCotisations}/stats'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur de chargement des statistiques');
    }
  }

  static Future<Map<String, dynamic>> uploadRecuCotisation(int cotisationId, dynamic imageFile) async {
    final token = await getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/adherent/cotisations/$cotisationId/upload-recu');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    // For Flutter Web, imageFile is often bytes or a specific web-friendly object
    // For Mobile/Desktop, it's a File
    if (imageFile is List<int>) {
       request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageFile,
        filename: 'recu_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    } else {
       // Assuming it's an XFile or similar for mobile
       request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(ApiErrorUtils.fromHttpResponse(
        response.statusCode,
        response.body,
        fallback: 'Échec de l\'upload du reçu',
      ));
    }
  }

  // ==================== ADMIN MESSAGES ====================

  // Envoyer un message broadcast à tous les utilisateurs
  static Future<Map<String, dynamic>> sendBroadcastMessage({
    required String content,
    int? recipientId,
  }) async {
    final headers = await getHeaders();
    final body = {
      'content': content,
      if (recipientId != null) 'recipientId': recipientId,
    };

    final response = await http.post(
      Uri.parse(ApiConfig.adminMessagesBroadcast),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(ApiErrorUtils.fromHttpResponse(
        response.statusCode,
        response.body,
        fallback: 'Impossible d\'envoyer le message',
      ));
    }
  }

  // Envoyer un message privé à un utilisateur
  static Future<Map<String, dynamic>> sendPrivateMessage({
    required int userId,
    required String content,
  }) async {
    final headers = await getHeaders();
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/admin/messages/private/$userId'),
      headers: headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(ApiErrorUtils.fromHttpResponse(
        response.statusCode,
        response.body,
        fallback: 'Impossible d\'envoyer le message privé',
      ));
    }
  }

  // Récupérer tous les messages admin
  static Future<List<dynamic>> getAllAdminMessages() async {
    final headers = await getHeaders();
    
    final response = await http.get(
      Uri.parse(ApiConfig.adminMessages),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(ApiErrorUtils.fromHttpResponse(
        response.statusCode,
        response.body,
        fallback: 'Erreur lors du chargement des messages',
      ));
    }
  }

  // Récupérer les messages envoyés par l'admin
  static Future<List<dynamic>> getSentMessages() async {
    final headers = await getHeaders();
    
    final response = await http.get(
      Uri.parse(ApiConfig.adminMessagesSent),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des messages envoyés');
    }
  }

  // Récupérer les statistiques des messages
  static Future<Map<String, dynamic>> getMessageStats() async {
    final headers = await getHeaders();
    
    final response = await http.get(
      Uri.parse(ApiConfig.adminMessagesStats),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des statistiques');
    }
  }

  // Récupérer les messages pour un utilisateur spécifique
  static Future<List<dynamic>> getMessagesForUser(int userId) async {
    final headers = await getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/admin/messages/user/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des messages');
    }
  }

  // Envoyer un message de groupe (rôle)
  static Future<Map<String, dynamic>> sendGroupMessage({
    required String role,
    required String content,
  }) async {
    final headers = await getHeaders();
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/admin/messages/group/$role'),
      headers: headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(ApiErrorUtils.fromHttpResponse(
        response.statusCode,
        response.body,
        fallback: 'Impossible d\'envoyer le message de groupe',
      ));
    }
  }

  // Récupérer la conversation privée exclusive entre l'admin et un utilisateur (côté admin)
  static Future<List<dynamic>> getAdminConversationPrivateHistory(int userId) async {
    final headers = await getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/admin/messages/private-conversation/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement de la conversation privée');
    }
  }

  // Récupérer les annonces destinées à l'utilisateur actuel (broadcast + groupe rôle) (côté utilisateur)
  static Future<List<dynamic>> getUserAnnouncements() async {
    final headers = await getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/messages/announcements'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des annonces');
    }
  }

  // Récupérer la conversation privée de l'utilisateur avec l'admin (côté utilisateur)
  static Future<List<dynamic>> getUserAdminConversation() async {
    final headers = await getHeaders();
    
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/messages/admin-conversation'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement de la conversation avec l\'admin');
    }
  }

  // Envoyer un message privé de l'utilisateur à l'admin (côté utilisateur)
  static Future<Map<String, dynamic>> sendUserMessageToAdmin({
    required String content,
  }) async {
    final headers = await getHeaders();
    
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBaseUrl}/messages/to-admin'),
      headers: headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(ApiErrorUtils.fromHttpResponse(
        response.statusCode,
        response.body,
        fallback: 'Impossible d\'envoyer le message à l\'admin',
      ));
    }
  }
}