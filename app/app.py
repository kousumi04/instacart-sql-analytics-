import streamlit as st
import pandas as pd
import joblib
import os
import random

# 1. Page Configuration
st.set_page_config(page_title="Instacart Recommendation Engine", layout="wide")

# 2. Load Data and Models
@st.cache_data 
def load_rules():
    model_path = os.path.join(os.path.dirname(__file__), '..', 'models', 'association_rules.pkl')
    try:
        return joblib.load(model_path)
    except FileNotFoundError:
        st.error("Model file not found. Please run train_model.py first.")
        return pd.DataFrame()

@st.cache_data
def load_catalog():
    base_dir = os.path.dirname(__file__)
    prod_path = os.path.join(base_dir, '..', 'data', 'products.csv')
    dept_path = os.path.join(base_dir, '..', 'data', 'departments.csv')
    try:
        products = pd.read_csv(prod_path)
        departments = pd.read_csv(dept_path)
        catalog = pd.merge(products, departments, on='department_id', how='inner')
        return catalog[['product_name', 'department']]
    except FileNotFoundError:
        st.error("Data files not found.")
        return pd.DataFrame()

rules = load_rules()
catalog = load_catalog()

# 3. Sidebar UI (The Sliders)
st.sidebar.header("⚙️ Algorithm Adjustments")

st.sidebar.markdown("**Likelihood (Confidence)**")
st.sidebar.caption("If they buy the selected item, what is the minimum percentage chance they buy the recommended item?")
min_confidence = st.sidebar.slider("Minimum Likelihood (%)", min_value=1, max_value=100, value=5, step=1)

st.sidebar.write("---")

st.sidebar.markdown("**Strength Multiplier (Lift)**")
st.sidebar.caption("How many times *more* likely are they to buy these together compared to random chance?")
min_lift = st.sidebar.slider("Minimum Strength (x)", min_value=1.0, max_value=20.0, value=1.0, step=0.5)

# 4. Main Page UI
st.title("🛒 Instacart Recommendation Engine")
st.markdown("Select a product to instantly generate data-driven cross-selling recommendations.")

if not catalog.empty:
    st.write("---")
    
    # Dual Search Workflows (Cleanly integrated)
    search_mode = st.radio(
        "Search Method:", 
        ["🔍 Global Search (Search all 50,000 items)", "📁 Browse by Department"], 
        horizontal=True
    )
    
    st.subheader("What is in your cart?")
    
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
            
    elif search_mode == "🔍 Global Search (Search all 50,000 items)":
        global_query = st.text_input("Search for a product:", placeholder="e.g., Grated Parmesan, Banana, Organic Milk...")
        
        if global_query:
            filtered_df = catalog[catalog['product_name'].str.contains(global_query, case=False, na=False)]
            filtered_products = sorted(filtered_df['product_name'].tolist())
            
            if filtered_products:
                selected_item = st.selectbox("Select exact item:", filtered_products)
                selected_dept = catalog[catalog['product_name'] == selected_item]['department'].values[0]
            else:
                st.warning(f"No products found matching '{global_query}'.")

    st.write("---")

    # 5. Recommendation Engine Logic (The layout from your screenshot)
    if selected_item:
        st.subheader(f"Because you bought {selected_item}, you might also like:")
        
        recommendations = pd.DataFrame()
        if not rules.empty:
            recommendations = rules[rules['antecedents'].apply(lambda x: selected_item in x)]
            recommendations = recommendations[
                (recommendations['confidence'] >= (min_confidence / 100.0)) & 
                (recommendations['lift'] >= min_lift)
            ]
        
        if not recommendations.empty:
            top_recs = recommendations.head(5)
            
            for index, row in top_recs.iterrows():
                rec_item = list(row['consequents'])[0]
                confidence = round(row['confidence'] * 100, 1)
                lift = round(row['lift'], 2)
                
                col1, col2, col3 = st.columns([3, 1, 1])
                with col1:
                    st.success(f"**{rec_item}**")  # The green box you liked
                with col2:
                    st.metric("Likelihood", f"{confidence}%")
                with col3:
                    st.metric("Strength Multiplier", f"{lift}x")

        else:
            # Fallback logic if there is no data
            st.info(f"We don't have enough data to make a strong recommendation for '{selected_item}' right now.")
            st.markdown(f"#### 🌟 While you're in the **{selected_dept}** aisle, check these out:")
            
            dept_items = catalog[catalog['department'] == selected_dept]['product_name'].tolist()
            if len(dept_items) >= 3:
                random_suggestions = random.sample(dept_items, 3)
                r1, r2, r3 = st.columns(3)
                with r1: st.success(f"{random_suggestions[0]}")
                with r2: st.success(f"{random_suggestions[1]}")
                with r3: st.success(f"{random_suggestions[2]}")