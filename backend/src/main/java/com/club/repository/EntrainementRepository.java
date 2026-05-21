package com.club.repository;

import com.club.model.Entrainement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EntrainementRepository extends JpaRepository<Entrainement, Long> {
    List<Entrainement> findByEquipeId(Long equipeId);
    List<Entrainement> findByEncadrantId(Long encadrantId);
    List<Entrainement> findByStatut(Entrainement.Statut statut);
}