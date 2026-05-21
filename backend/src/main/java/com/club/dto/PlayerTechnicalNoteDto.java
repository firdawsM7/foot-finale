package com.club.dto;

import java.time.LocalDateTime;

public class PlayerTechnicalNoteDto {
    private Long id;
    private Long playerId;
    private Long encadrantId;
    private String encadrantName;
    private Integer technicalRating;
    private Integer tacticalRating;
    private Integer physicalRating;
    private String strengths;
    private String weaknesses;
    private String observation;
    private LocalDateTime createdAt;

    public PlayerTechnicalNoteDto() {
    }

    public PlayerTechnicalNoteDto(Long id, Long playerId, Long encadrantId, String encadrantName,
            Integer technicalRating, Integer tacticalRating, Integer physicalRating, String strengths,
            String weaknesses, String observation, LocalDateTime createdAt) {
        this.id = id;
        this.playerId = playerId;
        this.encadrantId = encadrantId;
        this.encadrantName = encadrantName;
        this.technicalRating = technicalRating;
        this.tacticalRating = tacticalRating;
        this.physicalRating = physicalRating;
        this.strengths = strengths;
        this.weaknesses = weaknesses;
        this.observation = observation;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getPlayerId() {
        return playerId;
    }

    public void setPlayerId(Long playerId) {
        this.playerId = playerId;
    }

    public Long getEncadrantId() {
        return encadrantId;
    }

    public void setEncadrantId(Long encadrantId) {
        this.encadrantId = encadrantId;
    }

    public String getEncadrantName() {
        return encadrantName;
    }

    public void setEncadrantName(String encadrantName) {
        this.encadrantName = encadrantName;
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
}
