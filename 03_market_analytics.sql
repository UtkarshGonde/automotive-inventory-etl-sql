-- Query 1: Days on Market (DOM) & Market Days Supply (MDS)

SELECT make,
        model,
        ROUND(AVG(CASE WHEN status = 'SOLD' THEN last_seen_date - first_seen_date END),1) avg_days_on_market,
        ROUND(
            COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) / 
            NULLIF(COUNT(CASE WHEN status = 'SOLD' AND ('2026-11-18'::DATE - last_seen_date) <= 30 THEN 1 END) / 30.0, 0), 
        1) AS market_days_supply

FROM clean_inventory
GROUP BY make,model;

-- Query 2 : Locak Dealership Market Share by City

SELECT d.city,
        d.dealer_name,
        COUNT(c.vin) active_cars,
        SUM(COUNT(c.vin)) OVER( PARTITION BY d.city) city_total_cars,
        ROUND(COUNT(c.vin) * 100.0 / NULLIF(SUM(COUNT(c.vin)) OVER( PARTITION BY d.city),0),2) market_share_pct
FROM dealers d LEFT JOIN clean_inventory c 
ON d.dealer_id = c.dealer_id AND c.status = 'ACTIVE'
GROUP BY d.dealer_id,d.city, d.dealer_name
ORDER BY d.city, market_share_pct DECS;

-- Query 3: Fair Market Value Quartiles (25th, Median, 75th Percentiles)
SELECT 
    make,
    model,
    COUNT(*) AS active_listings,
    ROUND(AVG(price)) AS avg_price,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price)) AS p25_price,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price)) AS median_price,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price)) AS p75_price
FROM clean_inventory
WHERE status = 'ACTIVE'
GROUP BY make, model
ORDER BY make ASC, model ASC;

-- Query 4: Same-City Competitor Price Undercuts
SELECT 
    d1.city,
    d1.dealer_name AS overpriced_dealer,
    a.vin AS overpriced_vin,
    a.price AS asking_price,
    d2.dealer_name AS cheaper_competitor,
    b.vin AS competitor_vin,
    b.price AS competitor_price,
    (a.price - b.price) AS price_diff
FROM clean_inventory a
INNER JOIN dealers d1 
    ON a.dealer_id = d1.dealer_id
INNER JOIN clean_inventory b 
    ON a.make = b.make 
   AND a.model = b.model 
   AND a.model_year = b.model_year
   AND a.dealer_id <> b.dealer_id
   AND a.price > b.price
INNER JOIN dealers d2 
    ON b.dealer_id = d2.dealer_id
   AND d1.city = d2.city
WHERE a.status = 'ACTIVE' 
  AND b.status = 'ACTIVE'
ORDER BY d1.city ASC, price_diff DESC;
