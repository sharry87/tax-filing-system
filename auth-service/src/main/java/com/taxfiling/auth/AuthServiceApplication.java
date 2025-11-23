package com.taxfiling.auth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * Auth Service Application
 *
 * Handles user authentication and authorization.
 * Features:
 * - User registration and login
 * - JWT token generation (Access + Refresh)
 * - Token refresh mechanism
 * - Role-based access control (RBAC)
 * - Password hashing with BCrypt
 * - Account lockout after failed attempts
 * - Publishes UserRegisteredEvent to Kafka
 *
 * @author Tax Filing Team
 * @version 1.0
 */
@SpringBootApplication
@EnableJpaAuditing
public class AuthServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}
