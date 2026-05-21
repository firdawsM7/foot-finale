package com.club.repository;

import com.club.model.Cotisation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CotisationRepository extends JpaRepository<Cotisation, Long> {
    List<Cotisation> findByUserId(Long userId);
    List<Cotisation> findBySaison(String saison);
    List<Cotisation> findByStatut(Cotisation.Statut statut);
}