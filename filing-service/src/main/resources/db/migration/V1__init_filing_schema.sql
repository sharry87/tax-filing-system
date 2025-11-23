-- =============================================
-- Filing Service Database Schema
-- Version: 1.0
-- Description: Tax return filing and processing
-- =============================================

-- Tax returns table (Write model for CQRS)
CREATE TABLE tax_returns (
    filing_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    tax_year INT NOT NULL CHECK (tax_year BETWEEN 2020 AND 2030),
    filing_status VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    ssn_encrypted VARCHAR(255) NOT NULL,
    date_of_birth DATE NOT NULL,
    address_street VARCHAR(255) NOT NULL,
    address_city VARCHAR(100) NOT NULL,
    address_state VARCHAR(2) NOT NULL,
    address_zip VARCHAR(10) NOT NULL,
    total_income DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    adjusted_gross_income DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    taxable_income DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    total_tax DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    total_withheld DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    refund_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    amount_owed DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    irs_confirmation_number VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMP,
    completed_at TIMESTAMP,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT valid_filing_status CHECK (filing_status IN ('SINGLE', 'MARRIED_FILING_JOINTLY', 'MARRIED_FILING_SEPARATELY', 'HEAD_OF_HOUSEHOLD', 'QUALIFYING_WIDOW')),
    CONSTRAINT valid_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'PROCESSING', 'COMPLETED', 'REJECTED', 'PAYMENT_PENDING', 'PAYMENT_FAILED')),
    CONSTRAINT valid_state_code CHECK (length(address_state) = 2)
);

-- Income details table
CREATE TABLE income_details (
    income_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filing_id UUID NOT NULL REFERENCES tax_returns(filing_id) ON DELETE CASCADE,
    wages DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    interest DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    dividends DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    capital_gains DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    business_income DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    rental_income DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    other_income DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_income CHECK (
        wages >= 0 AND interest >= 0 AND dividends >= 0 AND
        capital_gains >= 0 AND business_income >= 0 AND
        rental_income >= 0 AND other_income >= 0
    )
);

-- Deductions table
CREATE TABLE deductions (
    deduction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filing_id UUID NOT NULL REFERENCES tax_returns(filing_id) ON DELETE CASCADE,
    is_standard_deduction BOOLEAN NOT NULL DEFAULT true,
    standard_deduction_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    mortgage_interest DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    state_local_taxes DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    charitable_contributions DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    medical_expenses DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    total_itemized_deductions DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_deductions CHECK (
        standard_deduction_amount >= 0 AND mortgage_interest >= 0 AND
        state_local_taxes >= 0 AND charitable_contributions >= 0 AND
        medical_expenses >= 0 AND total_itemized_deductions >= 0
    )
);

-- W-2 forms (supporting documents)
CREATE TABLE w2_forms (
    w2_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filing_id UUID NOT NULL REFERENCES tax_returns(filing_id) ON DELETE CASCADE,
    employer_name VARCHAR(255) NOT NULL,
    employer_ein VARCHAR(20) NOT NULL,
    wages DECIMAL(15,2) NOT NULL,
    federal_tax_withheld DECIMAL(15,2) NOT NULL,
    social_security_wages DECIMAL(15,2) NOT NULL,
    medicare_wages DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_ein CHECK (employer_ein ~ '^\d{2}-\d{7}$')
);

-- Filing history (State machine transitions)
CREATE TABLE filing_history (
    history_id BIGSERIAL PRIMARY KEY,
    filing_id UUID NOT NULL REFERENCES tax_returns(filing_id) ON DELETE CASCADE,
    from_status VARCHAR(50),
    to_status VARCHAR(50) NOT NULL,
    transition_reason VARCHAR(255),
    transitioned_by UUID,
    transitioned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

-- Tax returns read model (CQRS - denormalized for queries)
CREATE MATERIALIZED VIEW tax_returns_read_model AS
SELECT
    tr.filing_id,
    tr.user_id,
    tr.tax_year,
    tr.filing_status,
    tr.status,
    tr.first_name,
    tr.last_name,
    tr.total_income,
    tr.refund_amount,
    tr.amount_owed,
    tr.created_at,
    tr.submitted_at,
    tr.completed_at,
    COUNT(w2.w2_id) AS w2_count,
    COALESCE(SUM(w2.wages), 0) AS total_w2_wages
FROM tax_returns tr
LEFT JOIN w2_forms w2 ON tr.filing_id = w2.filing_id
GROUP BY tr.filing_id;

-- =============================================
-- Indexes for Performance
-- =============================================

CREATE INDEX idx_tax_returns_user_id ON tax_returns(user_id);
CREATE INDEX idx_tax_returns_tax_year ON tax_returns(tax_year);
CREATE INDEX idx_tax_returns_status ON tax_returns(status);
CREATE INDEX idx_tax_returns_submitted_at ON tax_returns(submitted_at);
CREATE INDEX idx_tax_returns_created_at ON tax_returns(created_at);

CREATE INDEX idx_income_details_filing_id ON income_details(filing_id);
CREATE INDEX idx_deductions_filing_id ON deductions(filing_id);
CREATE INDEX idx_w2_forms_filing_id ON w2_forms(filing_id);

CREATE INDEX idx_filing_history_filing_id ON filing_history(filing_id);
CREATE INDEX idx_filing_history_transitioned_at ON filing_history(transitioned_at);
CREATE INDEX idx_filing_history_to_status ON filing_history(to_status);

-- Unique constraint: One active filing per user per year
CREATE UNIQUE INDEX idx_tax_returns_user_year ON tax_returns(user_id, tax_year)
    WHERE status != 'REJECTED';

-- Materialized view index
CREATE UNIQUE INDEX idx_tax_returns_read_model_filing_id
    ON tax_returns_read_model(filing_id);

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

-- Trigger for tax_returns table
CREATE TRIGGER update_tax_returns_updated_at
    BEFORE UPDATE ON tax_returns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to log filing status changes
CREATE OR REPLACE FUNCTION log_filing_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO filing_history (filing_id, from_status, to_status, transition_reason)
        VALUES (NEW.filing_id, OLD.status, NEW.status, 'System state change');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-log status changes
CREATE TRIGGER trigger_log_filing_status_change
    AFTER UPDATE ON tax_returns
    FOR EACH ROW
    EXECUTE FUNCTION log_filing_status_change();

-- =============================================
-- Comments for Documentation
-- =============================================

COMMENT ON TABLE tax_returns IS 'Main tax return filing records (Write model)';
COMMENT ON TABLE income_details IS 'Detailed income breakdown for each filing';
COMMENT ON TABLE deductions IS 'Tax deductions (standard or itemized)';
COMMENT ON TABLE w2_forms IS 'W-2 wage and tax statement forms';
COMMENT ON TABLE filing_history IS 'Audit trail for filing status transitions';
COMMENT ON MATERIALIZED VIEW tax_returns_read_model IS 'Denormalized view for fast queries (CQRS Read model)';

COMMENT ON COLUMN tax_returns.ssn_encrypted IS 'AES-256 encrypted SSN';
COMMENT ON COLUMN tax_returns.version IS 'Optimistic locking version for concurrent updates';
COMMENT ON COLUMN tax_returns.status IS 'State machine: DRAFT → SUBMITTED → PROCESSING → COMPLETED';
