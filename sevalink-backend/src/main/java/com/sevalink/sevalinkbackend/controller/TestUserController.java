package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.TestUser;
import com.sevalink.sevalinkbackend.repository.TestUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;


import java.util.List;
@RestController
@RequestMapping("api/test-users")

public class TestUserController {
    @Autowired
    private TestUserRepository testUserRepository;

    @GetMapping
    public List<TestUser>getAllTestUsers() {
        return testUserRepository.findAll();
    };

    @PostMapping
    public TestUser createTestUser(@RequestBody TestUser testUser) {
        return testUserRepository.save(testUser);
    }

    // Update user ---
    @PutMapping("/{id}")
    public TestUser updateTestUser(@PathVariable Long id, @RequestBody TestUser testUserDetails) {
        TestUser user = testUserRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        user.setName(testUserDetails.getName());
        user.setEmail(testUserDetails.getEmail());
        return testUserRepository.save(user);
    }

    @DeleteMapping("/{id}")
    public void deleteTestUser(@PathVariable Long id){
        testUserRepository.deleteById(id);
    }
}
