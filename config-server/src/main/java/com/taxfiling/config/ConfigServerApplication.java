package com.taxfiling.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;

/**
 * Spring Cloud Config Server
 *
 * Provides centralized configuration management for all microservices.
 * Configuration is stored in Git repository (or native filesystem for local dev).
 *
 * @author Tax Filing Team
 * @version 1.0
 */
@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(ConfigServerApplication.class, args);
    }
}
