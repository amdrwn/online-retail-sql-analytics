WITH monthly_revenue AS (
    SELECT
        invoice_month,
        COUNT(DISTINCT invoice_no) AS invoices,
        COUNT(DISTINCT customer_id) AS active_customers,
        ROUND(SUM(revenue)::NUMERIC, 2) AS revenue
    FROM clean_transactions
    GROUP BY invoice_month
)
SELECT
    invoice_month,
    invoices,
    active_customers,
    revenue,
    LAG(revenue) OVER (ORDER BY invoice_month) AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY invoice_month), 2) AS mom_change,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY invoice_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY invoice_month), 0),
    2) AS mom_growth_pct
FROM monthly_revenue
ORDER BY invoice_month;

SELECT
    invoice_year,
    COUNT(DISTINCT invoice_no) AS invoices,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(revenue)::NUMERIC, 2) AS avg_order_line_value,
    ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2) AS avg_order_value
FROM clean_transactions
GROUP BY invoice_year
ORDER BY invoice_year;

SELECT
    TO_CHAR(invoice_date, 'Day') AS day_of_week,
    EXTRACT(DOW FROM invoice_date) AS day_number,
    COUNT(DISTINCT invoice_no) AS invoices,
    ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(revenue)::NUMERIC, 2) AS avg_revenue_per_line
FROM clean_transactions
GROUP BY TO_CHAR(invoice_date, 'Day'), EXTRACT(DOW FROM invoice_date)
ORDER BY day_number;

WITH product_stats AS (
    SELECT
        stock_code,
        description,
        SUM(quantity) AS total_quantity,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(unit_price)::NUMERIC, 2) AS avg_unit_price,
        COUNT(DISTINCT invoice_no) AS times_ordered
    FROM clean_transactions
    GROUP BY stock_code, description
),
ranked AS (
    SELECT
        stock_code,
        description,
        total_quantity,
        total_revenue,
        avg_unit_price,
        times_ordered,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY total_quantity DESC) AS volume_rank
    FROM product_stats
)
SELECT
    revenue_rank,
    volume_rank,
    volume_rank - revenue_rank AS rank_delta,
    stock_code,
    description,
    total_revenue,
    total_quantity,
    avg_unit_price,
    times_ordered
FROM ranked
WHERE revenue_rank <= 10 OR volume_rank <= 10
ORDER BY revenue_rank;

WITH product_revenue AS (
    SELECT
        stock_code,
        description,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue
    FROM clean_transactions
    GROUP BY stock_code, description
),
running_totals AS (
    SELECT
        stock_code,
        description,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_total,
        SUM(total_revenue) OVER () AS grand_total,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS product_rank
    FROM product_revenue
),
with_pct AS (
    SELECT
        product_rank,
        stock_code,
        description,
        total_revenue,
        ROUND(100.0 * running_total / grand_total, 2) AS cumulative_pct_of_revenue
    FROM running_totals
)
SELECT *
FROM with_pct
WHERE cumulative_pct_of_revenue <= 80
ORDER BY product_rank;

WITH country_stats AS (
    SELECT
        country,
        COUNT(DISTINCT invoice_no) AS invoices,
        COUNT(DISTINCT customer_id) AS customers,
        ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
        ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2) AS avg_order_value
    FROM clean_transactions
    GROUP BY country
)
SELECT
    country,
    invoices,
    customers,
    total_revenue,
    avg_order_value,
    ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 2) AS pct_of_total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM country_stats
ORDER BY total_revenue DESC;

WITH top_countries AS (
    SELECT country
    FROM clean_transactions
    GROUP BY country
    ORDER BY SUM(revenue) DESC
    LIMIT 5
)
SELECT
    ct.invoice_month,
    ct.country,
    COUNT(DISTINCT ct.invoice_no) AS invoices,
    ROUND(SUM(ct.revenue)::NUMERIC, 2) AS revenue
FROM clean_transactions ct
INNER JOIN top_countries tc ON ct.country = tc.country
GROUP BY ct.invoice_month, ct.country
ORDER BY ct.invoice_month, revenue DESC;

SELECT
    invoice_month,
    COUNT(DISTINCT invoice_no) AS invoices,
    ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2) AS avg_order_value,
    LAG(ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2))
        OVER (ORDER BY invoice_month) AS prev_month_aov,
    ROUND(
        100.0 * (
            ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2) -
            LAG(ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2))
                OVER (ORDER BY invoice_month)
        ) / NULLIF(
            LAG(ROUND(SUM(revenue)::NUMERIC / COUNT(DISTINCT invoice_no), 2))
                OVER (ORDER BY invoice_month), 0
        ),
    2) AS aov_growth_pct
FROM clean_transactions
GROUP BY invoice_month
ORDER BY invoice_month;