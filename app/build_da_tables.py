import pandas as pd
import os

# Define the absolute path to the data folder
base_dir = os.path.dirname(__file__)
data_dir = os.path.join(base_dir, '..', 'data')

print("Loading datasets...")
# Point directly to the CSVs in the data folder
df = pd.read_csv(os.path.join(data_dir, 'order_products__train.csv'), usecols=['order_id', 'product_id'])
products = pd.read_csv(os.path.join(data_dir, 'products.csv'), usecols=['product_id', 'product_name'])

print("Calculating baseline frequencies...")
# Count total times each product was bought (to calculate percentages later)
product_counts = df['product_id'].value_counts().to_dict()

print("Finding co-occurring items (This will take a minute)...")
# Self-join on order_id to find every pair of products bought in the same cart
pairs = pd.merge(df, df, on='order_id')

# Remove rows where a product is matched with itself
pairs = pairs[pairs['product_id_x'] != pairs['product_id_y']]

print("Aggregating historical facts...")
# Count exactly how many times each pair occurred
pair_counts = pairs.groupby(['product_id_x', 'product_id_y']).size().reset_index(name='co_purchase_count')

print("Ranking Top 5 pairings per product...")
# Sort by Product X, then by the highest co-purchase count
pair_counts = pair_counts.sort_values(['product_id_x', 'co_purchase_count'], ascending=[True, False])
top_5_pairs = pair_counts.groupby('product_id_x').head(5)

print("Mapping product names...")
# FIX: Drop the redundant 'product_id' column after each merge to prevent suffix collisions
top_5_pairs = top_5_pairs.merge(products, left_on='product_id_x', right_on='product_id', how='left')
top_5_pairs = top_5_pairs.drop(columns=['product_id']).rename(columns={'product_name': 'item_a'})

top_5_pairs = top_5_pairs.merge(products, left_on='product_id_y', right_on='product_id', how='left')
top_5_pairs = top_5_pairs.drop(columns=['product_id']).rename(columns={'product_name': 'item_b'})

# The DA Metric: Basket Share (%)
# What percentage of carts containing Item A also contained Item B?
top_5_pairs['basket_share_pct'] = top_5_pairs.apply(
    lambda row: round((row['co_purchase_count'] / product_counts[row['product_id_x']]) * 100, 2), axis=1
)
final_da_table = top_5_pairs[['item_a', 'item_b', 'co_purchase_count', 'basket_share_pct']]

# Save the final static table directly into the data folder
output_path = os.path.join(data_dir, 'da_recommendations.csv')
final_da_table.to_csv(output_path, index=False)

print(f"Success! Pure Data Analysis table saved to {output_path}")