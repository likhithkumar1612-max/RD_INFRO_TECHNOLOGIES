-- ============================================================
-- Task 6: Triggers and Constraints
-- RD INFRO TECHNOLOGY — SQL Internship Program
-- Tools: MySQL / PostgreSQL
-- ============================================================

USE rd_infro_ecommerce;

-- ============================================================
-- SETUP: Audit / Log tables used by triggers
-- ============================================================

-- Logs table: records every insert/update/delete event
CREATE TABLE IF NOT EXISTS activity_logs (
    log_id      INT           NOT NULL AUTO_INCREMENT,
    table_name  VARCHAR(100)  NOT NULL,
    action      VARCHAR(10)   NOT NULL,   -- INSERT / UPDATE / DELETE
    record_id   INT,
    description VARCHAR(500),
    logged_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_logs PRIMARY KEY (log_id)
);

-- Order history: tracks every status change on an order
CREATE TABLE IF NOT EXISTS order_status_history (
    history_id  INT          NOT NULL AUTO_INCREMENT,
    order_id    INT          NOT NULL,
    old_status  VARCHAR(50),
    new_status  VARCHAR(50),
    changed_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_order_history PRIMARY KEY (history_id)
);

-- ============================================================
-- SECTION 1: AFTER INSERT TRIGGERS
-- ============================================================

-- TRIGGER 1: Log every new customer added
DELIMITER //
CREATE TRIGGER after_insert_customer
AFTER INSERT ON customers
FOR EACH ROW
BEGIN
    INSERT INTO activity_logs (table_name, action, record_id, description)
    VALUES (
        'customers',
        'INSERT',
        NEW.customer_id,
        CONCAT('New customer added: ', NEW.full_name, ' (', NEW.email, ')')
    );
END //
DELIMITER ;


-- TRIGGER 2: Log every new product added
DELIMITER //
CREATE TRIGGER after_insert_product
AFTER INSERT ON products
FOR EACH ROW
BEGIN
    INSERT INTO activity_logs (table_name, action, record_id, description)
    VALUES (
        'products',
        'INSERT',
        NEW.product_id,
        CONCAT('New product added: ', NEW.name, ' | Price: ', NEW.price, ' | Stock: ', NEW.stock_qty)
    );
END //
DELIMITER ;


-- TRIGGER 3: Auto-reduce stock when an order item is inserted
DELIMITER //
CREATE TRIGGER after_insert_order_item
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    -- Reduce product stock by the ordered quantity
    UPDATE products
    SET    stock_qty = stock_qty - NEW.quantity
    WHERE  product_id = NEW.product_id;

    -- Log the stock reduction
    INSERT INTO activity_logs (table_name, action, record_id, description)
    VALUES (
        'order_items',
        'INSERT',
        NEW.item_id,
        CONCAT('Order item added: product_id=', NEW.product_id,
               ', qty=', NEW.quantity,
               ' for order_id=', NEW.order_id)
    );
END //
DELIMITER ;


-- ============================================================
-- SECTION 2: BEFORE INSERT TRIGGERS
-- ============================================================

-- TRIGGER 4: Prevent inserting an order item if product is out of stock
DELIMITER //
CREATE TRIGGER before_insert_order_item
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_stock INT;

    SELECT stock_qty INTO v_stock
    FROM   products
    WHERE  product_id = NEW.product_id;

    IF v_stock IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product does not exist';
    ELSEIF NEW.quantity > v_stock THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient stock for this product';
    END IF;
END //
DELIMITER ;


-- TRIGGER 5: Prevent duplicate email on customer insert (extra guard)
DELIMITER //
CREATE TRIGGER before_insert_customer
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM   customers
    WHERE  email = NEW.email;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A customer with this email already exists';
    END IF;
END //
DELIMITER ;


-- ============================================================
-- SECTION 3: AFTER UPDATE TRIGGERS
-- ============================================================

-- TRIGGER 6: Log every order status change
DELIMITER //
CREATE TRIGGER after_update_order_status
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        -- History table
        INSERT INTO order_status_history (order_id, old_status, new_status)
        VALUES (NEW.order_id, OLD.status, NEW.status);

        -- Activity log
        INSERT INTO activity_logs (table_name, action, record_id, description)
        VALUES (
            'orders',
            'UPDATE',
            NEW.order_id,
            CONCAT('Order ', NEW.order_id, ' status changed: ',
                   OLD.status, ' → ', NEW.status)
        );
    END IF;
END //
DELIMITER ;


-- TRIGGER 7: Log product price changes
DELIMITER //
CREATE TRIGGER after_update_product_price
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    IF OLD.price <> NEW.price THEN
        INSERT INTO activity_logs (table_name, action, record_id, description)
        VALUES (
            'products',
            'UPDATE',
            NEW.product_id,
            CONCAT('Price changed for "', NEW.name, '": ',
                   OLD.price, ' → ', NEW.price)
        );
    END IF;
END //
DELIMITER ;


-- ============================================================
-- SECTION 4: AFTER DELETE TRIGGERS
-- ============================================================

-- TRIGGER 8: Log customer deletions
DELIMITER //
CREATE TRIGGER after_delete_customer
AFTER DELETE ON customers
FOR EACH ROW
BEGIN
    INSERT INTO activity_logs (table_name, action, record_id, description)
    VALUES (
        'customers',
        'DELETE',
        OLD.customer_id,
        CONCAT('Customer deleted: ', OLD.full_name, ' (', OLD.email, ')')
    );
END //
DELIMITER ;


-- TRIGGER 9: Restore stock when an order item is deleted
DELIMITER //
CREATE TRIGGER after_delete_order_item
AFTER DELETE ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET    stock_qty = stock_qty + OLD.quantity
    WHERE  product_id = OLD.product_id;

    INSERT INTO activity_logs (table_name, action, record_id, description)
    VALUES (
        'order_items',
        'DELETE',
        OLD.item_id,
        CONCAT('Order item removed: product_id=', OLD.product_id,
               ', qty=', OLD.quantity, ' restored to stock')
    );
END //
DELIMITER ;


-- ============================================================
-- SECTION 5: CONSTRAINTS SUMMARY
-- (already applied in Task 2 — shown here for reference)
-- ============================================================

-- PRIMARY KEY constraint
-- ALTER TABLE customers ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);

-- UNIQUE constraint
-- ALTER TABLE customers ADD CONSTRAINT uq_email UNIQUE (email);

-- FOREIGN KEY with ON DELETE / ON UPDATE rules
-- ALTER TABLE orders ADD CONSTRAINT fk_cust
--     FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
--     ON UPDATE CASCADE ON DELETE RESTRICT;

-- CHECK constraint (MySQL 8+)
-- ALTER TABLE products ADD CONSTRAINT chk_price CHECK (price >= 0);
-- ALTER TABLE products ADD CONSTRAINT chk_stock CHECK (stock_qty >= 0);

-- DEFAULT constraint
-- ALTER TABLE orders ALTER status SET DEFAULT 'pending';


-- ============================================================
-- SECTION 6: VERIFY TRIGGERS
-- ============================================================

-- See all triggers in the database
SHOW TRIGGERS FROM rd_infro_ecommerce;

-- Test TRIGGER 1 + 5: Insert a new customer
INSERT INTO customers (full_name, email, phone)
VALUES ('Frank Test', 'frank@example.com', '9001122334');

-- Test TRIGGER 3: Add an order item → should reduce stock
-- First check current stock for product 9 (Yoga Mat → 90)
SELECT product_id, name, stock_qty FROM products WHERE product_id = 9;

-- Test order item insert (order 5 already has product 9 in data; use a new insert)
-- NOTE: This will trigger before_insert + after_insert
-- INSERT INTO order_items (order_id, product_id, quantity, unit_price)
-- VALUES (5, 9, 1, 849.00);

-- Test TRIGGER 6: Update an order status
UPDATE orders SET status = 'shipped' WHERE order_id = 3;

-- View all logs
SELECT * FROM activity_logs   ORDER BY logged_at DESC;
SELECT * FROM order_status_history ORDER BY changed_at DESC;
