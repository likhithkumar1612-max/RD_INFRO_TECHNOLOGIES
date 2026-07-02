-- ============================================================
-- Task 7: Performance Optimization
-- RD INFRO TECHNOLOGY — SQL Internship Program
-- Tools: EXPLAIN PLAN, Indexes, Query Profiler
-- ============================================================

USE rd_infro_ecommerce;

-- ============================================================
-- SECTION 1: EXPLAIN — Analyse query execution plans
-- ============================================================

-- Before adding indexes, use EXPLAIN to see how MySQL scans
-- (type: ALL = full table scan → bad for large tables)

-- Check how MySQL searches customers by email (no index yet)
EXPLAIN SELECT * FROM customers WHERE email = 'alice@example.com';

-- Check how MySQL joins orders to customers
EXPLAIN
SELECT o.order_id, c.full_name, o.total_amount
FROM   orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE  o.status = 'delivered';

-- Full query plan for multi-table join
EXPLAIN
SELECT
    c.full_name,
    p.name           AS product,
    oi.quantity,
    oi.unit_price
FROM orders o
INNER JOIN customers   c  ON o.customer_id  = c.customer_id
INNER JOIN order_items oi ON o.order_id     = oi.order_id
INNER JOIN products    p  ON oi.product_id  = p.product_id
WHERE o.status = 'shipped';

-- ============================================================
-- SECTION 2: CREATE INDEXES
-- Index types: Regular, Unique, Composite, Full-Text
-- ============================================================

-- INDEX on customers.email (very frequently searched)
CREATE INDEX idx_customers_email
    ON customers(email);

-- INDEX on orders.customer_id (FK joins are common)
CREATE INDEX idx_orders_customer_id
    ON orders(customer_id);

-- INDEX on orders.status (filtering orders by status)
CREATE INDEX idx_orders_status
    ON orders(status);

-- INDEX on orders.ordered_at (sorting/date range queries)
CREATE INDEX idx_orders_ordered_at
    ON orders(ordered_at);

-- INDEX on order_items.order_id (join from orders to items)
CREATE INDEX idx_order_items_order_id
    ON order_items(order_id);

-- INDEX on order_items.product_id (join to products)
CREATE INDEX idx_order_items_product_id
    ON order_items(product_id);

-- INDEX on products.category_id (join to categories)
CREATE INDEX idx_products_category_id
    ON products(category_id);

-- INDEX on products.price (sorted listings / range queries)
CREATE INDEX idx_products_price
    ON products(price);

-- COMPOSITE INDEX: status + ordered_at (used together in WHERE + ORDER BY)
CREATE INDEX idx_orders_status_date
    ON orders(status, ordered_at);

-- COMPOSITE INDEX: order_id + product_id on order_items (covering index)
CREATE INDEX idx_order_items_composite
    ON order_items(order_id, product_id);

-- FULL-TEXT index on products.name (for search-like queries)
CREATE FULLTEXT INDEX idx_products_name_ft
    ON products(name);

-- ============================================================
-- SECTION 3: EXPLAIN AFTER INDEXES
-- Compare execution plans — type should change to 'ref' or 'range'
-- ============================================================

-- Now check: MySQL should use idx_customers_email
EXPLAIN SELECT * FROM customers WHERE email = 'alice@example.com';

-- Range scan on price
EXPLAIN SELECT * FROM products WHERE price BETWEEN 500 AND 2000;

-- Full-text search using MATCH...AGAINST
EXPLAIN
SELECT product_id, name, price
FROM   products
WHERE  MATCH(name) AGAINST('keyboard' IN BOOLEAN MODE);

-- ============================================================
-- SECTION 4: QUERY OPTIMISATION TECHNIQUES
-- ============================================================

-- ❌ BAD: SELECT * fetches unnecessary columns
-- SELECT * FROM orders WHERE status = 'delivered';

-- ✅ GOOD: Select only needed columns
SELECT order_id, customer_id, total_amount, ordered_at
FROM   orders
WHERE  status = 'delivered'
ORDER BY ordered_at DESC;


-- ❌ BAD: Function on indexed column disables the index
-- SELECT * FROM customers WHERE UPPER(email) = 'ALICE@EXAMPLE.COM';

-- ✅ GOOD: Store consistently and search directly
SELECT * FROM customers WHERE email = 'alice@example.com';


-- ❌ BAD: OR on different columns prevents index use
-- SELECT * FROM customers WHERE email = 'x@y.com' OR full_name = 'Alice';

-- ✅ GOOD: Use UNION instead
SELECT customer_id, full_name, email FROM customers WHERE email     = 'alice@example.com'
UNION
SELECT customer_id, full_name, email FROM customers WHERE full_name = 'Alice Johnson';


-- ❌ BAD: Wildcard at the start prevents index use
-- SELECT * FROM products WHERE name LIKE '%keyboard%';

-- ✅ GOOD: Use FULLTEXT search (requires FULLTEXT index)
SELECT product_id, name, price
FROM   products
WHERE  MATCH(name) AGAINST('keyboard' IN BOOLEAN MODE);


-- ✅ GOOD: LIMIT to avoid fetching all rows when only top N needed
SELECT product_id, name, price
FROM   products
ORDER BY price DESC
LIMIT 10;


-- ✅ GOOD: Use EXISTS instead of IN for large sub-result sets
SELECT c.customer_id, c.full_name
FROM   customers c
WHERE  EXISTS (
    SELECT 1
    FROM   orders o
    WHERE  o.customer_id = c.customer_id
    AND    o.status = 'delivered'
);

-- ============================================================
-- SECTION 5: QUERY PROFILER (MySQL specific)
-- Enable to see time spent in each query stage
-- ============================================================

-- Enable profiling
SET profiling = 1;

-- Run a sample query
SELECT
    c.full_name,
    SUM(o.total_amount) AS total_spent
FROM   customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spent DESC;

-- View the execution profile
SHOW PROFILES;

-- View details for the last query (replace 1 with query_id from SHOW PROFILES)
SHOW PROFILE FOR QUERY 1;

-- ============================================================
-- SECTION 6: VIEW ALL INDEXES ON TABLES
-- ============================================================

SHOW INDEX FROM customers;
SHOW INDEX FROM products;
SHOW INDEX FROM orders;
SHOW INDEX FROM order_items;

-- ============================================================
-- SECTION 7: DROP INDEXES (cleanup if needed)
-- ============================================================

-- DROP INDEX idx_orders_status ON orders;
-- DROP INDEX idx_products_price ON products;
