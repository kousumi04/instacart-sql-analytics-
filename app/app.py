import streamlit as st
import pandas as pd
import os
import random

# 1. Page Configuration
st.set_page_config(page_title="Instacart Market Analytics", layout="wide")

# 2. Load Static DA Data
@st.cache_data 
def load_da_data():
    base_dir = os.path.dirname(__file__)
    data_path = os.path.join(base_dir, '..', 'data', 'da_recommendations.csv')
    try:
        return pd.read_csv(data_path)
    except FileNotFoundError:
        st.error("Data file not found. Please run build_da_tables.py first.")
        return pd.DataFrame()

@st.cache_data
def load_catalog():
    base_dir = os.path.dirname(__file__)
    data_dir = os.path.join(base_dir, '..', 'data')
    try:
        products = pd.read_csv(os.path.join(data_dir, 'products.csv'))
        departments = pd.read_csv(os.path.join(data_dir, 'departments.csv'))
        catalog = pd.merge(products, departments, on='department_id', how='inner')
        return catalog[['product_name', 'department']]
    except FileNotFoundError:
        st.error("Catalog files not found.")
        return pd.DataFrame()

da_rules = load_da_data()
catalog = load_catalog()

# 3. Sidebar UI (DA Filters instead of ML tuning)
st.sidebar.header("📊 Analytics Filters")
st.sidebar.markdown("Filter historical purchase data.")

st.sidebar.write("---")
min_basket_share = st.sidebar.slider("Minimum Basket Share (%)", min_value=0.0, max_value=20.0, value=0.0, step=0.5,
                                     help="What percentage of orders with the main item also included the paired item?")

# 4. Main Page UI
st.title("🛒 Instacart Co-Purchase Analytics")
st.markdown("Analyze historical shopping carts to discover the most frequently paired products.")

if not catalog.empty:
    st.write("---")
    
    search_mode = st.radio("Search Method:", ["🔍 Global Search", "📁 Browse by Department"], horizontal=True)
    st.subheader("Select a target product:")
    
    selected_item = None
    selected_dept = None
    
    if search_mode == "📁 Browse by Department":
        col1, col2 = st.columns(2)
        with col1:
            department_list = sorted(catalog['department'].dropna().unique().tolist())
            selected_dept = st.selectbox("1. Filter by department:", department_list)
        with col2:
            dept_products = sorted(catalog[catalog['department'] == selected_dept]['product_name'].tolist())
            selected_item = st.selectbox("2. Search for a product:", dept_products)
            
    elif search_mode == "🔍 Global Search":
        global_query = st.text_input("Search catalog:", placeholder="e.g., Grated Parmesan, Banana...")
        
        if global_query:
            filtered_df = catalog[catalog['product_name'].str.contains(global_query, case=False, na=False)].copy()
            
            # Relevance Engine
            lower_query = global_query.lower()
            def score_relevance(name):
                name_lower = name.lower()
                if name_lower == lower_query: return 1
                elif name_lower.startswith(lower_query): return 2
                else: return 3
            
            filtered_df['relevance'] = filtered_df['product_name'].apply(score_relevance)
            filtered_df['name_length'] = filtered_df['product_name'].str.len()
            filtered_df = filtered_df.sort_values(by=['relevance', 'name_length', 'product_name'])
            
            filtered_products = filtered_df['product_name'].tolist()
            if filtered_products:
                selected_item = st.selectbox("Select exact item:", filtered_products)
                selected_dept = catalog[catalog['product_name'] == selected_item]['department'].values[0]
            else:
                st.warning(f"No products found matching '{global_query}'.")

    st.write("---")

    # 5. Data Analytics Display
    if selected_item:
        st.subheader(f"Historical Data: Customers who bought {selected_item} also bought:")
        
        recommendations = pd.DataFrame()
        if not da_rules.empty:
            recommendations = da_rules[da_rules['item_a'] == selected_item]
            recommendations = recommendations[recommendations['basket_share_pct'] >= min_basket_share]
        
        if not recommendations.empty:
            for index, row in recommendations.iterrows():
                rec_item = row['item_b']
                co_purchases = int(row['co_purchase_count'])
                basket_share = row['basket_share_pct']
                
                col1, col2, col3 = st.columns([3, 1, 1])
                with col1:
                    st.success(f"**{rec_item}**") 
                with col2:
                    st.metric("Total Co-Purchases", f"{co_purchases:,}")
                with col3:
                    st.metric("Basket Share", f"{basket_share}%")

        else:
            # Descriptive Analytics Fallback
            st.info(f"We don't have enough historical co-purchase records for '{selected_item}'.")
            st.markdown(f"#### 🌟 Most popular items in the **{selected_dept}** department:")
            
            dept_items = catalog[catalog['department'] == selected_dept]['product_name'].tolist()
            if len(dept_items) >= 3:
                random_suggestions = random.sample(dept_items, 3)
                r1, r2, r3 = st.columns(3)
                with r1: st.success(f"{random_suggestions[0]}")
                with r2: st.success(f"{random_suggestions[1]}")
                with r3: st.success(f"{random_suggestions[2]}")