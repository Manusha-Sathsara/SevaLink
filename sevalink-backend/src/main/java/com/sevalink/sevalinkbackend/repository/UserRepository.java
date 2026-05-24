package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Standard JPA method (Spring Data JPA generates SQL automatically)
    Optional<User> findByEmail(String email);

    // Standard JPA method
    Optional<User> findByPhoneNumber(String phoneNumber);

    // CUSTOM QUERY - Allows login with EITHER email OR phone
    // The @Query tells JPA exactly what SQL to run
    @Query("SELECT u FROM User u WHERE u.email = :identifier OR u.phoneNumber = :identifier")
    Optional<User> findByEmailOrPhoneNumber(@Param("identifier") String identifier);

    // Check if email exists (for registration validation)
    boolean existsByEmail(String email);

    // Check if phone exists (for registration validation)
    boolean existsByPhoneNumber(String phoneNumber);

    // Find by password reset token (for "forgot password" feature)
    Optional<User> findByResetPasswordToken(String token);

    // Count users by role (for admin dashboard analytics)
    long countByRole(UserRole role);
}
