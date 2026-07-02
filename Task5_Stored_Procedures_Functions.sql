-- ============================================================
-- Task 5: Stored Procedures & Functions
-- RD INFRO TECHNOLOGY — SQL Internship Program
-- Tools: MySQL CLI / SQL Server Management Studio
-- ============================================================

USE rd_infro_ecommerce;

-- ============================================================
-- SECTION 1: STORED PROCEDURES (no return value, use OUT params)
-- ============================================================

-- ------------------------------------------------------
-- PROCEDURE 1: GetAllCustomers
-- Retrieves every customer record
-- CALL: CALL GetAllCustomers();
-- ------------------------------------------------------
DELIMITER //
CREATE PROCEDURE GetAllCustomers()
BEGIN
    SELECT
        customer_id,
        full_name,
        email,
        phone,
        created_at
    FROM customers
    ORDER BY customer_id;
END //
DELIMITER ;

-- CALL GetAllCustomers();


-- ------------------------------------------------------
-- PROCEDURE 2: GetOrdersByCustomer
-- Fetches all orders for a given customer_id
-- CALL: CALL GetOrdersByCustomer(1);
-- ------------------------------------------------------
DELIMITER //
CREATE PROCEDURE GetOrdersByCustomer(IN p_customer_id INT)
BEGIN
    SELECT
        o.order_id,
        c.full_name   AS customer_name,
        o.status,
        o.total_amount,
        o.ordered_at
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.customer_id = p_customer_id
    ORDER BY o.ordered_at DESC;
END //
DELIMITER ;

-- CALL GetOrdersByCustomer(1);


-- ------------------------------------------------------
-- PROCEDURE 3: AddNewProduct
-- Inserts a new product into the products table
-- CALL: CALL AddNewProduct(1, 'Smart Watch', 4999.00, 25);
-- ------------------------------------------------------
DELIMITER //
CREATE PROCEDURE AddNewProduct(
    IN  p_category_id  INT,
    IN  p_name         VARCHAR(150),
    IN  p_price        DECIMAL(10,2),
    IN  p_stock        INT
)
BEGIN
    -- Guard: price and stock must be non-negative
    IF p_price < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Price cannot be negative';
    ELSEIF p_stock < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock quantity cannot be negative';
    ELSE
        INSERT INTO products(category_id, name, price, stock_qty)
        VALUES (p_category_id, p_name, p_price, p_stock);
        SELECT LAST_INSERT_ID() AS new_product_id;
    END IF;
END //
DELIMITER ;

-- CALL AddNewProduct(1, 'Smart Watch', 4999.00, 25);


-- ------------------------------------------------------
-- PROCEDURE 4: UpdateOrderStatus
-- Updates an order's status by order_id
-- CALL: CALL UpdateOrderStatus(2, 'delivered');
-- ------------------------------------------------------
DELIMITER //
CREATE PROCEDURE UpdateOrderStatus(
    IN p_order_id INT,
    IN p_status   VARCHAR(50)
)
BEGIN
    IF p_status NOT IN ('pending','confirmed','shipped','delivered','cancelled') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid status value';
    ELSE
        UPDATE orders
        SET    status = p_status
        WHERE  order_id = p_order_id;

        IF ROW_COUNT() = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Order not found';
        ELSE
            SELECT CONCAT('Order ', p_order_id, ' updated to ', p_status) AS result;
        END IF;
    END IF;
END //
DELIMITER ;

-- CALL UpdateOrderStatus(2, 'delivered');


-- ------------------------------------------------------
-- PROCEDURE 5: GetCustomerOrderSummary (OUT parameter)
-- Returns number of orders and total spent for a customer
-- CALL: CALL GetCustomerOrderSummary(1, @cnt, @total);
--       SELECT @cnt, @total;
-- ------------------------------------------------------
DELIMITER //
CREATE PROCEDURE GetCustomerOrderSummary(
    IN  p_customer_id  INT,
    OUT p_order_count  INT,
    OUT p_total_spent  DECIMAL(10,2)
)
BEGIN
    SELECT COUNT(*),        SUM(total_amount)
    INTO   p_order_count,  p_total_spent
    FROM   orders
    WHERE  customer_id = p_customer_id;
END //
DELIMITER ;

-- CALL GetCustomerOrderSummary(1, @cnt, @total);
-- SELECT @cnt AS order_count, @total AS total_spent;


-- ============================================================
-- SECTION 2: USER-DEFINED FUNCTIONS (return a single value)
-- ============================================================

-- ------------------------------------------------------
-- FUNCTION 1: CalculateLineTotal
-- Returns quantity × unit_price for an order item
-- Usage: SELECT CalculateLineTotal(3, 799.00);
-- ------------------------------------------------------
DELIMITER //
CREATE FUNCTION CalculateLineTotal(
    p_quantity   INT,
    p_unit_price DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN p_quantity * p_unit_price;
END //
DELIMITER ;

-- SELECT CalculateLineTotal(3, 799.00) AS line_total;


-- ------------------------------------------------------
-- FUNCTION 2: GetCustomerFullLabel
-- Returns "ID - Name <email>" as a formatted label
-- Usage: SELECT GetCustomerFullLabel(1);
-- ------------------------------------------------------
DELIMITER //
CREATE FUNCTION GetCustomerFullLabel(p_customer_id INT)
RETURNS VARCHAR(300)
READS SQL DATA
BEGIN
    DECLARE v_label VARCHAR(300);
    SELECT CONCAT(customer_id, ' - ', full_name, ' <', email, '>')
    INTO   v_label
    FROM   customers
    WHERE  customer_id = p_customer_id;
    RETURN COALESCE(v_label, 'Customer not found');
END //
DELIMITER ;

-- SELECT GetCustomerFullLabel(1);


-- ------------------------------------------------------
-- FUNCTION 3: IsProductInStock
-- Returns 1 (TRUE) if stock > 0, else 0 (FALSE)
-- Usage: SELECT IsProductInStock(3);
-- ------------------------------------------------------
DELIMITER //
CREATE FUNCTION IsProductInStock(p_product_id INT)
RETURNS TINYINT(1)
READS SQL DATA
BEGIN
    DECLARE v_stock INT DEFAULT 0;
    SELECT stock_qty INTO v_stock
    FROM   products
    WHERE  product_id = p_product_id;
    RETURN IF(v_stock > 0, 1, 0);
END //
DELIMITER ;

-- SELECT IsProductInStock(1) AS in_stock;


-- ============================================================
-- SECTION 3: VERIFY — Call all procedures and functions
-- ============================================================

-- Get all customers
CALL GetAllCustomers();

-- Get orders for customer 1 (Alice)
CALL GetOrdersByCustomer(1);

-- Add a new product
CALL AddNewProduct(1, 'Smart Watch', 4999.00, 25);

-- Update order 2 to delivered
CALL UpdateOrderStatus(2, 'delivered');

-- Get summary for customer 1 using OUT params
CALL GetCustomerOrderSummary(1, @cnt, @total);
SELECT @cnt AS order_count, @total AS total_spent;

-- Use scalar functions
SELECT CalculateLineTotal(3, 799.00)   AS line_total;
SELECT GetCustomerFullLabel(1)         AS label;
SELECT IsProductInStock(1)             AS product_1_in_stock;
SELECT IsProductInStock(999)           AS product_999_in_stock;

-- List all stored procedures in database
SHOW PROCEDURE STATUS WHERE Db = 'rd_infro_ecommerce';

-- List all user-defined functions
SHOW FUNCTION STATUS WHERE Db = 'rd_infro_ecommerce';
