-- 1. Exact Match: Find the product_id for "Banana"
-- We need single quotes around text values.
SELECT product_id, product_name, department_id 
FROM products 
WHERE product_name = 'Banana';

-- 2. Numeric Filtering & AND: Find weekend orders (Days 0 and 1) placed early in the morning (before 8 AM)
SELECT order_id, order_dow, order_hour_of_day 
FROM orders 
WHERE order_dow IN (0, 1) 
  AND order_hour_of_day < 8
LIMIT 10;

-- 3. The IN Operator: Find all products that belong to the "frozen" (id: 1) or "bakery" (id: 3) departments
SELECT product_id, product_name, department_id 
FROM products 
WHERE department_id IN (1, 3)
LIMIT 15;