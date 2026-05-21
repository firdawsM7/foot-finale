class InjurySuspension {
  final int? id;
  final int playerId;
  final String playerName;
  final String type;
  final String severity;
  final String description;
  final DateTime startDate;
  final DateTime? estimatedEndDate;
  final String status;
  final String restrictions;

  InjurySuspension({
    this.id,
    required this.playerId,
    required this.playerName,
    required this.type,
    required this.severity,
    required this.description,
    required this.startDate,
    this.estimatedEndDate,
    required this.status,
    required this.restrictions,
  });

  factory InjurySuspension.fromJson(Map<String, dynamic> json) {
    return InjurySuspension(
      id: json['id'],
      playerId: json['playerId'] ?? 0,
      playerName: json['playerName'] ?? '',
      type: json['type'] ?? 'INJURY',
      severity: json['severity'] ?? 'MEDIUM',
      description: json['description'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      estimatedEndDate: json['estimatedEndDate'] != null
          ? DateTime.parse(json['estimatedEndDate'])
          : null,
      status: json['status'] ?? 'ACTIVE',
      restrictions: json['restrictions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'playerName': playerName,
      'type': type,
      'severity': severity,
      'description': description,
      'startDate': startDate.toIso8601String().split('T')[0],
      'estimatedEndDate': estimatedEndDate?.toIso8601String().split('T')[0],
      'status': status,
      'restrictions': restrictions,
    };
  }
}
