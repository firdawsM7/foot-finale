package com.club.dto;

import java.time.LocalDate;

public class InjurySuspensionDto {
    private Long id;
    private Long playerId;
    private String playerName;
    private String type;
    private String severity;
    private String description;
    private LocalDate startDate;
    private LocalDate estimatedEndDate;
    private String status;
    private String restrictions;

    public InjurySuspensionDto() {
    }

    public InjurySuspensionDto(Long id, Long playerId, String playerName, String type, String severity,
            String description, LocalDate startDate, LocalDate estimatedEndDate, String status, String restrictions) {
        this.id = id;
        this.playerId = playerId;
        this.playerName = playerName;
        this.type = type;
        this.severity = severity;
        this.description = description;
        this.startDate = startDate;
        this.estimatedEndDate = estimatedEndDate;
        this.status = status;
        this.restrictions = restrictions;
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

    public String getPlayerName() {
        return playerName;
    }

    public void setPlayerName(String playerName) {
        this.playerName = playerName;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getSeverity() {
        return severity;
    }

    public void setSeverity(String severity) {
        this.severity = severity;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEstimatedEndDate() {
        return estimatedEndDate;
    }

    public void setEstimatedEndDate(LocalDate estimatedEndDate) {
        this.estimatedEndDate = estimatedEndDate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getRestrictions() {
        return restrictions;
    }

    public void setRestrictions(String restrictions) {
        this.restrictions = restrictions;
    }
}
