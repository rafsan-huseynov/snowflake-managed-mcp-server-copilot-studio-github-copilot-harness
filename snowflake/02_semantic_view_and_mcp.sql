-- =====================================================================
-- STEP 2: Semantic view, MCP server (two tools), RBAC, delegate user
-- =====================================================================
-- CRITICAL GOTCHA:
--   CREATE OR REPLACE MCP SERVER DROPS ALL GRANTS on the server object.
--   Every rebuild, you MUST re-grant USAGE to your role in the same run,
--   or Copilot Studio shows "No tools found" while login still succeeds.
-- =====================================================================

-- 1) Semantic view: the plain-English "map" Cortex Analyst needs -----
CREATE OR REPLACE SEMANTIC VIEW RETAIL_SALES_DB.SALES_SCHEMA.SALES_ANALYST
  TABLES (
    orders    AS RETAIL_SALES_DB.SALES_SCHEMA.ORDERS    PRIMARY KEY (ORDER_ID),
    customers AS RETAIL_SALES_DB.SALES_SCHEMA.CUSTOMERS PRIMARY KEY (CUSTOMER_ID),
    products  AS RETAIL_SALES_DB.SALES_SCHEMA.PRODUCTS  PRIMARY KEY (PRODUCT_ID)
  )
  RELATIONSHIPS (
    orders_to_customers AS orders (CUSTOMER_ID) REFERENCES customers (CUSTOMER_ID),
    orders_to_products  AS orders (PRODUCT_ID)  REFERENCES products  (PRODUCT_ID)
  )
  FACTS (
    orders.quantity   AS orders.QUANTITY,
    orders.line_total AS orders.TOTAL_AMOUNT
  )
  DIMENSIONS (
    orders.order_date       AS orders.ORDER_DATE,
    customers.customer_name AS customers.FIRST_NAME || ' ' || customers.LAST_NAME,
    customers.city          AS customers.CITY,
    customers.state         AS customers.STATE,
    products.product_name   AS products.PRODUCT_NAME,
    products.category       AS products.CATEGORY
  )
  METRICS (
    orders.total_revenue AS SUM(orders.TOTAL_AMOUNT),
    orders.total_units   AS SUM(orders.QUANTITY),
    orders.order_count   AS COUNT(orders.ORDER_ID)
  );

-- Optional test of the view:
-- SELECT * FROM SEMANTIC_VIEW(
--   RETAIL_SALES_DB.SALES_SCHEMA.SALES_ANALYST
--   METRICS orders.total_revenue DIMENSIONS products.category);

-- 2) MCP server with TWO tools ---------------------------------------
--    sales_analyst : Cortex Analyst (plain English -> SQL)
--    run_sql       : executes the SQL and returns REAL rows
CREATE OR REPLACE MCP SERVER RETAIL_SALES_DB.SALES_SCHEMA.SALES_MCP_SERVER
FROM SPECIFICATION $$
  tools:
    - name: "sales_analyst"
      type: "CORTEX_ANALYST_MESSAGE"
      identifier: "RETAIL_SALES_DB.SALES_SCHEMA.SALES_ANALYST"
      title: "Sales Analyst"
      description: "Turns a plain English question about sales into SQL. Use for revenue, orders, customers, products, categories."
    - name: "run_sql"
      type: "SYSTEM_EXECUTE_SQL"
      title: "Run SQL"
      description: "Executes SQL and returns the actual data rows. Always call this with the SQL that sales_analyst produces."
$$;

-- 3) Role + grants (RBAC) --------------------------------------------
CREATE ROLE IF NOT EXISTS SALES_USER;
GRANT USAGE  ON DATABASE  RETAIL_SALES_DB              TO ROLE SALES_USER;
GRANT USAGE  ON SCHEMA    RETAIL_SALES_DB.SALES_SCHEMA TO ROLE SALES_USER;
GRANT SELECT ON SEMANTIC VIEW RETAIL_SALES_DB.SALES_SCHEMA.SALES_ANALYST TO ROLE SALES_USER;
-- Cortex Analyst reads the underlying tables — grant SELECT on them:
GRANT SELECT ON TABLE RETAIL_SALES_DB.SALES_SCHEMA.PRODUCTS  TO ROLE SALES_USER;
GRANT SELECT ON TABLE RETAIL_SALES_DB.SALES_SCHEMA.CUSTOMERS TO ROLE SALES_USER;
GRANT SELECT ON TABLE RETAIL_SALES_DB.SALES_SCHEMA.ORDERS    TO ROLE SALES_USER;
-- REQUIRED after every CREATE OR REPLACE of the MCP server:
GRANT USAGE   ON MCP SERVER RETAIL_SALES_DB.SALES_SCHEMA.SALES_MCP_SERVER TO ROLE SALES_USER;
GRANT USAGE   ON WAREHOUSE COMPUTE_WH TO ROLE SALES_USER;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE SALES_USER;  -- lets the role wake the warehouse

-- 4) Delegate user mapped to a Microsoft (Entra) identity ------------
--    LOGIN_NAME MUST equal the user's Entra UPN (their M365 sign-in email).
CREATE USER IF NOT EXISTS DELEGATE_USER
  LOGIN_NAME   = '<USER_UPN@yourtenant.onmicrosoft.com>'
  DISPLAY_NAME = 'Delegated User'
  COMMENT      = 'Delegate user for Copilot Studio MCP OAuth connectivity';

GRANT ROLE SALES_USER TO USER DELEGATE_USER;
ALTER USER DELEGATE_USER SET DEFAULT_ROLE            = SALES_USER;
ALTER USER DELEGATE_USER SET DEFAULT_WAREHOUSE       = COMPUTE_WH;
ALTER USER DELEGATE_USER SET DEFAULT_SECONDARY_ROLES = ('ALL');  -- required for session:role-any

-- 5) Confirm the grant survived the rebuild --------------------------
SHOW GRANTS ON MCP SERVER RETAIL_SALES_DB.SALES_SCHEMA.SALES_MCP_SERVER;
DESCRIBE MCP SERVER RETAIL_SALES_DB.SALES_SCHEMA.SALES_MCP_SERVER;

-- Find your exact account host for the Server URL (use the
-- SNOWFLAKE_DEPLOYMENT_REGIONLESS entry):
-- SELECT SYSTEM$ALLOWLIST();
