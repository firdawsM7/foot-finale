package com.club.service;

import com.club.model.Equipe;
import com.club.repository.EquipeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class EquipeService {
    
    @Autowired
    private EquipeRepository equipeRepository;
    
    public Equipe createEquipe(Equipe equipe) {
        return equipeRepository.save(equipe);
    }
    
    public Equipe updateEquipe(Long id, Equipe equipeDetails) {
        Equipe equipe = equipeRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Équipe non trouvée"));
        
        equipe.setNom(equipeDetails.getNom());
        equipe.setCategorie(equipeDetails.getCategorie());
        equipe.setEncadrant(equipeDetails.getEncadrant());
        equipe.setDescription(equipeDetails.getDescription());
        
        return equipeRepository.save(equipe);
    }
    
    public List<Equipe> getAllEquipes() {
        return equipeRepository.findAll();
    }
    
    public Equipe getEquipeById(Long id) {
        return equipeRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Équipe non trouvée"));
    }
    
    public List<Equipe> getEquipesByEncadrant(Long encadrantId) {
        return equipeRepository.findByEncadrantId(encadrantId);
    }
    
    public void deleteEquipe(Long id) {
        equipeRepository.deleteById(id);
    }
}