-- Amazon Athena external tables for Grocery Sales Database
-- Assumptions:
-- - Database/schema: mdw_raw
-- - S3 object paths: s3://mdw-prod-raw/grocery-sales/<table_name>/ (directory/prefix)
-- - CSV includes a header row (skipped via TBLPROPERTIES)
-- - CSV fields may contain commas and are enclosed in double quotes
-- - Datetime format: yyyy-MM-dd HH:mm:ss.SSS
-- Note: OpenCSVSerDe reads all columns as STRING. Use CAST() in queries for typed operations.

CREATE DATABASE IF NOT EXISTS mdw_raw;

CREATE EXTERNAL TABLE IF NOT EXISTS mdw_raw.categories (
  categoryid STRING,
  categoryname STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://mdw-prod-raw/grocery-sales/categories/'
TBLPROPERTIES (
  'skip.header.line.count' = '1'
);

CREATE EXTERNAL TABLE IF NOT EXISTS mdw_raw.countries (
  countryid STRING,
  countryname STRING,
  countrycode STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://mdw-prod-raw/grocery-sales/countries/'
TBLPROPERTIES (
  'skip.header.line.count' = '1'
);

CREATE EXTERNAL TABLE IF NOT EXISTS mdw_raw.cities (
  cityid STRING,
  cityname STRING,
  zipcode STRING,
  countryid STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://mdw-prod-raw/grocery-sales/cities/'
TBLPROPERTIES (
  'skip.header.line.count' = '1'
);

CREATE EXTERNAL TABLE IF NOT EXISTS mdw_raw.customers (
  customerid STRING,
  firstname STRING,
  middleinitial STRING,
  lastname STRING,
  cityid STRING,
  address STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://mdw-prod-raw/grocery-sales/customers/'
TBLPROPERTIES (
  'skip.header.line.count' = '1'
);

CREATE EXTERNAL TABLE IF NOT EXISTS mdw_raw.employees (
  employeeid STRING,
  firstname STRING,
  middleinitial STRING,
  lastname STRING,
  birthdate STRING,
  gender STRING,
  cityid STRING,
  hiredate STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://mdw-prod-raw/grocery-sales/employees/'
TBLPROPERTIES (
  'skip.header.line.count' = '1'
);

CREATE EXTERNAL TABLE IF NOT EXISTS mdw_raw.products (
  productid STRING,
  productname STRING,
  price STRING,
  categoryid STRING,
  class STRING,
  modifydate STRING,
  resistant STRING,
  isallergic STRING,
  vitalitydays STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://mdw-prod-raw/grocery-sales/products/'
TBLPROPERTIES (
  'skip.header.line.count' = '1'
);

CREATE EXTERNAL TABLE IF NOT EXISTS mdw_raw.sales (
  salesid STRING,
  salespersonid STRING,
  customerid STRING,
  productid STRING,
  quantity STRING,
  discount STRING,
  totalprice STRING,
  salesdate STRING,
  transactionnumber STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'separatorChar' = ',',
  'quoteChar' = '"',
  'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://mdw-prod-raw/grocery-sales/sales/'
TBLPROPERTIES (
  'skip.header.line.count' = '1'
);
