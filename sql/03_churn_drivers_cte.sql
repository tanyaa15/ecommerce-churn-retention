WITH customer_360 AS (
    SELECT 
        c.customer_id,
        c.region,
        c.onboarding_completed,
        s.contract_type,
        s.plan_tier,
        s.monthly_fee,
        s.churned,
        o.total_orders,
        o.days_since_last_order,
        COALESCE(t.ticket_count, 0) AS ticket_count
    FROM clean_customers c
    JOIN raw_subscriptions s ON c.customer_id = s.customer_id
    JOIN raw_orders_summary o ON c.customer_id = o.customer_id
    LEFT JOIN (
        SELECT customer_id, COUNT(*) AS ticket_count
        FROM raw_support_tickets
        GROUP BY customer_id
    ) t ON c.customer_id = t.customer_id
),
baseline AS (
    SELECT AVG(churned) AS base_churn_rate FROM customer_360
)
SELECT 
    c360.contract_type,
    CASE WHEN c360.onboarding_completed = 1 THEN 'With Onboarding' ELSE 'No Onboarding' END AS onboarding_status,
    COUNT(*) AS total_customers,
    SUM(c360.churned) AS churned_customers,
    ROUND(AVG(c360.churned) * 100.0, 2) AS churn_rate_pct,
    ROUND(AVG(c360.churned) / b.base_churn_rate, 2) AS risk_multiplier_vs_baseline,
    ROUND(SUM(CASE WHEN c360.churned = 1 THEN c360.monthly_fee ELSE 0 END), 2) AS mrr_lost
FROM customer_360 c360
CROSS JOIN baseline b
GROUP BY 1, 2, b.base_churn_rate
ORDER BY churn_rate_pct DESC;