CREATE TABLE users_enriched (
    id INT NOT NULL PRIMARY KEY,
    age INT,
    gender VARCHAR(255),
    country VARCHAR(255),
    city VARCHAR(255),
    first_traffic_source VARCHAR(255),
    last_traffic_source VARCHAR(255),
    created_at TIMESTAMP,
    first_order_date TIMESTAMP,
    last_order_date TIMESTAMP,
    days_to_activation INT,
    active_days INT,
    inactive_days INT,
    avg_days_to_order INT,
    std_days_to_order INT,
    n_orders INT,
    avg_order_items INT,
    avg_item_value FLOAT,
    avg_order_value FLOAT,
    first_order_categories VARCHAR(255)[],
    purchased_categories VARCHAR(255)[],
    segment VARCHAR(255),
    churn_status VARCHAR(255)
)