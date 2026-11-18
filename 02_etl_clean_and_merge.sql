WITH join_table AS (
    SELECT vin,
            dealer_id,
            make,
            model,
            model_year,
            clean_price,
            scraped_date
    FROM (
        SELECT UPPER(TRIM(r.vin)) vin,
        r.dealer_id,
        UPPER(TRIM(r.raw_make)) make,
        UPPER(TRIM(r.raw_model)) model,
        CAST(NULLIF(REGEXP_REPLACE(r.raw_year,'[^0-9]','','g'),'') AS INTEGER) model_year,
        CAST(NULLIF(REGEXP_REPLACE(r.raw_price, '[^0-9]','','g'),'') AS INTEGER) clean_price,
        DATE(r.scraped_date) scraped_date,
        ROW_NUMBER() OVER(PARTITION BY UPPER(TRIM(r.vin)) ORDER BY d.is_franchise DESC, r.scraped_date DESC ) rn
        FROM dealers d INNER JOIN raw_scraped_listings r 
        ON d.dealer_id = r.dealer_id
    ) t
    WHERE t.rn = 1 AND clean_price > 500


)

MERGE INTO clean_inventory t 
USING join_table s
ON t.vin = s.vin

WHEN MATCHED THEN 
    UPDATE SET
        dealer_id = s.dealer_id,
        price = s.clean_price,
        status = 'ACTIVE',
        last_seen_date = s.scraped_date
    
WHEN NOT MATCHED THEN
    INSERT(vin, dealer_id, make, model, model_year,price, status,first_seen_date,last_seen_date)
    VALUES(s.vin,s.dealer_id,s.make,s.model,s.model_year,s.clean_price,'ACTIVE',s.scraped_date,s.scraped_date)

WHEN NOT MATCHED BY SOURCE AND t.status = 'ACTIVE' THEN 
    UPDATE SET 
        status = 'SOLD';