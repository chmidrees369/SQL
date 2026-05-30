CREATE DATABASE BikeStores;
USE BikeStores;

SELECT * FROM production.categories;
SELECT * FROM production.brands;
SELECT * FROM production.products;
SELECT * FROM sales.customers;
SELECT * FROM sales.stores;
SELECT * FROM sales.staffs;
SELECT * FROM sales.orders;
SELECT * FROM sales.order_items;
SELECT * FROM production.stocks;
SELECT * FROM sales.customers;

SELECT first_name,last_name, email FROM sales.staffs;
SELECT first_name ,last_name, email FROM sales.customers;

SELECT DISTINCT city FROM sales.customers;

-- ============================================================
--  ASSIGNMENT 01 — Querying, Sorting & Filtering
--  Database : BikeStores
--  Topics   : SELECT, WHERE, ORDER BY, TOP/OFFSET-FETCH,
--             DISTINCT, AND / OR
-- ============================================================

-- ============================================================
--  Question 1 — SELECT & WHERE
--  Retrieve the first name, last name, city, and phone number
--  of all customers who live in the state of 'CA' (California)
--  and have a phone number on record.
-- ============================================================

SELECT first_name,
       last_name,
       city,
       phone
From sales.customers
WHERE state = 'CA' AND phone IS NOT NULL;


-- ============================================================
--  Question 2 — ORDER BY (Multiple Columns)
--  Fetch the product_id, product_name, model_year, and
--  list_price of all products.
--  Sort the results by model_year in descending order, and
--  within the same year sort by list_price in ascending order.
-- ============================================================

SELECT product_id,
       product_name,
       model_year,
       list_price
From production.products
ORDER BY model_year DESC, list_price ASC;


-- ============================================================
--  Question 3 — TOP N & TOP PERCENT
--  a) Return the top 5 most expensive products showing only
--     product_name and list_price.
--  b) Return the top 5% of cheapest products (all columns).
--     How many rows does the 5% result return? Add the row
--     count as a comment in your answer.
-- ============================================================

-- Part a:
SELECT TOP 5 product_name,
             list_price
From production.products
ORDER BY list_price DESC;


-- Part b:
SELECT TOP 5 PERCENT * 
FROM production.products
ORDER BY list_price ASC;


-- ============================================================
--  Question 4 — OFFSET & FETCH (Pagination)
--  The sales team wants to browse products page by page,
--  10 products per page, sorted by list_price descending.
--  Write queries to return:
--    a) Page 1  (rows  1 – 10)
--    b) Page 2  (rows 11 – 20)
--    c) Page 3  (rows 21 – 30)
-- ============================================================

-- Page 1:
SELECT product_id,
       product_name,
       model_year,
       list_price
FROM production.products
ORDER BY list_price DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Page 2:
SELECT product_id,
       product_name,
       model_year,
       list_price
FROM production.products  
ORDER BY list_price DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- Page 3:
SELECT product_id,
       product_name,
       model_year,
       list_price
FROM production.products
ORDER BY list_price DESC
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;


-- ============================================================
--  Question 5 — DISTINCT
--  a) List all unique states in which BikeStores has customers.
--     Sort the result alphabetically.
--  b) List every unique combination of state and city,
--     sorted by state then city (both ascending).
--  c) How many unique model years exist in the products table?
--     (Retrieve the distinct values; count them manually or
--     use COUNT — your choice.)
-- ============================================================

-- Part a:
SELECT DISTINCT state
FROM sales.customers
ORDER BY state ASC;

-- Part b:
SELECT DISTINCT state, city
FROM sales.customers
ORDER BY state ASC, city ASC;

-- Part c:
SELECT COUNT(DISTINCT model_year) AS unique_model_years
FROM production.products;

SELECT DISTINCT model_year
FROM production.products
ORDER BY model_year ASC;


-- ============================================================
--  Question 6 — Logical Operators (AND / OR)
--  Write a single query that returns the product_id,
--  product_name, brand_id, category_id, and list_price for
--  products that meet ALL of the following conditions:
--    • list_price is between $500 and $1500 (inclusive)
--    • model_year is 2019 OR 2020
--  Sort the results by list_price ascending.
--  Hint: use parentheses to control the order of evaluation.
-- ============================================================

SELECT product_id,
       product_name,
       brand_id,
       category_id,
       list_price
FROM production.products 
WHERE list_price BETWEEN 500 AND 1500
AND (model_year = 2019 OR model_year = 2020)
ORDER BY list_price ASC;

SELECT category_id,
       MAX(list_price) as max_price,
       MIN(list_price) as min_price
FROM production.products
GROUP BY category_id

SELECT * FROM sales.orders
WHERE customer_id IN (
SELECT customer_id 
FROM sales.customers 
WHERE city = 'New York')


SELECT  product_id,
       product_name,
       list_price
FROM production.products
WHERE list_price > (  
SELECT AVG(list_price)
FROM production.products
)

-- See all tables self made in the current database:
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- See all system tables in the current database:
SELECT * FROM sys.tables;

-- See all tables in the current database (only names):
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES;

-- ALL databes dekhana System ki aur jo khud banai ho
SELECT * FROM sys.databases;

-- Sirf ak he database dekhani ho
SELECT  name
FROM sys.databases
WHERE name = 'BikeStores';

-- SQL Server me agar aap check karni ho
IF DB_ID('BikeStores') IS NOT NULL
PRINT 'Database Exists'

-- Agar database create karni ho only if not exists
IF DB_ID('BikeStores') IS NULL
CREATE DATABASE BikeStores

