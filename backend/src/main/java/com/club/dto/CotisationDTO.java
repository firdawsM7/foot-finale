package com.club.dto;

import com.club.model.Cotisation;
import java.time.LocalDateTime;

public class CotisationDTO {
    private Long id;
    private Long userId;
    private String userNom;
    private String userPrenom;
    private String userEmail;
    private Double montant;
    private LocalDateTime datePaiement;
    private String saison;
    private String modePaiement;
    private String statut;
    private String reference;
    private String notes;
    private String recuPhoto;
    private String dateUploadRecu;

    public CotisationDTO() {
    }

    public CotisationDTO(Long id, Long userId, String userNom, String userPrenom, String userEmail, Double montant,
            LocalDateTime datePaiement, String saison, String modePaiement, String statut, String reference,
            String notes, String recuPhoto, String dateUploadRecu) {
        this.id = id;
        this.userId = userId;
        this.userNom = userNom;
        this.userPrenom = userPrenom;
        this.userEmail = userEmail;
        this.montant = montant;
        this.datePaiement = datePaiement;
        this.saison = saison;
        this.modePaiement = modePaiement;
        this.statut = statut;
        this.reference = reference;
        this.notes = notes;
        this.recuPhoto = recuPhoto;
        this.dateUploadRecu = dateUploadRecu;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUserNom() {
        return userNom;
    }

    public void setUserNom(String userNom) {
        this.userNom = userNom;
    }

    public String getUserPrenom() {
        return userPrenom;
    }

    public void setUserPrenom(String userPrenom) {
        this.userPrenom = userPrenom;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public Double getMontant() {
        return montant;
    }

    public void setMontant(Double montant) {
        this.montant = montant;
    }

    public LocalDateTime getDatePaiement() {
        return datePaiement;
    }

    public void setDatePaiement(LocalDateTime datePaiement) {
        this.datePaiement = datePaiement;
    }

    public String getSaison() {
        return saison;
    }

    public void setSaison(String saison) {
        this.saison = saison;
    }

    public String getModePaiement() {
        return modePaiement;
    }

    public void setModePaiement(String modePaiement) {
        this.modePaiement = modePaiement;
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
    }

    public String getReference() {
        return reference;
    }

    public void setReference(String reference) {
        this.reference = reference;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public String getRecuPhoto() {
        return recuPhoto;
    }

    public void setRecuPhoto(String recuPhoto) {
        this.recuPhoto = recuPhoto;
    }

    public String getDateUploadRecu() {
        return dateUploadRecu;
    }

    public void setDateUploadRecu(String dateUploadRecu) {
        this.dateUploadRecu = dateUploadRecu;
    }

    public static CotisationDTO fromEntity(Cotisation cotisation) {
        CotisationDTO dto = new CotisationDTO();
        dto.setId(cotisation.getId());
        dto.setUserId(cotisation.getUser().getId());
        dto.setUserNom(cotisation.getUser().getNom());
        dto.setUserPrenom(cotisation.getUser().getPrenom());
        dto.setUserEmail(cotisation.getUser().getEmail());
        dto.setMontant(cotisation.getMontant());
        dto.setDatePaiement(cotisation.getDatePaiement());
        dto.setSaison(cotisation.getSaison());
        dto.setModePaiement(cotisation.getModePaiement() != null ? cotisation.getModePaiement().name() : null);
        dto.setStatut(cotisation.getStatut() != null ? cotisation.getStatut().name() : null);
        dto.setReference(cotisation.getReference());
        dto.setNotes(cotisation.getNotes());
        dto.setRecuPhoto(cotisation.getRecuPhoto());
        dto.setDateUploadRecu(
                cotisation.getDateUploadRecu() != null ? cotisation.getDateUploadRecu().toString() : null);
        return dto;
    }
}
