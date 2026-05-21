package com.club.repository;

import com.club.model.RegistrationStatus;
import com.club.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    List<User> findByRole(User.Role role);
    List<User> findByEquipeId(Long equipeId);
    List<User> findByActif(Boolean actif);
    boolean existsByEmail(String email);
    List<User> findByRegistrationStatus(RegistrationStatus registrationStatus);
}