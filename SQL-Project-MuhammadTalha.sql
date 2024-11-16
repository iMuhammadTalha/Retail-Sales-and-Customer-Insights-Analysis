-- Key Objectives and Sample Queries
-- Module 1: Sales Performance Analysis
-- 1 Total Sales per Month
SELECT DATE_FORMAT(sale_date, '%Y-%m-01') AS month,  
       FORMAT(SUM(quantity_sold), 2) AS total_units_sold,
       FORMAT(SUM(total_amount), 2) AS total_revenue
FROM sales_data
GROUP BY month
ORDER BY month;

-- 2 Average Discount per Month
SELECT
  DATE_FORMAT(sale_date, '%Y-%m-01') AS month,
  FORMAT(AVG(discount_applied), 2) AS avg_discount,
  FORMAT(SUM(total_amount), 2) AS total_revenue
FROM sales_data
GROUP BY month
ORDER BY month;



-- Module 2: Customer Behavior and Insights
-- 3 Identify high-value customers
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  FORMAT(SUM(s.total_amount), 2) AS total_spent
FROM customers_data c
JOIN sales_data s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 10;

-- 4 Identify the oldest Customer
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  FORMAT(SUM(s.total_amount), 2) AS total_spent,
  COUNT(s.sale_id) AS total_orders
FROM customers_data c
JOIN sales_data s ON c.customer_id = s.customer_id
WHERE c.date_of_birth BETWEEN '1990-01-01' AND '1999-12-31'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- 5 Customer Segmentation
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  FORMAT(SUM(s.total_amount),2) AS total_spent,
  CASE
    WHEN SUM(s.total_amount) > 1000 THEN 'High Spender'
    WHEN SUM(s.total_amount) BETWEEN 500 AND 1000 THEN 'Medium Spender'
    ELSE 'Low Spender'
  END AS spending_segment
FROM customers_data c
JOIN sales_data s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- Module 3: Inventory and Product Management
-- 6 Stock Management:
SELECT
  product_id,
  product_name,
  stock_quantity,
  CASE
    WHEN stock_quantity < 10 THEN 'Low Stock - Restock Recommended'
    ELSE 'Sufficient Stock'
  END AS stock_status
FROM products_data
WHERE stock_quantity < 10;


-- 7 Inventory Movements Overview
SELECT
  IMD.product_id,
  PD.product_name,
  IMD.movement_type,
  SUM(IMD.quantity_moved) AS total_quantity_moved,
  IMD.movement_date
FROM inventory_movements_data IMD
JOIN products_data PD ON PD.product_id = IMD.product_id
GROUP BY IMD.product_id, PD.product_name, IMD.movement_type, IMD.movement_date
ORDER BY IMD.product_id, IMD.movement_date;

-- 8 Rank Products by Price in Each Category
SELECT
  category,
  product_name,
  price,
  RANK() OVER (PARTITION BY category ORDER BY price DESC) AS price_rank
FROM products_data;

-- Module 4: Advanced Analytics
-- 9 Average Order Size
SELECT
  SD.product_id,
  product_name,
  FORMAT(AVG(quantity_sold),2) AS avg_order_size
FROM sales_data SD
JOIN products_data PD ON PD.product_id=SD.product_id
GROUP BY product_id, product_name
ORDER BY avg_order_size DESC;

-- 10 Recent Restock Product
SELECT
  IMD.product_id,
  product_name,
  MAX(movement_date) AS last_restock_date
FROM inventory_movements_data IMD
JOIN products_data PD ON PD.product_id=IMD.product_id
WHERE movement_type = 'IN'
GROUP BY product_id, product_name
ORDER BY last_restock_date DESC
LIMIT 10;

-- 11 Dynamic Pricing Simulation
WITH Price_Adjustments AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.price AS original_price,
        p.price * 1.1 AS increased_price_10,
        p.price * 0.9 AS decreased_price_10
    FROM products_data p
),
Projected_Sales AS (
    SELECT
        pa.product_id,
        pa.product_name,
        FORMAT(SUM(CASE WHEN s.discount_applied >= 0.10 THEN s.quantity_sold * pa.increased_price_10
                 WHEN s.discount_applied <= 0.10 THEN s.quantity_sold * pa.decreased_price_10
                 ELSE s.quantity_sold * pa.original_price END),2) AS projected_revenue,
        SUM(s.quantity_sold) AS projected_units_sold
    FROM sales_data s
    JOIN Price_Adjustments pa ON s.product_id = pa.product_id
    GROUP BY pa.product_id, pa.product_name
)
SELECT * FROM Projected_Sales
ORDER BY projected_revenue DESC;

-- 12 Customer Purchase Patterns
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    DATE_FORMAT(s.sale_date, '%Y-%m-01') AS purchase_month,  
    COUNT(s.sale_id) AS purchase_frequency,
    LAG(COUNT(s.sale_id), 1) OVER (PARTITION BY c.customer_id ORDER BY DATE_FORMAT(s.sale_date, '%Y-%m-01')) AS previous_month_frequency
FROM customers_data c
JOIN sales_data s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, purchase_month
ORDER BY c.customer_id, purchase_month;

-- 13 Predictive Analytics
WITH Purchase_Gaps AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        MAX(s.sale_date) AS last_purchase_date,
        DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS days_since_last_purchase,
        COUNT(s.sale_id) AS total_purchases
    FROM customers_data c
    LEFT JOIN sales_data s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
    customer_id,
    first_name,
    last_name,
    last_purchase_date,
    days_since_last_purchase,
    CASE
        WHEN days_since_last_purchase > 180 THEN 'High Risk'
        WHEN days_since_last_purchase BETWEEN 90 AND 180 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS churn_risk
FROM Purchase_Gaps
ORDER BY churn_risk DESC, days_since_last_purchase DESC;

