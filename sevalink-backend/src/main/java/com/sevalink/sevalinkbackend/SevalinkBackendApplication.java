package com.sevalink.sevalinkbackend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SevalinkBackendApplication {

    public static void main(String[] args) {
        EnvLoader.load();
        SpringApplication.run(SevalinkBackendApplication.class, args);
    }

}
