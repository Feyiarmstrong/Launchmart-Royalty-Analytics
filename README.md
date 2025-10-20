# Launchmart-Royalty-Analytics

## Business Scenario
LaunchMart is a growing African e-commerce company that recently launched a loyalty program to increase customer retention. Customers earn points when they place orders and receive bonus points during promotional campaigns. As part of the data team, the task is to explore customers, orders and loyalty program data to support the marketing and operations teams in making informed decisions.

⸻

## Dataset Overview

The dataset includes the following tables:

 • customers

 • products

 • orders

 • order_items

 • loyalty_points

These tables contain customer details, order transactions, product information, and loyalty point records.

⸻

## Setup Instructions

 1. Create the database schema

Run the DDL statements in 01_schema.sql to create all tables.

 2. Insert seed data

Execute 02_seed_data.sql to populate the tables with sample records.

 3. Understand the relationships

Review 03_launchMart_erd.png to see the ERD and how the tables connect.

⸻

## SQL Analytics Tasks

Revenue and Customer Analysis

 • Count the total number of customers who joined in 2023.

 • Return each customer’s total revenue (sum of total_amount) sorted in descending order.

 • Return the top 5 customers by total revenue with rank.

 • Produce a monthly revenue trend for all months in 2023.

 • Find customers with no orders in the last 60 days of 2023.

 • Calculate the average order value (AOV) for each customer.


## Loyalty Program Insights

 • Compute total loyalty points per customer, including those with zero points.

 • Assign loyalty tiers based on total points:

 • Bronze: less than 100

 • Silver: 100–499

 • Gold: 500 and above

 • Return tier counts and total points per tier.


## Advanced Business Logic

 • Identify customers who spent more than ₦50,000 in total but have less than 200 loyalty points.

 • Flag customers as churn risk if they have no orders in the last 90 days of 2023 and are in the Bronze tier.


## Sample sql query 

-- Top 5 customers by total revenue with rank

SELECT

    c.customer_id,
    
    c.full_name,
    
    SUM(o.total_amount) AS total_revenue,
    
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS revenue_rank

FROM customers c

JOIN orders o ON c.customer_id = o.customer_id

GROUP BY c.customer_id, c.full_name

ORDER BY total_revenue DESC

LIMIT 5;


## Loyalty tier

SELECT 

    c.customer_id,
    
    c.full_name,
    
    COALESCE(SUM(lp.points_earned), 0) AS total_points,
    
    CASE
    
        WHEN COALESCE(SUM(lp.points_earned), 0) < 100 THEN 'Bronze'
        
        WHEN COALESCE(SUM(lp.points_earned), 0) BETWEEN 100 AND 499 THEN 'Silver'
        
        ELSE 'Gold'
    
    END AS loyalty_tier

FROM customers c

LEFT JOIN loyalty_points lp ON c.customer_id = lp.customer_id

GROUP BY c.customer_id, c.full_name;



## Project structure 

launchmart-loyalty-analytics

│

├── 01_schema.sql             # Database schema

├── 02_seed_data.sql          # Seed data

├── 03_launchMart_erd.png     # ERD diagram

├── queries/                  # SQL queries and analysis

├── README.md                 # Project documentation



## Key Learnings

 • Practiced relational data modeling and joining multiple tables

 • Used window functions (RANK, DENSE_RANK) for ranking logic

 • Applied date filtering to identify inactive customers

 • Performed loyalty tier classification and aggregation

 • Solved real-world business questions with SQL
