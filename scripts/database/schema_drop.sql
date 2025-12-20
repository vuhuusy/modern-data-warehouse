-- =============================================================================
-- Grocery Sales Database - PostgreSQL DROP TABLE Statements
-- Generated: 2025-12-20
-- Source: .github/dataset-instructions.md (Version 2.0)
-- Target Schema: public
-- =============================================================================

-- IMPORTANT NOTES:
-- 1. Tables are dropped in reverse dependency order (child tables first).
-- 2. CASCADE is NOT used to avoid unintended side effects.
-- 3. Run this script before schema_ddl.sql to recreate the schema.

-- =============================================================================
-- Drop tables in reverse dependency order
-- =============================================================================

-- Level 3: Tables with no dependents (leaf tables)
DROP TABLE IF EXISTS public.sales;

-- Level 2: Tables referenced only by Level 3
DROP TABLE IF EXISTS public.customers;
DROP TABLE IF EXISTS public.employees;
DROP TABLE IF EXISTS public.products;

-- Level 1: Tables referenced only by Level 2
DROP TABLE IF EXISTS public.cities;
DROP TABLE IF EXISTS public.categories;

-- Level 0: Root tables (no foreign keys)
DROP TABLE IF EXISTS public.countries;

-- =============================================================================
-- END OF DROP STATEMENTS
-- =============================================================================
