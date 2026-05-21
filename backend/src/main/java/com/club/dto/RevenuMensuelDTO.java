package com.club.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class RevenuMensuelDTO {
    private String mois;
    private Double montant;

    public RevenuMensuelDTO() {}

    public RevenuMensuelDTO(String mois, Double montant) {
        this.mois = mois;
        this.montant = montant;
    }

    public String getMois() { return mois; }
    public void setMois(String mois) { this.mois = mois; }
    public Double getMontant() { return montant; }
    public void setMontant(Double montant) { this.montant = montant; }
}
