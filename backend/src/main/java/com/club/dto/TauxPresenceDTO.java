package com.club.dto;

public class TauxPresenceDTO {
    private String equipe;
    private Double taux;

    public TauxPresenceDTO() {
    }

    public TauxPresenceDTO(String equipe, Double taux) {
        this.equipe = equipe;
        this.taux = taux;
    }

    public String getEquipe() {
        return equipe;
    }

    public void setEquipe(String equipe) {
        this.equipe = equipe;
    }

    public Double getTaux() {
        return taux;
    }

    public void setTaux(Double taux) {
        this.taux = taux;
    }
}
