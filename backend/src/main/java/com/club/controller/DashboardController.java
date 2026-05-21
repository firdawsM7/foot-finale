package com.club.controller;

import com.club.dto.DashboardStatsDTO;
import com.club.dto.EvolutionDTO;
import com.club.dto.RevenuMensuelDTO;
import com.club.dto.TauxPresenceDTO;
import com.club.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/admin/dashboard")
@PreAuthorize("hasRole('ADMIN')")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/stats")
    public ResponseEntity<DashboardStatsDTO> getStats() {
        return ResponseEntity.ok(dashboardService.getStats());
    }

    @GetMapping("/evolution")
    public ResponseEntity<List<EvolutionDTO>> getEvolution(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(dashboardService.getEvolution(startDate, endDate));
    }

    @GetMapping("/revenus-mensuel")
    public ResponseEntity<List<RevenuMensuelDTO>> getRevenusMensuels(@RequestParam int year) {
        return ResponseEntity.ok(dashboardService.getRevenusMensuels(year));
    }

    @GetMapping("/taux-presence")
    public ResponseEntity<List<TauxPresenceDTO>> getTauxPresence() {
        return ResponseEntity.ok(dashboardService.getTauxPresence());
    }
}
