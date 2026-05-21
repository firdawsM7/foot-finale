import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  final String? token;

  DashboardService(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<DashboardStats> getStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/dashboard/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return DashboardStats.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }

  Future<List<EvolutionData>> getEvolution(DateTime start, DateTime end) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/admin/dashboard/evolution?startDate=${start.toIso8601String()}&endDate=${end.toIso8601String()}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((e) => EvolutionData.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors de la récupération de l\'évolution');
    }
  }

  Future<List<RevenuData>> getRevenus(int year) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/dashboard/revenus-mensuel?year=$year'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((e) => RevenuData.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des revenus');
    }
  }

  Future<List<TauxPresenceData>> getTauxPresence() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/dashboard/taux-presence'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List list = json.decode(response.body);
      return list.map((e) => TauxPresenceData.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors de la récupération du taux de présence');
    }
  }
}
