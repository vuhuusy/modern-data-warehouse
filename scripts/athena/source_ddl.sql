-- Amazon Athena external tables for Grocery Sales Database
-- Assumptions:
-- - Database/schema: mdw_raw
-- - S3 object paths: s3://mdw-dev-data-lake/grocery-sales/raw/<table_name>/ (directory/prefix)
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
LOCATION 's3://mdw-dev-data-lake/grocery-sales/raw/categories/'
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
LOCATION 's3://mdw-dev-data-lake/grocery-sales/raw/countries/'
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
LOCATION 's3://mdw-dev-data-lake/grocery-sales/raw/cities/'
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
LOCATION 's3://mdw-dev-data-lake/grocery-sales/raw/customers/'
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
LOCATION 's3://mdw-dev-data-lake/grocery-sales/raw/employees/'
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
LOCATION 's3://mdw-dev-data-lake/grocery-sales/raw/products/'
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
LOCATION 's3://mdw-dev-data-lake/grocery-sales/raw/sales/'
TBLPROPERTIES (
  'skip.header.line.count' = '1'
);

CREATE TABLE mdw_raw.sales
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location = 's3://mdw-dev-data-lake/grocery-sales/raw/sales/',
    partitioned_by = ARRAY['partition']
) AS
WITH cleaned AS (
    SELECT
        salesid,
        salespersonid,
        customerid,
        productid,
        quantity,
        discount,
        totalprice,
        TRY_CAST(salesdate AS TIMESTAMP) AS salesdate_ts
    FROM mdw_raw.sales_tmp
)
SELECT
    salesid,
    salespersonid,
    customerid,
    productid,
    quantity,
    discount,
    totalprice,
    salesdate_ts AS salesdate,
    date_format(salesdate_ts, '%Y%m%d') AS partition
FROM cleaned
WHERE salesdate_ts IS NOT NULL
  AND date_format(salesdate_ts, '%Y%m%d')
      BETWEEN '20180101' AND '20180401';

INSERT INTO mdw_raw.sales
SELECT
    salesid,
    salespersonid,
    customerid,
    productid,
    quantity,
    discount,
    totalprice,
    salesdate_ts AS salesdate,
    date_format(salesdate_ts, '%Y%m%d') AS partition
FROM (
    SELECT
        salesid,
        salespersonid,
        customerid,
        productid,
        quantity,
        discount,
        totalprice,
        TRY_CAST(salesdate AS TIMESTAMP) AS salesdate_ts
    FROM mdw_raw.sales_tmp
) t
WHERE salesdate_ts IS NOT NULL
  AND date_format(salesdate_ts, '%Y%m%d') >= '20180401';