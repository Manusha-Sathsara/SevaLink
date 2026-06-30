package com.sevalink.sevalinkbackend.security;

import com.sevalink.sevalinkbackend.model.UserRole;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Date;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

@Component
public class JwtTokenProvider {
    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.access-token-expiry}")
    private long accessTokenExpiry;

    @Value("${jwt.refresh-token-expiry}")
    private long refreshTokenExpiry;

    // Helper to convert String secret into a proper HMAC Key
    private SecretKey getSigningKey() {
        byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    //    * CREATE Access Token (short-lived, contains user info)
//    * Called AFTER successful login/registration
    public String generateAccessToken(String email, UserRole role) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + accessTokenExpiry);
        // JWT structure: Header.Payload.Signature
        return Jwts.builder()
                .subject(email) // Payload: Who is this token for?
                .claim("role", role.name()) // Payload: What role do they have?
                .issuedAt(now)
                .expiration(expiryDate)   // Payload: When does it expire?
                .signWith(getSigningKey())  // Sign with secret
                .compact();  // Convert to string: "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJqb2huQGV4YW1wbGU
    }

    //    * CREATE Refresh Token (long-lived, only contains email)
//    * Used to get NEW access token when old one expires
    public String generateRefreshToken(String email) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + refreshTokenExpiry);

        return Jwts.builder()
                .subject(email)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    //    * EXTRACT email from token
//    * Called by JwtAuthenticationFilter to identify user
    public String getEmailFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())    // Previously setSigningKey
                .build()
                .parseSignedClaims(token)       // Previously parseClaimsJws
                .getPayload();                // Previously getBody
        return claims.getSubject();
    }

    //    * EXTRACT role from token
//    * Called to check if user is CLIENT/WORKER/ADMIN
    public UserRole getRoleFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        String roleString = claims.get("role", String.class);
        return UserRole.valueOf(roleString);
    }

//    * VALIDATE token (check if it's tampered or expired)
//    * Called for EVERY request to protected endpoints

    public boolean validateToken(String token) {
        try {
            // If this doesn't throw exception, token is valid
            Jwts.parser().verifyWith(getSigningKey()).build().parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    //    CHECK if token has expired
    public Boolean isTokenExpired(String token) {
        try {
            Date expiration = Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload()
                    .getExpiration();
            return expiration.before(new Date());
        } catch (ExpiredJwtException e) {
            return true;
        }
    }
}
