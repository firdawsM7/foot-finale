package com.club.repository;

import com.club.model.Equipe;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EquipeRepository extends JpaRepository<Equipe, Long> {
    Optional<Equipe> findByNom(String nom);
    List<Equipe> findByActive(Boolean active);
    List<Equipe> findByEncadrantId(Long encadrantId);
    List<Equipe> findByCategorie(String categorie);
}