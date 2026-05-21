package com.club.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "entrainements")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Entrainement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "equipe_id", nullable = false)
    private Equipe equipe;

    @Column(nullable = false)
    private LocalDateTime dateHeure;

    @Column(nullable = false)
    private String lieu;

    private Integer duree;

    @Column(columnDefinition = "TEXT")
    private String objectif;

    public String getObjectif() {
        return objectif;
    }

    public void setObjectif(String objectif) {
        this.objectif = objectif;
    }

    @Column(columnDefinition = "TEXT")
    private String exercices;

    @ManyToOne
    @JoinColumn(name = "encadrant_id")
    private User encadrant;

    @Enumerated(EnumType.STRING)
    private Statut statut = Statut.PLANIFIE;

    @Column(columnDefinition = "TEXT")
    private String notes;

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

    public Integer getDuree() {
        return duree;
    }

    public void setDuree(Integer duree) {
        this.duree = duree;
    }

    public String getExercices() {
        return exercices;
    }

    public void setExercices(String exercices) {
        this.exercices = exercices;
    }

    public User getEncadrant() {
        return encadrant;
    }

    public void setEncadrant(User encadrant) {
        this.encadrant = encadrant;
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

    public enum Statut {
        PLANIFIE,
        EN_COURS,
        TERMINE,
        ANNULE
    }
}