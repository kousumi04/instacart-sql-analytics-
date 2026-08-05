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


-- Business Question 3: Peak Ordering Hours
-- Business Objective: Determine when the app experiences the most traffic to optimize server scaling and customer support staffing.
SELECT 
    order_hour_of_day,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY 
    order_hour_of_day
ORDER BY 
    total_orders DESC;


-- Business Question 4: Average Cart Size by Day of Week
-- Business Objective: Understand if users buy bulk groceries on weekends versus quick restocks on weekdays.
WITH CartSizes AS (
    SELECT 
        o.order_id,
        o.order_dow,
        COUNT(op.product_id) AS cart_size
    FROM orders o
    INNER JOIN order_products op 
        ON o.order_id = op.order_id
    GROUP BY 
        o.order_id,
        o.order_dow
)
SELECT 
    order_dow AS day_of_week,
    ROUND(AVG(cart_size), 2) AS avg_items_per_order
FROM CartSizes
GROUP BY 
    order_dow
ORDER BY 
    avg_items_per_order DESC;


-- Business Question 5: Customer Segmentation (User Tiers)
-- Business Objective: Segment the user base into distinct marketing tiers based on their lifetime order count.
WITH UserOrderCounts AS (
    SELECT 
        user_id,
        MAX(order_number) AS lifetime_orders
    FROM orders
    GROUP BY user_id
)
SELECT 
    CASE 
        WHEN lifetime_orders >= 50 THEN '1. Super User (50+)'
        WHEN lifetime_orders >= 20 THEN '2. Loyal User (20-49)'
        WHEN lifetime_orders >= 5 THEN '3. Regular User (5-19)'
        ELSE '4. Occasional User (<5)'
    END AS customer_segment,
    COUNT(user_id) AS total_customers
FROM UserOrderCounts
GROUP BY 
    customer_segment
ORDER BY 
    customer_segment ASC;


-- Business Question 6: The "App Opener" (Top First-in-Cart Products)
-- Business Objective: Identify the primary anchor products that drive users to open the app and start a shopping trip.
SELECT 
    p.product_name,
    COUNT(op.product_id) AS times_added_first
FROM order_products op
INNER JOIN products p 
    ON op.product_id = p.product_id
WHERE op.add_to_cart_order = 1
GROUP BY 
    p.product_name
ORDER BY 
    times_added_first DESC
LIMIT 10;


-- Business Question 7: Customer Return Frequency
-- Business Objective: Analyze the distribution of days between orders to understand the natural buying cycle of our users.
SELECT 
    days_since_prior_order,
    COUNT(order_id) AS total_orders
FROM orders
WHERE days_since_prior_order IS NOT NULL
GROUP BY 
    days_since_prior_order
ORDER BY 
    total_orders DESC
LIMIT 10;


-- Business Question 8: Drill-Down (Top Aisles within the Top Department)
-- Business Objective: We know 'Produce' is the biggest department. Let's drill down into the specific aisles within Produce to see where the volume actually is.
SELECT 
    a.aisle,
    COUNT(op.product_id) AS total_items_sold
FROM order_products op
INNER JOIN products p 
    ON op.product_id = p.product_id
INNER JOIN departments d 
    ON p.department_id = d.department_id
INNER JOIN aisles a 
    ON p.aisle_id = a.aisle_id
WHERE 
    d.department = 'produce'
GROUP BY 
    a.aisle
ORDER BY 
    total_items_sold DESC;


-- Business Question 9: Organic vs. Non-Organic Product Volume
-- Business Objective: Determine what percentage of our total items sold are organic by searching for the word "Organic" in the product name.
WITH OrganicCategorization AS (
    SELECT 
        op.product_id,
        CASE 
            WHEN p.product_name ILIKE '%organic%' THEN 'Organic'
            ELSE 'Non-Organic'
        END AS product_type
    FROM order_products op
    INNER JOIN products p 
        ON op.product_id = p.product_id
)
SELECT 
    product_type,
    COUNT(*) AS total_items_sold
FROM OrganicCategorization
GROUP BY 
    product_type
ORDER BY 
    total_items_sold DESC;


-- Business Question 10: The "One and Done" Products (Lowest Reorder Rates)
-- Business Objective: Identify inventory that customers try once and never buy again. We filter for products ordered at least 100 times to remove statistical noise from rare items.
WITH ProductReorders AS (
    SELECT 
        p.product_name,
        COUNT(op.product_id) AS total_orders,
        AVG(op.reordered) AS reorder_rate
    FROM order_products op
    INNER JOIN products p 
        ON op.product_id = p.product_id
    GROUP BY 
        p.product_name
)
SELECT 
    product_name,
    total_orders,
    ROUND(reorder_rate * 100, 2) AS reorder_rate_percentage
FROM ProductReorders
WHERE 
    total_orders > 100
ORDER BY 
    reorder_rate_percentage ASC
LIMIT 10;


-- Business Question 11: Basket Size Distribution
-- Business Objective: Categorize shopping trips into size buckets to understand if Instacart is primarily used for quick convenience or bulk weekly shopping.
WITH OrderSizes AS (
    SELECT 
        order_id,
        COUNT(product_id) AS item_count
    FROM order_products
    GROUP BY order_id
),
SizeBuckets AS (
    SELECT 
        order_id,
        CASE 
            WHEN item_count <= 5 THEN '1. Quick Trip (1-5 items)'
            WHEN item_count <= 15 THEN '2. Standard (6-15 items)'
            WHEN item_count <= 30 THEN '3. Large (16-30 items)'
            ELSE '4. Stock Up (31+ items)'
        END AS basket_size_category
    FROM OrderSizes
)
SELECT 
    basket_size_category,
    COUNT(order_id) AS total_orders
FROM SizeBuckets
GROUP BY 
    basket_size_category
ORDER BY 
    basket_size_category ASC;