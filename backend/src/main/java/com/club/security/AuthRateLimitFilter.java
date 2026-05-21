package com.club.security;

import com.club.exception.SafeErrorMessages;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Limite les tentatives sur /auth/login et /auth/register (brute force).
 */
@Component
public class AuthRateLimitFilter extends OncePerRequestFilter {

    private final SecurityProperties securityProperties;
    private final ConcurrentHashMap<String, Window> buckets = new ConcurrentHashMap<>();

    public AuthRateLimitFilter(SecurityProperties securityProperties) {
        this.securityProperties = securityProperties;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        if (path == null) {
            return true;
        }
        return !(path.endsWith("/auth/login") || path.endsWith("/auth/register"));
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {

        String key = clientKey(request);
        int max = securityProperties.getAuthRateLimitMax();
        int windowSec = securityProperties.getAuthRateLimitWindowSeconds();
        long now = System.currentTimeMillis();

        Window window = buckets.compute(key, (k, w) -> {
            if (w == null || now - w.startMs > windowSec * 1000L) {
                return new Window(now, new AtomicInteger(0));
            }
            return w;
        });

        int count = window.counter.incrementAndGet();
        if (count > max) {
            response.setStatus(429);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            response.getWriter().write("{\"error\":\"" + SafeErrorMessages.OPERATION_FAILED + "\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private static String clientKey(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr() + ":" + request.getRequestURI();
    }

    private static final class Window {
        final long startMs;
        final AtomicInteger counter;

        Window(long startMs, AtomicInteger counter) {
            this.startMs = startMs;
            this.counter = counter;
        }
    }
}
