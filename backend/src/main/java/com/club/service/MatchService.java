package com.club.service;

import com.club.model.Match;
import com.club.repository.MatchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MatchService {
    
    @Autowired
    private MatchRepository matchRepository;
    
    public Match createMatch(Match match) {
        return matchRepository.save(match);
    }
    
    public Match updateMatch(Long id, Match matchDetails) {
        Match match = matchRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Match non trouvé"));
        
        match.setEquipe(matchDetails.getEquipe());
        match.setAdversaire(matchDetails.getAdversaire());
        match.setDateHeure(matchDetails.getDateHeure());
        match.setLieu(matchDetails.getLieu());
        match.setType(matchDetails.getType());
        match.setScoreEquipe(matchDetails.getScoreEquipe());
        match.setScoreAdversaire(matchDetails.getScoreAdversaire());
        match.setStatut(matchDetails.getStatut());
        match.setNotes(matchDetails.getNotes());
        match.setComposition(matchDetails.getComposition());
        
        return matchRepository.save(match);
    }
    
    public List<Match> getAllMatchs() {
        return matchRepository.findAll();
    }
    
    public Match getMatchById(Long id) {
        return matchRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Match non trouvé"));
    }
    
    public List<Match> getMatchsByEquipe(Long equipeId) {
        return matchRepository.findByEquipeId(equipeId);
    }
    
    public void deleteMatch(Long id) {
        matchRepository.deleteById(id);
    }
}