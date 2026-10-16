create database ecom_funnel;
use ecom_funnel;
create table events_raw (
	event_time VARCHAR(40),
    event_type VARCHAR(20),
    product_id BIGINT,
    category_id BIGINT,
    category_code VARCHAR(100),
    brand VARCHAR(100),
    price DECIMAL(10,2),
    user_id BIGINT,
    user_session VARCHAR(64)
  );
  
  describe events_raw;
 
  SHOW VARIABLES LIKE 'local_infile';
  
  use ecom_funnel;

-- LOADING DATA  
LOAD DATA LOCAL INFILE 'C:/Users/simra/OneDrive/Documents/MBA/PROJECTS/ecommerce-funnel-diagnosis/ecommerce-funnel-diagnosis/data/2019-Oct.csv'
INTO TABLE events_raw
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(event_time, event_type, product_id, category_id, @cc, @brand, price, user_id, user_session)
SET category_code = NULLIF(@cc,''),
    brand = NULLIF(@brand,'');
    
LOAD DATA LOCAL INFILE 'C:/Users/simra/OneDrive/Documents/MBA/PROJECTS/ecommerce-funnel-diagnosis/ecommerce-funnel-diagnosis/data/2019-Nov.csv'
INTO TABLE events_raw
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(event_time, event_type, product_id, category_id, @cc, @brand, price, user_id, user_session)
SET category_code = NULLIF(@cc,''),
    brand = NULLIF(@brand,'');
    
LOAD DATA LOCAL INFILE 'C:/Users/simra/OneDrive/Documents/MBA/PROJECTS/ecommerce-funnel-diagnosis/ecommerce-funnel-diagnosis/data/2019-Dec.csv'
INTO TABLE events_raw
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(event_time, event_type, product_id, category_id, @cc, @brand, price, user_id, user_session)
SET category_code = NULLIF(@cc,''),
    brand = NULLIF(@brand,'');
    
LOAD DATA LOCAL INFILE 'C:/Users/simra/OneDrive/Documents/MBA/PROJECTS/ecommerce-funnel-diagnosis/ecommerce-funnel-diagnosis/data/2020-Jan.csv'
INTO TABLE events_raw
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(event_time, event_type, product_id, category_id, @cc, @brand, price, user_id, user_session)
SET category_code = NULLIF(@cc,''),
    brand = NULLIF(@brand,'');
    
LOAD DATA LOCAL INFILE 'C:/Users/simra/OneDrive/Documents/MBA/PROJECTS/ecommerce-funnel-diagnosis/ecommerce-funnel-diagnosis/data/2020-Feb.csv'
INTO TABLE events_raw
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(event_time, event_type, product_id, category_id, @cc, @brand, price, user_id, user_session)
SET category_code = NULLIF(@cc,''),
    brand = NULLIF(@brand,'');

-- ROW COUNT AND DATE RANGE    
SELECT COUNT(*) AS total_rows,
       MIN(event_time) AS first_event,
       MAX(event_time) AS last_event
FROM events_raw;

-- EVENTS BY MONTH AND TYPE
SELECT LEFT(event_time, 7) AS month, event_type, COUNT(*) AS events
FROM events_raw
GROUP BY LEFT(event_time, 7), event_type
ORDER BY month, event_type;

-- MISSING DATA
SELECT COUNT(*) AS total_rows,
       SUM(category_code IS NULL) AS null_category_code,
       SUM(brand IS NULL) AS null_brand,
       SUM(price IS NULL) AS null_price
FROM events_raw;

SELECT event_type,
       COUNT(*) AS rows_cnt,
       SUM(price = 0) AS zero_rows,
       SUM(price < 0) AS negative_rows
FROM events_raw
WHERE price <= 0
GROUP BY event_type;

SELECT COUNT(DISTINCT user_id) FROM events_raw;

SELECT COUNT(DISTINCT user_session) FROM events_raw;

CREATE TABLE events_clean (
  event_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  event_time DATETIME NOT NULL,
  event_type VARCHAR(20) NOT NULL,
  product_id BIGINT,
  category_id BIGINT,
  category_code VARCHAR(100),
  brand VARCHAR(100),
  price DECIMAL(10,2),
  price_was_zero TINYINT NOT NULL DEFAULT 0,
  user_id BIGINT NOT NULL,
  user_session VARCHAR(64) NOT NULL
);

INSERT INTO events_clean
  (event_time, event_type, product_id, category_id, category_code, brand,
   price, price_was_zero, user_id, user_session)
SELECT STR_TO_DATE(LEFT(event_time, 19), '%Y-%m-%d %H:%i:%s'),
       event_type, product_id, category_id, category_code, brand,
       NULLIF(price, 0),
       (price = 0),
       user_id, user_session
FROM events_raw
WHERE price >= 0;

SELECT COUNT(*) AS total_rows,
       SUM(price IS NULL) AS null_price,
       SUM(price_was_zero) AS zero_flag,
       MIN(event_time), MAX(event_time)
FROM events_clean;