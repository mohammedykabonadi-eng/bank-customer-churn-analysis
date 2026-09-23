# Bank Customer Churn & Revenue-at-Risk Analysis

An end-to-end data analytics project that identifies which bank customers are churning, why, and how much revenue is at risk, built with Excel, SQL, and Power BI.

> **Note on the data:** this project uses a synthetic dataset generated to match the structure and patterns of the public [Kaggle Bank Customer Churn dataset](https://www.kaggle.com/datasets/shrutimechlearn/churn-modelling) (10,000 customers). It is not real customer data.

## Problem Statement

The bank is losing roughly 1 in 5 customers, and leadership has no clear picture of who is leaving, why, or how much revenue that represents. This project identifies the highest-risk customer segments and quantifies the revenue impact, so retention efforts can be targeted rather than generic.

## Key Findings

| Metric | Value |
|---|---|
| Overall churn rate | 20.8% (2,079 of 10,000 customers) |
| Total balance lost to churn | $186.3M (24.9% of all customer balances) |
| Highest-risk country | Germany, 30.5% churn (vs. ~17.5% in France and Spain) |
| Highest-risk age group | 50–59, 56.8% churn |
| Highest-risk product count | 3–4 products, 79–100% churn |
| Inactive vs. active members | Inactive members churn 1.51x more often (25.2% vs 16.7%) |
| Customers currently at high risk | 1,525 customers holding $135.3M in balances |
| Top 3 target segments' share of lost revenue | 28.9% of all balance lost ($53.8M of $186.3M) |

**The core insight:** churn is not evenly distributed. It concentrates in a small number of identifiable segments, most notably German customers aged 40–59 who are inactive or hold an unusual number of products. Retention spend aimed at these segments would reach a disproportionate share of at-risk revenue.

## Tools & Skills Demonstrated

- **Excel** — data cleaning, deduplication, standardization, pivot tables
- **SQL** — views, CTEs, window functions (`RANK() OVER PARTITION BY`), CASE-based segmentation, aggregate KPIs
- **Power BI** — data modeling, DAX measures, and an 3-page interactive dashboard using 11+ visual types (donut, bar, stacked column, matrix heatmap, scatter/bubble, line, treemap, waterfall, gauge, and formatted tables)

## Project Structure

```
├── data/
│   ├── bank_churn_raw.csv          # Raw data with intentional quality issues
│   └── bank_churn_clean.csv        # Cleaned dataset (10,000 rows)
├── sql/
│   └── churn_analysis.sql          # Full SQL script: setup, KPIs, segmentation, views
├── excel/
│   └── churn_sql_results.xlsx      # SQL query results exported for Power BI
├── powerbi/
│   └── bank_churn_dashboard.pbix   # The Power BI dashboard file
├── screenshots/
│   └── (dashboard page screenshots)
└── README.md
```

## Methodology

1. **Data cleaning (Excel):** started from a raw export with duplicate rows, inconsistent text casing, and missing values. Standardized categorical fields, removed duplicates, and validated row counts before moving to SQL.
2. **Analysis (SQL):** built a banded view (`customer_banded`) that groups customers into age, credit score, balance, and tenure bands. Wrote KPI queries, ranked segments by churn rate using window functions, and created a scored `high_risk_customers` view (0–8 point risk score based on age, activity, geography, product count, and balance) to flag current customers who resemble past churners.
3. **Visualization (Power BI):** loaded the SQL query results, modeled the relationships, and built DAX measures for churn rate, retention rate, balance lost, and active rate. Designed a 3-page dashboard:
   - **Executive overview** — headline KPIs and churn by country and gender
   - **Customer segments** — churn by age, products, tenure, and a country-by-age heatmap
   - **High-value customers at risk** — the business case: which segments to target and the estimated revenue that could be saved

## Business Recommendation

Retention efforts should prioritize German customers aged 40–59, particularly those who are inactive. This single segment accounts for the largest concentration of at-risk revenue. Assuming a conservative 25% reduction in churn from targeted outreach, the top 3 segments alone represent an estimated $13.5M in preventable revenue loss.

## How to Reproduce

1. Load `data/bank_churn_raw.csv` and clean it following the steps documented in `sql/churn_analysis.sql`'s comments (or use `bank_churn_clean.csv` directly).
2. Run `sql/churn_analysis.sql` against a SQL Server, MySQL, PostgreSQL, or SQLite database.
3. Export each query's results and load them into `excel/churn_sql_results.xlsx` (one sheet per query).
4. Open `powerbi/bank_churn_dashboard.pbix` in Power BI Desktop and point it at the Excel workbook, or rebuild the dashboard using the measures and visuals described above.

## Author

Mohammed — Data Analyst
GitHub: [github.com/mohammedykabonadi-eng](https://github.com/mohammedykabonadi-eng)
