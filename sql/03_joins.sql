-- 1. Two-Table Join: Show product names alongside their department names
-- We use 'p' and 'd' as aliases to make the query shorter.
SELECT 
    p.product_id, 
    p.product_name, 
    d.department
FROM products p
INNER JOIN departments d 
    ON p.department_id = d.department_id
LIMIT 10;

-- 2. Three-Table Join: Let's investigate a specific receipt (Order ID #2 from your screenshot)
-- We need to connect the bridge table (order_products) to the catalog (products)
SELECT 
    op.order_id,
    op.add_to_cart_order,
    p.product_name,
    p.department_id
FROM order_products op
INNER JOIN products p 
    ON op.product_id = p.product_id
WHERE op.order_id = 2
ORDER BY op.add_to_cart_order;