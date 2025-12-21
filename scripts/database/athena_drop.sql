-- Drops Athena objects for Grocery Sales Database
-- Order matters: drop tables first, then drop the database.

DROP TABLE IF EXISTS mdw_raw.sales;
DROP TABLE IF EXISTS mdw_raw.products;
DROP TABLE IF EXISTS mdw_raw.employees;
DROP TABLE IF EXISTS mdw_raw.customers;
DROP TABLE IF EXISTS mdw_raw.cities;
DROP TABLE IF EXISTS mdw_raw.countries;
DROP TABLE IF EXISTS mdw_raw.categories;

DROP DATABASE IF EXISTS mdw_raw;
