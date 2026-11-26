CREATE TABLE clean_customers AS
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date ASC) AS rn
    FROM raw_customers
)
SELECT 
    customer_id,
    signup_date::DATE,
    COALESCE(region, 'Unknown') AS region,
    acquisition_channel,
    onboarding_completed
FROM deduplicated
WHERE rn = 1;