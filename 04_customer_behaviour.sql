WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_orders,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
        MIN(invoice_date) AS first_order,
        MAX(invoice_date) AS last_order
    FROM clean_transactions
    GROUP BY customer_id
)
SELECT
    total_orders,
    COUNT(customer_id) AS customer_count,
    ROUND(100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (), 2) AS pct_of_customers,
    ROUND(AVG(total_revenue)::NUMERIC, 2) AS avg_revenue_per_customer
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_orders,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue
    FROM clean_transactions
    GROUP BY customer_id
),
segmented AS (
    SELECT
        customer_id,
        total_orders,
        total_revenue,
        CASE
            WHEN total_orders = 1 THEN '1. One-time'
            WHEN total_orders BETWEEN 2 AND 4 THEN '2. Occasional (2-4)'
            WHEN total_orders BETWEEN 5 AND 9 THEN '3. Regular (5-9)'
            WHEN total_orders >= 10 THEN '4. Loyal (10+)'
        END AS segment
    FROM customer_orders
)
SELECT
    segment,
    COUNT(customer_id) AS customers,
    ROUND(100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (), 2) AS pct_customers,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(100.0 * SUM(total_revenue) / SUM(SUM(total_revenue)) OVER (), 2) AS pct_revenue,
    ROUND(AVG(total_revenue)::NUMERIC, 2) AS avg_revenue_per_customer,
    ROUND(AVG(total_orders)::NUMERIC, 1) AS avg_orders
FROM segmented
GROUP BY segment
ORDER BY segment;

WITH customer_purchases AS (
    SELECT
        customer_id,
        invoice_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY invoice_date) AS purchase_number
    FROM (
        SELECT DISTINCT
            customer_id,
            DATE_TRUNC('day', invoice_date) AS invoice_date
        FROM clean_transactions
    ) daily_purchases
),
first_second AS (
    SELECT
        f.customer_id,
        f.invoice_date AS first_purchase,
        s.invoice_date AS second_purchase,
        EXTRACT(DAY FROM s.invoice_date - f.invoice_date) AS days_to_second_purchase
    FROM customer_purchases f
    INNER JOIN customer_purchases s
        ON f.customer_id = s.customer_id
        AND f.purchase_number = 1
        AND s.purchase_number = 2
)
SELECT
    COUNT(*) AS customers_with_second_purchase,
    ROUND(AVG(days_to_second_purchase)::NUMERIC, 1) AS avg_days_to_second,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_to_second_purchase) AS p25_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_to_second_purchase) AS median_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_to_second_purchase) AS p75_days,
    MIN(days_to_second_purchase) AS min_days,
    MAX(days_to_second_purchase) AS max_days,
    SUM(CASE WHEN days_to_second_purchase <= 30 THEN 1 ELSE 0 END) AS returned_within_30_days,
    ROUND(100.0 * SUM(CASE WHEN days_to_second_purchase <= 30 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_within_30_days,
    SUM(CASE WHEN days_to_second_purchase <= 90 THEN 1 ELSE 0 END) AS returned_within_90_days,
    ROUND(100.0 * SUM(CASE WHEN days_to_second_purchase <= 90 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_within_90_days
FROM first_second;

WITH customer_purchases AS (
    SELECT
        customer_id,
        invoice_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY invoice_date) AS purchase_number
    FROM (
        SELECT DISTINCT
            customer_id,
            DATE_TRUNC('day', invoice_date) AS invoice_date
        FROM clean_transactions
    ) daily_purchases
),
first_second AS (
    SELECT
        EXTRACT(DAY FROM s.invoice_date - f.invoice_date) AS days_to_second_purchase
    FROM customer_purchases f
    INNER JOIN customer_purchases s
        ON f.customer_id = s.customer_id
        AND f.purchase_number = 1
        AND s.purchase_number = 2
)
SELECT
    CASE
        WHEN days_to_second_purchase <= 7 THEN '0-7 days'
        WHEN days_to_second_purchase <= 14 THEN '8-14 days'
        WHEN days_to_second_purchase <= 30 THEN '15-30 days'
        WHEN days_to_second_purchase <= 60 THEN '31-60 days'
        WHEN days_to_second_purchase <= 90 THEN '61-90 days'
        WHEN days_to_second_purchase <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END AS days_bucket,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers
FROM first_second
GROUP BY
    CASE
        WHEN days_to_second_purchase <= 7 THEN '0-7 days'
        WHEN days_to_second_purchase <= 14 THEN '8-14 days'
        WHEN days_to_second_purchase <= 30 THEN '15-30 days'
        WHEN days_to_second_purchase <= 60 THEN '31-60 days'
        WHEN days_to_second_purchase <= 90 THEN '61-90 days'
        WHEN days_to_second_purchase <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END
ORDER BY MIN(days_to_second_purchase);

WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_orders,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
        ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2) AS avg_order_value
    FROM clean_transactions
    GROUP BY customer_id
),
segmented AS (
    SELECT
        customer_id,
        total_orders,
        total_revenue,
        avg_order_value,
        CASE
            WHEN total_orders = 1 THEN '1. One-time'
            WHEN total_orders BETWEEN 2 AND 4 THEN '2. Occasional (2-4)'
            WHEN total_orders BETWEEN 5 AND 9 THEN '3. Regular (5-9)'
            WHEN total_orders >= 10 THEN '4. Loyal (10+)'
        END AS segment
    FROM customer_stats
)
SELECT
    segment,
    COUNT(customer_id) AS customers,
    ROUND(AVG(avg_order_value)::NUMERIC, 2) AS avg_order_value,
    ROUND(MIN(avg_order_value)::NUMERIC, 2) AS min_order_value,
    ROUND(MAX(avg_order_value)::NUMERIC, 2) AS max_order_value,
    ROUND(AVG(total_revenue)::NUMERIC, 2) AS avg_lifetime_value,
    ROUND(AVG(total_orders)::NUMERIC, 1) AS avg_orders
FROM segmented
GROUP BY segment
ORDER BY segment;

WITH customer_stats AS (
    SELECT
        ct.customer_id,
        ct.country,
        COUNT(DISTINCT ct.invoice_no) AS total_orders,
        ROUND(SUM(ct.revenue)::NUMERIC, 2) AS total_revenue,
        ROUND(SUM(ct.revenue)::NUMERIC / COUNT(DISTINCT ct.invoice_no), 2) AS avg_order_value,
        MIN(ct.invoice_date) AS first_order_date,
        MAX(ct.invoice_date) AS last_order_date,
        EXTRACT(DAY FROM MAX(ct.invoice_date) - MIN(ct.invoice_date)) AS customer_lifespan_days
    FROM clean_transactions ct
    GROUP BY ct.customer_id, ct.country
)
SELECT
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    customer_id,
    country,
    total_orders,
    total_revenue,
    avg_order_value,
    customer_lifespan_days,
    first_order_date,
    last_order_date
FROM customer_stats
ORDER BY total_revenue DESC
LIMIT 20;

WITH customer_revenue AS (
    SELECT
        customer_id,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue
    FROM clean_transactions
    GROUP BY customer_id
),
running_totals AS (
    SELECT
        customer_id,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_total,
        SUM(total_revenue) OVER () AS grand_total,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS customer_rank
    FROM customer_revenue
),
with_pct AS (
    SELECT
        customer_rank,
        customer_id,
        total_revenue,
        ROUND(100.0 * running_total / grand_total, 2) AS cumulative_pct_of_revenue
    FROM running_totals
)
SELECT
    MAX(customer_rank) AS customers_needed,
    ROUND(100.0 * MAX(customer_rank) / (SELECT COUNT(DISTINCT customer_id) FROM clean_transactions), 2) AS pct_of_customer_base,
    MAX(cumulative_pct_of_revenue) AS revenue_covered_pct
FROM with_pct
WHERE cumulative_pct_of_revenue <= 80;

WITH first_purchases AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS first_month
    FROM clean_transactions
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT
        DATE_TRUNC('month', ct.invoice_date) AS invoice_month,
        ct.customer_id,
        CASE
            WHEN DATE_TRUNC('month', ct.invoice_date) = fp.first_month
            THEN 'New'
            ELSE 'Returning'
        END AS customer_type
    FROM clean_transactions ct
    INNER JOIN first_purchases fp ON ct.customer_id = fp.customer_id
)
SELECT
    invoice_month,
    COUNT(DISTINCT CASE WHEN customer_type = 'New' THEN customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN customer_type = 'Returning' THEN customer_id END) AS returning_customers,
    COUNT(DISTINCT customer_id) AS total_active_customers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN customer_type = 'New' THEN customer_id END)
        / COUNT(DISTINCT customer_id), 2) AS pct_new,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN customer_type = 'Returning' THEN customer_id END)
        / COUNT(DISTINCT customer_id), 2) AS pct_returning
FROM monthly_activity
GROUP BY invoice_month
ORDER BY invoice_month;