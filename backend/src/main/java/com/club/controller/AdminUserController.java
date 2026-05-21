package com.club.controller;

import com.club.dto.CreateUserRequest;
import com.club.dto.UserWithDocumentsResponse;
import com.club.model.RegistrationStatus;
import com.club.model.User;
import com.club.service.AdminUserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin/users")
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {
    
    private final AdminUserService adminUserService;
    
    public AdminUserController(AdminUserService adminUserService) {
        this.adminUserService = adminUserService;
    }
    
    /**
     * Create a new user (Player, Coach, or Member)
     */
    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody CreateUserRequest request) {
        User user = adminUserService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(user);
    }
    
    /**
     * Get all users
     */
    @GetMapping
    public ResponseEntity<List<User>> getAllUsers(
            @RequestParam(required = false) User.Role role) {
        
        List<User> users;
        if (role != null) {
            users = adminUserService.getUsersByRole(role);
        } else {
            users = adminUserService.getAllUsers();
        }
        
        return ResponseEntity.ok(users);
    }
    
    /**
     * Dossier utilisateur : infos + checklist documents + progression (evite conflit avec GET /admin/users/{id} simple).
     */
    @GetMapping("/{id}/dossier")
    public ResponseEntity<UserWithDocumentsResponse> getUserWithDocuments(@PathVariable Long id) {
        UserWithDocumentsResponse response = adminUserService.getUserWithDocuments(id);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Update user document status
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<User> updateUserStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> request) {
        
        RegistrationStatus status = RegistrationStatus.valueOf(request.get("status"));
        User user = adminUserService.updateUserStatus(id, status);
        return ResponseEntity.ok(user);
    }
}
