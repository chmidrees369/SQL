-- ============================================================
--   ASSIGNMENT 03 — GROUP BY, HAVING & SUBQUERIES
--   Database  : BikeStores
--   Topics    : GROUP BY · Aggregate Functions · HAVING
--               Subqueries · JOINs with GROUP BY
-- ============================================================


-- ============================================================
--  SECTION A — GROUP BY & AGGREGATE FUNCTIONS
-- ============================================================

-- Q1.
-- Count the total number of orders placed by each customer.
-- Show customer_id and order_count.
-- Sort by order_count descending.

SELECT 
    customer_id,
    COUNT(order_id) AS order_count
FROM sales.orders
GROUP BY customer_id
ORDER BY order_count DESC;


-- Q2.
-- For each store, find the total number of orders placed.
-- Show store_id and total_orders.

SELECT 
    store_id,
    COUNT(order_id) AS total_orders
FROM sales.orders
GROUP BY store_id
ORDER BY store_id;


-- Q3.
-- Calculate the net revenue per order.
-- Net revenue formula: SUM( quantity * list_price * (1 - discount) )
-- Show order_id and net_revenue, sorted by net_revenue descending.

SELECT 
    order_id,
    SUM(quantity * list_price * (1 - discount)) AS net_revenue
FROM sales.order_items
GROUP BY order_id
ORDER BY net_revenue DESC;


-- Q4.
-- Find the average list price of products in each category.
-- Show category_id and avg_price (rounded to 2 decimal places).

SELECT 
    category_id,
    ROUND(AVG(list_price), 2) AS avg_price
FROM production.products
GROUP BY category_id
ORDER BY category_id;


-- Q5.
-- Find the total number of orders placed in each year.
-- Show order_year and total_orders, sorted by order_year.

SELECT 
    YEAR(order_date) AS order_year,
    COUNT(order_id) AS total_orders
FROM sales.orders
GROUP BY YEAR(order_date)
ORDER BY order_year;


-- ============================================================
--  SECTION B — HAVING CLAUSE
-- ============================================================

-- Q6.
-- Find customers who have placed MORE than 5 orders in total.
-- Show customer_id and order_count.

SELECT 
    customer_id,
    COUNT(order_id) AS order_count
FROM sales.orders
GROUP BY customer_id
HAVING COUNT(order_id) > 5
ORDER BY order_count DESC;


-- Q7.
-- Find categories where the AVERAGE list price is greater than $1,500.
-- Show category_id and avg_price.

SELECT 
    category_id,
    ROUND(AVG(list_price), 2) AS avg_price
FROM production.products
GROUP BY category_id
HAVING AVG(list_price) > 1500
ORDER BY avg_price DESC;


-- Q8.
-- Find customers who placed at least 2 orders in the year 2017.
-- Show customer_id, order_year, and order_count.

SELECT 
    customer_id,
    YEAR(order_date) AS order_year,
    COUNT(order_id) AS order_count
FROM sales.orders
WHERE YEAR(order_date) = 2017
GROUP BY customer_id, YEAR(order_date)
HAVING COUNT(order_id) >= 2
ORDER BY order_count DESC;


-- ============================================================
--  SECTION C — SUBQUERIES
-- ============================================================

-- Q9.
-- Find all orders placed by customers who live in 'Houston'.
-- Use a subquery to get the customer_ids first.

SELECT *
FROM sales.orders
WHERE customer_id IN (
    SELECT customer_id
    FROM sales.customers
    WHERE city = 'Houston'
)
ORDER BY order_id;


-- Q10.
-- Find all products whose list_price is greater than the
-- AVERAGE list_price of ALL products.

SELECT 
    product_name,
    list_price
FROM production.products
WHERE list_price > (
    SELECT AVG(list_price)
    FROM production.products
)
ORDER BY list_price DESC;


-- Q11.
-- Find all products that belong to the category 'Mountain Bikes'
-- or 'Road Bikes'. Use a subquery on production.categories.

SELECT 
    product_name,
    list_price
FROM production.products
WHERE category_id IN (
    SELECT category_id
    FROM production.categories
    WHERE category_name IN ('Mountain Bikes', 'Road Bikes')
)
ORDER BY product_name;


-- Q12.
-- Find all customers who have NEVER placed an order.
-- Show customer_id, first_name, and last_name.

SELECT 
    customer_id,
    first_name,
    last_name
FROM sales.customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id
    FROM sales.orders
    WHERE customer_id IS NOT NULL
)
ORDER BY customer_id;


-- ============================================================
--  SECTION D — JOINs WITH GROUP BY
-- ============================================================

-- Q13.
-- Find the total number of orders per city (customer's city).
-- Join sales.orders with sales.customers.

SELECT 
    c.city,
    COUNT(o.order_id) AS total_orders
FROM sales.orders o
INNER JOIN sales.customers c ON o.customer_id = c.customer_id
GROUP BY c.city
ORDER BY total_orders DESC;


-- Q14.
-- For each staff member, count how many orders they handled.
-- Join sales.orders with sales.staffs.

SELECT 
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
    COUNT(o.order_id) AS order_count
FROM sales.orders o
INNER JOIN sales.staffs s ON o.staff_id = s.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY order_count DESC;


-- Q15. (BONUS — Multi-concept)
-- Find customers who have spent more than $10,000 in total.
-- Join sales.customers → sales.orders → sales.order_items.

SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
FROM sales.customers c
INNER JOIN sales.orders o ON c.customer_id = o.customer_id
INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 10000
ORDER BY total_spent DESC;


-- ============================================================
--  END OF ASSIGNMENT 03
-- ============================================================