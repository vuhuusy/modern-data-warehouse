-- =============================================================================
-- Grocery Sales Database - PostgreSQL DDL
-- Generated: 2025-12-20
-- Source: .github/dataset-instructions.md (Version 2.0)
-- Target Schema: public
-- =============================================================================

-- IMPORTANT NOTES:
-- 1. ONLY PRIMARY KEY constraints are included.
-- 2. FOREIGN KEY, NOT NULL, UNIQUE, CHECK, DEFAULT constraints are omitted per generation rules.
-- 3. Data types are mapped from documentation; original source types may differ.
-- 4. Currency, timezone, and business rules are UNSPECIFIED.

-- =============================================================================
-- Table: categories
-- Description: Product category definitions
-- Record Granularity: One row per category
-- =============================================================================
CREATE TABLE public.categories (
    CategoryID      INTEGER,
    CategoryName    VARCHAR(45),
    
    CONSTRAINT pk_categories PRIMARY KEY (CategoryID)
);

COMMENT ON TABLE public.categories IS 'Product category definitions. One row per category.';
COMMENT ON COLUMN public.categories.CategoryID IS 'Unique identifier for each product category.';
COMMENT ON COLUMN public.categories.CategoryName IS 'Name of the product category.';

-- =============================================================================
-- Table: countries
-- Description: Country-level metadata
-- Record Granularity: One row per country
-- =============================================================================
CREATE TABLE public.countries (
    CountryID       INTEGER,
    CountryName     VARCHAR(45),
    CountryCode     VARCHAR(2),
    
    CONSTRAINT pk_countries PRIMARY KEY (CountryID)
);

COMMENT ON TABLE public.countries IS 'Country-level metadata. One row per country.';
COMMENT ON COLUMN public.countries.CountryID IS 'Unique identifier for each country.';
COMMENT ON COLUMN public.countries.CountryName IS 'Name of the country.';
COMMENT ON COLUMN public.countries.CountryCode IS 'ISO 3166-1 alpha-2 country code.';

-- =============================================================================
-- Table: cities
-- Description: City-level geographic data
-- Record Granularity: One row per city
-- =============================================================================
CREATE TABLE public.cities (
    CityID          INTEGER,
    CityName        VARCHAR(45),
    Zipcode         DECIMAL(5,0),
    CountryID       INTEGER,
    
    CONSTRAINT pk_cities PRIMARY KEY (CityID)
);

COMMENT ON TABLE public.cities IS 'City-level geographic data. One row per city.';
COMMENT ON COLUMN public.cities.CityID IS 'Unique identifier for each city.';
COMMENT ON COLUMN public.cities.CityName IS 'Name of the city.';
COMMENT ON COLUMN public.cities.Zipcode IS 'Zipcode of the city.';
COMMENT ON COLUMN public.cities.CountryID IS 'Reference to countries.CountryID.';

-- =============================================================================
-- Table: customers
-- Description: Customer master data
-- Record Granularity: One row per customer
-- =============================================================================
CREATE TABLE public.customers (
    CustomerID      INTEGER,
    FirstName       VARCHAR(45),
    MiddleInitial   VARCHAR(1),
    LastName        VARCHAR(45),
    CityID          INTEGER,
    Address         VARCHAR(90),
    
    CONSTRAINT pk_customers PRIMARY KEY (CustomerID)
);

COMMENT ON TABLE public.customers IS 'Customer master data. One row per customer.';
COMMENT ON COLUMN public.customers.CustomerID IS 'Unique identifier for each customer.';
COMMENT ON COLUMN public.customers.FirstName IS 'First name of the customer.';
COMMENT ON COLUMN public.customers.MiddleInitial IS 'Middle initial of the customer.';
COMMENT ON COLUMN public.customers.LastName IS 'Last name of the customer.';
COMMENT ON COLUMN public.customers.CityID IS 'Reference to cities.CityID.';
COMMENT ON COLUMN public.customers.Address IS 'Residential address of the customer.';

-- =============================================================================
-- Table: employees
-- Description: Employee master data
-- Record Granularity: One row per employee
-- =============================================================================
CREATE TABLE public.employees (
    EmployeeID      INTEGER,
    FirstName       VARCHAR(45),
    MiddleInitial   VARCHAR(1),
    LastName        VARCHAR(45),
    BirthDate       DATE,
    Gender          VARCHAR(10),
    CityID          INTEGER,
    HireDate        DATE,
    
    CONSTRAINT pk_employees PRIMARY KEY (EmployeeID)
);

COMMENT ON TABLE public.employees IS 'Employee master data. One row per employee.';
COMMENT ON COLUMN public.employees.EmployeeID IS 'Unique identifier for each employee.';
COMMENT ON COLUMN public.employees.FirstName IS 'First name of the employee.';
COMMENT ON COLUMN public.employees.MiddleInitial IS 'Middle initial of the employee.';
COMMENT ON COLUMN public.employees.LastName IS 'Last name of the employee.';
COMMENT ON COLUMN public.employees.BirthDate IS 'Date of birth of the employee.';
COMMENT ON COLUMN public.employees.Gender IS 'Gender of the employee.';
COMMENT ON COLUMN public.employees.CityID IS 'Reference to cities.CityID.';
COMMENT ON COLUMN public.employees.HireDate IS 'Date when the employee was hired.';

-- =============================================================================
-- Table: products
-- Description: Product catalog
-- Record Granularity: One row per product
-- =============================================================================
CREATE TABLE public.products (
    ProductID       INTEGER,
    ProductName     VARCHAR(45),
    Price           DECIMAL(4,0),
    CategoryID      INTEGER,
    Class           VARCHAR(15),
    ModifyDate      DATE,
    Resistant       VARCHAR(15),
    IsAllergic      TEXT,
    VitalityDays    DECIMAL(3,0),
    
    CONSTRAINT pk_products PRIMARY KEY (ProductID)
);

COMMENT ON TABLE public.products IS 'Product catalog. One row per product.';
COMMENT ON COLUMN public.products.ProductID IS 'Unique identifier for each product.';
COMMENT ON COLUMN public.products.ProductName IS 'Name of the product.';
COMMENT ON COLUMN public.products.Price IS 'Price per unit of the product. UNKNOWN: Currency not specified.';
COMMENT ON COLUMN public.products.CategoryID IS 'Reference to categories.CategoryID.';
COMMENT ON COLUMN public.products.Class IS 'Classification of the product. UNKNOWN: Valid values not documented.';
COMMENT ON COLUMN public.products.ModifyDate IS 'Last modified date.';
COMMENT ON COLUMN public.products.Resistant IS 'Product resistance category. UNKNOWN: Valid values not documented.';
COMMENT ON COLUMN public.products.IsAllergic IS 'Indicates whether the item is an allergen. UNKNOWN: Valid values not documented.';
COMMENT ON COLUMN public.products.VitalityDays IS 'Product vitality/shelf-life classification. UNKNOWN: Valid values not documented.';

-- =============================================================================
-- Table: sales
-- Description: Sales transactions
-- Record Granularity: One row per transaction
-- =============================================================================
CREATE TABLE public.sales (
    SalesID             INTEGER,
    SalesPersonID       INTEGER,
    CustomerID          INTEGER,
    ProductID           INTEGER,
    Quantity            INTEGER,
    Discount            DECIMAL(10,2),
    TotalPrice          DECIMAL(10,2),
    SalesDate           TIMESTAMP,
    TransactionNumber   VARCHAR(25),
    
    CONSTRAINT pk_sales PRIMARY KEY (SalesID)
);

COMMENT ON TABLE public.sales IS 'Sales transactions. One row per transaction.';
COMMENT ON COLUMN public.sales.SalesID IS 'Unique identifier for each sale.';
COMMENT ON COLUMN public.sales.SalesPersonID IS 'Reference to employees.EmployeeID.';
COMMENT ON COLUMN public.sales.CustomerID IS 'Reference to customers.CustomerID.';
COMMENT ON COLUMN public.sales.ProductID IS 'Reference to products.ProductID.';
COMMENT ON COLUMN public.sales.Quantity IS 'Number of units sold.';
COMMENT ON COLUMN public.sales.Discount IS 'Discount applied to the sale. UNKNOWN: Business rules not specified.';
COMMENT ON COLUMN public.sales.TotalPrice IS 'Final sale price after discounts. UNKNOWN: Currency not specified.';
COMMENT ON COLUMN public.sales.SalesDate IS 'Date and time of the sale. UNKNOWN: Timezone not specified.';
COMMENT ON COLUMN public.sales.TransactionNumber IS 'Unique identifier for the transaction. UNKNOWN: Grouping behavior not specified.';

-- =============================================================================
-- END OF DDL
-- =============================================================================
