import pandas as pd
from sqlalchemy import create_engine
from mlxtend.preprocessing import TransactionEncoder
from mlxtend.frequent_patterns import fpgrowth, association_rules
import joblib
import os

# 1. Database Connection (Update password/port if yours is different)
DB_USER = 'postgres'
DB_PASSWORD = '12345' # Replace with your pgAdmin password
DB_HOST = 'localhost'
DB_PORT = '5173'
DB_NAME = 'instacart_analytics'

print("Connecting to the database...")
engine = create_engine(f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}')

# 2. Extract Data (Memory-Safe SQL Query)
# We take the top 500 products and a sample of 100,000 orders to prevent RAM exhaustion.
query = """
WITH TopProducts AS (
    SELECT product_id, product_name
    FROM products
    WHERE product_id IN (
        SELECT product_id FROM order_products
        GROUP BY product_id 
        ORDER BY COUNT(order_id) DESC 
        LIMIT 500
    )
),
SampledOrders AS (
    SELECT DISTINCT order_id 
    FROM orders 
    LIMIT 100000
)
SELECT 
    op.order_id, 
    tp.product_name
FROM order_products op
INNER JOIN TopProducts tp ON op.product_id = tp.product_id
INNER JOIN SampledOrders so ON op.order_id = so.order_id;
"""

print("Extracting order data...")
df = pd.read_sql(query, engine)

# 3. Data Preprocessing (Group into shopping carts)
print("Grouping items into baskets...")
baskets = df.groupby('order_id')['product_name'].apply(list).values.tolist()

# One-hot encode the baskets (Required format for mlxtend)
print("Encoding transactions...")
te = TransactionEncoder()
te_ary = te.fit(baskets).transform(baskets)
df_encoded = pd.DataFrame(te_ary, columns=te.columns_)

# 4. Train the FP-Growth Model
print("Training FP-Growth model (Finding frequent itemsets)...")
# min_support = 0.01 means the item must appear in at least 1% of the sampled orders
frequent_itemsets = fpgrowth(df_encoded, min_support=0.01, use_colnames=True)

print("Generating association rules...")
# metric="lift" > 1 ensures we only keep rules where items are actually bought together MORE often than by chance
rules = association_rules(frequent_itemsets, metric="lift", min_threshold=1.0)

# Sort by lift and confidence to get the strongest recommendations at the top
rules = rules.sort_values(by=['lift', 'confidence'], ascending=[False, False])

# 5. Save the Rules
output_path = os.path.join(os.path.dirname(__file__), '..', 'models', 'association_rules.pkl')
joblib.dump(rules, output_path)

print(f"Model successfully trained! Rules saved to: {output_path}")