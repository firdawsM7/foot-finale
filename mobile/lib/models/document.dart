class Document {
  final int id;
  final String nom;
  final String type;
  final String url;
  final DateTime? dateExpiration;
  final bool valide;
  final int userId;
  final String userNom;
  final String userPrenom;
  final DateTime uploadDate;
  final String uploadedBy;
  final int joursRestants;

  Document({
    required this.id,
    required this.nom,
    required this.type,
    required this.url,
    this.dateExpiration,
    required this.valide,
    required this.userId,
    required this.userNom,
    required this.userPrenom,
    required this.uploadDate,
    required this.uploadedBy,
    required this.joursRestants,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      nom: json['nom'],
      type: json['type'],
      url: json['url'],
      dateExpiration: json['dateExpiration'] != null 
          ? DateTime.parse(json['dateExpiration']) 
          : null,
      valide: json['valide'] ?? false,
      userId: json['userId'],
      userNom: json['userNom'] ?? '',
      userPrenom: json['userPrenom'] ?? '',
      uploadDate: DateTime.parse(json['uploadDate']),
      uploadedBy: json['uploadedBy'] ?? '',
      joursRestants: json['joursRestants'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'url': url,
      'dateExpiration': dateExpiration?.toIso8601String(),
      'valide': valide,
      'userId': userId,
      'userNom': userNom,
      'userPrenom': userPrenom,
      'uploadDate': uploadDate.toIso8601String(),
      'uploadedBy': uploadedBy,
      'joursRestants': joursRestants,
    };
  }

  bool get isExpired => joursRestants < 0;
  bool get isExpiringSoon => joursRestants >= 0 && joursRestants < 30;
}
