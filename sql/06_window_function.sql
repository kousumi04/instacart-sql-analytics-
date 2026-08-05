-- 1. Sequencing: Find the chronological order sequence for specific customers
-- We partition by user_id (so the counter resets for each new user) 
-- and order by the order_number so the earliest order gets ROW_NUMBER = 1.
SELECT 
    user_id,
    order_id,
    order_number,
    days_since_prior_order,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_number ASC) AS user_order_sequence
FROM orders
WHERE user_id IN (1, 2)
LIMIT 15;

-- 2. Running Totals: Track the cumulative count of items added to the cart for a specific order
-- We partition by order_id (the receipt) and order by the exact sequence the item was added.
SELECT 
    order_id,
    product_id,
    add_to_cart_order,
    COUNT(product_id) OVER (
        PARTITION BY order_id 
        ORDER BY add_to_cart_order
    ) AS cumulative_items_in_cart
FROM order_products
WHERE order_id = 2;