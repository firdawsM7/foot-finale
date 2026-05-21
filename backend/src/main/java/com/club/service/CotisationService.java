package com.club.service;

import com.club.model.Cotisation;
import com.club.repository.CotisationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CotisationService {

    @Autowired
    private CotisationRepository cotisationRepository;

    public Cotisation createCotisation(Cotisation cotisation) {
        return cotisationRepository.save(cotisation);
    }

    public Cotisation updateCotisation(Long id, Cotisation cotisationDetails) {
        Cotisation cotisation = cotisationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Cotisation non trouvée"));

        cotisation.setMontant(cotisationDetails.getMontant());
        cotisation.setDatePaiement(cotisationDetails.getDatePaiement());
        cotisation.setSaison(cotisationDetails.getSaison());
        cotisation.setModePaiement(cotisationDetails.getModePaiement());
        cotisation.setStatut(cotisationDetails.getStatut());
        cotisation.setReference(cotisationDetails.getReference());
        cotisation.setNotes(cotisationDetails.getNotes());

        return cotisationRepository.save(cotisation);
    }

    public List<Cotisation> getAllCotisations() {
        return cotisationRepository.findAll();
    }

    public Cotisation getCotisationById(Long id) {
        return cotisationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Cotisation non trouvée"));
    }

    public List<Cotisation> getCotisationsByUser(Long userId) {
        return cotisationRepository.findByUserId(userId);
    }

    public List<Cotisation> getCotisationsBySaison(String saison) {
        return cotisationRepository.findBySaison(saison);
    }

    public List<Cotisation> getCotisationsByStatut(Cotisation.Statut statut) {
        return cotisationRepository.findByStatut(statut);
    }

    public List<Cotisation> filterCotisations(Long userId, String saison, Cotisation.Statut statut) {
        List<Cotisation> cotisations = cotisationRepository.findAll();

        if (userId != null) {
            cotisations = cotisations.stream()
                    .filter(c -> c.getUser().getId().equals(userId))
                    .collect(Collectors.toList());
        }

        if (saison != null && !saison.isEmpty()) {
            cotisations = cotisations.stream()
                    .filter(c -> c.getSaison().equals(saison))
                    .collect(Collectors.toList());
        }

        if (statut != null) {
            cotisations = cotisations.stream()
                    .filter(c -> c.getStatut().equals(statut))
                    .collect(Collectors.toList());
        }

        return cotisations;
    }

    public Cotisation validerCotisation(Long id) {
        Cotisation cotisation = getCotisationById(id);
        cotisation.setStatut(Cotisation.Statut.VALIDEE);
        return cotisationRepository.save(cotisation);
    }

    public Cotisation rejeterCotisation(Long id, String motif) {
        Cotisation cotisation = getCotisationById(id);
        cotisation.setStatut(Cotisation.Statut.REJETEE);
        cotisation.setNotes(motif);
        return cotisationRepository.save(cotisation);
    }

    public Map<String, Object> getStatistiques() {
        List<Cotisation> all = cotisationRepository.findAll();

        Map<String, Object> stats = new HashMap<>();
        stats.put("total", all.size());
        stats.put("enAttente", all.stream().filter(c -> c.getStatut() == Cotisation.Statut.EN_ATTENTE).count());
        stats.put("validees", all.stream().filter(c -> c.getStatut() == Cotisation.Statut.VALIDEE).count());
        stats.put("rejetees", all.stream().filter(c -> c.getStatut() == Cotisation.Statut.REJETEE).count());
        stats.put("montantTotal", all.stream()
                .filter(c -> c.getStatut() == Cotisation.Statut.VALIDEE)
                .mapToDouble(Cotisation::getMontant)
                .sum());

        return stats;
    }

    public void deleteCotisation(Long id) {
        cotisationRepository.deleteById(id);
    }
}