package com.sevalinkbackend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * Global CORS configuration for the API.
 *
 * Allows the Flutter‑Web front‑end (running on http://localhost:* or any origin during development)
 * to call the backend without being blocked by the browser.
 *
 * In production you should replace the wildcard with the actual domain(s) of your front‑end
 * and consider tightening the allowed methods/headers.
 */
@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        // Development – allow any origin. Change to a specific origin for production.
        config.addAllowedOriginPattern("*"); // e.g., "https://myapp.example.com"
        config.addAllowedMethod("*");
        config.addAllowedHeader("*");
        // Allow cookies / Authorization header to be sent from the browser
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}
