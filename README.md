# 🚗 Automotive Inventory ETL & Market Valuation Pipeline (PostgreSQL)

An end-to-end **SQL Data Engineering & Business Intelligence project** modeled after automotive market intelligence platforms (such as MarketCheck). This pipeline ingests raw, messy dealership web scrapes, deduplicates multi-source vehicle listings, synchronizes master inventory via atomic `MERGE` upserts, and calculates real-time automotive pricing KPIs.

---

## 🏗️ Pipeline Architecture

```text
+---------------------------+      +-----------------------------------+      +---------------------------+

|  raw_scraped_listings     | ---> |  02_etl_clean_and_merge.sql       | ---> |  clean_inventory          |
|  (Dirty Web Scrape Feed)  |      |  - Regex + NULLIF Price Cleaning  |      |  (Master Production Table)|
|  - Duplicate VINs         |      |  - Franchise-Priority Dedup (CTE) |      |  - Active & Sold Status   |
|  - "$24,200" / "$0" / Text|      |  - Atomic MERGE (Upsert + Sold)   |      |  - First/Last Seen Dates  |
+---------------------------+      +-----------------------------------+      +---------------------------+
                                                                                            |
                                                                                            v
                                                                              +---------------------------+

                                                                              |  03_market_analytics.sql  |
                                                                              |  - Days on Market (DOM)   |
                                                                              |  - Market Days Supply     |
                                                                              |  - Median & Quartile FMV  |
                                                                              |  - Local Market Share     |
                                                                              |  - Competitor Undercuts   |
                                                                              +---------------------------+
```

---

## 📂 Repository Structure

| File | Description |
| :--- | :--- |
| `01_schema_and_seed_data.sql` | Creates relational tables (`dealers`, `raw_scraped_listings`, `clean_inventory`) and loads realistic dirty web-scrape test data. |
| `02_etl_clean_and_merge.sql` | Cleans messy text prices via `REGEXP_REPLACE` + `NULLIF`, deduplicates VINs prioritizing franchise dealers (`ROW_NUMBER()`), and syncs inventory using PostgreSQL `MERGE INTO`. |
| `03_market_analytics.sql` | Calculates automotive KPIs: Days on Market (DOM), Market Days Supply (MDS), Interquartile Fair Market Value (`PERCENTILE_CONT`), Local Market Share, and Same-City Competitor Undercuts. |

---

## 🛠️ Key Data Engineering Edge Cases Solved

* **Safe Type Casting Without Pipeline Crashes:** Raw scrapes often include strings like `'Call for Price'` or `'\$0'`. Combined `REGEXP_REPLACE(..., '[^0-9]', '', 'g')` with `NULLIF(..., '')` before `CAST(... AS INTEGER)` and filtered out invalid outliers (`<= 500`).
* **Preventing `MERGE` Cardinality Runtime Errors:** Normalized keys (`UPPER(TRIM(vin))`) *inside* the `PARTITION BY` clause before deduplicating so messy spacing (`' vin1001 '` vs `'VIN1001'`) never causes multiple source rows to collide on a single target row.
* **Source Prioritization:** Ranked same-day duplicate scrapes using `ORDER BY d.is_franchise DESC, r.scraped_date DESC` so official franchise dealership listings override third-party aggregators.
* **Inferred Sales Tracking:** Used `WHEN NOT MATCHED BY SOURCE AND t.status = 'ACTIVE'` inside `MERGE` to automatically transition delisted vehicles to `'SOLD'`.
* **Divide-by-Zero & Integer Division Protection:** Used `NULLIF(..., 0)` in Market Days Supply denominators and explicit decimal multiplication (`* 100.0`) for accurate market share percentages.

---

## 🚀 How to Run

1. Open any **PostgreSQL 15+** environment (local `psql`, pgAdmin, or Supabase SQL Editor).
2. Execute `01_schema_and_seed_data.sql` to build the schema and load sample data.
3. Execute `02_etl_clean_and_merge.sql` to clean the staging feed and sync `clean_inventory`.
4. Execute `03_market_analytics.sql` to generate the business intelligence reports.
