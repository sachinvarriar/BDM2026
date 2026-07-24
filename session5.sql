CREATE TABLE supermarket.PRODUCTS (
product_id serial primary key,
sku varchar(50),
name varchar(100),
description TEXT,
unit_price numeric(10,2) not null,
cost_price numeric(10,2) not null,
is_deleted boolean,
created_at timestamp,
updated_at timestamp
)


CREATE TABLE supermarket.customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE supermarket.payment_modes (
    payment_mode_id SERIAL PRIMARY KEY,
    mode_name VARCHAR(50) NOT NULL -- e.g., 'Cash', 'Credit Card', 'UPI'
);

CREATE TABLE supermarket.invoices (
    invoice_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES supermarket.customers(customer_id),
    product_id INT REFERENCES supermarket.PRODUCTS(product_id),
    payment_mode_id INT REFERENCES supermarket.payment_modes(payment_mode_id),
    quantity INT NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL,
    extra_details JSONB, -- The single JSONB column for flexible metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1. Insert sample products (using your provided PRODUCTS schema structure)
INSERT INTO supermarket.PRODUCTS (sku, name, description, unit_price, cost_price, is_deleted, created_at, updated_at) VALUES
('SKU-MILK-001', 'Whole Milk 1L', 'Fresh pasteurized whole milk', 2.50, 1.80, FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('SKU-BREAD-002', 'Sourdough Bread', 'Artisanal freshly baked sourdough loaf', 4.00, 2.20, FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('SKU-EGGS-003', 'Free Range Eggs (Dozen)', 'Grade A large free range eggs', 5.50, 3.80, FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 2. Insert sample customers
INSERT INTO supermarket.customers (name, email, phone) VALUES
('Alice Smith', 'alice.smith@example.com', '555-0101'),
('Bob Jones', 'bob.jones@example.com', '555-0202');

-- 3. Insert sample payment modes
INSERT INTO supermarket.payment_modes (mode_name) VALUES
('Cash'),
('Credit Card'),
('Mobile Payment');

-- 4. Insert sample invoices (incorporating the foreign keys and JSONB metadata)
INSERT INTO supermarket.invoices (customer_id, product_id, payment_mode_id, quantity, total_amount, extra_details) VALUES
(
    1, 
    1, 
    2, 
    2, 
    5.00, 
    '{"discount_applied": 0.00, "cashier": "John Doe", "store_location": "Downtown Branch"}'
),
(
    2, 
    3, 
    3, 
    1, 
    5.50, 
    '{"discount_applied": 0.50, "promo_code": "WELCOME10", "store_location": "Uptown Branch"}'
);


SELECT * FROM supermarket.products


SELECT a.invoice_id,a.product_id,b.name ,a.extra_details->'promo_code' as promo_code
 FROM supermarket.invoices a
 inner join supermarket.products b
 on a.product_id=b.product_id