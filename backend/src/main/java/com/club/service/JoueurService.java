package com.club.service;

import com.club.model.Joueur;
import com.club.repository.JoueurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class JoueurService {
    
    @Autowired
    private JoueurRepository joueurRepository;
    
    public Joueur createJoueur(Joueur joueur) {
        return joueurRepository.save(joueur);
    }
    
    public Joueur updateJoueur(Long id, Joueur joueurDetails) {
        Joueur joueur = joueurRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Joueur non trouvé"));
        
        joueur.setNom(joueurDetails.getNom());
        joueur.setPrenom(joueurDetails.getPrenom());
        joueur.setDateNaissance(joueurDetails.getDateNaissance());
        joueur.setNationalite(joueurDetails.getNationalite());
        joueur.setPoste(joueurDetails.getPoste());
        joueur.setNumeroMaillot(joueurDetails.getNumeroMaillot());
        joueur.setPoids(joueurDetails.getPoids());
        joueur.setTaille(joueurDetails.getTaille());
        joueur.setPhoto(joueurDetails.getPhoto());
        joueur.setEquipe(joueurDetails.getEquipe());
        joueur.setNotes(joueurDetails.getNotes());
        
        return joueurRepository.save(joueur);
    }
    
    public List<Joueur> getAllJoueurs() {
        return joueurRepository.findAll();
    }
    
    public Joueur getJoueurById(Long id) {
        return joueurRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Joueur non trouvé"));
    }
    
    public List<Joueur> getJoueursByEquipe(Long equipeId) {
        return joueurRepository.findByEquipeId(equipeId);
    }
    
    public void deleteJoueur(Long id) {
        joueurRepository.deleteById(id);
    }
}