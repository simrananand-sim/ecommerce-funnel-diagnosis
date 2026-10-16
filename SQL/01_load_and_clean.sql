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

CREATE INDEX idx_session ON events_clean (user_session);

CREATE INDEX idx_user_time ON events_clean (user_id, event_time);

CREATE INDEX idx_time_type ON events_clean (event_time, event_type);

SHOW INDEX FROM events_clean;

CREATE INDEX idx_dup ON events_clean (user_session, event_time, event_type, product_id);

SELECT COUNT(*) AS duplicate_groups,
       SUM(c - 1) AS extra_rows
FROM (
  SELECT COUNT(*) AS c
  FROM events_clean
  GROUP BY user_session, event_time, event_type, product_id
  HAVING COUNT(*) > 1
) d;

 SELECT user_session, event_time, event_type, product_id,
       COUNT(*) AS c, MIN(price) AS min_price, MAX(price) AS max_price
FROM events_clean
GROUP BY user_session, event_time, event_type, product_id
HAVING COUNT(*) > 1
LIMIT 10;

SELECT DATE_FORMAT(event_time, '%Y-%m') AS month, event_type,
       COUNT(*) AS duplicate_groups, SUM(c - 1) AS extra_rows
FROM (
  SELECT event_time, event_type, COUNT(*) AS c
  FROM events_clean
  GROUP BY user_session, event_time, event_type, product_id
  HAVING COUNT(*) > 1
) d
WHERE event_type IN ('cart', 'remove_from_cart')
GROUP BY DATE_FORMAT(event_time, '%Y-%m'), event_type
ORDER BY month, event_type;

SELECT COUNT(*) AS sessions,
       SUM(has_view) AS sessions_with_view,
       SUM(has_cart) AS sessions_with_cart,
       SUM(has_purchase) AS sessions_with_purchase,
       SUM(has_cart = 1 AND has_view = 0) AS cart_without_view,
       SUM(has_purchase = 1 AND has_cart = 0) AS purchase_without_cart,
       SUM(has_purchase = 1 AND has_view = 0) AS purchase_without_view
FROM (
  SELECT user_session,
         MAX(event_type = 'view') AS has_view,
         MAX(event_type = 'cart') AS has_cart,
         MAX(event_type = 'purchase') AS has_purchase
  FROM events_clean
  GROUP BY user_session
) s;

SELECT month,
       COUNT(*) AS sessions,
       SUM(has_view) AS with_view,
       SUM(has_cart) AS with_cart,
       SUM(has_purchase) AS with_purchase
FROM (
  SELECT user_session,
         DATE_FORMAT(MIN(event_time), '%Y-%m') AS month,
         MAX(event_type = 'view') AS has_view,
         MAX(event_type = 'cart') AS has_cart,
         MAX(event_type = 'purchase') AS has_purchase
  FROM events_clean
  GROUP BY user_session
) session_flags
GROUP BY month
ORDER BY month;

SELECT DATE(first_time) AS day,
       COUNT(*) AS sessions,
       SUM(has_cart) AS with_cart,
       SUM(has_purchase) AS with_purchase,
       ROUND(100 * SUM(has_purchase) / COUNT(*), 2) AS conv_pct
FROM (
  SELECT user_session,
         MIN(event_time) AS first_time,
         MAX(event_type = 'cart') AS has_cart,
         MAX(event_type = 'purchase') AS has_purchase
  FROM events_clean
  WHERE event_time >= '2019-11-14' AND event_time < '2019-12-07'
  GROUP BY user_session
) s
WHERE first_time >= '2019-11-15' AND first_time < '2019-12-06'
GROUP BY DATE(first_time)
ORDER BY day;

DELETE FROM sessions_summary WHERE user_session < '4';

CREATE INDEX idx_cover ON events_clean (user_session, event_time, event_type, user_id);

INSERT INTO sessions_summary
SELECT user_session, MIN(user_id), MAX(user_id), MIN(event_time),
       MAX(event_type = 'view'), MAX(event_type = 'cart'),
       MAX(event_type = 'purchase'), COUNT(*)
FROM events_clean
WHERE user_session < '4'
GROUP BY user_session;

INSERT INTO sessions_summary
SELECT user_session, MIN(user_id), MAX(user_id), MIN(event_time),
       MAX(event_type = 'view'), MAX(event_type = 'cart'),
       MAX(event_type = 'purchase'), COUNT(*)
FROM events_clean
WHERE user_session >= '4' AND user_session < '8'
GROUP BY user_session;

INSERT INTO sessions_summary
SELECT user_session, MIN(user_id), MAX(user_id), MIN(event_time),
       MAX(event_type = 'view'), MAX(event_type = 'cart'),
       MAX(event_type = 'purchase'), COUNT(*)
FROM events_clean
WHERE user_session >= '8' AND user_session < 'c'
GROUP BY user_session;

INSERT INTO sessions_summary
SELECT user_session, MIN(user_id), MAX(user_id), MIN(event_time),
       MAX(event_type = 'view'), MAX(event_type = 'cart'),
       MAX(event_type = 'purchase'), COUNT(*)
FROM events_clean
WHERE user_session >= 'c'
GROUP BY user_session;

CREATE INDEX idx_ss_time ON sessions_summary (first_time);

CREATE INDEX idx_ss_user ON sessions_summary (user_id);

SELECT COUNT(*), SUM(has_purchase) FROM sessions_summary;

SELECT COUNT(*) FROM sessions_summary WHERE user_id <> max_user_id;

CREATE TABLE user_first (
  user_id BIGINT PRIMARY KEY,
  user_first_time DATETIME
);

CREATE INDEX idx_ss_user_time ON sessions_summary (user_id, first_time);

SHOW INDEX FROM sessions_summary;

INSERT INTO user_first
SELECT user_id, MIN(first_time)
FROM sessions_summary
GROUP BY user_id;

SELECT COUNT(*), MIN(user_first_time), MAX(user_first_time)
FROM user_first;

SELECT DATE_FORMAT(s.first_time,'%Y-%m') AS month,
       COUNT(*) AS joined_sessions
FROM sessions_summary s
JOIN user_first u ON u.user_id = s.user_id
GROUP BY month
ORDER BY month;

SELECT DATE_FORMAT(s.first_time,'%Y-%m') AS month,
       (s.first_time = u.user_first_time) AS is_new,
       COUNT(*) AS sessions,
       SUM(s.has_cart) AS cart_sessions,
       SUM(s.has_purchase) AS purchase_sessions,
       ROUND(100*SUM(s.has_cart)/COUNT(*),2) AS cart_pct,
       ROUND(100*SUM(s.has_purchase)/COUNT(*),2) AS conv_pct
FROM sessions_summary s
JOIN user_first u ON u.user_id = s.user_id
GROUP BY month, is_new
ORDER BY month, is_new;


SELECT YEARWEEK(s.first_time,3) AS wk,
       MIN(DATE(s.first_time)) AS week_start,
       COUNT(*) AS new_sessions,
       ROUND(100*SUM(s.has_cart)/COUNT(*),2) AS cart_pct,
       ROUND(100*SUM(s.has_purchase)/COUNT(*),2) AS conv_pct
FROM sessions_summary s
JOIN user_first u ON u.user_id = s.user_id
WHERE s.first_time = u.user_first_time
  AND s.first_time < '2019-12-01'
GROUP BY wk
ORDER BY wk;

SELECT YEARWEEK(s.first_time,3) AS wk,
       MIN(DATE(s.first_time)) AS week_start,
       (s.first_time = u.user_first_time) AS is_new,
       COUNT(*) AS sessions,
       ROUND(100*SUM(s.has_cart)/COUNT(*),2) AS cart_pct,
       ROUND(100*SUM(s.has_purchase)/COUNT(*),2) AS conv_pct
FROM sessions_summary s
JOIN user_first u ON u.user_id = s.user_id
WHERE s.first_time >= '2019-10-14'
GROUP BY wk, is_new
ORDER BY wk, is_new;

SELECT DATE(s.first_time) AS d,
       COUNT(*) AS new_sessions,
       ROUND(100*SUM(s.has_cart)/COUNT(*),2) AS cart_pct,
       ROUND(100*SUM(s.has_purchase)/COUNT(*),2) AS conv_pct
FROM sessions_summary s
JOIN user_first u ON u.user_id = s.user_id
WHERE s.first_time = u.user_first_time
  AND s.first_time >= '2019-11-18'
  AND s.first_time <  '2019-12-12'
GROUP BY d
ORDER BY d;



CREATE TABLE zero_cart_sessions (user_session CHAR(36) PRIMARY KEY);

INSERT IGNORE INTO zero_cart_sessions
SELECT DISTINCT user_session FROM events_clean
WHERE event_time >= '2019-10-01' AND event_time < '2019-11-01'
  AND event_type = 'cart' AND price_was_zero = 1;
  
  INSERT IGNORE INTO zero_cart_sessions
SELECT DISTINCT user_session FROM events_clean
WHERE event_time >= '2019-11-01' AND event_time < '2019-12-01'
  AND event_type = 'cart' AND price_was_zero = 1;
  
  INSERT IGNORE INTO zero_cart_sessions
SELECT DISTINCT user_session FROM events_clean
WHERE event_time >= '2019-12-01' AND event_time < '2020-01-01'
  AND event_type = 'cart' AND price_was_zero = 1;
  
  INSERT IGNORE INTO zero_cart_sessions
SELECT DISTINCT user_session FROM events_clean
WHERE event_time >= '2020-01-01' AND event_time < '2020-02-01'
  AND event_type = 'cart' AND price_was_zero = 1;
  
  INSERT IGNORE INTO zero_cart_sessions
SELECT DISTINCT user_session FROM events_clean
WHERE event_time >= '2020-02-01' AND event_time < '2020-03-01'
  AND event_type = 'cart' AND price_was_zero = 1;

SELECT COUNT(*) FROM zero_cart_sessions;

SELECT DATE_FORMAT(s.first_time, '%Y-%m') AS month, COUNT(*) AS sessions
FROM zero_cart_sessions z
JOIN sessions_summary s ON s.user_session = z.user_session
GROUP BY month
ORDER BY month;

SELECT
  DATE_FORMAT(s.first_time, '%Y-%m')                              AS month,
  ROUND(100 * SUM(s.has_purchase) / COUNT(*), 2)                  AS conv_all,
  ROUND(100 * SUM(CASE WHEN z.user_session IS NULL THEN s.has_purchase END)
            / SUM(z.user_session IS NULL), 2)                     AS conv_excl_zero_cart
FROM sessions_summary s
LEFT JOIN zero_cart_sessions z ON z.user_session = s.user_session
GROUP BY month
ORDER BY month;

 SHOW CREATE TABLE sessions_summary;