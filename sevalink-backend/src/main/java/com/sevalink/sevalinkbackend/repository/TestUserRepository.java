package com.sevalink.sevalinkbackend.repository;

import com.sevalink.sevalinkbackend.model.TestUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TestUserRepository extends JpaRepository<TestUser, Long> {

}
