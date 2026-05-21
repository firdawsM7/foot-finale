package com.club.service;

import com.club.model.Entrainement;
import com.club.repository.EntrainementRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class EntrainementService {
    
    @Autowired
    private EntrainementRepository entrainementRepository;
    
    public Entrainement createEntrainement(Entrainement entrainement) {
        return entrainementRepository.save(entrainement);
    }
    
    public Entrainement updateEntrainement(Long id, Entrainement entrainementDetails) {
        Entrainement entrainement = entrainementRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Entraînement non trouvé"));
        
        entrainement.setEquipe(entrainementDetails.getEquipe());
        entrainement.setDateHeure(entrainementDetails.getDateHeure());
        entrainement.setLieu(entrainementDetails.getLieu());
        entrainement.setDuree(entrainementDetails.getDuree());
        entrainement.setObjectif(entrainementDetails.getObjectif());
        entrainement.setExercices(entrainementDetails.getExercices());
        entrainement.setEncadrant(entrainementDetails.getEncadrant());
        entrainement.setStatut(entrainementDetails.getStatut());
        entrainement.setNotes(entrainementDetails.getNotes());
        
        return entrainementRepository.save(entrainement);
    }
    
    public List<Entrainement> getAllEntrainements() {
        return entrainementRepository.findAll();
    }
    
    public Entrainement getEntrainementById(Long id) {
        return entrainementRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Entraînement non trouvé"));
    }
    
    public List<Entrainement> getEntrainementsByEquipe(Long equipeId) {
        return entrainementRepository.findByEquipeId(equipeId);
    }
    
    public void deleteEntrainement(Long id) {
        entrainementRepository.deleteById(id);
    }
}