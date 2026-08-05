# Instacart Market Basket Analysis & SQL Portfolio

## Project Overview
This project transforms a massive, raw relational database of grocery orders into actionable business insights. Using advanced PostgreSQL techniques and Power BI, this repository demonstrates an end-to-end data pipeline designed to answer critical business questions regarding customer loyalty, product volume, and purchasing affinity.

## 🛠️ Technology Stack
*   **Database:** PostgreSQL (pgAdmin 4)
*   **Data Transformation:** SQL (CTEs, Window Functions, Self-Joins, Aggregations)
*   **Data Visualization:** Power BI
*   **Version Control:** Git & GitHub

## 📊 Executive Dashboard
*(The interactive Power BI dashboard provides a top-level view of department performance and customer reorder rates.)*

![Instacart Dashboard Overview](screenshots/dashboard_overview.png)

## 💡 Key Business Questions Answered
This repository contains complex SQL scripts designed to answer real-world product and operations questions:
1. **Volume:** What are the top 10 most popular products across the platform?
2. **Loyalty:** Which departments have the highest repeat purchase (reorder) rates?
3. **Market Basket Analysis:** Which products are most frequently bought together in the exact same cart? (Recommendation Engine Logic)

## 📁 Repository Structure
*   `/sql`: Contains all `.sql` scripts ranging from basic schema creation to advanced window functions and views.
*   `/powerbi`: Contains the `.pbix` dashboard file.
*   `/screenshots`: Visual documentation of the project.