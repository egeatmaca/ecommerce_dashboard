CREATE TABLE order_items_enriched (
    id INT NOT NULL PRIMARY KEY,
    order_id INT NOT NULL,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    inventory_item_id INT NOT NULL,
    status VARCHAR(255),
    created_at TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    returned_at TIMESTAMP,
    sale_price FLOAT,
    cost FLOAT,
    product_category VARCHAR(255),
    product_department VARCHAR(255),
    product_brand VARCHAR(255),
    product_name VARCHAR(255),
    distribution_center VARCHAR(255),
    user_age INT,
    user_gender VARCHAR(50),
    user_county VARCHAR(255),
    user_city VARCHAR(255),
    user_traffic_source VARCHAR(255)
);
