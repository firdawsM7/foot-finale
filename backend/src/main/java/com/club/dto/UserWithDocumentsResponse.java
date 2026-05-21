package com.club.dto;

import com.club.model.RegistrationStatus;
import com.club.model.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserWithDocumentsResponse {
    
    private Long id;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private LocalDate dateOfBirth;
    private User.Role role;
    private User.AccountStatus accountStatus;
    /** PENDING, ACTIVE, REJECTED */
    private RegistrationStatus registrationStatus;
    private Boolean actif;
    private LocalDateTime dateInscription;
    private String address;
    
    private List<DocumentResponse> documents;
    private Integer completionPercentage; // Percentage of required documents uploaded and approved
    private Integer documentsCompleted;
    private Integer documentsRequired;
    private List<DocumentResponse> missingDocuments;
    
    public static UserWithDocumentsResponse fromEntity(User user, List<DocumentResponse> documents, 
                                                        Integer completionPercentage, 
                                                        Integer documentsCompleted,
                                                        Integer documentsRequired,
                                                        List<DocumentResponse> missingDocuments) {
        return UserWithDocumentsResponse.builder()
                .id(user.getId())
                .firstName(user.getPrenom())
                .lastName(user.getNom())
                .email(user.getEmail())
                .phone(user.getTelephone())
                .dateOfBirth(parseDate(user.getDateNaissance()))
                .role(user.getRole())
                .accountStatus(user.getAccountStatus())
                .registrationStatus(user.getRegistrationStatus())
                .actif(user.getActif())
                .dateInscription(user.getDateInscription())
                .address(user.getAdresse())
                .documents(documents)
                .completionPercentage(completionPercentage)
                .documentsCompleted(documentsCompleted)
                .documentsRequired(documentsRequired)
                .missingDocuments(missingDocuments)
                .build();
    }
    
    private static LocalDate parseDate(String dateStr) {
        if (dateStr == null || dateStr.isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(dateStr);
        } catch (Exception e) {
            return null;
        }
    }
}
