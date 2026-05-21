package com.club.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "cotisations")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Cotisation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private Double montant;

    @Column(nullable = false)
    private LocalDateTime datePaiement;

    @Column(nullable = false)
    private String saison;

    @Enumerated(EnumType.STRING)
    private ModePaiement modePaiement = ModePaiement.ESPECES;

    @Enumerated(EnumType.STRING)
    private Statut statut = Statut.EN_ATTENTE;

    private String reference;

    @Column(columnDefinition = "TEXT")
    private String notes;

    private String recuPhoto;

    private LocalDateTime dateUploadRecu;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
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

    public ModePaiement getModePaiement() {
        return modePaiement;
    }

    public void setModePaiement(ModePaiement modePaiement) {
        this.modePaiement = modePaiement;
    }

    public Statut getStatut() {
        return statut;
    }

    public void setStatut(Statut statut) {
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

    public LocalDateTime getDateUploadRecu() {
        return dateUploadRecu;
    }

    public void setDateUploadRecu(LocalDateTime dateUploadRecu) {
        this.dateUploadRecu = dateUploadRecu;
    }

    public enum ModePaiement {
        ESPECES,
        CARTE_BANCAIRE,
        VIREMENT,
        CHEQUE
    }

    public enum Statut {
        EN_ATTENTE,
        VALIDEE,
        REJETEE
    }
}