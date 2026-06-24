# Task 1: Database Requirement Analysis
**RD INFRO TECHNOLOGY — SQL Internship Program**

---

## 1. Objective
Understand what data is needed and how it should be stored for an e-commerce order management system.

---

## 2. Stakeholder Interview Summary

| Stakeholder      | Role            | Key Requirement                                      |
|------------------|-----------------|------------------------------------------------------|
| Product Manager  | Business Owner  | Track customers, orders, and product catalog         |
| Developer        | Backend Dev     | Need normalized tables with clear PKs and FKs        |
| Sales Team       | End User        | View orders per customer, product stock levels       |
| DBA              | Admin           | Enforce data integrity via constraints and indexes   |

---

## 3. Identified Entities

| Entity        | Description                                      |
|---------------|--------------------------------------------------|
| CUSTOMERS     | People who place orders                          |
| PRODUCTS      | Items available for purchase                     |
| CATEGORIES    | Groupings for products                           |
| ORDERS        | A purchase transaction made by a customer        |
| ORDER_ITEMS   | Individual line items within an order            |

---

## 4. Attributes per Entity

### CUSTOMERS
| Attribute    | Data Type      | Constraint        |
|--------------|----------------|-------------------|
| customer_id  | INT            | PRIMARY KEY, AUTO_INCREMENT |
| full_name    | VARCHAR(100)   | NOT NULL          |
| email        | VARCHAR(150)   | UNIQUE, NOT NULL  |
| phone        | VARCHAR(20)    | NULLABLE          |
| created_at   | TIMESTAMP      | DEFAULT NOW()     |

### CATEGORIES
| Attribute     | Data Type    | Constraint        |
|---------------|--------------|-------------------|
| category_id   | INT          | PRIMARY KEY, AUTO_INCREMENT |
| name          | VARCHAR(100) | NOT NULL          |
| description   | TEXT         | NULLABLE          |

### PRODUCTS
| Attribute    | Data Type      | Constraint                      |
|--------------|----------------|---------------------------------|
| product_id   | INT            | PRIMARY KEY, AUTO_INCREMENT     |
| category_id  | INT            | FOREIGN KEY → CATEGORIES        |
| name         | VARCHAR(150)   | NOT NULL                        |
| price        | DECIMAL(10,2)  | NOT NULL                        |
| stock_qty    | INT            | DEFAULT 0                       |

### ORDERS
| Attribute      | Data Type     | Constraint                      |
|----------------|---------------|---------------------------------|
| order_id       | INT           | PRIMARY KEY, AUTO_INCREMENT     |
| customer_id    | INT           | FOREIGN KEY → CUSTOMERS         |
| status         | VARCHAR(50)   | DEFAULT 'pending'               |
| total_amount   | DECIMAL(10,2) | NOT NULL                        |
| ordered_at     | TIMESTAMP     | DEFAULT NOW()                   |

### ORDER_ITEMS
| Attribute    | Data Type     | Constraint                      |
|--------------|---------------|---------------------------------|
| item_id      | INT           | PRIMARY KEY, AUTO_INCREMENT     |
| order_id     | INT           | FOREIGN KEY → ORDERS            |
| product_id   | INT           | FOREIGN KEY → PRODUCTS          |
| quantity     | INT           | NOT NULL                        |
| unit_price   | DECIMAL(10,2) | NOT NULL                        |

---

## 5. Relationships

| Relationship                        | Cardinality |
|-------------------------------------|-------------|
| CUSTOMERS → ORDERS                  | 1 : Many    |
| ORDERS → ORDER_ITEMS                | 1 : Many    |
| PRODUCTS → ORDER_ITEMS              | 1 : Many    |
| CATEGORIES → PRODUCTS               | 1 : Many    |


---

## 7. Tools Used
- **Google Docs** — Stakeholder interview notes and requirement documentation
- **Excel** — Entity-attribute table structuring
- **Lucidchart** — ER diagram visualization (crow's-foot notation)

---

## 8. Business Rules Captured
- A customer can place zero or many orders.
- An order must belong to exactly one customer.
- An order contains one or more order items.
- Each order item references exactly one product.
- A product belongs to exactly one category.
- Stock quantity must not go negative (enforced via triggers in Task 6).
