package com.sevalink.sevalinkbackend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name="testusers")
public class TestUser {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;
    private String name;
    private String email;
    @Column(name = "created_date")
    private LocalDateTime createdDate;

    public TestUser() {}

    public TestUser(String name, String email) {
        this.name = name;
        this.email = email;

        this.createdDate = LocalDateTime.now();
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public LocalDateTime getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(LocalDateTime createdDate) {
        this.createdDate = createdDate;
    }
}
