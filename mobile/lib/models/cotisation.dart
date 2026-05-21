class Cotisation {
  final int id;
  final int userId;
  final String userNom;
  final String userPrenom;
  final String userEmail;
  final double montant;
  final DateTime datePaiement;
  final String saison;
  final String modePaiement;
  final String statut;
  final String? reference;
  final String? notes;
  final String? recuPhoto;
  final String? dateUploadRecu;

  Cotisation({
    required this.id,
    required this.userId,
    required this.userNom,
    required this.userPrenom,
    required this.userEmail,
    required this.montant,
    required this.datePaiement,
    required this.saison,
    required this.modePaiement,
    required this.statut,
    this.reference,
    this.notes,
    this.recuPhoto,
    this.dateUploadRecu,
  });

  factory Cotisation.fromJson(Map<String, dynamic> json) {
    // Handle both nested user object and top-level user fields
    final user = json['user'] as Map<String, dynamic>?;
    final userId = user != null ? user['id'] as int : json['userId'] as int? ?? json['user_id'] as int? ?? 0;
    final userNom = user != null ? user['nom'] ?? '' : json['userNom'] ?? json['user_nom'] ?? '';
    final userPrenom = user != null ? user['prenom'] ?? '' : json['userPrenom'] ?? json['user_prenom'] ?? '';
    final userEmail = user != null ? user['email'] ?? '' : json['userEmail'] ?? json['user_email'] ?? '';
    
    return Cotisation(
      id: json['id'] as int? ?? 0,
      userId: userId,
      userNom: userNom,
      userPrenom: userPrenom,
      userEmail: userEmail,
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0,
      datePaiement: json['datePaiement'] != null ? DateTime.parse(json['datePaiement']) : DateTime.now(),
      saison: json['saison'] ?? '',
      modePaiement: json['modePaiement'] ?? '',
      statut: json['statut'] ?? '',
      reference: json['reference'],
      notes: json['notes'],
      recuPhoto: json['recuPhoto'],
      dateUploadRecu: json['dateUploadRecu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userNom': userNom,
      'userPrenom': userPrenom,
      'userEmail': userEmail,
      'montant': montant,
      'datePaiement': datePaiement.toIso8601String(),
      'saison': saison,
      'modePaiement': modePaiement,
      'statut': statut,
      'reference': reference,
      'notes': notes,
    };
  }

  String get statutLabel {
    switch (statut) {
      case 'VALIDEE':
        return 'Validée';
      case 'EN_ATTENTE':
        return 'En attente';
      case 'REJETEE':
        return 'Rejetée';
      default:
        return statut;
    }
  }

  String get modePaiementLabel {
    switch (modePaiement) {
      case 'ESPECES':
        return 'Espèces';
      case 'CARTE_BANCAIRE':
        return 'Carte bancaire';
      case 'VIREMENT':
        return 'Virement';
      case 'CHEQUE':
        return 'Chèque';
      default:
        return modePaiement;
    }
  }
}
