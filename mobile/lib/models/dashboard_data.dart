class DashboardData {
  final DashboardStats stats;
  final List<EvolutionData> evolution;
  final List<RevenuData> revenus;
  final List<TauxPresenceData> tauxPresence;

  DashboardData({
    required this.stats,
    required this.evolution,
    required this.revenus,
    required this.tauxPresence,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      evolution: (json['evolution'] as List? ?? [])
          .map((e) => EvolutionData.fromJson(e))
          .toList(),
      revenus: (json['revenus'] as List? ?? [])
          .map((e) => RevenuData.fromJson(e))
          .toList(),
      tauxPresence: (json['tauxPresence'] as List? ?? [])
          .map((e) => TauxPresenceData.fromJson(e))
          .toList(),
    );
  }
}

class DashboardStats {
  final int totalJoueurs;
  final int totalEquipes;
  final int totalEntrainements;
  final double totalRevenus;

  DashboardStats({
    required this.totalJoueurs,
    required this.totalEquipes,
    required this.totalEntrainements,
    required this.totalRevenus,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalJoueurs: json['totalJoueurs'] ?? 0,
      totalEquipes: json['totalEquipes'] ?? 0,
      totalEntrainements: json['totalEntrainements'] ?? 0,
      totalRevenus: (json['totalRevenus'] ?? 0).toDouble(),
    );
  }
}

class EvolutionData {
  final String mois;
  final int count;

  EvolutionData({required this.mois, required this.count});

  factory EvolutionData.fromJson(Map<String, dynamic> json) {
    return EvolutionData(
      mois: json['mois'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class RevenuData {
  final String mois;
  final double montant;

  RevenuData({required this.mois, required this.montant});

  factory RevenuData.fromJson(Map<String, dynamic> json) {
    return RevenuData(
      mois: json['mois'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
    );
  }
}

class TauxPresenceData {
  final String equipe;
  final double taux;

  TauxPresenceData({required this.equipe, required this.taux});

  factory TauxPresenceData.fromJson(Map<String, dynamic> json) {
    return TauxPresenceData(
      equipe: json['equipe'] ?? '',
      taux: (json['taux'] ?? 0).toDouble(),
    );
  }
}
