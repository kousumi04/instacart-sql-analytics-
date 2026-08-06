import streamlit as st
import pandas as pd
import joblib
import os

# 1. Page Configuration
st.set_page_config(page_title="Instacart Recommendation Engine", layout="centered")

# 2. Load the Trained Rules
@st.cache_data # Caches the data so the app doesn't reload the file on every click
def load_rules():
    model_path = os.path.join(os.path.dirname(__file__), '..', 'models', 'association_rules.pkl')
    try:
        return joblib.load(model_path)
    except FileNotFoundError:
        st.error("Model file not found. Please run train_model.py first.")
        return pd.DataFrame()

rules = load_rules()

# 3. UI Layout
st.title("🛒 Instacart Recommendation Engine")
st.markdown("Powered by the FP-Growth Algorithm & Market Basket Analysis")

if not rules.empty:
    # Extract unique products from the 'antecedents' (the items the user already has)
    # The frozenset needs to be unpacked to a list of strings
    unique_items = sorted(set([item for sublist in rules['antecedents'] for item in sublist]))
    
    st.subheader("What is in your cart?")
    selected_item = st.selectbox("Select a product to get recommendations:", unique_items)

    st.write("---")

    # 4. Recommendation Logic
    if selected_item:
        st.subheader(f"Because you bought **{selected_item}**, you might also like:")
        
        # Filter rules where the selected item is exactly in the antecedents
        # We use a lambda to check if our item is in the frozenset
        recommendations = rules[rules['antecedents'].apply(lambda x: selected_item in x)]
        
        if not recommendations.empty:
            # Get the top 5 consequents (recommendations)
            top_recs = recommendations.head(5)
            
            for index, row in top_recs.iterrows():
                # Unpack the frozenset consequent
                rec_item = list(row['consequents'])[0]
                confidence = round(row['confidence'] * 100, 1)
                lift = round(row['lift'], 2)
                
                # Display it nicely using Streamlit metrics
                col1, col2, col3 = st.columns([3, 1, 1])
                with col1:
                    st.success(f"**{rec_item}**")
                with col2:
                    st.metric("Confidence", f"{confidence}%")
                with col3:
                    st.metric("Lift", f"{lift}x")
        else:
            st.info("No strong recommendations found for this item.")