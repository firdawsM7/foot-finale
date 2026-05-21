package com.club.model;

import com.club.util.EncryptionConverter;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "player_technical_notes")
public class PlayerTechnicalNote {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "player_id", nullable = false)
    private Joueur player;

    @ManyToOne
    @JoinColumn(name = "encadrant_id", nullable = false)
    private User encadrant;

    private Integer technicalRating; // 1-10
    private Integer tacticalRating; // 1-10
    private Integer physicalRating; // 1-10

    @Column(columnDefinition = "TEXT")
    private String strengths;

    @Column(columnDefinition = "TEXT")
    private String weaknesses;

    @Convert(converter = EncryptionConverter.class)
    @Column(columnDefinition = "TEXT")
    private String observation; // Encrypted

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public PlayerTechnicalNote() {
    }

    public PlayerTechnicalNote(Joueur player, User encadrant, Integer technicalRating, Integer tacticalRating,
            Integer physicalRating, String strengths, String weaknesses, String observation) {
        this.player = player;
        this.encadrant = encadrant;
        this.technicalRating = technicalRating;
        this.tacticalRating = tacticalRating;
        this.physicalRating = physicalRating;
        this.strengths = strengths;
        this.weaknesses = weaknesses;
        this.observation = observation;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Joueur getPlayer() {
        return player;
    }

    public void setPlayer(Joueur player) {
        this.player = player;
    }

    public User getEncadrant() {
        return encadrant;
    }

    public void setEncadrant(User encadrant) {
        this.encadrant = encadrant;
    }

    public Integer getTechnicalRating() {
        return technicalRating;
    }

    public void setTechnicalRating(Integer technicalRating) {
        this.technicalRating = technicalRating;
    }

    public Integer getTacticalRating() {
        return tacticalRating;
    }

    public void setTacticalRating(Integer tacticalRating) {
        this.tacticalRating = tacticalRating;
    }

    public Integer getPhysicalRating() {
        return physicalRating;
    }

    public void setPhysicalRating(Integer physicalRating) {
        this.physicalRating = physicalRating;
    }

    public String getStrengths() {
        return strengths;
    }

    public void setStrengths(String strengths) {
        this.strengths = strengths;
    }

    public String getWeaknesses() {
        return weaknesses;
    }

    public void setWeaknesses(String weaknesses) {
        this.weaknesses = weaknesses;
    }

    public String getObservation() {
        return observation;
    }

    public void setObservation(String observation) {
        this.observation = observation;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
