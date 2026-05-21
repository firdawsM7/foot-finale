package com.club.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "matchs")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Match {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "equipe_id", nullable = false)
    private Equipe equipe;

    @Column(nullable = false)
    private String adversaire;

    @Column(nullable = false)
    private LocalDateTime dateHeure;

    @Column(nullable = false)
    private String lieu;

    @Enumerated(EnumType.STRING)
    private TypeMatch type = TypeMatch.AMICAL;

    private Integer scoreEquipe;

    private Integer scoreAdversaire;

    @Enumerated(EnumType.STRING)
    private Statut statut = Statut.PLANIFIE;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(columnDefinition = "TEXT")
    private String composition;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Equipe getEquipe() {
        return equipe;
    }

    public void setEquipe(Equipe equipe) {
        this.equipe = equipe;
    }

    public String getAdversaire() {
        return adversaire;
    }

    public void setAdversaire(String adversaire) {
        this.adversaire = adversaire;
    }

    public LocalDateTime getDateHeure() {
        return dateHeure;
    }

    public void setDateHeure(LocalDateTime dateHeure) {
        this.dateHeure = dateHeure;
    }

    public String getLieu() {
        return lieu;
    }

    public void setLieu(String lieu) {
        this.lieu = lieu;
    }

    public TypeMatch getType() {
        return type;
    }

    public void setType(TypeMatch type) {
        this.type = type;
    }

    public Integer getScoreEquipe() {
        return scoreEquipe;
    }

    public void setScoreEquipe(Integer scoreEquipe) {
        this.scoreEquipe = scoreEquipe;
    }

    public Integer getScoreAdversaire() {
        return scoreAdversaire;
    }

    public void setScoreAdversaire(Integer scoreAdversaire) {
        this.scoreAdversaire = scoreAdversaire;
    }

    public Statut getStatut() {
        return statut;
    }

    public void setStatut(Statut statut) {
        this.statut = statut;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public String getComposition() {
        return composition;
    }

    public void setComposition(String composition) {
        this.composition = composition;
    }

    public enum TypeMatch {
        CHAMPIONNAT,
        COUPE,
        AMICAL,
        TOURNOI
    }

    public enum Statut {
        PLANIFIE,
        EN_COURS,
        TERMINE,
        ANNULE
    }
}
