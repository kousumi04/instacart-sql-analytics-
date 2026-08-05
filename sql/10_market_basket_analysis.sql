-- Market Basket Analysis: Top 10 Product Pairs
WITH ProductPairs AS (
    -- Step 1: Join the order_products table to itself to find pairs in the same cart
    SELECT 
        op1.product_id AS product_1_id,
        op2.product_id AS product_2_id,
        COUNT(*) AS times_bought_together
    FROM order_products op1
    INNER JOIN order_products op2
        ON op1.order_id = op2.order_id
        AND op1.product_id < op2.product_id -- Prevents A-A duplicates and B-A reverse duplicates
    GROUP BY 
        op1.product_id, 
        op2.product_id
)
-- Step 2: Translate the raw IDs into human-readable product names
SELECT 
    p1.product_name AS product_1_name,
    p2.product_name AS product_2_name,
    pp.times_bought_together
FROM ProductPairs pp
INNER JOIN products p1 
    ON pp.product_1_id = p1.product_id
INNER JOIN products p2 
    ON pp.product_2_id = p2.product_id
ORDER BY 
    pp.times_bought_together DESC
LIMIT 10;