package com.sevalink.sevalinkbackend.security;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    @Autowired
    private JwtTokenProvider jwtTokenProvider;
    @Autowired
    private CustomUserDetailsService userDetailsService;

    //    * This method runs for EVERY HTTP request to your API
//    * It checks: "Does this request have a valid JWT token?"
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        // Step 1: Extract JWT token from Authorization header
        String token = extractToken(request);
        // Step 2: If token exists AND is valid
        if (token != null && jwtTokenProvider.validateToken(token)) {
            // Step 3: Get user email from token
            String email = jwtTokenProvider.getEmailFromToken(token);
            // Step 4: Load user details from database
            UserDetails userDetails = userDetailsService.loadUserByUsername(email);

            // Step 5: Create authentication object
            // This tells Spring Security: "This user is authenticated!"
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            userDetails,           // The user
                            null,                  // Credentials (already authenticated)
                            userDetails.getAuthorities()  // Roles (CLIENT/WORKER/ADMIN)
                    );
            // Step 6: Add IP address, session info to authentication
            authentication.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request)
            );

            // Step 7: Set authentication in Security Context
            // This is CRITICAL - without this, Spring Security thinks user is not logged in
            SecurityContextHolder.getContext().setAuthentication(authentication);
        }
        // Step 8: Continue to the controller
        // If authentication was set, controller will see @PreAuthorize or hasRole()
        filterChain.doFilter(request, response);
    }

    private String extractToken(HttpServletRequest request){
        String BearerToken = request.getHeader("Authorization");
        if (BearerToken != null &&  BearerToken.startsWith("Bearer ")) {
            return BearerToken.substring(7);
        }
        return null;
    }

}

