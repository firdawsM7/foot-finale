package com.club.dto;

public class DashboardStatsDTO {
    private long totalJoueurs;
    private long totalEquipes;
    private long totalEntrainements;
    private double totalRevenus;

    public DashboardStatsDTO() {
    }

    public DashboardStatsDTO(long totalJoueurs, long totalEquipes, long totalEntrainements, double totalRevenus) {
        this.totalJoueurs = totalJoueurs;
        this.totalEquipes = totalEquipes;
        this.totalEntrainements = totalEntrainements;
        this.totalRevenus = totalRevenus;
    }

    public long getTotalJoueurs() {
        return totalJoueurs;
    }

    public void setTotalJoueurs(long totalJoueurs) {
        this.totalJoueurs = totalJoueurs;
    }

    public long getTotalEquipes() {
        return totalEquipes;
    }

    public void setTotalEquipes(long totalEquipes) {
        this.totalEquipes = totalEquipes;
    }

    public long getTotalEntrainements() {
        return totalEntrainements;
    }

    public void setTotalEntrainements(long totalEntrainements) {
        this.totalEntrainements = totalEntrainements;
    }

    public double getTotalRevenus() {
        return totalRevenus;
    }

    public void setTotalRevenus(double totalRevenus) {
        this.totalRevenus = totalRevenus;
    }
}
