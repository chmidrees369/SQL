-- ============================================================
--   ASSIGNMENT 05 — INDEXES, VIEWS & WINDOW FUNCTIONS
--   Database  : BikeStores
--   Topics    : Indexes (Clustered & Non-Clustered)
--               Views
--               ROW_NUMBER / RANK / DENSE_RANK
--               LAG / LEAD
--               COALESCE
-- ============================================================


-- ============================================================
--  SECTION A — INDEXES
-- ============================================================

-- Q1.
-- The marketing team frequently runs campaigns filtered by brand.
-- They search products like this:
--
--   SELECT product_id, product_name, list_price
--   FROM production.products
--   WHERE brand_id = 3;
--
-- This query is slow. Create an appropriate index to fix it.
-- Then run the query to confirm it returns results correctly.

-- Create non-clustered index on brand_id
CREATE INDEX IX_products_brand_id
ON production.products (brand_id);
GO

-- Test the query
SELECT product_id, product_name, list_price
FROM production.products
WHERE brand_id = 3;
GO

-- Q2.
-- The finance team runs a monthly report that filters orders
-- by a date range, for example:
--
--   SELECT order_id, customer_id, order_date
--   FROM sales.orders
--   WHERE order_date BETWEEN '2018-01-01' AND '2018-06-30';
--
-- Create an index to make this query more efficient.

-- Create non-clustered index on order_date
CREATE INDEX IX_orders_order_date
ON sales.orders (order_date);
GO


-- ============================================================
--  SECTION B — VIEWS
-- ============================================================

-- Q3.
-- The customer support team needs a daily list of all
-- pending and processing orders so they can follow up.
-- Create a view that shows:
--   order_id, customer full name, phone, email,
--   order_date, and order status as a readable label
--   (not a number — use 1=Pending, 2=Processing).
-- After creating it, query the view to see today's workload.

-- Create the view
CREATE VIEW sales.vw_pending_processing_orders AS
SELECT 
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
    c.phone,
    c.email,
    o.order_date,
    CASE 
        WHEN o.order_status = 1 THEN 'Pending'
        WHEN o.order_status = 2 THEN 'Processing'
        ELSE CAST(o.order_status AS VARCHAR)
    END AS order_status_label
FROM sales.orders o
INNER JOIN sales.customers c ON o.customer_id = c.customer_id
WHERE o.order_status IN (1, 2);
GO

-- Query the view for today's workload
SELECT * FROM sales.vw_pending_processing_orders
WHERE CAST(order_date AS DATE) = CAST(GETDATE() AS DATE)
ORDER BY order_date;
GO

-- Q4.
-- The inventory manager wants a single view to monitor stock
-- across all stores without writing complex joins every time.
-- Create a view that shows:
--   store_name, product_name, brand_name, category_name, quantity
-- After creating it, query the view to find all products
-- that have fewer than 3 units remaining in any store.

-- Create the view
CREATE VIEW production.vw_store_inventory AS
SELECT 
    s.store_name,
    p.product_name,
    b.brand_name,
    c.category_name,
    st.quantity
FROM production.stocks st
INNER JOIN sales.stores s ON st.store_id = s.store_id
INNER JOIN production.products p ON st.product_id = p.product_id
INNER JOIN production.brands b ON p.brand_id = b.brand_id
INNER JOIN production.categories c ON p.category_id = c.category_id;
GO

-- Find all products with fewer than 3 units remaining
SELECT * FROM production.vw_store_inventory
WHERE quantity < 3
ORDER BY store_name, quantity;
GO


-- ============================================================
--  SECTION C — ROW_NUMBER, RANK & DENSE_RANK
-- ============================================================

-- Q5.
-- The sales director wants to see the top 2 best-selling products
-- per store based on total quantity sold.
-- Show store_id, product_id, total_quantity, and their rank within the store.
-- Return only rank 1 and rank 2 for each store.

WITH product_ranking_by_store AS (
    SELECT 
        o.store_id,
        oi.product_id,
        SUM(oi.quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY o.store_id ORDER BY SUM(oi.quantity) DESC) AS rank
    FROM sales.orders o
    INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.store_id, oi.product_id
)
SELECT 
    store_id,
    product_id,
    total_quantity,
    rank
FROM product_ranking_by_store
WHERE rank <= 2
ORDER BY store_id, rank;
GO

-- Q6.
-- The pricing team wants to find the 2nd most expensive product
-- in each category.
-- Show category_id, product_name, list_price, and their price rank
-- within the category.
-- Return only the products ranked 2nd in their category.

WITH product_price_ranking AS (
    SELECT 
        category_id,
        product_name,
        list_price,
        RANK() OVER (PARTITION BY category_id ORDER BY list_price DESC) AS price_rank
    FROM production.products
)
SELECT 
    category_id,
    product_name,
    list_price,
    price_rank
FROM product_price_ranking
WHERE price_rank = 2
ORDER BY category_id, list_price DESC;
GO

-- Q7.
-- The data team suspects there are duplicate customer records.
-- Use the test table below (already has duplicates built in).
-- Write a query to identify the duplicate rows
-- (same first_name, last_name, and phone).
-- Return only the duplicates — not the original/first occurrence.

-- Run this setup first:

CREATE TABLE test_customers (
    customer_id  INT,
    first_name   VARCHAR(50),
    last_name    VARCHAR(50),
    phone        VARCHAR(20),
    city         VARCHAR(50)
);
GO

INSERT INTO test_customers VALUES
    (1,  'Ali',    'Khan',    '0300-1111111', 'Karachi'),
    (2,  'Sara',   'Ahmed',   '0321-2222222', 'Lahore'),
    (3,  'Ali',    'Khan',    '0300-1111111', 'Karachi'),   -- duplicate of 1
    (4,  'Usman',  'Malik',   '0333-3333333', 'Islamabad'),
    (5,  'Sara',   'Ahmed',   '0321-2222222', 'Lahore'),   -- duplicate of 2
    (6,  'Sara',   'Ahmed',   '0321-2222222', 'Lahore'),   -- 3rd copy of 2
    (7,  'Hina',   'Raza',    '0312-4444444', 'Peshawar');
GO

-- Now write your query to find the duplicate rows
WITH duplicate_check AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        phone,
        city,
        ROW_NUMBER() OVER (
            PARTITION BY first_name, last_name, phone 
            ORDER BY customer_id
        ) AS rn
    FROM test_customers
)
SELECT 
    customer_id,
    first_name,
    last_name,
    phone,
    city
FROM duplicate_check
WHERE rn > 1
ORDER BY first_name, last_name, customer_id;
GO


-- ============================================================
--  SECTION D — LAG, LEAD & COALESCE
-- ============================================================

-- Q8.
-- The finance team wants a month-by-month revenue report for 2017.
-- For each month, show total net sales and how much it grew or
-- dropped compared to the previous month.
-- Show month, net_sales, previous_month_sales, and the difference.
-- Net sales = SUM( quantity * list_price * (1 - discount) )

WITH monthly_sales AS (
    SELECT 
        MONTH(o.order_date) AS month,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS net_sales
    FROM sales.orders o
    INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE YEAR(o.order_date) = 2017
    GROUP BY MONTH(o.order_date)
)
SELECT 
    month,
    ROUND(net_sales, 2) AS net_sales,
    ROUND(LAG(net_sales) OVER (ORDER BY month), 2) AS previous_month_sales,
    ROUND(net_sales - LAG(net_sales) OVER (ORDER BY month), 2) AS difference
FROM monthly_sales
ORDER BY month;
GO

-- Q9.
-- The product team wants to see each product's price compared to
-- the next cheaper product in the same category.
-- Show product_name, list_price, and the next lower price
-- in the same category.
-- Sort by category_id and list_price descending.

WITH price_comparison AS (
    SELECT 
        category_id,
        product_name,
        list_price,
        LEAD(list_price) OVER (PARTITION BY category_id ORDER BY list_price DESC) AS next_lower_price
    FROM production.products
)
SELECT 
    product_name,
    list_price,
    next_lower_price
FROM price_comparison
WHERE next_lower_price IS NOT NULL
ORDER BY category_id, list_price DESC;
GO

-- Q10.
-- The CRM team is cleaning up customer records.
-- Some customers have no phone number on file.
-- Show each customer's full name, phone, and email.
-- Replace any missing phone with their email address instead.
-- If both are missing, show 'No Contact Info'.
-- Sort by last_name, first_name.

SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    COALESCE(phone, email, 'No Contact Info') AS contact_info,
    email
FROM sales.customers
ORDER BY last_name, first_name;
GO


-- ============================================================
--  END OF ASSIGNMENT 05
-- ============================================================