WITH cohort_base AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
),
customer_activity AS (
    SELECT
        ct.customer_id,
        cb.cohort_month,
        DATE_TRUNC('month', ct.invoice_date) AS activity_month,
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', ct.invoice_date),
            cb.cohort_month
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', ct.invoice_date),
            cb.cohort_month
        )) AS cohort_index
    FROM clean_transactions ct
    INNER JOIN cohort_base cb ON ct.customer_id = cb.customer_id
),
cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_id) AS customers
    FROM customer_activity
    GROUP BY cohort_month, cohort_index
),
cohort_sizes AS (
    SELECT
        cohort_month,
        customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
)
SELECT
    cc.cohort_month,
    cs.cohort_size,
    cc.cohort_index,
    cc.customers AS active_customers,
    ROUND(100.0 * cc.customers / cs.cohort_size, 1) AS retention_rate
FROM cohort_counts cc
INNER JOIN cohort_sizes cs ON cc.cohort_month = cs.cohort_month
ORDER BY cc.cohort_month, cc.cohort_index;

WITH cohort_base AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
),
customer_activity AS (
    SELECT
        ct.customer_id,
        cb.cohort_month,
        DATE_TRUNC('month', ct.invoice_date) AS activity_month,
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', ct.invoice_date),
            cb.cohort_month
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', ct.invoice_date),
            cb.cohort_month
        )) AS cohort_index
    FROM clean_transactions ct
    INNER JOIN cohort_base cb ON ct.customer_id = cb.customer_id
),
cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_id) AS customers
    FROM customer_activity
    GROUP BY cohort_month, cohort_index
),
cohort_sizes AS (
    SELECT
        cohort_month,
        customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
),
retention AS (
    SELECT
        cc.cohort_month,
        cs.cohort_size,
        cc.cohort_index,
        ROUND(100.0 * cc.customers / cs.cohort_size, 1) AS retention_rate
    FROM cohort_counts cc
    INNER JOIN cohort_sizes cs ON cc.cohort_month = cs.cohort_month
)
SELECT
    cohort_month,
    cohort_size,
    MAX(CASE WHEN cohort_index = 0 THEN retention_rate END) AS month_0,
    MAX(CASE WHEN cohort_index = 1 THEN retention_rate END) AS month_1,
    MAX(CASE WHEN cohort_index = 2 THEN retention_rate END) AS month_2,
    MAX(CASE WHEN cohort_index = 3 THEN retention_rate END) AS month_3,
    MAX(CASE WHEN cohort_index = 4 THEN retention_rate END) AS month_4,
    MAX(CASE WHEN cohort_index = 5 THEN retention_rate END) AS month_5,
    MAX(CASE WHEN cohort_index = 6 THEN retention_rate END) AS month_6,
    MAX(CASE WHEN cohort_index = 7 THEN retention_rate END) AS month_7,
    MAX(CASE WHEN cohort_index = 8 THEN retention_rate END) AS month_8,
    MAX(CASE WHEN cohort_index = 9 THEN retention_rate END) AS month_9,
    MAX(CASE WHEN cohort_index = 10 THEN retention_rate END) AS month_10,
    MAX(CASE WHEN cohort_index = 11 THEN retention_rate END) AS month_11,
    MAX(CASE WHEN cohort_index = 12 THEN retention_rate END) AS month_12
FROM retention
GROUP BY cohort_month, cohort_size
ORDER BY cohort_month;

WITH cohort_base AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
),
customer_activity AS (
    SELECT
        ct.customer_id,
        cb.cohort_month,
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', ct.invoice_date),
            cb.cohort_month
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', ct.invoice_date),
            cb.cohort_month
        )) AS cohort_index
    FROM clean_transactions ct
    INNER JOIN cohort_base cb ON ct.customer_id = cb.customer_id
),
cohort_counts AS (
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_id) AS customers
    FROM customer_activity
    GROUP BY cohort_month, cohort_index
),
cohort_sizes AS (
    SELECT
        cohort_month,
        customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
),
retention AS (
    SELECT
        cc.cohort_month,
        cc.cohort_index,
        ROUND(100.0 * cc.customers / cs.cohort_size, 1) AS retention_rate
    FROM cohort_counts cc
    INNER JOIN cohort_sizes cs ON cc.cohort_month = cs.cohort_month
)
SELECT
    cohort_index,
    COUNT(cohort_month) AS cohorts_measured,
    ROUND(AVG(retention_rate), 1) AS avg_retention_rate,
    ROUND(MIN(retention_rate), 1) AS min_retention_rate,
    ROUND(MAX(retention_rate), 1) AS max_retention_rate
FROM retention
GROUP BY cohort_index
ORDER BY cohort_index;

WITH cohort_base AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS cohort_month
    FROM clean_transactions
    GROUP BY customer_id
),
customer_activity AS (
    SELECT
        ct.customer_id,
        cb.cohort_month,
        ct.revenue,
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', ct.invoice_date),
            cb.cohort_month
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', ct.invoice_date),
            cb.cohort_month
        )) AS cohort_index
    FROM clean_transactions ct
    INNER JOIN cohort_base cb ON ct.customer_id = cb.customer_id
),
cohort_revenue AS (
    SELECT
        cohort_month,
        cohort_index,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM customer_activity
    GROUP BY cohort_month, cohort_index
)
SELECT
    cr.cohort_month,
    cr.cohort_index,
    cr.active_customers,
    cr.total_revenue,
    ROUND(cr.total_revenue / cr.active_customers, 2) AS revenue_per_active_customer
FROM cohort_revenue cr
ORDER BY cr.cohort_month, cr.cohort_index;