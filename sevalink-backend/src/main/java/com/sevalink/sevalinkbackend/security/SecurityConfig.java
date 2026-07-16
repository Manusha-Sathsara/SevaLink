package com.sevalink.sevalinkbackend.security;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                // Disable CSRF (we're using JWT, not sessions)
                .csrf(csrf -> csrf.disable())

                // IMPORTANT: Enable CORS and use OUR CorsConfig
                // This tells Spring Security to respect the CORS configuration
                .cors(cors -> {})  // ← This line is CRITICAL

                // Use stateless session (JWT handles everything)
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                // URL Authorization Rules
                .authorizeHttpRequests(auth -> auth
                        // CRITICAL: Allow OPTIONS pre-flight requests for ALL endpoints
                        // Without this, CORS pre-flight will fail with 403
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        // Public endpoints (no authentication needed)
                        .requestMatchers(
                                    "/api/auth/**"
//                                "/api/auth/register",
//                                "/api/auth/login",
//                                "/api/auth/forgot-password",
//                                "/api/auth/reset-password",
//                                "/api/auth/refresh",
//                                "/api/auth/me"
                                ).permitAll()
                        .requestMatchers("/api/public/**").permitAll()

                        // Role-based protected endpoints
                        .requestMatchers("/api/client/**").hasRole("CLIENT")
                        .requestMatchers("/api/worker/**").hasRole("WORKER")
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/chat/**").authenticated()

                        // All other requests need authentication
                        .anyRequest().authenticated()
                )

                // Add JWT filter before Spring Security's default filter
                .addFilterBefore(jwtAuthenticationFilter,
                        UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}