import pandas as pd
from sqlalchemy import create_engine
from mlxtend.preprocessing import TransactionEncoder
from mlxtend.frequent_patterns import fpgrowth, association_rules
import joblib
import os

# 1. Database Connection 
DB_USER = 'postgres'
DB_PASSWORD = '12345' # Replace with your pgAdmin password
DB_HOST = 'localhost'
DB_PORT = '5173'         # Change to 5433 if needed
DB_NAME = 'instacart_analytics'

print("Connecting to the database...")
engine = create_engine(f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}')

# 2. Extract Data (Expanded to ALL products)
query = """
WITH SampledOrders AS (
    SELECT DISTINCT order_id 
    FROM orders 
    LIMIT 100000
)
SELECT 
    op.order_id, 
    p.product_name
FROM order_products op
INNER JOIN products p ON op.product_id = p.product_id
INNER JOIN SampledOrders so ON op.order_id = so.order_id;
"""

print("Extracting order data across all categories...")
df = pd.read_sql(query, engine)

# 3. Data Preprocessing
print("Grouping items into baskets...")
baskets = df.groupby('order_id')['product_name'].apply(list).values.tolist()

print("Encoding transactions...")
te = TransactionEncoder()
te_ary = te.fit(baskets).transform(baskets)
df_encoded = pd.DataFrame(te_ary, columns=te.columns_)

# 4. Train the FP-Growth Model (Lower support to catch non-food items)
print("Training FP-Growth model (Finding frequent itemsets)...")
# Reduced to 0.001 (0.1% of carts) so non-grocery categories appear
frequent_itemsets = fpgrowth(df_encoded, min_support=0.001, use_colnames=True)

print("Generating association rules...")
rules = association_rules(frequent_itemsets, metric="lift", min_threshold=1.0)
rules = rules.sort_values(by=['lift', 'confidence'], ascending=[False, False])

# 5. Save the Rules
output_path = os.path.join(os.path.dirname(__file__), '..', 'models', 'association_rules.pkl')
joblib.dump(rules, output_path)

print(f"Model successfully trained! Rules saved to: {output_path}")