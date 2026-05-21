class PlayerTechnicalNote {
  final int? id;
  final int playerId;
  final int encadrantId;
  final String encadrantName;
  final int technicalRating;
  final int tacticalRating;
  final int physicalRating;
  final String strengths;
  final String weaknesses;
  final String observation;
  final DateTime? createdAt;

  PlayerTechnicalNote({
    this.id,
    required this.playerId,
    required this.encadrantId,
    required this.encadrantName,
    required this.technicalRating,
    required this.tacticalRating,
    required this.physicalRating,
    required this.strengths,
    required this.weaknesses,
    required this.observation,
    this.createdAt,
  });

  factory PlayerTechnicalNote.fromJson(Map<String, dynamic> json) {
    return PlayerTechnicalNote(
      id: json['id'],
      playerId: json['playerId'] ?? 0,
      encadrantId: json['encadrantId'] ?? 0,
      encadrantName: json['encadrantName'] ?? '',
      technicalRating: json['technicalRating'] ?? 5,
      tacticalRating: json['tacticalRating'] ?? 5,
      physicalRating: json['physicalRating'] ?? 5,
      strengths: json['strengths'] ?? '',
      weaknesses: json['weaknesses'] ?? '',
      observation: json['observation'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'encadrantId': encadrantId,
      'encadrantName': encadrantName,
      'technicalRating': technicalRating,
      'tacticalRating': tacticalRating,
      'physicalRating': physicalRating,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'observation': observation,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
