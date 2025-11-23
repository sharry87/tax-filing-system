package com.taxfiling.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * API Gateway Application
 *
 * Single entry point for all client requests.
 * Provides:
 * - Request routing to downstream services
 * - JWT token validation
 * - Rate limiting (Redis-backed)
 * - CORS handling
 * - Request/response logging
 *
 * @author Tax Filing Team
 * @version 1.0
 */
@SpringBootApplication
public class ApiGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }
}
