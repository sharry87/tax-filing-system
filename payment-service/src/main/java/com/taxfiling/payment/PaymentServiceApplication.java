package com.taxfiling.payment;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * Payment Service Application
 *
 * Handles payment processing for tax liabilities.
 * Features:
 * - Payment initiation (Stripe integration)
 * - Idempotent Kafka consumers (prevents duplicate charges)
 * - Transaction ledger for accounting
 * - Circuit breaker for external gateway calls
 * - Payment status tracking
 * - Refund processing
 * - Publishes PaymentProcessedEvent to Kafka
 * - Consumes TaxReturnFiledEvent from Kafka
 *
 * @author Tax Filing Team
 * @version 1.0
 */
@SpringBootApplication
@EnableJpaAuditing
public class PaymentServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(PaymentServiceApplication.class, args);
    }
}
