package com.sevalink.sevalinkbackend.security;

import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;
import java.util.Collections;
@Service
public class CustomUserDetailsService implements UserDetailsService {
    @Autowired
    private UserRepository userRepository;


//     * This method is called by Spring Security whenever it needs to load a user
//     * It converts our User entity into Spring Security's UserDetails object
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        // Step 1: Find user in database by email
        User user = userRepository.findByEmail(email).orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));
        // Step 2: Convert our User to Spring Security's UserDetails
        // Spring Security needs: username, password, authorities (roles)
        return new org.springframework.security.core.userdetails.User(
                user.getEmail(),                // username (Spring Security uses this)
                user.getPasswordHash(),         // password (already hashed)
                Collections.singletonList(      // authorities = what user can do
                        new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
                )
        );
    }

//        * Helper method to load user by phone number (for login flexibility)
//        * This is our custom method, not required by Spring Security
        public UserDetails loadUserByPhoneOrEmail(String identifier) {
            User user = userRepository.findByEmailOrPhoneNumber(identifier).orElseThrow(()->new UsernameNotFoundException("User not found with : " + identifier));

        return new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPasswordHash(),
                Collections.singletonList(
                        new SimpleGrantedAuthority("ROLE_"+user.getRole().name())
                )
        );
    }
}
