--1, Count the total number of customers who joined in 2023.
SELECT COUNT(*) AS total_customers_2023
FROM customers
WHERE EXTRACT(YEAR FROM join_date) = 2023;

--2, For each customer return customer_id, full_name, total_revenue (sum of total_amount from orders).
--sort descending.
SELECT 
    c.customer_id,
    c.full_name,
    SUM(o.total_amount) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_revenue DESC;


--3, Return the top 5 customers by total_revenue with their rank.
SELECT 
    c.customer_id,
    c.full_name,
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS revenue_rank
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY revenue_rank
LIMIT 5;


--4, Produce a table with year, month, monthly_revenue for all months in 2023 ordered chronologically.
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(total_amount) AS monthly_revenue
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2023
GROUP BY year, month
ORDER BY year, month;


--5, Find customers with no orders in the last 60 days relative to 2023-12-31
--(i.e., consider last active date up to 2023-12-31). Return customer_id, full_name, last_order_date.
SELECT 
    c.customer_id,
    c.full_name,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
HAVING MAX(o.order_date) IS NULL
   OR MAX(o.order_date) < '2023-12-31'::DATE - INTERVAL '60 days'
ORDER BY last_order_date;


--6, Calculate average order value (AOV) for each customer: return customer_id, full_name,
--aov (average total_amount of their orders). Exclude customers with no orders.
SELECT 
    c.customer_id,
    c.full_name,
    ROUND(AVG(o.total_amount), 2) AS aov
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY aov DESC;

--7, For all customers who have at least one order, compute customer_id, full_name, total_revenue,
--spend_rank where spend_rank is a dense rank, highest spender = rank 1.
SELECT 
    c.customer_id,
    c.full_name,
    SUM(o.total_amount) AS total_revenue,
    DENSE_RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS spend_rank
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY spend_rank;

--8, List customers who placed more than 1 order and show customer_id, full_name, order_count,
--first_order_date, last_order_date.
SELECT 
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS order_count,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
HAVING COUNT(o.order_id) > 1
ORDER BY order_count DESC;


--9, Compute total loyalty points per customer. Include customers with 0 points.
SELECT 
    c.customer_id,
    c.full_name,
    COALESCE(SUM(lp.points_earned), 0) AS total_points
FROM customers c
LEFT JOIN loyalty_points lp
    ON c.customer_id = lp.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_points DESC;

--10, Assign loyalty tiers based on total points:
--Bronze: < 100
--Silver: 100–499
--Gold: >= 500
--Output: tier, tier_count, tier_total_points
WITH customer_points AS (
    SELECT 
        c.customer_id,
        c.full_name,
        COALESCE(SUM(lp.points_earned), 0) AS total_points
    FROM customers c
    LEFT JOIN loyalty_points lp
        ON c.customer_id = lp.customer_id
    GROUP BY c.customer_id, c.full_name
)
SELECT 
    CASE 
        WHEN total_points < 100 THEN 'Bronze'
        WHEN total_points BETWEEN 100 AND 499 THEN 'Silver'
        WHEN total_points >= 500 THEN 'Gold'
    END AS tier,
    COUNT(*) AS tier_count,
    SUM(total_points) AS tier_total_points
FROM customer_points
GROUP BY tier
ORDER BY tier;


--11, Identify customers who spent more than ₦50,000 in total but have less than 200 loyalty points.
--Return customer_id, full_name, total_spend, total_points.
WITH spend AS (
    SELECT 
        c.customer_id,
        c.full_name,
        SUM(o.total_amount) AS total_spend
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.full_name
),
points AS (
    SELECT 
        c.customer_id,
        COALESCE(SUM(lp.points_earned), 0) AS total_points
    FROM customers c
    LEFT JOIN loyalty_points lp 
        ON c.customer_id = lp.customer_id
    GROUP BY c.customer_id
)
SELECT 
    s.customer_id,
    s.full_name,
    s.total_spend,
    p.total_points
FROM spend s
JOIN points p 
    ON s.customer_id = p.customer_id
WHERE s.total_spend > 50000
  AND p.total_points < 200
ORDER BY s.total_spend DESC;

--12, Flag customers as churn_risk if they have no orders in the last 90 days (relative to 2023-12-31)
--AND are in the Bronze tier. Return customer_id, full_name, last_order_date, total_points.
WITH last_order AS (
    SELECT 
        c.customer_id,
        c.full_name,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.full_name
),
points AS (
    SELECT 
        c.customer_id,
        COALESCE(SUM(lp.points_earned), 0) AS total_points
    FROM customers c
    LEFT JOIN loyalty_points lp 
        ON c.customer_id = lp.customer_id
    GROUP BY c.customer_id
),
tiered AS (
    SELECT 
        p.customer_id,
        p.total_points,
        CASE 
            WHEN p.total_points < 100 THEN 'Bronze'
            WHEN p.total_points BETWEEN 100 AND 499 THEN 'Silver'
            WHEN p.total_points >= 500 THEN 'Gold'
        END AS tier
    FROM points p
)
SELECT 
    l.customer_id,
    l.full_name,
    l.last_order_date,
    t.total_points
FROM last_order l
JOIN tiered t
    ON l.customer_id = t.customer_id
WHERE (l.last_order_date IS NULL 
       OR l.last_order_date < '2023-12-31'::DATE - INTERVAL '90 days')
  AND t.tier = 'Bronze'
ORDER BY l.last_order_date;