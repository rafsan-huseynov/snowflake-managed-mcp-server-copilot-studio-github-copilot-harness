-- =====================================================================
-- STEP 1: Snowflake data setup (sample: Retail Sales)
-- Run blocks in order. If your worksheet only runs the statement under
-- the cursor, select all first before running.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS RETAIL_SALES_DB;
CREATE SCHEMA   IF NOT EXISTS RETAIL_SALES_DB.SALES_SCHEMA;

CREATE TABLE IF NOT EXISTS RETAIL_SALES_DB.SALES_SCHEMA.PRODUCTS (
    PRODUCT_ID   INT AUTOINCREMENT PRIMARY KEY,
    PRODUCT_NAME VARCHAR(255) NOT NULL,
    CATEGORY     VARCHAR(100),
    PRICE        DECIMAL(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS RETAIL_SALES_DB.SALES_SCHEMA.CUSTOMERS (
    CUSTOMER_ID INT AUTOINCREMENT PRIMARY KEY,
    FIRST_NAME  VARCHAR(100) NOT NULL,
    LAST_NAME   VARCHAR(100) NOT NULL,
    CITY        VARCHAR(100),
    STATE       VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS RETAIL_SALES_DB.SALES_SCHEMA.ORDERS (
    ORDER_ID     INT AUTOINCREMENT PRIMARY KEY,
    CUSTOMER_ID  INT NOT NULL,
    PRODUCT_ID   INT NOT NULL,
    QUANTITY     INT NOT NULL,
    ORDER_DATE   DATE NOT NULL,
    TOTAL_AMOUNT DECIMAL(10,2) NOT NULL
);

-- Sample data (synthetic) -------------------------------------------
INSERT INTO RETAIL_SALES_DB.SALES_SCHEMA.PRODUCTS (PRODUCT_NAME, CATEGORY, PRICE) VALUES
('Wireless Mouse','Electronics',25.00),
('Mechanical Keyboard','Electronics',89.00),
('27-inch Monitor','Electronics',299.00),
('USB-C Hub','Electronics',45.00),
('Laptop Stand','Accessories',35.00),
('Office Chair','Furniture',189.00),
('Standing Desk','Furniture',425.00),
('Desk Lamp','Furniture',55.00),
('Notebook Set','Stationery',12.00),
('Pen Pack','Stationery',8.00);

INSERT INTO RETAIL_SALES_DB.SALES_SCHEMA.CUSTOMERS (FIRST_NAME, LAST_NAME, CITY, STATE) VALUES
('James','Miller','Seattle','Washington'),
('Sarah','Johnson','Portland','Oregon'),
('Michael','Davis','San Francisco','California'),
('Emily','Brown','Los Angeles','California'),
('David','Wilson','Austin','Texas'),
('Jessica','Garcia','Dallas','Texas'),
('Daniel','Martinez','Denver','Colorado'),
('Laura','Anderson','Chicago','Illinois'),
('Robert','Taylor','New York','New York'),
('Anna','Thomas','Boston','Massachusetts');

INSERT INTO RETAIL_SALES_DB.SALES_SCHEMA.ORDERS (CUSTOMER_ID, PRODUCT_ID, QUANTITY, ORDER_DATE, TOTAL_AMOUNT) VALUES
(1,3,1,'2026-01-15',299.00),(1,1,2,'2026-01-15',50.00),
(2,6,1,'2026-01-22',189.00),(3,7,1,'2026-02-03',425.00),
(3,2,1,'2026-02-03',89.00),(4,3,2,'2026-02-18',598.00),
(5,6,3,'2026-03-05',567.00),(6,9,5,'2026-03-12',60.00),
(7,4,1,'2026-03-25',45.00),(8,7,1,'2026-04-02',425.00),
(9,3,1,'2026-04-15',299.00),(10,8,2,'2026-04-20',110.00),
(2,1,1,'2026-05-06',25.00),(4,6,1,'2026-05-14',189.00),
(5,3,1,'2026-06-01',299.00),(3,5,2,'2026-06-10',70.00),
(7,7,1,'2026-06-18',425.00),(1,8,1,'2026-06-25',55.00),
(6,3,2,'2026-06-28',598.00),(9,2,1,'2026-06-30',89.00);

-- Sanity check ------------------------------------------------------
SELECT COUNT(*) AS PRODUCTS  FROM RETAIL_SALES_DB.SALES_SCHEMA.PRODUCTS;
SELECT COUNT(*) AS CUSTOMERS FROM RETAIL_SALES_DB.SALES_SCHEMA.CUSTOMERS;
SELECT COUNT(*) AS ORDERS    FROM RETAIL_SALES_DB.SALES_SCHEMA.ORDERS;

-- Cost control: auto-suspend + a small resource monitor -------------
ALTER WAREHOUSE COMPUTE_WH SET AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;

CREATE OR REPLACE RESOURCE MONITOR DEMO_BUDGET
  WITH CREDIT_QUOTA = 3
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 75  PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND
    ON 110 PERCENT DO SUSPEND_IMMEDIATE;
ALTER WAREHOUSE COMPUTE_WH SET RESOURCE_MONITOR = DEMO_BUDGET;
