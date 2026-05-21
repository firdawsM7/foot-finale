enum UserRole {
  JOUEUR,
  ENCADRANT,
  ADHERENT,
  ADMIN,
}

enum UserStatus {
  PENDING,
  ACTIVE,
  REJECTED
}

enum UserAccountStatus {
  ACTIF,
  ACTIVATION_REQUISE,
  SUSPENDU
}

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final DateTime? dateOfBirth;
  final UserRole role;
  final UserAccountStatus accountStatus;
  /** PENDING, ACTIVE, REJECTED — aligné sur registrationStatus côté API */
  final UserStatus registrationStatus;
  final bool actif;
  final DateTime dateInscription;
  final int? equipeId;
  final String? poste;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    this.dateOfBirth,
    required this.role,
    required this.accountStatus,
    required this.registrationStatus,
    required this.actif,
    required this.dateInscription,
    this.equipeId,
    this.poste,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final reg = json['registrationStatus'] ?? json['documentStatus'];
    return UserModel(
      id: json['id'] ?? 0,
      // Some endpoints return {prenom, nom, telephone, adresse, dateNaissance}
      // Others (dossier) return {firstName, lastName, phone, address, dateOfBirth}
      firstName: json['prenom'] ?? json['firstName'] ?? '',
      lastName: json['nom'] ?? json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['telephone'] ?? json['phone'] ?? '',
      address: json['adresse'] ?? json['address'] ?? '',
      dateOfBirth: _parseDate(json['dateNaissance'] ?? json['dateOfBirth']),
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.ADHERENT,
      ),
      accountStatus: UserAccountStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['accountStatus'],
        orElse: () => UserAccountStatus.ACTIVATION_REQUISE,
      ),
      registrationStatus: UserStatus.values.firstWhere(
        (e) => e.name == reg?.toString(),
        orElse: () => UserStatus.PENDING,
      ),
      actif: json['actif'] ?? false,
      dateInscription: (json['dateInscription'] ?? json['date_inscription']) != null
          ? DateTime.parse((json['dateInscription'] ?? json['date_inscription']).toString())
          : DateTime.now(),
      equipeId: json['equipeId'],
      poste: json['poste'],
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return DateTime.tryParse(s) ?? DateTime.tryParse('${s}T00:00:00');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prenom': firstName,
      'nom': lastName,
      'email': email,
      'telephone': phone,
      'adresse': address,
      'dateNaissance': dateOfBirth?.toIso8601String(),
      'role': role.toString().split('.').last,
      'accountStatus': accountStatus.toString().split('.').last,
      'registrationStatus': registrationStatus.name,
      'actif': actif,
      'dateInscription': dateInscription.toIso8601String(),
      'equipeId': equipeId,
      'poste': poste,
    };
  }

  bool get isMinor {
    if (dateOfBirth == null) return false;
    final now = DateTime.now();
    final age = now.year - dateOfBirth!.year;
    return age < 18;
  }

  String get fullName => '$firstName $lastName';

  String get roleLabel {
    switch (role) {
      case UserRole.JOUEUR:
        return 'Joueur';
      case UserRole.ENCADRANT:
        return 'Encadrant';
      case UserRole.ADHERENT:
        return 'Adhérent';
      case UserRole.ADMIN:
        return 'Administrateur';
    }
  }
}
