-- 1. Department Size: Count how many unique products exist in each department.
-- We join products to departments, group them by the department name, and count the rows.
SELECT 
    d.department,
    COUNT(p.product_id) AS total_products
FROM departments d
INNER JOIN products p 
    ON d.department_id = p.department_id
GROUP BY 
    d.department
ORDER BY 
    total_products DESC;

-- 2. Massive Orders: Find specific orders that contain more than 25 items.
-- Here we group by the receipt (order_id), count the items, and use HAVING to filter the results.
SELECT 
    op.order_id,
    COUNT(op.product_id) AS items_in_cart
FROM order_products op
GROUP BY 
    op.order_id
HAVING 
    COUNT(op.product_id) > 25
ORDER BY 
    items_in_cart DESC
LIMIT 10;