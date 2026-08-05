-- Business Question 1: Top 10 Most Popular Products
-- Business Objective: Identify which inventory items drive the most volume to ensure they are never out of stock.
SELECT 
    p.product_name,
    COUNT(op.product_id) AS total_times_ordered
FROM order_products op
INNER JOIN products p 
    ON op.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    total_times_ordered DESC
LIMIT 10;


-- Business Question 2: Department Reorder Rates
-- Business Objective: Determine which departments drive customer loyalty. 
-- The "reordered" column is a 1 (Yes) or 0 (No). Taking the AVG() of a 1/0 column mathematically gives you the percentage rate!
WITH DepartmentReorders AS (
    SELECT 
        d.department,
        op.reordered
    FROM order_products op
    INNER JOIN products p 
        ON op.product_id = p.product_id
    INNER JOIN departments d 
        ON p.department_id = d.department_id
)
SELECT 
    department,
    COUNT(*) AS total_items_sold,
    ROUND(AVG(reordered) * 100, 2) AS reorder_rate_percentage
FROM DepartmentReorders
GROUP BY 
    department
ORDER BY 
    reorder_rate_percentage DESC;