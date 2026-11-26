-- 1. Raw Customers (Notice no PRIMARY KEY yet because it has intentional duplicates!)

CREATE TABLE raw_customers (
    customer_id VARCHAR(20),
    signup_date TIMESTAMP,
    region VARCHAR(50),
    acquisition_channel VARCHAR(50),
    onboarding_completed INT
);

-- 2. Raw Subscriptions
CREATE TABLE raw_subscriptions (
    subscription_id VARCHAR(20),
    customer_id VARCHAR(20),
    contract_type VARCHAR(30),
    plan_tier VARCHAR(20),
    monthly_fee NUMERIC(10, 2),
    payment_method VARCHAR(30),
    churned INT,
    churn_date TIMESTAMP
);

-- 3. Raw Support Tickets
CREATE TABLE raw_support_tickets (
    ticket_id VARCHAR(20),
    customer_id VARCHAR(20),
    issue_category VARCHAR(30),
    resolution_hours INT
);

-- 4. Raw Orders Summary
CREATE TABLE raw_orders_summary (
    customer_id VARCHAR(20),
    total_orders INT,
    avg_order_value NUMERIC(10, 2),
    days_since_last_order INT
);