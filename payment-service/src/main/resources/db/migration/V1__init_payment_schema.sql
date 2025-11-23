-- =============================================
-- Payment Service Database Schema
-- Version: 1.0
-- Description: Payment processing and transaction management
-- =============================================

-- Payments table
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filing_id UUID NOT NULL,
    user_id UUID NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    payment_method VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    idempotency_key UUID NOT NULL UNIQUE,
    gateway_provider VARCHAR(50),
    gateway_transaction_id VARCHAR(255),
    gateway_response_code VARCHAR(50),
    authorization_code VARCHAR(100),
    last_four_digits VARCHAR(4),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    failed_at TIMESTAMP,
    failure_reason TEXT,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT valid_payment_method CHECK (payment_method IN ('CREDIT_CARD', 'DEBIT_CARD', 'ACH', 'WIRE_TRANSFER')),
    CONSTRAINT valid_status CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'REFUNDED', 'CANCELLED')),
    CONSTRAINT valid_currency CHECK (currency IN ('USD', 'EUR', 'GBP'))
);

-- Payment transactions (Ledger for accounting)
CREATE TABLE payment_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES payments(payment_id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(50) NOT NULL,
    gateway_transaction_id VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_transaction_type CHECK (transaction_type IN ('CHARGE', 'REFUND', 'CHARGEBACK', 'ADJUSTMENT'))
);

-- Processed events table (Idempotency tracking for Kafka consumers)
CREATE TABLE processed_events (
    event_id UUID PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    topic_name VARCHAR(255) NOT NULL,
    partition_key VARCHAR(255),
    processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Payment audit log
CREATE TABLE payment_audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    payment_id UUID REFERENCES payments(payment_id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_by UUID,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Indexes for Performance
-- =============================================

CREATE INDEX idx_payments_filing_id ON payments(filing_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created_at ON payments(created_at);
CREATE INDEX idx_payments_idempotency_key ON payments(idempotency_key);
CREATE INDEX idx_payments_gateway_transaction_id ON payments(gateway_transaction_id);

CREATE INDEX idx_payment_transactions_payment_id ON payment_transactions(payment_id);
CREATE INDEX idx_payment_transactions_created_at ON payment_transactions(created_at);
CREATE INDEX idx_payment_transactions_transaction_type ON payment_transactions(transaction_type);

CREATE INDEX idx_processed_events_processed_at ON processed_events(processed_at);
CREATE INDEX idx_processed_events_event_type ON processed_events(event_type);
CREATE INDEX idx_processed_events_topic_name ON processed_events(topic_name);

CREATE INDEX idx_payment_audit_log_payment_id ON payment_audit_log(payment_id);
CREATE INDEX idx_payment_audit_log_created_at ON payment_audit_log(created_at);

-- =============================================
-- Triggers
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for payments table
CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- Functions for Data Cleanup
-- =============================================

-- Function to cleanup old processed events (retain 24 hours for idempotency)
CREATE OR REPLACE FUNCTION cleanup_old_processed_events()
RETURNS void AS $$
BEGIN
    DELETE FROM processed_events
    WHERE processed_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Note: In production, schedule this function with pg_cron or external scheduler
-- Example: SELECT cron.schedule('cleanup-processed-events', '0 * * * *', 'SELECT cleanup_old_processed_events()');

-- =============================================
-- Views for Reporting
-- =============================================

-- Daily payment summary view
CREATE VIEW daily_payment_summary AS
SELECT
    DATE(created_at) AS payment_date,
    status,
    payment_method,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS average_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM payments
GROUP BY DATE(created_at), status, payment_method
ORDER BY payment_date DESC;

-- =============================================
-- Comments for Documentation
-- =============================================

COMMENT ON TABLE payments IS 'Payment records with gateway integration details';
COMMENT ON TABLE payment_transactions IS 'Transaction ledger for double-entry accounting';
COMMENT ON TABLE processed_events IS 'Kafka event deduplication tracking (24-hour retention)';
COMMENT ON TABLE payment_audit_log IS 'Audit trail for all payment-related events';

COMMENT ON COLUMN payments.idempotency_key IS 'Client-provided UUID to prevent duplicate charges';
COMMENT ON COLUMN payments.version IS 'Optimistic locking version for concurrent updates';
COMMENT ON COLUMN payments.last_four_digits IS 'Last 4 digits of card (for user reference)';
COMMENT ON COLUMN processed_events.event_id IS 'Kafka event ID from TaxReturnFiledEvent';

COMMENT ON VIEW daily_payment_summary IS 'Aggregated daily payment metrics for reporting';

-- =============================================
-- Sample Data for Development
-- =============================================

-- Note: Uncomment below for development/testing only
-- INSERT INTO payments (filing_id, user_id, amount, currency, payment_method, status, idempotency_key, gateway_provider)
-- VALUES
--     ('550e8400-e29b-41d4-a716-446655440000', '880e8400-e29b-41d4-a716-446655440000', 2500.00, 'USD', 'CREDIT_CARD', 'COMPLETED', gen_random_uuid(), 'STRIPE');
