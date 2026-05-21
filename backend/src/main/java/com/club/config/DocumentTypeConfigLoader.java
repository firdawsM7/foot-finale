package com.club.config;

import com.club.model.DocumentTypeConfig;
import com.club.model.TypeDocument;
import com.club.model.User;
import com.club.repository.DocumentTypeConfigRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@Order(2)
public class DocumentTypeConfigLoader implements CommandLineRunner {

    private final DocumentTypeConfigRepository documentTypeConfigRepository;

    public DocumentTypeConfigLoader(DocumentTypeConfigRepository documentTypeConfigRepository) {
        this.documentTypeConfigRepository = documentTypeConfigRepository;
    }

    @Override
    public void run(String... args) {
        if (documentTypeConfigRepository.count() > 0) {
            return;
        }

        List<DocumentTypeConfig> all = List.of(
                cfg(User.Role.JOUEUR, TypeDocument.CIN_OR_BIRTH_CERTIFICATE, "CIN ou acte de naissance",
                        "pdf,jpg,jpeg,png", true, false, null),
                cfg(User.Role.JOUEUR, TypeDocument.IDENTITY_PHOTO, "Photo d identite",
                        "jpg,jpeg,png", true, false, null),
                cfg(User.Role.JOUEUR, TypeDocument.MEDICAL_CERTIFICATE, "Certificat medical aptitude (< 3 mois)",
                        "pdf", true, false, null),
                cfg(User.Role.JOUEUR, TypeDocument.FEDERAL_LICENSE, "Licence federale FRMF",
                        "pdf", true, false, null),
                cfg(User.Role.JOUEUR, TypeDocument.REGISTRATION_FORM, "Fiche inscription club",
                        "pdf", true, false, null),
                cfg(User.Role.JOUEUR, TypeDocument.PARENTAL_AUTHORIZATION, "Autorisation parentale mineur",
                        "pdf", true, true, "Si mineur"),
                cfg(User.Role.JOUEUR, TypeDocument.PROOF_OF_ADDRESS, "Justificatif domicile",
                        "pdf,jpg,jpeg,png", true, false, null),

                cfg(User.Role.ENCADRANT, TypeDocument.CIN, "CIN",
                        "pdf,jpg,jpeg,png", true, false, null),
                cfg(User.Role.ENCADRANT, TypeDocument.IDENTITY_PHOTO, "Photo identite",
                        "jpg,jpeg,png", true, false, null),
                cfg(User.Role.ENCADRANT, TypeDocument.SPORT_DIPLOMA, "Diplome sportif CAF UEFA FRMF",
                        "pdf", true, false, null),
                cfg(User.Role.ENCADRANT, TypeDocument.CV, "CV sportif",
                        "pdf", true, false, null),
                cfg(User.Role.ENCADRANT, TypeDocument.CRIMINAL_RECORD, "Casier judiciaire vierge",
                        "pdf", true, false, null),
                cfg(User.Role.ENCADRANT, TypeDocument.CONTRACT, "Contrat club",
                        "pdf", true, false, null),
                cfg(User.Role.ENCADRANT, TypeDocument.FEDERAL_LICENSE_COACH, "Licence encadrant FRMF",
                        "pdf", true, false, null),

                cfg(User.Role.ADHERENT, TypeDocument.CIN_OR_BIRTH_CERTIFICATE, "CIN ou acte de naissance",
                        "pdf,jpg,jpeg,png", true, false, null),
                cfg(User.Role.ADHERENT, TypeDocument.IDENTITY_PHOTO, "Photo identite",
                        "jpg,jpeg,png", true, false, null),
                cfg(User.Role.ADHERENT, TypeDocument.MEMBERSHIP_FORM, "Fiche adhesion",
                        "pdf", true, false, null),
                cfg(User.Role.ADHERENT, TypeDocument.PAYMENT_PROOF, "Justificatif paiement cotisation",
                        "pdf,jpg,jpeg,png", true, false, null),
                cfg(User.Role.ADHERENT, TypeDocument.PARENTAL_AUTHORIZATION, "Autorisation parentale mineur",
                        "pdf", true, true, "Si mineur")
        );

        documentTypeConfigRepository.saveAll(all);
    }

    private static DocumentTypeConfig cfg(User.Role role, TypeDocument type, String label,
                                          String allowed, boolean required, boolean conditional, String condDesc) {
        return DocumentTypeConfig.builder()
                .role(role)
                .documentType(type)
                .documentLabel(label)
                .allowedFileTypes(allowed)
                .isRequired(required)
                .isConditional(conditional)
                .conditionDescription(condDesc)
                .build();
    }
}