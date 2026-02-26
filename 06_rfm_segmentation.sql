WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(revenue)::NUMERIC, 2) AS monetary,
        (DATE '2011-12-10' - MAX(invoice_date)::DATE) AS recency_days
    FROM clean_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    last_purchase_date,
    recency_days,
    frequency,
    monetary,
    ROUND(monetary / frequency, 2) AS avg_order_value
FROM rfm_base
ORDER BY monetary DESC
LIMIT 20;

WITH rfm_base AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(revenue)::NUMERIC, 2) AS monetary,
        (DATE '2011-12-10' - MAX(invoice_date)::DATE) AS recency_days
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS rfm_total_score
FROM rfm_scores
ORDER BY rfm_total_score DESC
LIMIT 20;

WITH rfm_base AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(revenue)::NUMERIC, 2) AS monetary,
        (DATE '2011-12-10' - MAX(invoice_date)::DATE) AS recency_days
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score) AS rfm_total,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'New Customers'
            WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 3
                THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4
                THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
                THEN 'Needs Attention'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2
                THEN 'Lost'
            WHEN r_score <= 2 AND f_score <= 2
                THEN 'Hibernating'
            ELSE 'About To Sleep'
        END AS segment
    FROM rfm_scores
)
SELECT *
FROM rfm_segments
ORDER BY rfm_total DESC;

WITH rfm_base AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(revenue)::NUMERIC, 2) AS monetary,
        (DATE '2011-12-10' - MAX(invoice_date)::DATE) AS recency_days
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'New Customers'
            WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 3
                THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4
                THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
                THEN 'Needs Attention'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2
                THEN 'Lost'
            WHEN r_score <= 2 AND f_score <= 2
                THEN 'Hibernating'
            ELSE 'About To Sleep'
        END AS segment
    FROM rfm_scores
)
SELECT
    segment,
    COUNT(customer_id) AS customers,
    ROUND(100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (), 2) AS pct_customers,
    ROUND(SUM(monetary)::NUMERIC, 2) AS total_revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 2) AS pct_revenue,
    ROUND(AVG(monetary)::NUMERIC, 2) AS avg_customer_revenue,
    ROUND(AVG(frequency)::NUMERIC, 1) AS avg_orders,
    ROUND(AVG(recency_days)::NUMERIC, 0) AS avg_recency_days
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;

WITH rfm_base AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(revenue)::NUMERIC, 2) AS monetary,
        (DATE '2011-12-10' - MAX(invoice_date)::DATE) AS recency_days
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    rs.customer_id,
    ct.country,
    rs.recency_days,
    rs.frequency,
    rs.monetary,
    ROUND(rs.monetary / rs.frequency, 2) AS avg_order_value,
    rs.r_score,
    rs.f_score,
    rs.m_score
FROM rfm_scores rs
INNER JOIN (
    SELECT DISTINCT customer_id, country
    FROM clean_transactions
) ct ON rs.customer_id = ct.customer_id
WHERE rs.r_score >= 4
  AND rs.f_score >= 4
  AND rs.m_score >= 4
ORDER BY rs.monetary DESC;

WITH rfm_base AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(revenue)::NUMERIC, 2) AS monetary,
        (DATE '2011-12-10' - MAX(invoice_date)::DATE) AS recency_days
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    rs.customer_id,
    ct.country,
    rs.recency_days,
    rs.frequency,
    rs.monetary,
    ROUND(rs.monetary / rs.frequency, 2) AS avg_order_value,
    rs.r_score,
    rs.f_score,
    rs.m_score
FROM rfm_scores rs
INNER JOIN (
    SELECT DISTINCT customer_id, country
    FROM clean_transactions
) ct ON rs.customer_id = ct.customer_id
WHERE rs.r_score <= 2
  AND rs.f_score >= 4
  AND rs.m_score >= 4
ORDER BY rs.monetary DESC;

WITH rfm_base AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS frequency,
        ROUND(SUM(revenue)::NUMERIC, 2) AS monetary,
        (DATE '2011-12-10' - MAX(invoice_date)::DATE) AS recency_days
    FROM clean_transactions
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    (r_score + f_score + m_score) AS rfm_total_score,
    COUNT(customer_id) AS customers,
    ROUND(100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (), 2) AS pct_customers
FROM rfm_scores
GROUP BY (r_score + f_score + m_score)
ORDER BY rfm_total_score DESC;