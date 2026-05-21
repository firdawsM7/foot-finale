package com.club.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class EvolutionDTO {
    private String mois;
    private long count;

    public EvolutionDTO() {}

    public EvolutionDTO(String mois, long count) {
        this.mois = mois;
        this.count = count;
    }

    public String getMois() { return mois; }
    public void setMois(String mois) { this.mois = mois; }
    public long getCount() { return count; }
    public void setCount(long count) { this.count = count; }
}
