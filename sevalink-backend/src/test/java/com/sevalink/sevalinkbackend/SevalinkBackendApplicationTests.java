package com.sevalink.sevalinkbackend;

import com.sevalink.sevalinkbackend.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class SevalinkBackendApplicationTests {

    @Autowired
    private UserRepository userRepository;

    @Test
    void contextLoads() {
        userRepository.findAll().forEach(user -> {
            System.out.println("USER_DEBUG: ID=" + user.getId() + ", Name=" + user.getFullName() + ", Email=" + user.getEmail() + ", ProfileImage=" + user.getProfileImageUrl() + ", Location=" + user.getLocation());
        });
    }

}
