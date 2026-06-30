package com.sevalink.sevalinkbackend.controller;

import com.sevalink.sevalinkbackend.model.User;
import com.sevalink.sevalinkbackend.service.UserService;
import com.sevalink.sevalinkbackend.dto.ApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserService userService;

    // GET http://localhost:8080/api/users
    @GetMapping
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    // GET http://localhost:8080/api/users/1
    @GetMapping("/{id}")
    public ResponseEntity<?> getUserById(@PathVariable Long id) {
        return userService.getUserById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // PUT http://localhost:8080/api/users/1
    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody User payload) {
        try {
            User updated = userService.updateUser(id, payload);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // DELETE (soft block) http://localhost:8080/api/users/1
    @DeleteMapping("/{id}")
    public ResponseEntity<?> blockUser(@PathVariable Long id) {
        try {
            userService.blockUser(id);
            return ResponseEntity.ok(ApiResponse.success("User blocked", null));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // POST http://localhost:8080/api/users/register
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        try {
            User saved = userService.registerUser(user);
            return ResponseEntity.ok(saved);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // POST http://localhost:8080/api/users/login
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User loginRequest) {
        return userService.findByEmail(loginRequest.getEmail())
                .filter(u -> u.getPasswordHash().equals(loginRequest.getPasswordHash()))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.status(401).build());
    }
}