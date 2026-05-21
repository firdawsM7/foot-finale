package com.club.security;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
@ConfigurationProperties(prefix = "app.security")
public class SecurityProperties {

    /** Origines CORS autorisées (patterns Spring). */
    private List<String> corsAllowedOrigins = new ArrayList<>(List.of(
            "http://localhost:*",
            "http://127.0.0.1:*",
            "http://10.0.2.2:*"
    ));

    private int authRateLimitMax = 30;
    private int authRateLimitWindowSeconds = 60;

    public List<String> getCorsAllowedOrigins() {
        return corsAllowedOrigins;
    }

    public void setCorsAllowedOrigins(List<String> corsAllowedOrigins) {
        this.corsAllowedOrigins = corsAllowedOrigins;
    }

    public int getAuthRateLimitMax() {
        return authRateLimitMax;
    }

    public void setAuthRateLimitMax(int authRateLimitMax) {
        this.authRateLimitMax = authRateLimitMax;
    }

    public int getAuthRateLimitWindowSeconds() {
        return authRateLimitWindowSeconds;
    }

    public void setAuthRateLimitWindowSeconds(int authRateLimitWindowSeconds) {
        this.authRateLimitWindowSeconds = authRateLimitWindowSeconds;
    }
}
