package com.sevalink.sevalinkbackend;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

/**
 * A zero-dependency loader to read a .env file and set properties as JVM System Properties.
 * This enables Spring Boot's application.properties to resolve these values at startup.
 */
public class EnvLoader {

    public static void load() {
        File envFile = findEnvFile();
        if (envFile == null || !envFile.exists()) {
            System.out.println("[EnvLoader] No .env file found. Proceeding with system environment variables and default properties.");
            return;
        }

        System.out.println("[EnvLoader] Loading environment variables from: " + envFile.getAbsolutePath());
        try (BufferedReader reader = new BufferedReader(new FileReader(envFile))) {
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                // Skip empty lines and comments
                if (line.isEmpty() || line.startsWith("#")) {
                    continue;
                }
                int eqIdx = line.indexOf('=');
                if (eqIdx > 0) {
                    String key = line.substring(0, eqIdx).trim();
                    String value = line.substring(eqIdx + 1).trim();
                    
                    // Remove surrounding double or single quotes if present
                    if ((value.startsWith("\"") && value.endsWith("\"")) ||
                        (value.startsWith("'") && value.endsWith("'"))) {
                        value = value.substring(1, value.length() - 1);
                    }
                    
                    // Set JVM System Property if not already set (e.g. via -D command-line arguments)
                    if (System.getProperty(key) == null) {
                        System.setProperty(key, value);
                    }
                }
            }
        } catch (IOException e) {
            System.err.println("[EnvLoader] Error reading .env file: " + e.getMessage());
        }
    }

    private static File findEnvFile() {
        // 1. Check current working directory
        File file = new File(".env");
        if (file.exists()) {
            return file;
        }
        // 2. Check sevalink-backend folder (if running from parent workspace folder)
        file = new File("sevalink-backend/.env");
        if (file.exists()) {
            return file;
        }
        // 3. Check parent directory (useful in nested or test runs)
        file = new File("../.env");
        if (file.exists()) {
            return file;
        }
        return null;
    }
}
