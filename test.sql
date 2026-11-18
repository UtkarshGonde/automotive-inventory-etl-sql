

SELECT 'dealers' AS table_name, COUNT(*) AS row_count FROM dealers;
UNION ALL
SELECT 'clean_inventory', COUNT(*) FROM clean_inventory
UNION ALL
SELECT 'raw_scraped_listings', COUNT(*) FROM raw_scraped_listings;
