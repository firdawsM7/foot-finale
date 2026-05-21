import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/injury_suspension.dart';
import '../services/api_service.dart';

class AlertProvider with ChangeNotifier {
  List<InjurySuspension> _alerts = [];
  bool _isLoading = false;

  List<InjurySuspension> get alerts => _alerts;
  bool get isLoading => _isLoading;

  Future<void> loadAllActiveAlerts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/encadrant/alerts'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _alerts = data.map((json) => InjurySuspension.fromJson(json)).toList();
      } else {
        print('Error loading alerts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading alerts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlayerAlerts(int playerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/encadrant/players/$playerId/alerts'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _alerts = data.map((json) => InjurySuspension.fromJson(json)).toList();
      } else {
        print('Error loading player alerts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading player alerts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAlert(int playerId, InjurySuspension alert) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/encadrant/players/$playerId/alerts'),
        headers: await ApiService.getHeaders(),
        body: json.encode(alert.toJson()),
      );

      if (response.statusCode == 200) {
        final newAlert = InjurySuspension.fromJson(json.decode(response.body));
        _alerts.insert(0, newAlert);
        notifyListeners();
        return true;
      } else {
        print('Error creating alert: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error creating alert: $e');
      return false;
    }
  }

  Future<bool> updateAlertStatus(int alertId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/encadrant/alerts/$alertId/status?status=$status'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        _alerts.removeWhere((alert) => alert.id == alertId);
        notifyListeners();
        return true;
      } else {
        print('Error updating alert status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating alert status: $e');
      return false;
    }
  }
}
