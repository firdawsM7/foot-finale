package com.club.repository;

import com.club.model.InjurySuspension;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InjurySuspensionRepository extends JpaRepository<InjurySuspension, Long> {
    List<InjurySuspension> findByPlayerIdAndStatus(Long playerId, InjurySuspension.Status status);

    List<InjurySuspension> findByStatus(InjurySuspension.Status status);
}
