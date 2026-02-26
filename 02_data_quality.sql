UPDATE transactions
SET customer_id = CASE
    WHEN customer_id = 'NaN' THEN NULL
    ELSE REPLACE(customer_id, '.0', '')
END;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN invoice_no IS NULL THEN 1 ELSE 0 END) AS null_invoice_no,
    SUM(CASE WHEN stock_code IS NULL THEN 1 ELSE 0 END) AS null_stock_code,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS null_description,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN invoice_date IS NULL THEN 1 ELSE 0 END) AS null_invoice_date,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
    ROUND(100.0 * SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_null_customer_id
FROM transactions;

SELECT
    CASE WHEN invoice_no LIKE 'C%' THEN 'Cancellation' ELSE 'Normal' END AS transaction_type,
    COUNT(DISTINCT invoice_no) AS unique_invoices,
    COUNT(*) AS total_rows,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price)::NUMERIC, 2) AS total_revenue_impact
FROM transactions
GROUP BY CASE WHEN invoice_no LIKE 'C%' THEN 'Cancellation' ELSE 'Normal' END
ORDER BY transaction_type;

SELECT
    SUM(CASE WHEN quantity < 0 AND invoice_no NOT LIKE 'C%' THEN 1 ELSE 0 END) AS negative_qty_non_cancellation,
    SUM(CASE WHEN quantity = 0 THEN 1 ELSE 0 END) AS zero_quantity,
    SUM(CASE WHEN unit_price < 0 THEN 1 ELSE 0 END) AS negative_price,
    SUM(CASE WHEN unit_price = 0 THEN 1 ELSE 0 END) AS zero_price,
    SUM(CASE WHEN quantity > 0 AND unit_price = 0 THEN 1 ELSE 0 END) AS sold_free
FROM transactions;

SELECT
    stock_code,
    description,
    COUNT(*) AS occurrences,
    ROUND(SUM(quantity * unit_price)::NUMERIC, 2) AS revenue_impact
FROM transactions
WHERE stock_code ~* '[^0-9]'
  AND LENGTH(stock_code) < 5
GROUP BY stock_code, description
ORDER BY occurrences DESC
LIMIT 20;

SELECT COUNT(*) AS duplicate_rows
FROM (
    SELECT
        invoice_no, stock_code, quantity,
        invoice_date, unit_price, customer_id,
        COUNT(*) AS row_count
    FROM transactions
    GROUP BY invoice_no, stock_code, quantity, invoice_date, unit_price, customer_id
    HAVING COUNT(*) > 1
) duplicates;

SELECT COUNT(*) AS duplicate_rows
FROM (
    SELECT
        invoice_no, stock_code, quantity,
        invoice_date, unit_price, customer_id,
        COUNT(*) AS row_count
    FROM clean_transactions
    GROUP BY invoice_no, stock_code, quantity, invoice_date, unit_price, customer_id
    HAVING COUNT(*) > 1
) duplicates;

SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantity) AS q1_quantity,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY quantity) AS median_quantity,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantity) AS q3_quantity,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY quantity) AS p99_quantity,
    MAX(quantity) AS max_quantity,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY unit_price) AS q1_price,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY unit_price) AS median_price,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY unit_price) AS q3_price,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY unit_price) AS p99_price,
    MAX(unit_price) AS max_price
FROM clean_transactions;

SELECT
    invoice_month,
    COUNT(DISTINCT invoice_no) AS invoices,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(revenue)::NUMERIC, 2) AS revenue
FROM clean_transactions
GROUP BY invoice_month
ORDER BY invoice_month;

CREATE VIEW clean_transactions AS
SELECT DISTINCT
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    ROUND((quantity * unit_price)::NUMERIC, 2) AS revenue,
    DATE_TRUNC('month', invoice_date) AS invoice_month,
    DATE_TRUNC('year', invoice_date) AS invoice_year
FROM transactions
WHERE invoice_no NOT LIKE 'C%'
  AND customer_id IS NOT NULL
  AND quantity > 0
  AND unit_price > 0
  AND stock_code NOT IN ('POST', 'DOT', 'M', 'm', 'BANK CHARGES', 'PADS', 'C2', 'D', 'S', 'B', 'CRUK', 'GIFT', 'C3');

SELECT
    COUNT(*) AS clean_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT invoice_no) AS unique_invoices,
    COUNT(DISTINCT stock_code) AS unique_products,
    ROUND(SUM(revenue)::NUMERIC, 2) AS total_revenue
FROM clean_transactions;
