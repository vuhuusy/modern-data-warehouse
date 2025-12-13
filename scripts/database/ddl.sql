-- DDL script to create database schema and tables for a multinational retail company
CREATE SCHEMA IF NOT EXISTS sales;

CREATE TABLE IF NOT EXISTS sales.customers (
    customer_id     INT,
    name            VARCHAR(255),
    email           VARCHAR(255),
    telephone       VARCHAR(255),
    city            VARCHAR(255),
    country         VARCHAR(255),
    gender          CHAR(1),
    date_of_birth   DATE,
    job_title       VARCHAR(255)
);

COMMENT ON TABLE sales.customers IS 'This table contains detailed information about customers, focusing on their personal attributes, contact details, and geographical location';

COMMENT ON COLUMN sales.customers.customer_id   IS 'Unique numeric identifier for the customer';
COMMENT ON COLUMN sales.customers.name          IS 'Full name (may include titles/honorifics like Mr. or professional suffixes)';
COMMENT ON COLUMN sales.customers.email         IS 'Anonymized email with fake domains (fake_gmail.com, fake_hotmail.com)';
COMMENT ON COLUMN sales.customers.telephone     IS 'Phone number with inconsistent formatting (mix of country codes and extensions)';
COMMENT ON COLUMN sales.customers.city          IS 'City of the customer';
COMMENT ON COLUMN sales.customers.country       IS 'Country of the customer';
COMMENT ON COLUMN sales.customers.gender        IS 'Gender (F = Female, M = Male, D = Diverse)';
COMMENT ON COLUMN sales.customers.date_of_birth IS 'Birthdate in YYYY-MM-DD format';
COMMENT ON COLUMN sales.customers.job_title     IS 'Occupation (optional field, may be empty or contain multiple roles)';


CREATE TABLE IF NOT EXISTS sales.stores (
    store_id            INT,
    country             VARCHAR(255),
    city                VARCHAR(255),
    store_name          VARCHAR(255),
    number_of_employees INTEGER,
    zip_code            VARCHAR(20),
    latitude            NUMERIC(10, 4),
    longitude           NUMERIC(10, 4)
);

COMMENT ON TABLE sales.stores IS 'This table provides detailed information about store locations for a multinational company. Each record represents a specific store, with details about its geographical location, number of employees, and more';

COMMENT ON COLUMN sales.stores.store_id             IS 'Unique identifier for the store location';
COMMENT ON COLUMN sales.stores.country              IS 'Country where the store is located';
COMMENT ON COLUMN sales.stores.city                 IS 'City where the store is located';
COMMENT ON COLUMN sales.stores.store_name           IS 'Human-readable name following the format Store [City]';
COMMENT ON COLUMN sales.stores.number_of_employees  IS 'Total employees assigned to the store';
COMMENT ON COLUMN sales.stores.zip_code             IS 'Postal code of the store location';
COMMENT ON COLUMN sales.stores.latitude             IS 'Geographical latitude of the store';
COMMENT ON COLUMN sales.stores.longitude            IS 'Geographical longitude of the store';


CREATE TABLE IF NOT EXISTS sales.employees (
    employee_id   INT,
    store_id      INT,
    name          VARCHAR(255),
    position      VARCHAR(255)
);

COMMENT ON TABLE sales.employees IS 'This table contains information about employees working at different store locations, detailing their roles and unique identifiers';

COMMENT ON COLUMN sales.employees.employee_id IS 'Unique numeric identifier for the employee';
COMMENT ON COLUMN sales.employees.store_id    IS 'Foreign key linking to Store ID in stores table';
COMMENT ON COLUMN sales.employees.name        IS 'Full employee name in First Last format';
COMMENT ON COLUMN sales.employees.position    IS 'Role within store hierarchy (Manager oversees operations, Seller handles transactions)';


CREATE TABLE IF NOT EXISTS sales.products (
    product_id         INT,
    category           VARCHAR(255),
    sub_category       VARCHAR(255),
    description_pt     TEXT,
    description_de     TEXT,
    description_fr     TEXT,
    description_es     TEXT,
    description_en     TEXT,
    description_zh     TEXT,
    color              VARCHAR(255),
    sizes              VARCHAR(255),
    production_cost    NUMERIC(10, 2)
);

COMMENT ON TABLE sales.products IS 'This table contains detailed information about products sold by a company, with descriptions provided in multiple languages and other product attributes such as category, Production cost, and sizes';

COMMENT ON COLUMN sales.products.product_id       IS 'Unique numeric identifier for the product';
COMMENT ON COLUMN sales.products.category         IS 'High-level classification of the product (EN) (e.g., Feminine, Masculine, Children)';
COMMENT ON COLUMN sales.products.sub_category     IS 'More specific classification within the category (EN)';
COMMENT ON COLUMN sales.products.description_pt   IS 'Product description in Portuguese';
COMMENT ON COLUMN sales.products.description_de   IS 'Product description in German';
COMMENT ON COLUMN sales.products.description_fr   IS 'Product description in French';
COMMENT ON COLUMN sales.products.description_es   IS 'Product description in Spanish';
COMMENT ON COLUMN sales.products.description_en   IS 'Product description in English';
COMMENT ON COLUMN sales.products.description_zh   IS 'Product description in Chinese';
COMMENT ON COLUMN sales.products.color            IS 'Product color';
COMMENT ON COLUMN sales.products.sizes            IS 'Product Sizes Available (pipe-separated format: S|M|L|XL)';
COMMENT ON COLUMN sales.products.production_cost  IS 'Cost incurred to produce the Product in USD';


CREATE TABLE IF NOT EXISTS sales.transactions (
    invoice_id        VARCHAR(255),
    line              INTEGER,
    customer_id       INT,
    product_id        INT,
    size              VARCHAR(255),
    color             VARCHAR(255),
    unit_price        NUMERIC(12, 2),
    quantity          INTEGER,
    transaction_date  TIMESTAMP,
    discount          NUMERIC(5,2),
    line_total        NUMERIC(14,2),
    store_id          INT,
    employee_id       INT,
    currency          CHAR(3),
    currency_symbol   CHAR(1),
    sku               VARCHAR(50),
    transaction_type  VARCHAR(20),
    payment_method    VARCHAR(50),
    invoice_total     NUMERIC(14,2)
);

COMMENT ON TABLE sales.transactions IS 'This table provides detailed transaction information for a multinational retail company operating in multiple countries and currencies. Each record represents a single line item from an invoice, including both sales and returns';

COMMENT ON COLUMN sales.transactions.invoice_id IS 'A unique identifier for each transaction, distinguishing sales and returns. It follows the format: (INV for sales or RET for returns) + Country Code + Store ID + Sequential Counter. This ensures all items from the same transaction are grouped under the same invoice';
COMMENT ON COLUMN sales.transactions.line IS 'Sequential number representing the position of the product in the invoice. A single invoice can contain multiple line items';
COMMENT ON COLUMN sales.transactions.customer_id IS 'Unique identifier referencing the customer who made the purchase';
COMMENT ON COLUMN sales.transactions.product_id IS 'Unique identifier referencing the product purchased';
COMMENT ON COLUMN sales.transactions.size IS 'Product size variant (e.g., S, M, L, XL). Left blank if not applicable';
COMMENT ON COLUMN sales.transactions.color IS 'Color variation of the product. Left blank if not applicable';
COMMENT ON COLUMN sales.transactions.unit_price IS 'Price of a single unit of the product before any discounts are applied';
COMMENT ON COLUMN sales.transactions.quantity IS 'Number of units of the product purchased within this invoice line item';
COMMENT ON COLUMN sales.transactions.transaction_date IS 'Date and time of the transaction in the format YYYY-MM-DD HH:MM:SS (24-hour format)';
COMMENT ON COLUMN sales.transactions.discount IS 'Discount applied to the line item, represented as a decimal (e.g., 0.30 = 30% discount, 0.00 = no discount)';
COMMENT ON COLUMN sales.transactions.line_total IS 'Total cost for the line item after applying any discounts. Calculated as: Unit Price * Quantity * (1 - Discount)';
COMMENT ON COLUMN sales.transactions.store_id IS 'Unique identifier referencing the store where the transaction took place';
COMMENT ON COLUMN sales.transactions.employee_id IS 'Unique identifier referencing the employee who processed the transaction';
COMMENT ON COLUMN sales.transactions.currency IS 'Three-letter ISO currency code representing the currency used for the transaction (e.g., USD, EUR, CNY, GBP)';
COMMENT ON COLUMN sales.transactions.currency_symbol IS 'Symbol associated with the transaction currency (e.g., $, €, £, ¥)';
COMMENT ON COLUMN sales.transactions.sku IS 'Stock Keeping Unit (SKU), a unique inventory code combining the Product ID, Size, and Color (e.g., FESH81-M-PINK = Product ID 81 + Size M + Color PINK)';
COMMENT ON COLUMN sales.transactions.transaction_type IS 'Specifies whether the transaction is a Sale or Return';
COMMENT ON COLUMN sales.transactions.payment_method IS 'Method used to complete the transaction (e.g., Credit Card, Cash)';
COMMENT ON COLUMN sales.transactions.invoice_total IS 'Refers to the total value of the transaction (Invoice ID). It is the sum of all Line Total values for the same Invoice ID. This value is repeated across all line items within the same Invoice ID';


-- create replication user and grant permissions for airbyte
CREATE USER IF NOT EXISTS airbyte WITH PASSWORD 'airbyte';
ALTER USER airbyte REPLICATION;

GRANT USAGE ON SCHEMA sales TO airbyte;
GRANT SELECT ON ALL TABLES IN SCHEMA sales TO airbyte;

ALTER DEFAULT PRIVILEGES IN SCHEMA sales GRANT SELECT ON TABLES TO airbyte;
