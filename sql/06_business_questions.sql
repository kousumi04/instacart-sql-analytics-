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


-- Business Question 12: Churn Risk Assessment (Inactive Customers)
-- Business Objective: Identify high-value users who have hit the maximum trackable time between orders (30 days). These users are at risk of churning and should receive a re-engagement email with a discount code.
SELECT 
    user_id,
    MAX(days_since_prior_order) AS longest_gap,
    MAX(order_number) AS total_lifetime_orders
FROM orders
GROUP BY 
    user_id
HAVING 
    MAX(days_since_prior_order) = 30 
    AND MAX(order_number) > 10 -- Only target users who have proven they are valuable (10+ past orders)
ORDER BY 
    total_lifetime_orders DESC
LIMIT 15;


-- Business Question 13: Dayparting Analysis (Morning vs. Night Shopping)
-- Business Objective: Discover which departments sell best in the morning versus the evening to optimize app homepage banners based on the current time of day.
WITH DaypartSales AS (
    SELECT 
        d.department,
        CASE 
            WHEN o.order_hour_of_day BETWEEN 6 AND 11 THEN '1. Morning (6AM - 11AM)'
            WHEN o.order_hour_of_day BETWEEN 17 AND 22 THEN '2. Evening (5PM - 10PM)'
            ELSE '3. Other Times'
        END AS time_of_day,
        COUNT(op.product_id) AS items_sold
    FROM orders o
    INNER JOIN order_products op 
        ON o.order_id = op.order_id
    INNER JOIN products p 
        ON op.product_id = p.product_id
    INNER JOIN departments d 
        ON p.department_id = d.department_id
    GROUP BY 
        d.department, 
        time_of_day
)
SELECT 
    department,
    time_of_day,
    items_sold
FROM DaypartSales
WHERE 
    time_of_day IN ('1. Morning (6AM - 11AM)', '2. Evening (5PM - 10PM)')
ORDER BY 
    department ASC, 
    time_of_day ASC;


-- Business Question 14: The "Emergency Run" (Single-Item Orders)
-- Business Objective: Identify which products are most frequently bought entirely by themselves (a cart size of exactly 1). This indicates high-urgency items.
WITH SingleItemOrders AS (
    SELECT 
        order_id
    FROM order_products
    GROUP BY 
        order_id
    HAVING 
        COUNT(product_id) = 1
)
SELECT 
    p.product_name,
    COUNT(op.order_id) AS times_bought_alone
FROM SingleItemOrders sio
INNER JOIN order_products op 
    ON sio.order_id = op.order_id
INNER JOIN products p 
    ON op.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    times_bought_alone DESC
LIMIT 10;


-- Business Question 15: The "Impulse Buy" (Late-Cart Additions)
-- Business Objective: Identify products that are consistently added to the cart last. These are digital "checkout aisle" items. We filter for products ordered 500+ times to ensure statistical significance.
SELECT 
    p.product_name,
    ROUND(AVG(op.add_to_cart_order), 2) AS avg_cart_position,
    COUNT(op.product_id) AS total_times_ordered
FROM order_products op
INNER JOIN products p 
    ON op.product_id = p.product_id
GROUP BY 
    p.product_name
HAVING 
    COUNT(op.product_id) > 500
ORDER BY 
    avg_cart_position DESC
LIMIT 10;


-- Business Question 16: The "Pantry Loading" Theory
-- Business Objective: Test the hypothesis that the longer a customer waits between orders, the larger their basket size will be.
WITH OrderSizes AS (
    SELECT 
        order_id,
        COUNT(product_id) AS cart_size
    FROM order_products
    GROUP BY 
        order_id
)
SELECT 
    o.days_since_prior_order,
    ROUND(AVG(os.cart_size), 2) AS avg_cart_size
FROM orders o
INNER JOIN OrderSizes os 
    ON o.order_id = os.order_id
WHERE 
    o.days_since_prior_order IS NOT NULL
GROUP BY 
    o.days_since_prior_order
ORDER BY 
    o.days_since_prior_order ASC;


-- Business Question 17: Department Cross-Pollination
-- Business Objective: Measure how much customers explore the store. Do they stick to just 1 or 2 departments, or are they navigating across many different categories in a single trip?
WITH DepartmentCounts AS (
    SELECT 
        op.order_id,
        COUNT(DISTINCT p.department_id) AS distinct_departments_visited
    FROM order_products op
    INNER JOIN products p 
        ON op.product_id = p.product_id
    GROUP BY 
        op.order_id
)
SELECT 
    distinct_departments_visited,
    COUNT(order_id) AS total_orders
FROM DepartmentCounts
GROUP BY 
    distinct_departments_visited
ORDER BY 
    distinct_departments_visited ASC;


-- Business Question 18: Loyalty by Day of the Week
-- Business Objective: Determine if users are more likely to try new, exploratory items on weekends compared to strict, routine reorders on weekdays.
SELECT 
    o.order_dow AS day_of_week,
    COUNT(op.product_id) AS total_items_sold,
    ROUND(AVG(op.reordered) * 100, 2) AS reorder_rate_percentage
FROM orders o
INNER JOIN order_products op 
    ON o.order_id = op.order_id
GROUP BY 
    o.order_dow
ORDER BY 
    o.order_dow ASC;


-- Business Question 19: "Quick Trip" Staples
-- Business Objective: Identify the most popular products in small baskets (5 items or less) to optimize the checkout experience and recommendations for high-speed shoppers.
WITH SmallBaskets AS (
    SELECT 
        order_id
    FROM order_products
    GROUP BY 
        order_id
    HAVING 
        COUNT(product_id) <= 5
)
SELECT 
    p.product_name,
    COUNT(op.product_id) AS times_bought_in_small_basket
FROM SmallBaskets sb
INNER JOIN order_products op 
    ON sb.order_id = op.order_id
INNER JOIN products p 
    ON op.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    times_bought_in_small_basket DESC
LIMIT 10;


-- Business Question 20: Department Reorder Dependency
-- Business Objective: Identify which departments survive purely on habitual reorders versus departments that rely heavily on users discovering them organically (new item additions).
SELECT 
    d.department,
    SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS total_reordered_items,
    SUM(CASE WHEN op.reordered = 0 THEN 1 ELSE 0 END) AS total_new_items,
    ROUND(AVG(op.reordered) * 100, 2) AS reorder_dependency_percentage
FROM order_products op
INNER JOIN products p 
    ON op.product_id = p.product_id
INNER JOIN departments d 
    ON p.department_id = d.department_id
GROUP BY 
    d.department
ORDER BY 
    reorder_dependency_percentage DESC;


-- Business Question 21: Top Product per Department (Category Champions)
-- Business Objective: Find the absolute best-selling single product within every individual department using ranking functions.
WITH RankedProducts AS (
    SELECT 
        d.department,
        p.product_name,
        COUNT(op.product_id) AS total_sold,
        ROW_NUMBER() OVER(PARTITION BY d.department ORDER BY COUNT(op.product_id) DESC) as sales_rank
    FROM order_products op
    INNER JOIN products p 
        ON op.product_id = p.product_id
    INNER JOIN departments d 
        ON p.department_id = d.department_id
    GROUP BY 
        d.department, 
        p.product_name
)
SELECT 
    department,
    product_name AS top_selling_product,
    total_sold
FROM RankedProducts
WHERE 
    sales_rank = 1
ORDER BY 
    total_sold DESC;


-- Business Question 22: Department Market Share (Percentage of Total Volume)
-- Business Objective: Calculate exactly what percentage of the company's total item volume is driven by each department, without writing separate queries for the numerator and denominator.
WITH DepartmentVolume AS (
    SELECT 
        d.department,
        COUNT(op.product_id) AS items_sold
    FROM order_products op
    INNER JOIN products p 
        ON op.product_id = p.product_id
    INNER JOIN departments d 
        ON p.department_id = d.department_id
    GROUP BY 
        d.department
)
SELECT 
    department,
    items_sold,
    SUM(items_sold) OVER() AS company_total_items,
    ROUND((items_sold::NUMERIC / SUM(items_sold) OVER()) * 100, 2) AS market_share_percentage
FROM DepartmentVolume
ORDER BY 
    market_share_percentage DESC;


-- Business Question 23: Rolling 3-Hour Order Volume (Time-Series Smoothing)
-- Business Objective: Smooth out the hourly order data using a rolling average to better visualize broader traffic trends throughout the day, ignoring brief one-hour spikes.
WITH HourlyOrders AS (
    SELECT 
        order_hour_of_day,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY 
        order_hour_of_day
)
SELECT 
    order_hour_of_day,
    total_orders AS absolute_orders,
    ROUND(AVG(total_orders) OVER(
        ORDER BY order_hour_of_day 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3_hour_avg
FROM HourlyOrders
ORDER BY 
    order_hour_of_day ASC;


-- Business Question 24: User's Favorite Product (Personalized Recommendations)
-- Business Objective: Determine the single most frequently purchased item for each individual user. This is the exact logic used to populate a "Buy it Again" widget on the homepage.
WITH UserProductCounts AS (
    SELECT 
        o.user_id,
        p.product_name,
        COUNT(op.product_id) AS times_bought,
        ROW_NUMBER() OVER(PARTITION BY o.user_id ORDER BY COUNT(op.product_id) DESC) as user_rank
    FROM orders o
    INNER JOIN order_products op 
        ON o.order_id = op.order_id
    INNER JOIN products p 
        ON op.product_id = p.product_id
    GROUP BY 
        o.user_id, 
        p.product_name
)
SELECT 
    user_id,
    product_name AS favorite_product,
    times_bought
FROM UserProductCounts
WHERE 
    user_rank = 1
ORDER BY 
    user_id ASC
LIMIT 20; -- Limited to 20 just for visual inspection in pgAdmin


-- Business Question 25: The "Weekend Warrior" Departments (Weekend vs Weekday Ratio)
-- Business Objective: Identify which departments experience the biggest surge in volume on weekends compared to weekdays, helping marketing plan push notification schedules.
WITH DayTypeVolume AS (
    SELECT 
        d.department,
        CASE 
            WHEN o.order_dow IN (0, 1) THEN 'Weekend' 
            ELSE 'Weekday' 
        END AS day_type,
        COUNT(op.product_id) AS items_sold
    FROM orders o
    INNER JOIN order_products op 
        ON o.order_id = op.order_id
    INNER JOIN products p 
        ON op.product_id = p.product_id
    INNER JOIN departments d 
        ON p.department_id = d.department_id
    GROUP BY 
        d.department, 
        day_type
)
SELECT 
    department,
    SUM(CASE WHEN day_type = 'Weekend' THEN items_sold ELSE 0 END) AS weekend_sales,
    SUM(CASE WHEN day_type = 'Weekday' THEN items_sold ELSE 0 END) AS weekday_sales,
    ROUND(SUM(CASE WHEN day_type = 'Weekend' THEN items_sold ELSE 0 END)::NUMERIC / 
          NULLIF(SUM(CASE WHEN day_type = 'Weekday' THEN items_sold ELSE 0 END), 0), 2) AS weekend_to_weekday_ratio
FROM DayTypeVolume
GROUP BY 
    department
ORDER BY 
    weekend_to_weekday_ratio DESC;


-- Business Question 26: The "Heavy Lifters" (Top 1% of Customers)
-- Business Objective: Segment our user base into 100 equal percentiles based on total volume purchased. Filter for the 1st percentile to identify our VIP "Heavy Lifters" for exclusive rewards.
WITH UserVolumes AS (
    SELECT 
        o.user_id,
        COUNT(op.product_id) AS total_items_bought,
        NTILE(100) OVER(ORDER BY COUNT(op.product_id) DESC) as volume_percentile
    FROM orders o
    INNER JOIN order_products op 
        ON o.order_id = op.order_id
    GROUP BY 
        o.user_id
)
SELECT 
    user_id,
    total_items_bought
FROM UserVolumes
WHERE 
    volume_percentile = 1
ORDER BY 
    total_items_bought DESC
LIMIT 20; -- Limited to 20 just for visual inspection


-- Business Question 27: Aisle Diversity (Exploration Metric)
-- Business Objective: Determine how much users explore the store by calculating the average number of unique aisles visited per order. Are they laser-focused or browsing?
WITH AisleCounts AS (
    SELECT 
        op.order_id,
        COUNT(DISTINCT p.aisle_id) AS unique_aisles
    FROM order_products op
    INNER JOIN products p 
        ON op.product_id = p.product_id
    GROUP BY 
        op.order_id
)
SELECT 
    ROUND(AVG(unique_aisles), 2) AS avg_unique_aisles_per_order,
    MAX(unique_aisles) AS max_unique_aisles_in_one_order
FROM AisleCounts;


-- Business Question 28: Routine by Time of Day
-- Business Objective: Discover if users stick to their routines (high reorder rate) more strictly in the early morning versus the evening when they might have more time to browse for new items.
SELECT 
    CASE 
        WHEN o.order_hour_of_day BETWEEN 6 AND 11 THEN '1. Morning (6AM - 11AM)'
        WHEN o.order_hour_of_day BETWEEN 12 AND 16 THEN '2. Afternoon (12PM - 4PM)'
        WHEN o.order_hour_of_day BETWEEN 17 AND 22 THEN '3. Evening (5PM - 10PM)'
        ELSE '4. Night (11PM - 5AM)'
    END AS time_of_day,
    COUNT(op.product_id) AS total_items,
    ROUND(AVG(op.reordered) * 100, 2) AS reorder_rate_percentage
FROM orders o
INNER JOIN order_products op 
    ON o.order_id = op.order_id
GROUP BY 
    time_of_day
ORDER BY 
    time_of_day ASC;


-- Business Question 29: Return Trip Velocity by Department
-- Business Objective: Identify which departments drive the fastest return trips to the app by averaging the days_since_prior_order for items in each department.
SELECT 
    d.department,
    ROUND(AVG(o.days_since_prior_order), 2) AS avg_days_between_orders
FROM orders o
INNER JOIN order_products op 
    ON o.order_id = op.order_id
INNER JOIN products p 
    ON op.product_id = p.product_id
INNER JOIN departments d 
    ON p.department_id = d.department_id
WHERE 
    o.days_since_prior_order IS NOT NULL
GROUP BY 
    d.department
ORDER BY 
    avg_days_between_orders ASC;