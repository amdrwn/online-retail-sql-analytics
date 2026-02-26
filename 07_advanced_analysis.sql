WITH customer_stats AS (
    SELECT
        customer_id,
        MIN(invoice_date) AS first_purchase,
        MAX(invoice_date) AS last_purchase,
        COUNT(DISTINCT invoice_no) AS total_orders,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
        ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2) AS avg_order_value,
        EXTRACT(DAY FROM (
            MAX(invoice_date) - MIN(invoice_date)
        )) AS active_days
    FROM clean_transactions
    GROUP BY customer_id
),
ltv_calc AS (
    SELECT
        customer_id,
        total_orders,
        total_revenue,
        avg_order_value,
        active_days,
        CASE
            WHEN active_days > 0
            THEN ROUND((total_orders::NUMERIC / (active_days / 365.0)), 2)
            ELSE 0
        END AS orders_per_year,
        CASE
            WHEN active_days > 0
            THEN ROUND(
                (total_orders::NUMERIC / (active_days / 365.0)) * avg_order_value,
                2)
            ELSE 0
        END AS projected_annual_ltv
    FROM customer_stats
)
SELECT
    customer_id,
    total_orders,
    total_revenue,
    avg_order_value,
    active_days,
    orders_per_year,
    projected_annual_ltv,
    CASE
        WHEN projected_annual_ltv > 0
        THEN ROUND(50.0 / (projected_annual_ltv / 12), 1)
        ELSE NULL
    END AS months_to_recover_50_cac
FROM ltv_calc
WHERE active_days > 30 
ORDER BY projected_annual_ltv DESC
LIMIT 30;

WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_orders,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
        ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2) AS avg_order_value,
        EXTRACT(DAY FROM (
            MAX(invoice_date) - MIN(invoice_date)
        )) AS active_days
    FROM clean_transactions
    GROUP BY customer_id
),
ltv_calc AS (
    SELECT
        customer_id,
        CASE
            WHEN active_days > 0
            THEN ROUND(
                (total_orders::NUMERIC / (active_days / 365.0)) * avg_order_value,
                2)
            ELSE 0
        END AS projected_annual_ltv
    FROM customer_stats
    WHERE active_days > 30
)
SELECT
    CASE
        WHEN projected_annual_ltv >= 50000 THEN '6. £50k+'
        WHEN projected_annual_ltv >= 10000 THEN '5. £10k-£50k'
        WHEN projected_annual_ltv >= 5000  THEN '4. £5k-£10k'
        WHEN projected_annual_ltv >= 1000  THEN '3. £1k-£5k'
        WHEN projected_annual_ltv >= 500   THEN '2. £500-£1k'
        ELSE                                    '1. Under £500'
    END AS ltv_band,
    COUNT(customer_id) AS customers,
    ROUND(100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (), 2) AS pct_customers,
    ROUND(AVG(projected_annual_ltv)::NUMERIC, 2) AS avg_ltv_in_band,
    ROUND(SUM(projected_annual_ltv)::NUMERIC, 2) AS total_projected_ltv
FROM ltv_calc
GROUP BY
    CASE
        WHEN projected_annual_ltv >= 50000 THEN '6. £50k+'
        WHEN projected_annual_ltv >= 10000 THEN '5. £10k-£50k'
        WHEN projected_annual_ltv >= 5000  THEN '4. £5k-£10k'
        WHEN projected_annual_ltv >= 1000  THEN '3. £1k-£5k'
        WHEN projected_annual_ltv >= 500   THEN '2. £500-£1k'
        ELSE                                    '1. Under £500'
    END
ORDER BY ltv_band DESC;

WITH invoice_products AS (
    SELECT DISTINCT
        invoice_no,
        stock_code,
        description
    FROM clean_transactions
),
multi_item_invoices AS (
    SELECT invoice_no
    FROM invoice_products
    GROUP BY invoice_no
    HAVING COUNT(DISTINCT stock_code) >= 2
),
product_pairs AS (
    SELECT
        a.stock_code AS product_a,
        a.description AS description_a,
        b.stock_code AS product_b,
        b.description AS description_b,
        COUNT(DISTINCT a.invoice_no) AS times_bought_together
    FROM invoice_products a
    INNER JOIN invoice_products b
        ON a.invoice_no = b.invoice_no
        AND a.stock_code < b.stock_code
    INNER JOIN multi_item_invoices m
        ON a.invoice_no = m.invoice_no
    GROUP BY
        a.stock_code,
        a.description,
        b.stock_code,
        b.description
)
SELECT
    product_a,
    description_a,
    product_b,
    description_b,
    times_bought_together,
    ROUND(100.0 * times_bought_together / (
        SELECT COUNT(DISTINCT invoice_no) FROM multi_item_invoices
    ), 4) AS support_pct
FROM product_pairs
WHERE times_bought_together >= 50
ORDER BY times_bought_together DESC
LIMIT 30;

WITH country_revenue AS (
    SELECT
        country,
        customer_id,
        ROUND(SUM(revenue)::NUMERIC, 2) AS customer_revenue
    FROM clean_transactions
    GROUP BY country, customer_id
),
country_totals AS (
    SELECT
        country,
        SUM(customer_revenue) AS total_country_revenue,
        COUNT(customer_id) AS customer_count,
        MAX(customer_revenue) AS top_customer_revenue
    FROM country_revenue
    GROUP BY country
)
SELECT
    country,
    customer_count,
    ROUND(total_country_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(top_customer_revenue::NUMERIC, 2) AS top_customer_revenue,
    ROUND(100.0 * top_customer_revenue / total_country_revenue, 1) AS top_customer_pct_of_country
FROM country_totals
WHERE customer_count >= 3
ORDER BY top_customer_pct_of_country DESC;

WITH monthly_revenue AS (
    SELECT
        EXTRACT(YEAR FROM invoice_date) AS year,
        EXTRACT(MONTH FROM invoice_date) AS month,
        ROUND(SUM(revenue)::NUMERIC, 2) AS revenue
    FROM clean_transactions
    GROUP BY
        EXTRACT(YEAR FROM invoice_date),
        EXTRACT(MONTH FROM invoice_date)
)
SELECT
    m11.month,
    TO_CHAR(TO_DATE(m11.month::TEXT, 'MM'), 'Month') AS month_name,
    m10.revenue AS revenue_2010,
    m11.revenue AS revenue_2011,
    ROUND(100.0 * (m11.revenue - m10.revenue) / m10.revenue, 1) AS yoy_growth_pct,
    SUM(m10.revenue) OVER (ORDER BY m11.month) AS cumulative_2010,
    SUM(m11.revenue) OVER (ORDER BY m11.month) AS cumulative_2011
FROM monthly_revenue m11
INNER JOIN monthly_revenue m10
    ON m11.month = m10.month
    AND m11.year = 2011
    AND m10.year = 2010
WHERE m11.month <= 11
ORDER BY m11.month;