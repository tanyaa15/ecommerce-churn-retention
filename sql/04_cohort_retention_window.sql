WITH user_cohorts AS (
    SELECT 
        c.customer_id,
        DATE_TRUNC('month', c.signup_date)::DATE AS cohort_month,
        s.churned,
        COALESCE(s.churn_date, DATE '2024-06-30') AS end_date,
        ((EXTRACT(YEAR FROM COALESCE(s.churn_date, DATE '2024-06-30')) - EXTRACT(YEAR FROM c.signup_date)) * 12 +
         (EXTRACT(MONTH FROM COALESCE(s.churn_date, DATE '2024-06-30')) - EXTRACT(MONTH FROM c.signup_date))) AS months_active
    FROM clean_customers c
    JOIN raw_subscriptions s ON c.customer_id = s.customer_id
)
SELECT 
    cohort_month,
    COUNT(*) AS cohort_size,
    ROUND(AVG(CASE WHEN months_active >= 1 THEN 1.0 ELSE 0.0 END) * 100, 1) AS m1_retention_pct,
    ROUND(AVG(CASE WHEN months_active >= 3 THEN 1.0 ELSE 0.0 END) * 100, 1) AS m3_retention_pct,
    ROUND(AVG(CASE WHEN months_active >= 6 THEN 1.0 ELSE 0.0 END) * 100, 1) AS m6_retention_pct,
    ROUND(AVG(CASE WHEN months_active >= 12 THEN 1.0 ELSE 0.0 END) * 100, 1) AS m12_retention_pct
FROM user_cohorts
WHERE cohort_month >= '2022-01-01' AND cohort_month <= '2023-06-01'
GROUP BY cohort_month
ORDER BY cohort_month;