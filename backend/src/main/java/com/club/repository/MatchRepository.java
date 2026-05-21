package com.club.repository;

import com.club.model.Match;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MatchRepository extends JpaRepository<Match, Long> {
    List<Match> findByEquipeId(Long equipeId);
    List<Match> findByStatut(Match.Statut statut);
    List<Match> findByType(Match.TypeMatch type);
}