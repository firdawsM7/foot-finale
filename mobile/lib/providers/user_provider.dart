import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';

class UserProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider(this._authProvider);

  UserService _createService() {
    return UserService(
      baseUrl: ApiConfig.serverBaseUrl,
      token: _authProvider.token,
    );
  }

  /// Load all users
  Future<void> loadUsers({UserRole? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _createService().getAllUsers(role: role);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new user
  Future<UserModel?> createUser({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _createService().createUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth,
        role: role,
        address: address,
        password: password,
        equipeId: equipeId,
        poste: poste,
      );
      
      _users.add(user);
      _error = null;
      notifyListeners();
      return user;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get user by ID with documents
  Future<Map<String, dynamic>?> getUserWithDocuments(int userId) async {
    try {
      return await _createService().getUserWithDocuments(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(int userId) async {
    try {
      return await _createService().getUserById(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update user profile fields
  Future<bool> updateUserProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    DateTime? dateOfBirth,
    UserRole? role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _createService().updateUser(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
      );

      if (role != null) {
        await _createService().changeUserRole(userId: userId, role: role);
      }

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updated;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user status
  Future<bool> updateUserStatus(int userId, UserStatus status) async {
    try {
      await _createService().updateUserStatus(userId, status);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        // Refresh users list
        await loadUsers();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Filter users by role
  List<UserModel> getUsersByRole(UserRole role) {
    return _users.where((user) => user.role == role).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
