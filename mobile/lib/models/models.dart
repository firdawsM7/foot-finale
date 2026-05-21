export 'document.dart';
export 'cotisation.dart';

// User Model
class User {
  final int? id;
  final String email;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? adresse;
  final String? dateNaissance;
  final String? photo;
  final String role;
  final bool actif;
  final String? dateInscription;
  final String? derniereConnexion;
  final int? equipeId;

  User({
    this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.adresse,
    this.dateNaissance,
    this.photo,
    required this.role,
    this.actif = true,
    this.dateInscription,
    this.derniereConnexion,
    this.equipeId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'],
      adresse: json['adresse'],
      dateNaissance: json['dateNaissance'],
      photo: json['photo'],
      role: json['role'] ?? 'ADHERENT',
      actif: json['actif'] ?? true,
      dateInscription: json['dateInscription'],
      derniereConnexion: json['derniereConnexion'],
      equipeId: json['equipeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
      'dateNaissance': dateNaissance,
      'photo': photo,
      'role': role,
      'actif': actif,
      'equipeId': equipeId,
    };
  }
}

// Joueur Model
class Joueur {
  final int? id;
  final String nom;
  final String prenom;
  final String? dateNaissance;
  final String? nationalite;
  final String poste;
  final int? numeroMaillot;
  final double? poids;
  final double? taille;
  final String? photo;
  final int? equipeId;
  final bool actif;
  final String? notes;

  Joueur({
    this.id,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.nationalite,
    required this.poste,
    this.numeroMaillot,
    this.poids,
    this.taille,
    this.photo,
    this.equipeId,
    this.actif = true,
    this.notes,
  });

  factory Joueur.fromJson(Map<String, dynamic> json) {
    return Joueur(
      id: json['id'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      dateNaissance: json['dateNaissance'],
      nationalite: json['nationalite'],
      poste: json['poste'] ?? '',
      numeroMaillot: json['numeroMaillot'],
      poids: json['poids']?.toDouble(),
      taille: json['taille']?.toDouble(),
      photo: json['photo'],
      equipeId: json['equipe']?['id'],
      actif: json['actif'] ?? true,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': dateNaissance,
      'nationalite': nationalite,
      'poste': poste,
      'numeroMaillot': numeroMaillot,
      'poids': poids,
      'taille': taille,
      'photo': photo,
      'actif': actif,
      'notes': notes,
    };
  }
}

// Equipe Model
class Equipe {
  final int? id;
  final String nom;
  final String? categorie;
  final int? encadrantId;
  final bool active;
  final String? description;

  Equipe({
    this.id,
    required this.nom,
    this.categorie,
    this.encadrantId,
    this.active = true,
    this.description,
  });

  factory Equipe.fromJson(Map<String, dynamic> json) {
    return Equipe(
      id: json['id'],
      nom: json['nom'] ?? '',
      categorie: json['categorie'],
      encadrantId: json['encadrant']?['id'],
      active: json['active'] ?? true,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'categorie': categorie,
      'active': active,
      'description': description,
    };
  }
}

// Entrainement Model
class Entrainement {
  final int? id;
  final int equipeId;
  final String dateHeure;
  final String lieu;
  final int? duree;
  final String? objectif;
  final String? exercices;
  final int? encadrantId;
  final String? encadrantNom;
  final String? encadrantPrenom;
  final String statut;
  final String? notes;

  Entrainement({
    this.id,
    required this.equipeId,
    required this.dateHeure,
    required this.lieu,
    this.duree,
    this.objectif,
    this.exercices,
    this.encadrantId,
    this.encadrantNom,
    this.encadrantPrenom,
    this.statut = 'PLANIFIE',
    this.notes,
  });

  factory Entrainement.fromJson(Map<String, dynamic> json) {
    final encadrant = json['encadrant'];
    return Entrainement(
      id: json['id'],
      equipeId: json['equipe']?['id'] ?? 0,
      dateHeure: json['dateHeure'] ?? '',
      lieu: json['lieu'] ?? '',
      duree: json['duree'],
      objectif: json['objectif'],
      exercices: json['exercices'],
      encadrantId: encadrant?['id'],
      encadrantNom: encadrant?['nom'],
      encadrantPrenom: encadrant?['prenom'],
      statut: json['statut'] ?? 'PLANIFIE',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateHeure': dateHeure,
      'lieu': lieu,
      'duree': duree,
      'objectif': objectif,
      'exercices': exercices,
      'statut': statut,
      'notes': notes,
      if (encadrantId != null) 'encadrant': {'id': encadrantId},
    };
  }
}

// Match Model
class Match {
  final int? id;
  final int equipeId;
  final String adversaire;
  final String dateHeure;
  final String lieu;
  final String type;
  final int? scoreEquipe;
  final int? scoreAdversaire;
  final String statut;
  final String? notes;
  final String? composition;

  Match({
    this.id,
    required this.equipeId,
    required this.adversaire,
    required this.dateHeure,
    required this.lieu,
    this.type = 'AMICAL',
    this.scoreEquipe,
    this.scoreAdversaire,
    this.statut = 'PLANIFIE',
    this.notes,
    this.composition,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      equipeId: json['equipe']?['id'] ?? 0,
      adversaire: json['adversaire'] ?? '',
      dateHeure: json['dateHeure'] ?? '',
      lieu: json['lieu'] ?? '',
      type: json['type'] ?? 'AMICAL',
      scoreEquipe: json['scoreEquipe'],
      scoreAdversaire: json['scoreAdversaire'],
      statut: json['statut'] ?? 'PLANIFIE',
      notes: json['notes'],
      composition: json['composition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adversaire': adversaire,
      'dateHeure': dateHeure,
      'lieu': lieu,
      'type': type,
      'scoreEquipe': scoreEquipe,
      'scoreAdversaire': scoreAdversaire,
      'statut': statut,
      'notes': notes,
      'composition': composition,
    };
  }
}