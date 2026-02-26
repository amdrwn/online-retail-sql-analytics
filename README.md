# E-Commerce Retail Analytics (SQL, 1M+ Transactions)

**Tools:** PostgreSQL · Python · DBeaver
**Dataset:** UCI Online Retail II: 1,067,371 transactions · Dec 2009 – Dec 2011  
**Domain:** UK-based online gift and homeware wholesaler  

---

## Executive Summary

Analysis of 776,624 transactions across 5,861 customers reveals a business at a strategic inflection point.

- **Revenue is flat year-on-year** — 2011 full-year revenue (£8.17M) was virtually identical to 2010 (£8.22M), with Q1-Q2 weakness offset by a strong H2 recovery
- **Retention drives 67%+ of revenue** — loyal customers (10+ orders, 16.4% of base) generate 67% of total revenue at £11,907 average LTV, 34x the value of a one-time buyer
- **New customer acquisition is collapsing** — new customers fell from 40-53% of monthly actives in early 2010 to just 10-11% by mid-2011; 95.4% of December 2011 actives were returning accounts
- **£1M in high-value customers is at risk** — 239 Champions-tier customers averaging £4,353 lifetime spend have not purchased in 344 days on average; targeted win-back could recover ~£260,000
- **International revenue is dangerously concentrated** — one customer accounts for 95.8% of Netherlands revenue and 85.8% of Australian revenue; losing either account would effectively end those markets

---

## Project Overview

End-to-end SQL analytics project on a real-world transactional dataset. The project covers the full analyst workflow: raw data ingestion, data quality profiling, revenue analysis, customer behaviour, cohort retention, RFM segmentation, and advanced business intelligence queries. Analysis is performed in PostgreSQL, with Python used for data ingestion.

The dataset represents a UK-based online gift retailer selling primarily to wholesale trade buyers across 43 countries. All findings are interpreted through a business lens with actionable recommendations throughout.

---

## Repository Structure

```
├── 01_load_data.py                   # Python ingestion script 
├── 02_data_quality.sql            # Data profiling and clean dataset definition
├── 03_revenue_sales.sql           # Revenue trends, seasonality, geography, products
├── 04_customer_behaviour.sql      # Segmentation, frequency, retention, LTV
├── 05_cohort_retention.sql        # Monthly cohort retention matrix
├── 06_rfm_segmentation.sql        # RFM scoring and named segment assignment
├── 07_advanced_analysis.sql       # LTV projection, market basket, concentration risk
├── .env.example                   # Environment variable template
├── .gitignore                     # Excludes .env and data files
└── README.md
```

---

## Technical Stack

| Tool | Purpose |
|---|---|
| PostgreSQL 16 | Primary analytical database |
| Python 3 (pandas, psycopg2, openpyxl) | Data ingestion and loading |
| DBeaver | SQL client and query execution |

**SQL techniques demonstrated:** Window functions (RANK, NTILE, LAG, ROW_NUMBER, SUM OVER), multi-layer CTEs, self-joins for market basket analysis, conditional aggregation, date arithmetic, percentile functions, pivot via CASE WHEN aggregation.

---

## Dataset & Data Quality

**Raw dataset:** 1,067,371 rows across two Excel sheets (2009–2010 and 2010–2011).

**Data quality issues identified and resolved:**

| Issue | Count | Action |
|---|---|---|
| Missing customer_id (guest transactions) | 243,007 rows (22.77%) | Excluded from customer analysis |
| Cancellation invoices (prefix 'C') | 8,292 invoices reversing £1,526,667 | Excluded |
| Duplicate rows | 24,649 surviving deduplication | DISTINCT applied in view |
| Zero/negative price rows | 6,220 rows | Excluded |
| Non-product stock codes | 13 codes (POST, DOT, M, B, D, S…) | Excluded |

**Clean dataset (view `clean_transactions`):**

| Metric | Value |
|---|---|
| Rows | 776,624 |
| Customers | 5,861 |
| Invoices | 36,639 |
| Products | 4,624 |
| Total Revenue | £17,073,078 |
| Date Range | Dec 2009 – Dec 2011 (25 months) |

---

## Key Findings

### 1. Revenue & Seasonality

The business has a strong and consistent seasonal pattern driven by Christmas gifting demand. Revenue peaks in October and November each year then collapses ~50% post-Christmas into January/February.

| Period | Revenue 2010 | Revenue 2011 | YoY Change |
|---|---|---|---|
| January | £537,342 | £562,683 | +4.7% |
| April | £585,150 | £454,441 | **-22.3%** |
| September | £805,545 | £938,753 | **+16.5%** |
| November | £1,155,978 | £1,136,534 | -1.7% |

Full-year 2011 revenue was virtually identical to 2010 (£8.17M vs £8.22M) — flat growth driven by a weak Q1-Q2 offset by a strong H2. By November cumulative revenues differed by less than £2,000 across the two years.

**B2B wholesale signals:** Thursday accounts for the highest invoice count and revenue. Saturday has fewer than 30 invoices across the entire 2-year period. This is not a consumer retail operation.

---

### 2. Customer Behaviour

**Order frequency drives revenue exponentially:**

| Segment | Customers | % Customers | Total Revenue | % Revenue | Avg LTV |
|---|---|---|---|---|---|
| One-time (1 order) | 1,625 | 27.73% | £556,149 | 3.26% | £342 |
| Occasional (2–4) | 2,094 | 35.73% | £2,190,065 | 12.83% | £1,046 |
| Regular (5–9) | 1,180 | 20.13% | £2,872,499 | 16.82% | £2,434 |
| Loyal (10+) | 962 | 16.41% | £11,454,366 | **67.09%** | £11,907 |

A loyal customer (£11,907 average LTV) is worth **34x** a one-time buyer (£342). The 27.73% one-time buyer rate represents a significant retention challenge. These customers generated only 3.26% of total revenue.

**Repurchase behaviour:** 71.3% of customers made a second purchase. The median time to second purchase is **63 days**, which represents the natural repurchase cycle for this business. 27% of customers returned within 30 days; 61% within 90 days.

**Customer Pareto:** The top 23.1% of customers drive 80% of total revenue, closely mirroring the product-level distribution (top 24.8% of products drive 80% of revenue). Both distributions sit around 80/23-25 rather than the classic 80/20.

**New customer acquisition collapse:** New customers as a share of monthly active customers fell from 40-53% in early 2010 to just 10-11% by mid-2011. By December 2011, 95.4% of active customers were returning accounts. The business transitioned from acquisition-led to almost entirely retention-led within 12 months.

---

### 3. Cohort Retention

Monthly cohort retention matrix built entirely in SQL tracking 25 acquisition cohorts from December 2009 through December 2011.

**December 2009 founding cohort (952 customers)** shows exceptional retention. Monthly activity of 33-49% is maintained across the full 2-year window, stabilising at 25-31% through months 13-24. This cohort is the commercial backbone of the business.

**Average retention curve across all cohorts:**

| Month | Avg Retention |
|---|---|
| Month 1 | 21.0% |
| Month 3 | 21.7% |
| Month 6 | 17.9% |
| Month 9 | 15.3% |
| Month 12 | 18.2% |

The curve flattens after month 3 rather than continuing to decay. Customers who survive early churn become long-term accounts active at a consistent 15-20% monthly rate for 2+ years.

**Seasonal reactivation:** Almost every cohort shows a spike at months 11-12. Customers return exactly one year later for the next Christmas season. The December 2009 cohort jumps from 34.3% at month 10 to **49.6%** at month 11.

**Revenue per retained customer grows over time.** The December 2009 cohort averaged £712 per customer at acquisition, rising to £1,416 per active customer by month 22, representing a 99% increase. Retained customers become more valuable, not less.

---

### 4. RFM Segmentation

Every customer scored 1–5 on Recency, Frequency and Monetary value using NTILE quintiles and assigned to named segments.

| Segment | Customers | % Customers | Total Revenue | % Revenue | Avg Revenue | Avg Recency |
|---|---|---|---|---|---|---|
| Champions | 1,296 | 22.1% | £11,685,404 | **68.4%** | £9,017 | 20 days |
| Loyal Customers | 1,207 | 20.6% | £2,760,118 | 16.2% | £2,287 | 72 days |
| At Risk | 239 | 4.1% | £1,040,483 | 6.1% | £4,353 | **344 days** |
| Needs Attention | 451 | 7.7% | £582,455 | 3.4% | £1,291 | **376 days** |
| Hibernating | 717 | 12.2% | £335,935 | 1.97% | £469 | 343 days |
| Lost | 812 | 13.9% | £198,988 | 1.2% | £245 | 561 days |
| New Customers | 439 | 7.5% | £170,703 | 1.0% | £389 | 28 days |

**Champions and Loyal Customers together** represent 42.7% of the customer base but generate **84.6% of all revenue**.

**At Risk is the most urgent commercial finding.** 239 high-value customers (avg £4,353, avg 8.9 orders) have gone silent for an average of 344 days. These accounts know the business and have demonstrated significant spend. Targeted win-back campaigns could recover a meaningful portion of the £1,040,483 in dormant revenue. Even 25% reactivation would recover ~£260,000.

---

### 5. Geographic Analysis & Concentration Risk

UK dominates at 83.7% of revenue (£14.29M) from 5,336 customers at £428 average order value.

**High-value international wholesale accounts:**

| Country | Customers | Revenue | Avg Order Value |
|---|---|---|---|
| Netherlands | 22 | £549,773 | £2,545 |
| EIRE | 5 | £588,022 | £1,091 |
| Germany | 107 | £383,419 | £363 |
| France | 94 | £309,460 | £341 |
| Australia | 15 | £167,800 | £1,885 |

Netherlands AOV is **6x the UK average**, driven by a small number of high-value wholesale distributors.

**Revenue concentration risk by country:**

| Country | Customers | Top Customer % of Country Revenue |
|---|---|---|
| Netherlands | 22 | **95.8%** |
| Australia | 15 | **85.8%** |
| EIRE | 5 | 51.6% |
| Sweden | 19 | 55.4% |
| Germany | 107 | **9.2%** |
| France | 94 | **10.5%** |
| United Kingdom | 5,336 | 4.1% |

Netherlands and Australia are essentially single-customer markets. One account departure would eliminate most of each country's revenue. France and Germany show healthy diversification, with genuine market depth across many accounts.

---

### 6. Product Analysis

**Modified Pareto:** The top 24.8% of products (1,146 of 4,624) drive 80% of revenue. The top product contributes only 1.63% of total revenue, indicating healthy diversification with no single-product dependency.

**Revenue vs volume divergence reveals product strategy:** High-revenue products like REGENCY CAKESTAND 3 TIER (£277,656 revenue, ranked #47 by volume at £12.46 avg) disproportionately drive value. The highest-volume product (WORLD WAR 2 GLIDERS, 105,185 units) ranks #110 by revenue at £0.26/unit. Mid-ticket repeating items in the £5-£12 range are the commercial engine of the business.

**Market basket analysis** identifies strong product family cross-selling patterns. The top product pair RED and WHITE HANGING HEART T-LIGHT HOLDERS were purchased together in 1,153 invoices (3.4% of all multi-item orders). The Lunch Bag range, Jumbo Bag range, and Regency Teacup range all show high within-family co-purchase rates, supporting bundle promotion strategies.

---

### 7. Strategic Recommendations

Based on the full analysis, the five highest-priority business actions are:

**1. Win-back the 239 At Risk customers.** £1,040,483 in dormant revenue from customers who have demonstrated high frequency and high spend. Segment by recency: urgent outreach for 190-300 day dormant accounts, last-chance offer for 300-500 days, write-offs beyond 500 days.

**2. Address the new customer acquisition collapse.** New customers fell from 40%+ of monthly actives in early 2010 to 10% by mid-2011. A business at 95% returning customers has no buffer against natural attrition. Acquisition investment is needed to sustain the revenue base.

**3. Implement a 63-day repurchase trigger.** The median time to second purchase is 63 days. Any customer who has not returned within 63 days of their first order should receive an automated re-engagement communication. 39% of repeat customers take over 90 days. A tiered outreach strategy is needed.

**4. Protect the Champions segment.** 1,296 customers generating 68.4% of revenue averaging just 20 days since last purchase. These are active, high-value wholesale accounts requiring dedicated account management rather than transactional marketing.

**5. Diversify international markets.** Netherlands (95.8% concentrated), Australia (85.8% concentrated) and EIRE (51.6% concentrated) represent fragile single-account revenue streams. France and Germany demonstrate that diversified international markets are achievable. These models should inform expansion strategy in concentrated markets.

---

## How to Run

**Prerequisites:** Python 3, PostgreSQL, the UCI Online Retail II dataset (`.xlsx`) from [UCI Machine Learning Repository](https://archive.uci.edu/dataset/502/online+retail+ii).

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/online-retail-sql-analysis
cd online-retail-sql-analysis

# 2. Install Python dependencies
pip install pandas psycopg2-binary openpyxl python-dotenv

# 3. Copy the environment template and fill in your values
cp .env.example .env

# 4. Create the database in PostgreSQL
createdb online_retail

# 5. Run the ingestion script
python load_data.py

# 6. Run SQL scripts in order (02 through 07) in DBeaver or psql
```

**Note:** The raw dataset file is not included in this repository. Download it from the UCI link above and set the path in your `.env` file.

---

## About

Dataset source: Daqing Chen, Sai Liang Sain, and Kun Guo, *Data mining for the online retail industry*, Journal of Database Marketing and Customer Strategy Management, 2012.