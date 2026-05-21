package com.club.service;

import com.club.dto.DashboardStatsDTO;
import com.club.dto.EvolutionDTO;
import com.club.dto.RevenuMensuelDTO;
import com.club.dto.TauxPresenceDTO;
import com.club.model.Cotisation;
import com.club.repository.*;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.Month;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class DashboardService {

    private final JoueurRepository joueurRepository;
    private final EquipeRepository equipeRepository;
    private final EntrainementRepository entrainementRepository;
    private final CotisationRepository cotisationRepository;
    private final UserRepository userRepository;

    public DashboardService(JoueurRepository joueurRepository, EquipeRepository equipeRepository,
            EntrainementRepository entrainementRepository, CotisationRepository cotisationRepository,
            UserRepository userRepository) {
        this.joueurRepository = joueurRepository;
        this.equipeRepository = equipeRepository;
        this.entrainementRepository = entrainementRepository;
        this.cotisationRepository = cotisationRepository;
        this.userRepository = userRepository;
    }

    public DashboardStatsDTO getStats() {
        long totalJoueurs = joueurRepository.count();
        long totalEquipes = equipeRepository.count();
        long totalEntrainements = entrainementRepository.count();

        Double totalRevenus = cotisationRepository.findAll().stream()
                .filter(c -> c.getStatut() == Cotisation.Statut.VALIDEE)
                .mapToDouble(Cotisation::getMontant)
                .sum();

        return new DashboardStatsDTO(totalJoueurs, totalEquipes, totalEntrainements, totalRevenus);
    }

    public List<EvolutionDTO> getEvolution(LocalDateTime startDate, LocalDateTime endDate) {
        // Logique simplifiée pour l'exemple : compte par mois d'inscription
        List<EvolutionDTO> evolution = new ArrayList<>();
        // En prod, faire une requête JPQL groupé par mois
        for (int i = 0; i < 6; i++) {
            Month month = LocalDateTime.now().minusMonths(5 - i).getMonth();
            String label = month.getDisplayName(TextStyle.SHORT, Locale.FRENCH);
            evolution.add(new EvolutionDTO(label, 10 + (i * 5))); // Mock data pour le moment
        }
        return evolution;
    }

    public List<RevenuMensuelDTO> getRevenusMensuels(int year) {
        List<RevenuMensuelDTO> revenus = new ArrayList<>();
        for (int i = 1; i <= 12; i++) {
            Month month = Month.of(i);
            String label = month.getDisplayName(TextStyle.SHORT, Locale.FRENCH);
            revenus.add(new RevenuMensuelDTO(label, Double.valueOf(2000.0 + (i * 200)))); // Mock data
        }
        return revenus;
    }

    public List<TauxPresenceDTO> getTauxPresence() {
        List<TauxPresenceDTO> taux = new ArrayList<>();
        equipeRepository.findAll().forEach(e -> {
            taux.add(new TauxPresenceDTO(e.getNom(), Double.valueOf(80.0 + (Math.random() * 15)))); // Mock data
        });
        return taux;
    }
}
