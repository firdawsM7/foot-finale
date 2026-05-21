import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  DashboardStats? _stats;
  List<EvolutionData> _evolution = [];
  List<RevenuData> _revenus = [];
  List<TauxPresenceData> _tauxPresence = [];
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  List<EvolutionData> get evolution => _evolution;
  List<RevenuData> get revenus => _revenus;
  List<TauxPresenceData> get tauxPresence => _tauxPresence;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboardData(String? token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final service = DashboardService(token);
      
      // Parallel fetch
      final results = await Future.wait([
        service.getStats(),
        service.getEvolution(
            DateTime.now().subtract(const Duration(days: 180)), DateTime.now()),
        service.getRevenus(DateTime.now().year),
        service.getTauxPresence(),
      ]);

      _stats = results[0] as DashboardStats;
      _evolution = results[1] as List<EvolutionData>;
      _revenus = results[2] as List<RevenuData>;
      _tauxPresence = results[3] as List<TauxPresenceData>;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
