package com.club.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class WebConfig implements WebMvcConfigurer {

        @Override
        public void addResourceHandlers(@org.springframework.lang.NonNull ResourceHandlerRegistry registry) {
                Path uploadsRoot = Paths.get("uploads");
                String uploadsAbsolute = uploadsRoot.toFile().getAbsolutePath();
                registry.addResourceHandler("/uploads/**")
                                .addResourceLocations("file:/" + uploadsAbsolute + "/");

                Path documentUploadDir = Paths.get("uploads/documents");
                String documentUploadPath = documentUploadDir.toFile().getAbsolutePath();

                registry.addResourceHandler("/uploads/documents/**")
                                .addResourceLocations("file:/" + documentUploadPath + "/");

                // Photos de profil
                Path photoUploadDir = Paths.get("uploads/photos");
                String photoUploadPath = photoUploadDir.toFile().getAbsolutePath();

                registry.addResourceHandler("/uploads/photos/**")
                                .addResourceLocations("file:/" + photoUploadPath + "/");

                // Reçus de cotisation
                Path recuUploadDir = Paths.get("uploads/recus");
                String recuUploadPath = recuUploadDir.toFile().getAbsolutePath();

                registry.addResourceHandler("/uploads/recus/**")
                                .addResourceLocations("file:/" + recuUploadPath + "/");
        }

        // CORS : configuré dans SecurityConfig (une seule source de vérité)
}
