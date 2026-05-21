package com.club.repository;

import com.club.model.Joueur;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface JoueurRepository extends JpaRepository<Joueur, Long> {
    List<Joueur> findByEquipeId(Long equipeId);
    List<Joueur> findByActif(Boolean actif);
    Optional<Joueur> findByNumeroMaillot(Integer numero);
}