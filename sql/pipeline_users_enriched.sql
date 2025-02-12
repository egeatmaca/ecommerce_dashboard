BEGIN;

TRUNCATE TABLE users_enriched;

-- Deduplicate users based on email
WITH users_deduplicated AS (
    SELECT DISTINCT ON (email)
        id, email, age, gender, country, city, traffic_source,
        MIN(created_at) OVER (PARTITION BY email) AS created_at
    FROM users
    ORDER BY email, created_at DESC
), 
-- Agg. order item values by orders (including user emails)
email_orders AS (
    SELECT u.email, oie.order_id,
        MIN(oie.created_at) AS created_at,
        COUNT(*) AS n_order_items,
        SUM(oie.sale_price) AS order_value,
        ARRAY_AGG(oie.product_category) AS purchased_categories,
        ARRAY_AGG(oie.product_brand) AS purchased_brands
    FROM order_items_enriched AS oie
    LEFT JOIN users AS u
    ON oie.user_id = u.id
    GROUP BY u.email, oie.order_id
    ORDER BY u.email, created_at
), 
-- Calculate time-to-order
email_orders_times AS (
    SELECT *,
        EXTRACT(DAY FROM 
            created_at - LAG(created_at)
            OVER (PARTITION BY email ORDER BY created_at ASC)
        ) AS days_to_order
    FROM email_orders
), 
-- Agg. orders by email
email_purchases AS (
    SELECT email,
        COUNT(DISTINCT order_id) AS n_orders,
        AVG(n_order_items) AS avg_order_items, 
        SUM(order_value) / SUM(n_order_items) AS avg_item_value,
        AVG(order_value) AS avg_order_value,
        MIN(created_at) AS first_order_timestamp,
        MAX(created_at) AS last_order_timestamp,
        AVG(days_to_order) AS avg_days_to_order,
        COALESCE(STDDEV(days_to_order), 0) AS std_days_to_order
    FROM email_orders_times
    GROUP BY email
),
-- Get values for first orders of emails
email_orders_numbered AS (
    SELECT *,
        ROW_NUMBER() 
            OVER (PARTITION BY email ORDER BY created_at)
            AS order_number
    FROM email_orders
), email_first_orders AS (
    SELECT email, order_id, created_at, 
           order_value, purchased_categories, purchased_brands
    FROM email_orders_numbered
    WHERE order_number = 1
), 
-- Join deduplicated users and values aggregated by emails
users_with_purchases AS (
    SELECT
        u.id,
        u.age,
        u.gender,
        COALESCE(
            CASE WHEN u.country = 'España' THEN 'Spain' END,
            CASE WHEN country = 'Deutschland' THEN 'Germany' END,
            country
        ) AS country,
        u.city,
        u.traffic_source,
        u.created_at,
        p.first_order_timestamp,
        p.last_order_timestamp,
        EXTRACT(DAY FROM 
            p.first_order_timestamp - u.created_at
        ) AS days_to_activation,
        EXTRACT(DAY FROM 
            p.last_order_timestamp - p.first_order_timestamp
        ) AS active_days,
        EXTRACT(DAY FROM 
            CURRENT_TIMESTAMP - p.last_order_timestamp
        ) AS inactive_days,
        p.avg_days_to_order,
        p.std_days_to_order,
        COALESCE(p.n_orders, 0) AS n_orders,
        p.avg_order_items AS avg_order_items,
        p.avg_item_value AS avg_item_value,
        p.avg_order_value AS avg_order_value,
        fo.order_value AS first_order_value,
        fo.purchased_categories AS first_order_categories,
        fo.purchased_brands AS first_order_brands
    FROM users_deduplicated AS u
    LEFT JOIN email_purchases AS p
    ON u.email = p.email
    LEFT JOIN email_first_orders AS fo
    ON u.email = fo.email
    ORDER BY created_at
), 
-- Calculate usere lifetime status
users_with_lt_status AS (
    SELECT *,
        CASE
            WHEN n_orders = 0 THEN 'Inactive'
            WHEN n_orders = 1 THEN 'One-Off Purchaser'
            WHEN inactive_days > avg_days_to_order + 2 * std_days_to_order THEN 'Churn Likely'
            ELSE 'Repeat Purchaser'
        END AS lifetime_status
    FROM users_with_purchases
)

INSERT INTO users_enriched (
    id, age, gender, country, city, traffic_source,
    created_at, first_order_timestamp, last_order_timestamp, 
    days_to_activation, active_days, inactive_days,
    avg_days_to_order, std_days_to_order, 
    n_orders, avg_order_items, avg_item_value, avg_order_value, 
    first_order_value, first_order_categories, first_order_brands,
    lifetime_status
)
SELECT id, age, gender, country, city, traffic_source,
    created_at, first_order_timestamp, last_order_timestamp, 
    days_to_activation, active_days, inactive_days,
    avg_days_to_order, std_days_to_order, 
    n_orders, avg_order_items, avg_item_value, avg_order_value,
    first_order_value, first_order_categories, first_order_brands,
    lifetime_status
FROM users_with_lt_status;

COMMIT;





