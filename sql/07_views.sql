-- 1. Create the View
CREATE OR REPLACE VIEW vw_department_reorder_rates AS
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
    department;

-- 2. Query the View (Notice how much cleaner this is!)
SELECT * 
FROM vw_department_reorder_rates 
ORDER BY reorder_rate_percentage DESC;