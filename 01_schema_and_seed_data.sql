DROP TABLE IF EXISTS clean_inventory CASCADE;
DROP TABLE IF EXISTS raw_scraped_listings CASCADE;
DROP TABLE IF EXISTS dealers CASCADE;


-- dealser table (dimensin table)

CREATE TABLE dealers (
    dealer_id INT PRIMARY KEY,
    dealer_name TEXT,
    city TEXT,
    is_franchise BOOLEAN DEFAULT FALSE
);

-- raw_scraped_listings (Staging table)
CREATE TABLE raw_scraped_listings(
    scraped_id SERIAL PRIMARY KEY,
    vin TEXT,
    dealer_id INT,
    raw_make TEXT,
    raw_model TEXT,
    raw_year TEXT,
    raw_price TEXT,
    scraped_date TIMESTAMP    
);

-- clean_inventory (Production Target Table)
CREATE TABLE clean_inventory(
    vin VARCHAR(20) PRIMARY KEY,
    dealer_id INT REFERENCES dealers(dealer_id),
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    model_year INTEGER, 
    price INTEGER,
    status TEXT DEFAULT 'ACTIVE',
    first_seen_date DATE,
    last_seen_date DATE 

)

-- 1. Seed Dealers (2 in Austin, 1 in Dallas)
INSERT INTO dealers (dealer_id, dealer_name, city, is_franchise) VALUES
(101, 'Capital Honda',      'Austin', TRUE),
(102, 'Lone Star Auto Lot', 'Austin', FALSE),
(103, 'Metro Ford',         'Dallas', TRUE);

-- 2. Seed Existing Clean Inventory (From yesterday's run: 2026-11-17)
INSERT INTO dealers (dealer_id, dealer_name, city, is_franchise) VALUES
(101, 'Capital Honda',      'Austin', TRUE),
(102, 'Lone Star Auto Lot', 'Austin', FALSE),
(103, 'Metro Ford',         'Dallas', TRUE);

INSERT INTO clean_inventory (vin, dealer_id, make, model, model_year, price, status, first_seen_date, last_seen_date) VALUES
('VIN1001', 101, 'HONDA', 'CIVIC', 2023, 25000, 'ACTIVE', '2026-11-10', '2026-11-17'),
('VIN1002', 102, 'FORD',  'F-150', 2022, 34000, 'ACTIVE', '2026-11-05', '2026-11-17');

INSERT INTO raw_scraped_listings (vin, dealer_id, raw_make, raw_model, raw_year, raw_price, scraped_date) VALUES
(' vin1001 ', 102, 'honda ', ' civic', '2023', '$24,800',        '2026-11-18 09:00:00'),
('VIN1001',   101, 'HONDA',  'Civic',  '2023', '$24,200',        '2026-11-18 11:30:00'),
('vin1003',   102, ' honda', 'civic ', '2023', '$23,500',        '2026-11-18 10:15:00'),
('VIN1004',   103, 'Ford',   'F-150',  '2022', '$36,500',        '2026-11-18 10:45:00'),
('VIN1005',   101, 'Honda',  'Civic',  '2023', '$25,900',        '2026-11-18 12:00:00'),
('VIN1006',   102, 'BMW',    'X5',     '2024', 'Call for Price', '2026-11-18 12:15:00'),
('VIN1007',   103, 'Audi',   'A4',     '2021', '$0',             '2026-11-18 12:30:00');