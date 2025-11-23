package com.taxfiling.filing;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * Filing Service Application
 *
 * Core tax return processing service.
 * Features:
 * - Tax return creation and validation
 * - State machine (DRAFT → SUBMITTED → PROCESSING → COMPLETED)
 * - Tax calculation logic (AGI, deductions, credits)
 * - CQRS implementation (Command/Query separation)
 * - Saga orchestrator for filing + payment workflow
 * - IRS submission integration
 * - Kafka event publishing (TaxReturnFiledEvent)
 * - Kafka event consuming (PaymentProcessedEvent)
 *
 * @author Tax Filing Team
 * @version 1.0
 */
@SpringBootApplication
@EnableJpaAuditing
@EnableCaching
public class FilingServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(FilingServiceApplication.class, args);
    }
}
