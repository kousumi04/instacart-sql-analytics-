-- 1. Create independent catalog tables first
CREATE TABLE departments (
    department_id INTEGER PRIMARY KEY,
    department VARCHAR(255) NOT NULL
);

CREATE TABLE aisles (
    aisle_id INTEGER PRIMARY KEY,
    aisle VARCHAR(255) NOT NULL
);

-- 2. Create the products table (Child of departments and aisles)
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    aisle_id INTEGER,
    department_id INTEGER,
    FOREIGN KEY (aisle_id) REFERENCES aisles(aisle_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 3. Create the orders table (Independent event table)
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    user_id INTEGER,
    eval_set VARCHAR(50),
    order_number INTEGER,
    order_dow INTEGER, -- Day of week
    order_hour_of_day INTEGER,
    days_since_prior_order NUMERIC(5,1) -- Allows decimals like 15.0 based on your CSV screenshots
);

-- 4. Create the bridge table (Child of orders and products)
CREATE TABLE order_products (
    order_id INTEGER,
    product_id INTEGER,
    add_to_cart_order INTEGER,
    reordered INTEGER,
    PRIMARY KEY (order_id, product_id), -- Composite Primary Key
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);