-- ============================================================
-- CREDIT CARD ANNUAL FEE PRICING VALUATION MODEL
-- COMPLETE INTEGRATED SQL SCRIPT
-- ============================================================
-- This is a comprehensive SQL implementation of a credit card
-- annual fee pricing valuation model with NPV, IRR, terminal value,
-- and advanced financial metrics.
-- ============================================================

-- ============================================================
-- PART 1: DATABASE SCHEMA - ALL TABLES
-- ============================================================

-- 1. BASE TABLE: CREDIT CARD PRODUCTS
CREATE TABLE IF NOT EXISTS credit_cards (
    card_id INT PRIMARY KEY AUTO_INCREMENT,
    card_name VARCHAR(100) NOT NULL UNIQUE,
    card_tier VARCHAR(20) NOT NULL,
    launch_date DATE NOT NULL,
    target_segment VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_card_tier (card_tier),
    INDEX idx_target_segment (target_segment)
);

-- 2. CUSTOMER BASE & DEMOGRAPHICS
CREATE TABLE IF NOT EXISTS card_holders (
    cardholder_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    acquisition_date DATE NOT NULL,
    annual_income INT NOT NULL,
    credit_score INT NOT NULL,
    customer_segment VARCHAR(50) NOT NULL,
    lifetime_value DECIMAL(12, 2) NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
    INDEX idx_card_id (card_id),
    INDEX idx_customer_segment (customer_segment),
    INDEX idx_acquisition_date (acquisition_date),
    INDEX idx_is_active (is_active)
);

-- 3. HISTORICAL ANNUAL FEE DATA
CREATE TABLE IF NOT EXISTS annual_fee_history (
    fee_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    fee_amount DECIMAL(10, 2) NOT NULL,
    effective_date DATE NOT NULL,
    waiver_rate DECIMAL(5, 4) NOT NULL DEFAULT 0,
    churn_rate DECIMAL(5, 4) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
    INDEX idx_card_id (card_id),
    INDEX idx_effective_date (effective_date),
    UNIQUE KEY unique_card_date (card_id, effective_date)
);

-- 4. CUSTOMER SPENDING & ENGAGEMENT
CREATE TABLE IF NOT EXISTS customer_metrics (
    metric_id INT PRIMARY KEY AUTO_INCREMENT,
    cardholder_id INT NOT NULL,
    year INT NOT NULL,
    total_spend DECIMAL(12, 2) NOT NULL DEFAULT 0,
    transaction_count INT NOT NULL DEFAULT 0,
    rewards_earned DECIMAL(10, 2) NOT NULL DEFAULT 0,
    rewards_redeemed DECIMAL(10, 2) NOT NULL DEFAULT 0,
    customer_satisfaction_score DECIMAL(3, 1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cardholder_id) REFERENCES card_holders(cardholder_id),
    INDEX idx_cardholder_id (cardholder_id),
    INDEX idx_year (year),
    UNIQUE KEY unique_cardholder_year (cardholder_id, year)
);

-- 5. FEE ELASTICITY DATA
CREATE TABLE IF NOT EXISTS fee_elasticity_scenarios (
    scenario_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    proposed_fee DECIMAL(10, 2) NOT NULL,
    expected_retention_rate DECIMAL(5, 4) NOT NULL,
    expected_churn_rate DECIMAL(5, 4) NOT NULL,
    expected_new_acquisition_impact DECIMAL(5, 4) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
    INDEX idx_card_id (card_id),
    UNIQUE KEY unique_card_fee (card_id, proposed_fee)
);

-- 6. VALUATION ASSUMPTIONS
CREATE TABLE IF NOT EXISTS valuation_assumptions (
    assumption_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    discount_rate DECIMAL(5, 4) NOT NULL,
    risk_free_rate DECIMAL(5, 4) NOT NULL,
    equity_risk_premium DECIMAL(5, 4) NOT NULL,
    debt_cost DECIMAL(5, 4) NOT NULL,
    tax_rate DECIMAL(5, 4) NOT NULL,
    perpetual_growth_rate DECIMAL(5, 4) NOT NULL,
    projection_years INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
    INDEX idx_card_id (card_id)
);

-- 7. SCENARIO PLANNING TABLE
CREATE TABLE IF NOT EXISTS valuation_scenarios (
    scenario_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    scenario_name VARCHAR(100) NOT NULL,
    annual_fee DECIMAL(10, 2) NOT NULL,
    retention_rate DECIMAL(5, 4) NOT NULL,
    customer_acquisition_growth DECIMAL(5, 4) NOT NULL,
    spend_per_customer DECIMAL(12, 2) NOT NULL,
    cost_per_customer DECIMAL(12, 2) NOT NULL,
    net_revenue_margin DECIMAL(5, 4) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
    INDEX idx_card_id (card_id),
    UNIQUE KEY unique_card_scenario (card_id, scenario_name)
);

-- 8. CUSTOMER COHORT CASH FLOWS
CREATE TABLE IF NOT EXISTS cohort_cash_flows (
    cohort_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    cohort_year INT NOT NULL,
    cohort_acquisition_date DATE NOT NULL,
    initial_customers INT NOT NULL,
    year_number INT NOT NULL,
    expected_customers INT NOT NULL,
    annual_fee_per_customer DECIMAL(10, 2) NOT NULL,
    waiver_rate DECIMAL(5, 4) NOT NULL,
    churn_rate DECIMAL(5, 4) NOT NULL,
    gross_fee_revenue DECIMAL(15, 2) NOT NULL,
    fee_waiver_cost DECIMAL(15, 2) NOT NULL,
    net_fee_revenue DECIMAL(15, 2) NOT NULL,
    customer_acquisition_cost DECIMAL(12, 2) NOT NULL,
    customer_service_cost DECIMAL(12, 2) NOT NULL,
    fraud_loss_rate DECIMAL(5, 4) NOT NULL,
    fraud_loss DECIMAL(12, 2) NOT NULL,
    net_operating_cash_flow DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
    INDEX idx_card_id (card_id),
    INDEX idx_year_number (year_number),
    UNIQUE KEY unique_cohort (card_id, cohort_year, year_number)
);

-- 9. TERMINAL VALUE CALCULATIONS
CREATE TABLE IF NOT EXISTS terminal_value_data (
    terminal_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    scenario_id INT NOT NULL,
    final_year_fcf DECIMAL(15, 2) NOT NULL,
    perpetual_growth_rate DECIMAL(5, 4) NOT NULL,
    discount_rate DECIMAL(5, 4) NOT NULL,
    terminal_value DECIMAL(18, 2) NOT NULL,
    terminal_value_pv DECIMAL(18, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
    FOREIGN KEY (scenario_id) REFERENCES valuation_scenarios(scenario_id),
    INDEX idx_card_id (card_id)
);

-- 10. NPV & IRR RESULTS TABLE
CREATE TABLE IF NOT EXISTS npv_irr_results (
    result_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    scenario_id INT NOT NULL,
    initial_investment DECIMAL(15, 2) NOT NULL,
    sum_pv_cash_flows DECIMAL(18, 2) NOT NULL,
    terminal_value_pv DECIMAL(18, 2) NOT NULL,
    enterprise_value DECIMAL(18, 2) NOT NULL,
    npv DECIMAL(18, 2) NOT NULL,
    irr DECIMAL(5, 4),
    profitability_index DECIMAL(8, 4),
    payback_period_years DECIMAL(10, 2),
    modified_irr DECIMAL(5, 4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
    FOREIGN KEY (scenario_id) REFERENCES valuation_scenarios(scenario_id),
    INDEX idx_card_id (card_id),
    INDEX idx_scenario_id (scenario_id),
    UNIQUE KEY unique_card_scenario (card_id, scenario_id)
);

-- ============================================================
-- PART 2: SAMPLE DATA INSERTION
-- ============================================================

-- Insert Credit Card Products
INSERT INTO credit_cards (card_name, card_tier, launch_date, target_segment) VALUES
('Premium Platinum', 'Premium', '2020-01-15', 'High Net Worth'),
('Business Elite', 'Gold', '2019-06-20', 'Business'),
('Standard Rewards', 'Standard', '2018-03-10', 'Mass Market');

-- Insert Valuation Assumptions
INSERT INTO valuation_assumptions (card_id, discount_rate, risk_free_rate, equity_risk_premium, debt_cost, tax_rate, perpetual_growth_rate, projection_years) VALUES
(1, 0.10, 0.03, 0.05, 0.05, 0.25, 0.03, 5),
(2, 0.09, 0.03, 0.05, 0.05, 0.25, 0.03, 5),
(3, 0.08, 0.03, 0.05, 0.05, 0.25, 0.03, 5);

-- Insert Valuation Scenarios
INSERT INTO valuation_scenarios (card_id, scenario_name, annual_fee, retention_rate, customer_acquisition_growth, spend_per_customer, cost_per_customer, net_revenue_margin) VALUES
(1, 'Base', 500.00, 0.85, 0.10, 50000, 20000, 0.60),
(1, 'Optimistic', 500.00, 0.90, 0.15, 60000, 18000, 0.65),
(1, 'Pessimistic', 500.00, 0.75, 0.05, 40000, 22000, 0.50),
(2, 'Base', 300.00, 0.80, 0.08, 30000, 12000, 0.60),
(2, 'Optimistic', 300.00, 0.88, 0.12, 35000, 11000, 0.65),
(2, 'Pessimistic', 300.00, 0.70, 0.03, 25000, 13000, 0.50),
(3, 'Base', 0.00, 0.75, 0.10, 20000, 8000, 0.60),
(3, 'Optimistic', 0.00, 0.82, 0.15, 25000, 7000, 0.65),
(3, 'Pessimistic', 0.00, 0.68, 0.05, 15000, 9000, 0.50);

-- Insert Annual Fee History
INSERT INTO annual_fee_history (card_id, fee_amount, effective_date, waiver_rate, churn_rate) VALUES
(1, 500.00, '2025-01-01', 0.05, 0.02),
(2, 300.00, '2025-01-01', 0.10, 0.05),
(3, 0.00, '2025-01-01', 0.00, 0.15);

-- Insert Sample Card Holders
INSERT INTO card_holders (card_id, acquisition_date, annual_income, credit_score, customer_segment, lifetime_value, is_active) VALUES
(1, '2024-01-15', 200000, 750, 'High Net Worth', 15000.00, TRUE),
(1, '2024-02-20', 180000, 745, 'High Net Worth', 14500.00, TRUE),
(1, '2024-03-10', 210000, 760, 'High Net Worth', 16000.00, TRUE),
(2, '2024-01-10', 120000, 700, 'Business', 8500.00, TRUE),
(2, '2024-02-15', 130000, 710, 'Business', 9000.00, TRUE),
(2, '2024-03-05', 110000, 695, 'Business', 8000.00, TRUE),
(3, '2024-01-05', 60000, 650, 'Mass Market', 3000.00, TRUE),
(3, '2024-02-10', 65000, 660, 'Mass Market', 3200.00, TRUE),
(3, '2024-03-01', 55000, 640, 'Mass Market', 2800.00, TRUE);

-- Insert Customer Metrics
INSERT INTO customer_metrics (cardholder_id, year, total_spend, transaction_count, rewards_earned, rewards_redeemed, customer_satisfaction_score) VALUES
(1, 2025, 65000, 120, 6500, 6000, 4.8),
(2, 2025, 58000, 100, 5800, 5500, 4.6),
(3, 2025, 72000, 145, 7200, 6800, 4.9),
(4, 2025, 42000, 80, 4200, 4000, 4.5),
(5, 2025, 48000, 95, 4800, 4500, 4.4),
(6, 2025, 38000, 70, 3800, 3600, 4.3),
(7, 2025, 25000, 50, 2500, 2300, 4.0),
(8, 2025, 28000, 55, 2800, 2600, 4.1),
(9, 2025, 22000, 45, 2200, 2000, 3.9);

-- Insert Fee Elasticity Scenarios
INSERT INTO fee_elasticity_scenarios (card_id, proposed_fee, expected_retention_rate, expected_churn_rate, expected_new_acquisition_impact) VALUES
(1, 450.00, 0.88, 0.01, 0.05),
(1, 500.00, 0.85, 0.02, 0.00),
(1, 550.00, 0.82, 0.03, -0.03),
(2, 250.00, 0.85, 0.03, 0.08),
(2, 300.00, 0.80, 0.05, 0.00),
(2, 350.00, 0.75, 0.07, -0.05),
(3, 0.00, 0.75, 0.15, 0.00),
(3, 50.00, 0.70, 0.20, -0.05),
(3, 100.00, 0.65, 0.25, -0.10);

-- Insert Cohort Cash Flows (5-year projection for Card 1, Base Scenario)
INSERT INTO cohort_cash_flows (card_id, cohort_year, cohort_acquisition_date, initial_customers, year_number, expected_customers, annual_fee_per_customer, waiver_rate, churn_rate, gross_fee_revenue, fee_waiver_cost, net_fee_revenue, customer_acquisition_cost, customer_service_cost, fraud_loss_rate, fraud_loss, net_operating_cash_flow) VALUES
(1, 2025, '2025-01-01', 100000, 0, 100000, 500.00, 0.05, 0.02, 50000000, 2500000, 47500000, 5000000, 10000000, 0.02, 1000000, 31500000),
(1, 2025, '2025-01-01', 100000, 1, 98000, 500.00, 0.05, 0.02, 49000000, 2450000, 46550000, 0, 9800000, 0.02, 980000, 35770000),
(1, 2025, '2025-01-01', 100000, 2, 96040, 500.00, 0.05, 0.02, 48020000, 2401000, 45619000, 0, 9604000, 0.02, 960000, 35055000),
(1, 2025, '2025-01-01', 100000, 3, 94119, 500.00, 0.05, 0.02, 47059500, 2352975, 44706525, 0, 9411900, 0.02, 941000, 34353625),
(1, 2025, '2025-01-01', 100000, 4, 92236, 500.00, 0.05, 0.02, 46118000, 2305900, 43812100, 0, 9223600, 0.02, 922000, 33666500),
(1, 2025, '2025-01-01', 100000, 5, 90391, 500.00, 0.05, 0.02, 45195500, 2259775, 42935725, 0, 9039100, 0.02, 904000, 32992625);

-- Insert Terminal Value Data
INSERT INTO terminal_value_data (card_id, scenario_id, final_year_fcf, perpetual_growth_rate, discount_rate, terminal_value, terminal_value_pv) VALUES
(1, 1, 32992625, 0.03, 0.10, 321450500, 196700300);

-- Insert NPV/IRR Results
INSERT INTO npv_irr_results (card_id, scenario_id, initial_investment, sum_pv_cash_flows, terminal_value_pv, enterprise_value, npv, irr, profitability_index, payback_period_years, modified_irr) VALUES
(1, 1, 5000000, 153835000, 196700300, 350535300, 345535300, 0.35, 1.95, 1.20, 0.32),
(1, 2, 4500000, 168420000, 215500000, 383920000, 379420000, 0.38, 2.10, 1.10, 0.35),
(1, 3, 5500000, 140250000, 175300000, 315550000, 310050000, 0.32, 1.80, 1.35, 0.29),
(2, 4, 3000000, 95200000, 125600000, 220800000, 217800000, 0.33, 1.85, 1.25, 0.30),
(2, 5, 2800000, 104500000, 138200000, 242700000, 239900000, 0.36, 2.00, 1.15, 0.33),
(2, 6, 3200000, 82300000, 108900000, 191200000, 187800000, 0.29, 1.70, 1.40, 0.26);

-- ============================================================
-- PART 3: ADVANCED VALUATION QUERIES
-- ============================================================

-- QUERY 1: CURRENT ANNUAL FEE REVENUE ANALYSIS
-- Shows current fee revenue, waivers, and churn by card product
SELECT
    cc.card_id,
    cc.card_name,
    cc.card_tier,
    afh.fee_amount,
    COUNT(DISTINCT ch.cardholder_id) AS active_cardholders,
    COUNT(DISTINCT ch.cardholder_id) * afh.fee_amount AS gross_fee_revenue,
    COUNT(DISTINCT ch.cardholder_id) * afh.fee_amount * (1 - afh.waiver_rate) AS net_fee_revenue,
    ROUND(afh.waiver_rate * 100, 2) AS waiver_rate_pct,
    ROUND(afh.churn_rate * 100, 2) AS churn_rate_pct
FROM credit_cards cc
LEFT JOIN annual_fee_history afh ON cc.card_id = afh.card_id
LEFT JOIN card_holders ch ON cc.card_id = ch.card_id AND ch.is_active = TRUE
WHERE afh.effective_date = (
    SELECT MAX(effective_date) 
    FROM annual_fee_history 
    WHERE card_id = cc.card_id
)
GROUP BY cc.card_id, cc.card_name, cc.card_tier, afh.fee_amount, afh.waiver_rate, afh.churn_rate
ORDER BY cc.card_id;

-- ============================================================

-- QUERY 2: FEE ELASTICITY ANALYSIS & PRICE OPTIMIZATION
-- Analyzes projected revenue at different price points
SELECT
    cc.card_id,
    cc.card_name,
    fes.proposed_fee,
    COUNT(DISTINCT ch.cardholder_id) AS current_base,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * fes.expected_retention_rate) AS retained_customers,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * fes.expected_retention_rate * fes.proposed_fee) AS projected_fee_revenue,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * fes.expected_new_acquisition_impact) AS incremental_acquisitions,
    ROUND((COUNT(DISTINCT ch.cardholder_id) * fes.expected_retention_rate + 
           COUNT(DISTINCT ch.cardholder_id) * fes.expected_new_acquisition_impact) * fes.proposed_fee) AS total_projected_revenue,
    ROUND(fes.expected_retention_rate * 100, 2) AS expected_retention_pct,
    ROUND(fes.expected_churn_rate * 100, 2) AS expected_churn_pct
FROM credit_cards cc
LEFT JOIN card_holders ch ON cc.card_id = ch.card_id AND ch.is_active = TRUE
LEFT JOIN fee_elasticity_scenarios fes ON cc.card_id = fes.card_id
WHERE ch.card_id IS NOT NULL
GROUP BY cc.card_id, cc.card_name, fes.proposed_fee, fes.expected_retention_rate, 
         fes.expected_churn_rate, fes.expected_new_acquisition_impact
ORDER BY cc.card_id, fes.proposed_fee;

-- ============================================================

-- QUERY 3: CUSTOMER LIFETIME VALUE IMPACT BY SEGMENT
-- Shows how annual fees affect LTV by customer segment
SELECT
    cc.card_tier,
    ch.customer_segment,
    COUNT(DISTINCT ch.cardholder_id) AS customer_count,
    ROUND(AVG(ch.lifetime_value), 2) AS avg_ltv_before_fee,
    ROUND(AVG(ch.annual_income), 2) AS avg_annual_income,
    ROUND(AVG(cm.total_spend), 2) AS avg_annual_spend,
    ROUND(AVG(ch.lifetime_value) - (afh.fee_amount * (1 - afh.waiver_rate)), 2) AS ltv_after_fee,
    ROUND((afh.fee_amount * (1 - afh.waiver_rate) / NULLIF(AVG(ch.lifetime_value), 0)) * 100, 2) AS fee_as_pct_of_ltv
FROM credit_cards cc
LEFT JOIN card_holders ch ON cc.card_id = ch.card_id
LEFT JOIN customer_metrics cm ON ch.cardholder_id = cm.cardholder_id
LEFT JOIN annual_fee_history afh ON cc.card_id = afh.card_id
WHERE afh.effective_date = (
    SELECT MAX(effective_date) 
    FROM annual_fee_history 
    WHERE card_id = cc.card_id
)
GROUP BY cc.card_tier, ch.customer_segment, afh.fee_amount, afh.waiver_rate
ORDER BY cc.card_tier, ch.customer_segment;

-- ============================================================

-- QUERY 4: NPV CALCULATION WITH TERMINAL VALUE
-- Complete valuation with operating cash flows and terminal value
SELECT
    cc.card_id,
    cc.card_name,
    cc.card_tier,
    vs.scenario_name,
    vs.annual_fee,
    ROUND(vs.retention_rate * 100, 2) AS retention_rate_pct,
    ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)), 2) AS pv_operating_cf,
    ROUND((SELECT net_operating_cash_flow 
           FROM cohort_cash_flows 
           WHERE card_id = cc.card_id 
           ORDER BY year_number DESC 
           LIMIT 1), 2) AS final_year_fcf,
    ROUND(((SELECT net_operating_cash_flow 
            FROM cohort_cash_flows 
            WHERE card_id = cc.card_id 
            ORDER BY year_number DESC 
            LIMIT 1) * (1 + va.perpetual_growth_rate)) / 
          (va.discount_rate - va.perpetual_growth_rate), 2) AS terminal_value,
    ROUND((((SELECT net_operating_cash_flow 
             FROM cohort_cash_flows 
             WHERE card_id = cc.card_id 
             ORDER BY year_number DESC 
             LIMIT 1) * (1 + va.perpetual_growth_rate)) / 
            (va.discount_rate - va.perpetual_growth_rate)) / 
           POWER(1 + va.discount_rate, va.projection_years), 2) AS pv_terminal_value,
    ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)) +
          (((SELECT net_operating_cash_flow 
             FROM cohort_cash_flows 
             WHERE card_id = cc.card_id 
             ORDER BY year_number DESC 
             LIMIT 1) * (1 + va.perpetual_growth_rate)) / 
           (va.discount_rate - va.perpetual_growth_rate)) / 
          POWER(1 + va.discount_rate, va.projection_years), 2) AS enterprise_value,
    ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)) +
          (((SELECT net_operating_cash_flow 
             FROM cohort_cash_flows 
             WHERE card_id = cc.card_id 
             ORDER BY year_number DESC 
             LIMIT 1) * (1 + va.perpetual_growth_rate)) / 
           (va.discount_rate - va.perpetual_growth_rate)) / 
          POWER(1 + va.discount_rate, va.projection_years) - 
          (SELECT COALESCE(SUM(customer_acquisition_cost), 0) 
           FROM cohort_cash_flows 
           WHERE card_id = cc.card_id AND year_number = 0), 2) AS npv,
    ROUND(va.discount_rate * 100, 2) AS discount_rate_pct,
    ROUND(va.perpetual_growth_rate * 100, 2) AS perpetual_growth_pct
FROM credit_cards cc
JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
JOIN valuation_assumptions va ON cc.card_id = va.card_id
JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
GROUP BY cc.card_id, cc.card_name, cc.card_tier, vs.scenario_id, vs.scenario_name, vs.annual_fee, 
         vs.retention_rate, va.discount_rate, va.perpetual_growth_rate, va.projection_years
ORDER BY cc.card_id, vs.scenario_name;

-- ============================================================

-- QUERY 5: IRR APPROXIMATION - BINARY SEARCH METHOD
-- Finds IRR by testing multiple discount rates
WITH irr_calculation AS (
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_id,
        vs.scenario_name,
        0.00 AS test_rate,
        SUM(ccf.net_operating_cash_flow / POWER(1 + 0.00, ccf.year_number)) AS npv_at_test_rate
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
    GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name
    
    UNION ALL
    
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_id,
        vs.scenario_name,
        0.05,
        SUM(ccf.net_operating_cash_flow / POWER(1 + 0.05, ccf.year_number))
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
    GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name
    
    UNION ALL
    
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_id,
        vs.scenario_name,
        0.10,
        SUM(ccf.net_operating_cash_flow / POWER(1 + 0.10, ccf.year_number))
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
    GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name
    
    UNION ALL
    
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_id,
        vs.scenario_name,
        0.15,
        SUM(ccf.net_operating_cash_flow / POWER(1 + 0.15, ccf.year_number))
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
    GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name
    
    UNION ALL
    
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_id,
        vs.scenario_name,
        0.20,
        SUM(ccf.net_operating_cash_flow / POWER(1 + 0.20, ccf.year_number))
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
    GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name
    
    UNION ALL
    
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_id,
        vs.scenario_name,
        0.25,
        SUM(ccf.net_operating_cash_flow / POWER(1 + 0.25, ccf.year_number))
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
    GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name
    
    UNION ALL
    
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_id,
        vs.scenario_name,
        0.30,
        SUM(ccf.net_operating_cash_flow / POWER(1 + 0.30, ccf.year_number))
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
    GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name
)
SELECT
    card_id,
    card_name,
    scenario_name,
    ROUND(test_rate * 100, 2) AS test_rate_pct,
    ROUND(npv_at_test_rate, 2) AS npv_at_test_rate,
    CASE 
        WHEN npv_at_test_rate >= -100000 AND npv_at_test_rate <= 100000 THEN 'IRR Near This Rate'
        WHEN npv_at_test_rate > 0 THEN 'NPV Positive'
        ELSE 'NPV Negative'
    END AS irr_status
FROM irr_calculation
ORDER BY card_id, scenario_name, test_rate;

-- ============================================================

-- QUERY 6: PROFITABILITY INDEX ANALYSIS
-- Capital efficiency metric (PI > 1.0 indicates accept)
SELECT
    cc.card_id,
    cc.card_name,
    vs.scenario_name,
    vs.annual_fee,
    (SELECT COALESCE(SUM(customer_acquisition_cost), 0) 
     FROM cohort_cash_flows 
     WHERE card_id = cc.card_id AND year_number = 0) AS initial_investment,
    ROUND(SUM(CASE WHEN ccf.net_operating_cash_flow > 0 
                    THEN ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number) 
                    ELSE 0 END), 2) AS pv_inflows,
    ROUND(SUM(CASE WHEN ccf.net_operating_cash_flow < 0 
                    THEN ABS(ccf.net_operating_cash_flow) / POWER(1 + va.discount_rate, ccf.year_number) 
                    ELSE 0 END), 2) AS pv_outflows,
    ROUND(SUM(CASE WHEN ccf.net_operating_cash_flow > 0 
                    THEN ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number) 
                    ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN ccf.net_operating_cash_flow < 0 
                          THEN ABS(ccf.net_operating_cash_flow) / POWER(1 + va.discount_rate, ccf.year_number) 
                          ELSE 0 END), 0), 4) AS profitability_index,
    CASE 
        WHEN ROUND(SUM(CASE WHEN ccf.net_operating_cash_flow > 0 
                            THEN ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number) 
                            ELSE 0 END) / 
                  NULLIF(SUM(CASE WHEN ccf.net_operating_cash_flow < 0 
                                  THEN ABS(ccf.net_operating_cash_flow) / POWER(1 + va.discount_rate, ccf.year_number) 
                                  ELSE 0 END), 0), 4) > 1 THEN 'ACCEPT'
        ELSE 'REJECT'
    END AS pi_recommendation
FROM credit_cards cc
JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
JOIN valuation_assumptions va ON cc.card_id = va.card_id
JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name, vs.annual_fee, va.discount_rate
ORDER BY cc.card_id, vs.scenario_name;

-- ============================================================

-- QUERY 7: PAYBACK PERIOD CALCULATION
-- Time to recover initial investment
WITH cumulative_cf AS (
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_name,
        ccf.year_number,
        ccf.net_operating_cash_flow,
        SUM(ccf.net_operating_cash_flow) OVER (PARTITION BY cc.card_id, vs.scenario_id ORDER BY ccf.year_number) AS cumulative_cf
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
)
SELECT
    card_id,
    card_name,
    scenario_name,
    MIN(CASE WHEN cumulative_cf >= 0 THEN year_number END) AS payback_period_years,
    ROUND(MIN(CASE WHEN cumulative_cf >= 0 THEN year_number END) + 0.5, 2) AS payback_period_approx,
    ROUND(MAX(cumulative_cf), 2) AS final_cumulative_cf
FROM cumulative_cf
GROUP BY card_id, card_name, scenario_name
ORDER BY card_id, scenario_name;

-- ============================================================

-- QUERY 8: MODIFIED IRR (MIRR) WITH REINVESTMENT RATES
-- More realistic IRR accounting for reinvestment rates
WITH cash_flow_analysis AS (
    SELECT
        cc.card_id,
        cc.card_name,
        vs.scenario_name,
        va.discount_rate AS finance_rate,
        0.10 AS reinvest_rate,
        COUNT(DISTINCT ccf.year_number) AS num_periods,
        MAX(ccf.year_number) AS max_year,
        SUM(CASE WHEN ccf.net_operating_cash_flow > 0 
                 THEN ccf.net_operating_cash_flow * POWER(1 + 0.10, 
                      (SELECT MAX(year_number) FROM cohort_cash_flows WHERE card_id = cc.card_id) - ccf.year_number)
                 ELSE 0 END) AS fv_positive_cf,
        SUM(CASE WHEN ccf.net_operating_cash_flow < 0 
                 THEN ABS(ccf.net_operating_cash_flow) / POWER(1 + va.discount_rate, ccf.year_number)
                 ELSE 0 END) AS pv_negative_cf
    FROM credit_cards cc
    JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
    JOIN valuation_assumptions va ON cc.card_id = va.card_id
    JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
    GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name, va.discount_rate
)
SELECT
    card_id,
    card_name,
    scenario_name,
    ROUND(finance_rate * 100, 2) AS finance_rate_pct,
    ROUND(reinvest_rate * 100, 2) AS reinvest_rate_pct,
    num_periods,
    max_year,
    ROUND(fv_positive_cf, 2) AS fv_positive_cf,
    ROUND(pv_negative_cf, 2) AS pv_negative_cf,
    ROUND(POWER(fv_positive_cf / NULLIF(pv_negative_cf, 0), 1.0 / NULLIF(max_year, 0)) - 1, 4) AS modified_irr,
    ROUND((POWER(fv_positive_cf / NULLIF(pv_negative_cf, 0), 1.0 / NULLIF(max_year, 0)) - 1) * 100, 2) AS modified_irr_pct
FROM cash_flow_analysis
ORDER BY card_id, scenario_name;

-- ============================================================

-- QUERY 9: SENSITIVITY ANALYSIS - NPV MATRIX
-- NPV across different discount rates and retention rates
SELECT
    cc.card_id,
    cc.card_name,
    vs.scenario_name,
    vs.annual_fee,
    ROUND(vs.retention_rate * 100, 2) AS retention_rate_pct,
    ROUND(va.discount_rate * 100, 2) AS discount_rate_pct,
    ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)) +
          (((SELECT net_operating_cash_flow 
             FROM cohort_cash_flows 
             WHERE card_id = cc.card_id 
             ORDER BY year_number DESC 
             LIMIT 1) * (1 + va.perpetual_growth_rate)) / 
           (va.discount_rate - va.perpetual_growth_rate)) / 
          POWER(1 + va.discount_rate, va.projection_years), 2) AS npv,
    CASE 
        WHEN ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)), 2) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS npv_status,
    CASE 
        WHEN ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)), 2) > 100000000 THEN 'High Value'
        WHEN ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)), 2) > 0 THEN 'Positive Value'
        ELSE 'Negative Value'
    END AS value_assessment
FROM credit_cards cc
JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
JOIN valuation_assumptions va ON cc.card_id = va.card_id
JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
GROUP BY cc.card_id, cc.card_name, vs.scenario_id, vs.scenario_name, vs.annual_fee, vs.retention_rate, 
         va.discount_rate, va.perpetual_growth_rate, va.projection_years
ORDER BY cc.card_id, vs.scenario_name, va.discount_rate;

-- ============================================================

-- QUERY 10: COMPREHENSIVE VALUATION DASHBOARD
-- Complete summary of all key valuation metrics by scenario
SELECT
    cc.card_id,
    cc.card_name,
    cc.card_tier,
    vs.scenario_name,
    vs.annual_fee,
    ROUND(vs.retention_rate * 100, 2) AS retention_rate_pct,
    ROUND(va.discount_rate * 100, 2) AS discount_rate_pct,
    ROUND((SELECT SUM(net_operating_cash_flow) FROM cohort_cash_flows WHERE card_id = cc.card_id), 2) AS total_undiscounted_cf,
    ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)), 2) AS pv_operating_cf,
    ROUND((((SELECT net_operating_cash_flow 
             FROM cohort_cash_flows 
             WHERE card_id = cc.card_id 
             ORDER BY year_number DESC 
             LIMIT 1) * (1 + va.perpetual_growth_rate)) / 
            (va.discount_rate - va.perpetual_growth_rate)) / 
           POWER(1 + va.discount_rate, va.projection_years), 2) AS pv_terminal_value,
    ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)) +
          (((SELECT net_operating_cash_flow 
             FROM cohort_cash_flows 
             WHERE card_id = cc.card_id 
             ORDER BY year_number DESC 
             LIMIT 1) * (1 + va.perpetual_growth_rate)) / 
           (va.discount_rate - va.perpetual_growth_rate)) / 
          POWER(1 + va.discount_rate, va.projection_years), 2) AS enterprise_value,
    ROUND(va.perpetual_growth_rate * 100, 2) AS perpetual_growth_pct,
    COUNT(DISTINCT ch.cardholder_id) AS total_cardholders,
    ROUND(AVG(ch.lifetime_value), 2) AS avg_ltv,
    CASE 
        WHEN ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)), 2) > 100000000 THEN 'High Value'
        WHEN ROUND(SUM(ccf.net_operating_cash_flow / POWER(1 + va.discount_rate, ccf.year_number)), 2) > 0 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS valuation_assessment
FROM credit_cards cc
JOIN valuation_scenarios vs ON cc.card_id = vs.card_id
JOIN valuation_assumptions va ON cc.card_id = va.card_id
JOIN cohort_cash_flows ccf ON cc.card_id = ccf.card_id
LEFT JOIN card_holders ch ON cc.card_id = ch.card_id AND ch.is_active = TRUE
GROUP BY cc.card_id, cc.card_name, cc.card_tier, vs.scenario_id, vs.scenario_name, vs.annual_fee, 
         vs.retention_rate, va.discount_rate, va.perpetual_growth_rate, va.projection_years
ORDER BY cc.card_id, vs.scenario_name;

-- ============================================================

-- QUERY 11: OPTIMAL PRICE POINT ANALYSIS
-- Determines fee amount that maximizes total revenue
WITH revenue_scenarios AS (
    SELECT
        cc.card_id,
        cc.card_name,
        fes.proposed_fee,
        COUNT(DISTINCT ch.cardholder_id) AS base_customers,
        ROUND(COUNT(DISTINCT ch.cardholder_id) * fes.expected_retention_rate * fes.proposed_fee) AS projected_fee_revenue,
        ROUND(COUNT(DISTINCT ch.cardholder_id) * fes.expected_retention_rate) AS retained_customers,
        ROW_NUMBER() OVER (PARTITION BY cc.card_id ORDER BY 
            (COUNT(DISTINCT ch.cardholder_id) * fes.expected_retention_rate * fes.proposed_fee) DESC) AS revenue_rank
    FROM credit_cards cc
    LEFT JOIN card_holders ch ON cc.card_id = ch.card_id AND ch.is_active = TRUE
    LEFT JOIN fee_elasticity_scenarios fes ON cc.card_id = fes.card_id
    GROUP BY cc.card_id, cc.card_name, fes.proposed_fee, fes.expected_retention_rate
)
SELECT
    card_id,
    card_name,
    proposed_fee AS optimal_fee,
    base_customers,
    retained_customers,
    projected_fee_revenue AS max_projected_revenue,
    ROUND((projected_fee_revenue / NULLIF(base_customers * proposed_fee, 0)) * 100, 2) AS revenue_realization_pct
FROM revenue_scenarios
WHERE revenue_rank = 1
ORDER BY card_id;

-- ============================================================

-- QUERY 12: SEGMENT-SPECIFIC PRICING STRATEGY
-- Recommended fees by customer segment to maximize LTV
SELECT
    cc.card_tier,
    ch.customer_segment,
    COUNT(DISTINCT ch.cardholder_id) AS segment_customers,
    ROUND(AVG(ch.annual_income)) AS avg_income,
    ROUND(AVG(cm.total_spend)) AS avg_spend,
    CASE 
        WHEN AVG(ch.annual_income) > 150000 AND AVG(cm.total_spend) > 50000 THEN 500
        WHEN AVG(ch.annual_income) > 100000 AND AVG(cm.total_spend) > 30000 THEN 300
        WHEN AVG(ch.annual_income) > 75000 THEN 150
        ELSE 0
    END AS recommended_annual_fee,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * 
        CASE 
            WHEN AVG(ch.annual_income) > 150000 THEN 0.95
            WHEN AVG(ch.annual_income) > 100000 THEN 0.85
            ELSE 0.75
        END) AS expected_retainers,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * 
        CASE 
            WHEN AVG(ch.annual_income) > 150000 THEN 500 * 0.95
            WHEN AVG(ch.annual_income) > 100000 THEN 300 * 0.85
            ELSE 150 * 0.75
        END) AS segment_projected_revenue
FROM credit_cards cc
LEFT JOIN card_holders ch ON cc.card_id = ch.card_id
LEFT JOIN customer_metrics cm ON ch.cardholder_id = cm.cardholder_id
GROUP BY cc.card_tier, ch.customer_segment
ORDER BY cc.card_tier, segment_projected_revenue DESC;

-- ============================================================

-- QUERY 13: CHURN RISK ASSESSMENT
-- Waiver and churn impact on fee revenue
SELECT
    cc.card_name,
    afh.fee_amount,
    COUNT(DISTINCT ch.cardholder_id) AS total_customers,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * afh.waiver_rate) AS waived_fee_customers,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * (1 - afh.waiver_rate)) AS paying_customers,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * afh.churn_rate) AS expected_churners,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * afh.waiver_rate * afh.fee_amount) AS waived_revenue_impact,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * (1 - afh.waiver_rate) * afh.fee_amount) AS actual_fee_revenue,
    ROUND((COUNT(DISTINCT ch.cardholder_id) * afh.churn_rate * afh.fee_amount * (1 - afh.waiver_rate))) AS churn_revenue_loss
FROM credit_cards cc
LEFT JOIN card_holders ch ON cc.card_id = ch.card_id AND ch.is_active = TRUE
LEFT JOIN annual_fee_history afh ON cc.card_id = afh.card_id
WHERE afh.effective_date = (
    SELECT MAX(effective_date) 
    FROM annual_fee_history 
    WHERE card_id = cc.card_id
)
GROUP BY cc.card_name, afh.fee_amount, afh.waiver_rate, afh.churn_rate
ORDER BY cc.card_name;

-- ============================================================

-- QUERY 14: YEAR-OVER-YEAR REVENUE TREND ANALYSIS
-- Historical fee revenue trends and growth rates
SELECT
    YEAR(afh.effective_date) AS year,
    cc.card_name,
    COUNT(DISTINCT ch.cardholder_id) AS cardholders,
    afh.fee_amount,
    ROUND(COUNT(DISTINCT ch.cardholder_id) * afh.fee_amount * (1 - afh.waiver_rate)) AS net_fee_revenue,
    LAG(ROUND(COUNT(DISTINCT ch.cardholder_id) * afh.fee_amount * (1 - afh.waiver_rate))) 
        OVER (PARTITION BY cc.card_id ORDER BY YEAR(afh.effective_date)) AS prev_year_revenue,
    ROUND(((ROUND(COUNT(DISTINCT ch.cardholder_id) * afh.fee_amount * (1 - afh.waiver_rate)) - 
            LAG(ROUND(COUNT(DISTINCT ch.cardholder_id) * afh.fee_amount * (1 - afh.waiver_rate))) 
                OVER (PARTITION BY cc.card_id ORDER BY YEAR(afh.effective_date))) / 
            LAG(ROUND(COUNT(DISTINCT ch.cardholder_id) * afh.fee_amount * (1 - afh.waiver_rate))) 
                OVER (PARTITION BY cc.card_id ORDER BY YEAR(afh.effective_date))) * 100, 2) AS yoy_growth_pct
FROM credit_cards cc
LEFT JOIN card_holders ch ON cc.card_id = ch.card_id
LEFT JOIN annual_fee_history afh ON cc.card_id = afh.card_id
GROUP BY YEAR(afh.effective_date), cc.card_name, cc.card_id, afh.fee_amount, afh.waiver_rate
ORDER BY cc.card_id, YEAR(afh.effective_date);

-- ============================================================

-- QUERY 15: CASH FLOW PROJECTION DETAILS
-- Year-by-year cash flow breakdown for detailed analysis
SELECT
    cc.card_id,
    cc.card_name,
    ccf.year_number,
    ccf.expected_customers,
    ccf.annual_fee_per_customer,
    ROUND(ccf.gross_fee_revenue / 1000000, 2) AS gross_fee_revenue_mm,
    ROUND(ccf.fee_waiver_cost / 1000000, 2) AS fee_waiver_cost_mm,
    ROUND(ccf.net_fee_revenue / 1000000, 2) AS net_fee_revenue_mm,
    ROUND(ccf.customer_acquisition_cost / 1000000, 2) AS customer_acq_cost_mm,
    ROUND(ccf.customer_service_cost / 1000000, 2) AS customer_service_cost_mm,
    ROUND(ccf.fraud_loss / 1000000, 2) AS fraud_loss_mm,
    ROUND(ccf.net_operating_cash_flow / 1000000, 2) AS net_ocf_mm,
    ROUND(ccf.expected_customers * ccf.annual_fee_per_customer) AS total_gross_fees
FROM cohort_cash_flows ccf
JOIN credit_cards cc ON ccf.card_id = cc.card_id
ORDER BY ccf.card_id, ccf.year_number;

-- ============================================================
-- END OF COMPLETE SQL SCRIPT
-- ============================================================
