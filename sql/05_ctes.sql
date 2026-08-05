-- 1. Average Basket Size
-- First, count items per order. Then, take the average of those counts.
WITH OrderItemCounts AS (
    SELECT 
        order_id,
        COUNT(product_id) AS total_items
    FROM order_products
    GROUP BY order_id
)
SELECT 
    ROUND(AVG(total_items), 2) AS average_basket_size
FROM OrderItemCounts;


-- 2. Multi-Step Logic: Products in Top 3 Departments
-- Step A: Find the IDs of the top 3 biggest departments
WITH TopDepartments AS (
    SELECT 
        department_id,
        COUNT(product_id) AS product_count
    FROM products
    GROUP BY department_id
    ORDER BY product_count DESC
    LIMIT 3
)
-- Step B: Join that temporary result to our main tables
SELECT 
    p.product_name,
    d.department,
    td.product_count AS department_total_size
FROM products p
INNER JOIN departments d 
    ON p.department_id = d.department_id
INNER JOIN TopDepartments td 
    ON p.department_id = td.department_id
LIMIT 15;