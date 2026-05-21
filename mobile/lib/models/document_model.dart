enum DocumentType {
  // JOUEUR (Player) documents
  CIN_OR_BIRTH_CERTIFICATE,
  IDENTITY_PHOTO,
  MEDICAL_CERTIFICATE,
  FEDERAL_LICENSE,
  REGISTRATION_FORM,
  PARENTAL_AUTHORIZATION,
  PROOF_OF_ADDRESS,

  // ENCADRANT (Coach/Staff) documents
  CIN,
  SPORT_DIPLOMA,
  CV,
  CRIMINAL_RECORD,
  CONTRACT,
  FEDERAL_LICENSE_COACH,

  // ADHÉRENT (Member) documents
  MEMBERSHIP_FORM,
  PAYMENT_PROOF
}

enum DocumentStatus {
  PENDING,
  APPROVED,
  REJECTED,
  MISSING
}

class DocumentModel {
  final int? id;
  final DocumentType documentType;
  final String documentLabel;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final DocumentStatus status;
  final bool isRequired;
  /** true si le document dépend d'une condition (ex. mineur) */
  final bool isConditional;
  final DateTime? uploadedAt;
  final String? rejectionReason;

  DocumentModel({
    this.id,
    required this.documentType,
    required this.documentLabel,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.status = DocumentStatus.MISSING,
    this.isRequired = true,
    this.isConditional = false,
    this.uploadedAt,
    this.rejectionReason,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      documentType: DocumentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['documentType'],
        orElse: () => DocumentType.CIN_OR_BIRTH_CERTIFICATE,
      ),
      documentLabel: json['documentLabel'] ?? '',
      fileName: json['fileName'],
      fileType: json['fileType'],
      fileSize: json['fileSize'] is int ? json['fileSize'] as int : int.tryParse('${json['fileSize']}'),
      status: _parseStatus(json['status']),
      isRequired: json['isRequired'] ?? true,
      isConditional: json['isConditional'] == true,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  static DocumentStatus _parseStatus(dynamic v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return DocumentStatus.MISSING;
    return DocumentStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => DocumentStatus.MISSING,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'documentType': documentType.toString().split('.').last,
      'documentLabel': documentLabel,
      if (fileName != null) 'fileName': fileName,
      if (fileType != null) 'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
      'status': status.toString().split('.').last,
      'isRequired': isRequired,
      if (uploadedAt != null) 'uploadedAt': uploadedAt?.toIso8601String(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  String get statusLabel {
    switch (status) {
      case DocumentStatus.PENDING:
        return 'En attente';
      case DocumentStatus.APPROVED:
        return 'Approuvé';
      case DocumentStatus.REJECTED:
        return 'Rejeté';
      case DocumentStatus.MISSING:
        return 'Manquant';
    }
  }

  String get statusIcon {
    switch (status) {
      case DocumentStatus.PENDING:
        return '⏳';
      case DocumentStatus.APPROVED:
        return '✅';
      case DocumentStatus.REJECTED:
        return '🔴';
      case DocumentStatus.MISSING:
        return '❌';
    }
  }

  String get typeLabel {
    switch (documentType) {
      case DocumentType.CIN_OR_BIRTH_CERTIFICATE:
        return 'CIN ou Acte de naissance';
      case DocumentType.IDENTITY_PHOTO:
        return 'Photo d\'identité';
      case DocumentType.MEDICAL_CERTIFICATE:
        return 'Certificat médical';
      case DocumentType.FEDERAL_LICENSE:
        return 'Licence fédérale FRMF';
      case DocumentType.REGISTRATION_FORM:
        return 'Fiche d\'inscription';
      case DocumentType.PARENTAL_AUTHORIZATION:
        return 'Autorisation parentale';
      case DocumentType.PROOF_OF_ADDRESS:
        return 'Justificatif de domicile';
      case DocumentType.CIN:
        return 'CIN';
      case DocumentType.SPORT_DIPLOMA:
        return 'Diplôme sportif';
      case DocumentType.CV:
        return 'CV sportif';
      case DocumentType.CRIMINAL_RECORD:
        return 'Casier judiciaire';
      case DocumentType.CONTRACT:
        return 'Contrat';
      case DocumentType.FEDERAL_LICENSE_COACH:
        return 'Licence encadrant FRMF';
      case DocumentType.MEMBERSHIP_FORM:
        return 'Fiche d\'adhésion';
      case DocumentType.PAYMENT_PROOF:
        return 'Justificatif de paiement';
    }
  }

  bool get isImage {
    return fileType != null &&
        (fileType!.toLowerCase() == 'jpg' ||
            fileType!.toLowerCase() == 'jpeg' ||
            fileType!.toLowerCase() == 'png');
  }

  bool get isPdf {
    return fileType != null && fileType!.toLowerCase() == 'pdf';
  }

  String get allowedFileTypes {
    switch (documentType) {
      case DocumentType.IDENTITY_PHOTO:
        return 'JPG, PNG';
      case DocumentType.MEDICAL_CERTIFICATE:
      case DocumentType.FEDERAL_LICENSE:
      case DocumentType.REGISTRATION_FORM:
      case DocumentType.PARENTAL_AUTHORIZATION:
      case DocumentType.SPORT_DIPLOMA:
      case DocumentType.CV:
      case DocumentType.CRIMINAL_RECORD:
      case DocumentType.CONTRACT:
      case DocumentType.FEDERAL_LICENSE_COACH:
      case DocumentType.MEMBERSHIP_FORM:
        return 'PDF';
      default:
        return 'PDF, JPG, PNG';
    }
  }
}
