import os
import numpy as np
import pandas as pd

os.makedirs("data/raw", exist_ok=True)
np.random.seed(42)

n_customers = 75000

# 1. CUSTOMERS TABLE
signup_dates = pd.to_datetime("2022-01-01") + pd.to_timedelta(
    np.random.randint(0, 730, size=n_customers), unit="D"
)
customers = pd.DataFrame({
    "customer_id": [f"CUST-{100000 + i}" for i in range(n_customers)],
    "signup_date": signup_dates,
    "region": np.random.choice(["North America", "Europe", "APAC", "LATAM"], n_customers, p=[0.45, 0.30, 0.15, 0.10]),
    "acquisition_channel": np.random.choice(["Organic", "Paid Search", "Social Ads", "Referral"], n_customers, p=[0.35, 0.30, 0.20, 0.15]),
    "onboarding_completed": np.random.choice([0, 1], n_customers, p=[0.45, 0.55])
})

# Inject realistic data quality issues (~1.5% missing region, 200 duplicate records)
null_idx = np.random.choice(customers.index, size=1000, replace=False)
customers.loc[null_idx, "region"] = np.nan
duplicates = customers.sample(200, random_state=42)
customers_dirty = pd.concat([customers, duplicates], ignore_index=True)

# 2. SUBSCRIPTIONS TABLE
contract_type = np.random.choice(["Month-to-Month", "Annual", "Two-Year"], n_customers, p=[0.55, 0.30, 0.15])
plan_tier = np.random.choice(["Basic", "Standard", "Premium"], n_customers, p=[0.40, 0.40, 0.20])
tier_price = np.where(plan_tier == "Basic", 19.99, np.where(plan_tier == "Standard", 39.99, 79.99))

# Support tickets count per customer
ticket_counts = np.random.poisson(lam=1.3, size=n_customers)
days_inactive = np.random.randint(1, 95, size=n_customers)

# Churn probability logic (baseline ~13%, Month-to-Month + No Onboarding ~3x baseline)
logit = -2.35 + 0.014 * days_inactive + 0.28 * ticket_counts
high_risk = (contract_type == "Month-to-Month") & (customers["onboarding_completed"].values == 0)
logit += np.where(high_risk, 1.55, 0.0)
logit += np.where(contract_type == "Annual", -0.65, 0.0)
logit += np.where(contract_type == "Two-Year", -1.15, 0.0)

churn_prob = 1 / (1 + np.exp(-logit))
churned = np.random.binomial(1, churn_prob)

tenure_days = np.where(
    churned == 1,
    np.random.randint(15, 240, size=n_customers),
    (pd.to_datetime("2024-06-30") - signup_dates).days
)
churn_date = pd.to_datetime(np.where(
    churned == 1,
    signup_dates + pd.to_timedelta(tenure_days, unit="D"),
    pd.NaT
))

subscriptions = pd.DataFrame({
    "subscription_id": [f"SUB-{500000 + i}" for i in range(n_customers)],
    "customer_id": customers["customer_id"],
    "contract_type": contract_type,
    "plan_tier": plan_tier,
    "monthly_fee": tier_price,
    "payment_method": np.random.choice(["Credit Card", "Debit Card", "PayPal", "Bank Transfer"], n_customers),
    "churned": churned,
    "churn_date": churn_date
})

# 3. SUPPORT TICKETS TABLE (~97k ticket rows)
ticket_rows = []
for cid, cnt in zip(customers["customer_id"], ticket_counts):
    if cnt > 0:
        for _ in range(cnt):
            ticket_rows.append((cid, np.random.choice(["Billing", "Onboarding", "Delivery", "Product Bug"]),
                                np.random.randint(1, 72)))
support_tickets = pd.DataFrame(ticket_rows, columns=["customer_id", "issue_category", "resolution_hours"])
support_tickets.insert(0, "ticket_id", [f"TKT-{i+1}" for i in range(len(support_tickets))])

# 4. ORDERS / ENGAGEMENT SUMMARY TABLE (75k rows)
orders = pd.DataFrame({
    "customer_id": customers["customer_id"],
    "total_orders": np.maximum(1, np.random.poisson(lam=6, size=n_customers) - churned * 2),
    "avg_order_value": np.round(np.random.gamma(3.2, 22, size=n_customers) + 15, 2),
    "days_since_last_order": days_inactive
})

customers_dirty.to_csv("data/raw/customers.csv", index=False)
subscriptions.to_csv("data/raw/subscriptions.csv", index=False)
support_tickets.to_csv("data/raw/support_tickets.csv", index=False)
orders.to_csv("data/raw/orders_summary.csv", index=False)

print(f"Generated 4 tables! Overall Churn Rate: {subscriptions['churned'].mean():.2%}")