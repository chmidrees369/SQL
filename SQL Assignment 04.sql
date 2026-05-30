-- ============================================================
--   ASSIGNMENT 04 — SET OPERATORS, CTEs, CONSTRAINTS & CASES
--   Database  : BikeStores
--   Topics    : UNION / UNION ALL / INTERSECT / EXCEPT
--               CTEs (Single & Multiple)
--               Constraints (PK, FK, NOT NULL, UNIQUE, CHECK)
--               CASE Expressions
-- ============================================================


-- ============================================================
--  SECTION A — SET OPERATORS
-- ============================================================

-- Q1.
-- The marketing team wants a single contact list of everyone in the system
-- — both staff members and customers.
-- Build a unified list showing full name and email for all of them.
-- Make sure no one is accidentally listed twice.

SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    email
FROM sales.customers

UNION

SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    email
FROM sales.staffs
ORDER BY full_name;


-- Q2.
-- The logistics team wants to know which states have BOTH
-- a store location AND customers living there.
-- Find those states.

SELECT state FROM sales.stores
INTERSECT
SELECT state FROM sales.customers
ORDER BY state;


-- Q3.
-- Management wants to identify stores that received zero orders
-- in the year 2018.
-- Find the store_ids that appear in sales.stores but did NOT
-- receive any orders in 2018.

SELECT store_id FROM sales.stores
EXCEPT
SELECT DISTINCT store_id 
FROM sales.orders 
WHERE YEAR(order_date) = 2018
ORDER BY store_id;


-- ============================================================
--  SECTION B — CTEs
-- ============================================================

-- Q4.
-- The pricing team wants to flag overpriced products.
-- For each category, find all products whose list_price is
-- higher than the average list_price of their own category.
-- Show category_id, product_name, list_price, and the category average.

WITH category_avg AS (
    SELECT 
        category_id,
        AVG(list_price) AS avg_category_price
    FROM production.products
    GROUP BY category_id
)
SELECT 
    p.category_id,
    p.product_name,
    p.list_price,
    ROUND(ca.avg_category_price, 2) AS category_avg_price
FROM production.products p
INNER JOIN category_avg ca ON p.category_id = ca.category_id
WHERE p.list_price > ca.avg_category_price
ORDER BY p.category_id, p.list_price DESC;


-- Q5.
-- HR wants to reward the hardest-working staff member.
-- Find all staff members whose order count is higher than
-- the average order count across all staff.
-- Show staff_id and their order_count.

WITH staff_order_counts AS (
    SELECT 
        staff_id,
        COUNT(order_id) AS order_count
    FROM sales.orders
    GROUP BY staff_id
),
avg_order_count AS (
    SELECT AVG(order_count) AS avg_orders
    FROM staff_order_counts
)
SELECT 
    staff_id,
    order_count
FROM staff_order_counts
WHERE order_count > (SELECT avg_orders FROM avg_order_count)
ORDER BY order_count DESC;


-- Q6.
-- The finance team needs a yearly performance report per store.
-- For each store and each year, calculate total revenue.
-- Then find only the years where a store's revenue
-- exceeded $1,000,000.
-- Show store_id, year, and total_revenue.

WITH store_yearly_revenue AS (
    SELECT 
        o.store_id,
        YEAR(o.order_date) AS year,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
    FROM sales.orders o
    INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.store_id, YEAR(o.order_date)
)
SELECT 
    store_id,
    year,
    ROUND(total_revenue, 2) AS total_revenue
FROM store_yearly_revenue
WHERE total_revenue > 1000000
ORDER BY store_id, year;


-- ============================================================
--  SECTION C — CONSTRAINTS (DDL)
-- ============================================================

-- Q7.
-- The business wants to launch a customer loyalty program.
-- Below is the table structure. Your job is to add the correct constraints:

-- Complete table creation with all constraints:
CREATE TABLE sales.loyalty_cards (
    card_number   INT PRIMARY KEY,
    customer_id   INT NOT NULL,
    points        INT NOT NULL CHECK (points >= 0),
    tier          VARCHAR(10) NOT NULL CHECK (tier IN ('Bronze', 'Silver', 'Gold')),
    join_date     DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES sales.customers (customer_id) ON DELETE CASCADE
);

-- Once the table is created, run these inserts to verify your constraints work:

INSERT INTO sales.loyalty_cards VALUES (1001, 1,  500,  'Gold',   '2024-01-15');
INSERT INTO sales.loyalty_cards VALUES (1002, 2,  150,  'Silver', '2024-03-22');
INSERT INTO sales.loyalty_cards VALUES (1003, 3,  0,    'Bronze', '2024-06-01');

-- Also try these to confirm your constraints REJECT bad data:
-- INSERT INTO sales.loyalty_cards VALUES (1001, 4,  100,  'Gold',   '2024-07-01'); -- duplicate card_number (fails PK)
-- INSERT INTO sales.loyalty_cards VALUES (1004, 1,  -50,  'Silver', '2024-08-01'); -- negative points (fails CHECK)
-- INSERT INTO sales.loyalty_cards VALUES (1005, 5,  200,  'Diamond','2024-09-01'); -- invalid tier (fails CHECK)


-- Q8.
-- The operations team realized that some orders in the database have
-- a shipped_date that is earlier than the order_date, which is impossible.
-- Add a rule to the table below that prevents this from happening.

-- Run this setup first:

CREATE TABLE test_orders (
    order_id      INT PRIMARY KEY,
    order_date    DATE NOT NULL,
    shipped_date  DATE
);

INSERT INTO test_orders VALUES (1, '2024-01-10', '2024-01-13');
INSERT INTO test_orders VALUES (2, '2024-02-05', '2024-02-07');
INSERT INTO test_orders VALUES (3, '2024-03-01', NULL);

-- Now add the constraint using ALTER TABLE:
ALTER TABLE test_orders
ADD CONSTRAINT chk_shipped_after_order 
CHECK (shipped_date IS NULL OR shipped_date >= order_date);

-- After adding it, test with:
-- INSERT INTO test_orders VALUES (4, '2024-04-10', '2024-04-08'); -- should FAIL
-- INSERT INTO test_orders VALUES (5, '2024-04-10', '2024-04-15'); -- should PASS


-- ============================================================
--  SECTION D — CASE EXPRESSIONS
-- ============================================================

-- Q9.
-- The sales team wants to see how quickly each order was shipped.
-- Using the difference between shipped_date and order_date:

SELECT 
    order_id,
    order_date,
    shipped_date,
    CASE 
        WHEN shipped_date IS NULL THEN 'Pending'
        WHEN DATEDIFF(day, order_date, shipped_date) <= 2 THEN 'Fast'
        WHEN DATEDIFF(day, order_date, shipped_date) <= 5 THEN 'Normal'
        ELSE 'Delayed'
    END AS shipping_speed
FROM sales.orders
ORDER BY order_id;


-- Q10.
-- The warehouse team wants to label stock levels for each product per store.
-- Using production.stocks:

SELECT 
    store_id,
    product_id,
    quantity,
    CASE 
        WHEN quantity = 0 THEN 'Out of Stock'
        WHEN quantity BETWEEN 1 AND 10 THEN 'Low Stock'
        WHEN quantity BETWEEN 11 AND 50 THEN 'Sufficient'
        WHEN quantity > 50 THEN 'Well Stocked'
        ELSE 'Unknown'
    END AS stock_status
FROM production.stocks
ORDER BY store_id, quantity ASC;


-- ============================================================
--  END OF ASSIGNMENT 04
-- ============================================================