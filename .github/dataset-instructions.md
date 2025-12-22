# Grocery Sales Database

## 1. Overview

| Property            | Value                                                    |
|---------------------|----------------------------------------------------------|
| **Dataset Name**    | Grocery Sales Database                                   |
| **Description**     | Simulated grocery sales data for a retail grocery store  |
| **Time Period**     | 2018-01-01 to 2018-05-09 (approximately 4 months)        |
| **Data Type**       | Relational (structured)                                  |
| **Number of Tables**| 7                                                        |

## 2. Data Source

| Property              | Status        | Details                                      |
|-----------------------|---------------|----------------------------------------------|
| **Origin**            | Specified     | Simulated data (not real transactional data) |
| **Data Provider**     | Specified     | Andrex Ibiza, MBA                            |

## 3. File Inventory

| File Name        | Description                                              | Record Granularity     |
|------------------|----------------------------------------------------------|------------------------|
| `categories.csv` | Product category definitions                             | One row per category   |
| `cities.csv`     | City-level geographic data                               | One row per city       |
| `countries.csv`  | Country-level metadata                                   | One row per country    |
| `customers.csv`  | Customer master data                                     | One row per customer   |
| `employees.csv`  | Employee master data                                     | One row per employee   |
| `products.csv`   | Product catalog                                          | One row per product    |
| `sales.csv`      | Sales transactions                                       | One row per transaction|

## 4. Schema Definitions

### 4.1 `categories`

| Key | Column Name    | Data Type     | Nullable | Description                                  |
|-----|----------------|---------------|----------|----------------------------------------------|
| PK  | `CategoryID`   | `INT`         | No       | Unique identifier for each product category  |
|     | `CategoryName` | `VARCHAR(45)` | No       | Name of the product category                 |

### 4.2 `cities`

| Key | Column Name | Data Type      | Nullable | Description                             |
|-----|-------------|----------------|----------|-----------------------------------------|
| PK  | `CityID`    | `INT`          | No       | Unique identifier for each city         |
|     | `CityName`  | `VARCHAR(45)`  | No       | Name of the city                        |
|     | `Zipcode`   | `DECIMAL(5,0)` | No       | Zipcode of the city                     |
| FK  | `CountryID` | `INT`          | No       | Reference to `countries.CountryID`      |

### 4.3 `countries`

| Key | Column Name   | Data Type     | Nullable | Description                         |
|-----|---------------|---------------|----------|-------------------------------------|
| PK  | `CountryID`   | `INT`         | No       | Unique identifier for each country  |
|     | `CountryName` | `VARCHAR(45)` | No       | Name of the country                 |
|     | `CountryCode` | `VARCHAR(2)`  | No       | ISO 3166-1 alpha-2 country code     |

### 4.4 `customers`

| Key | Column Name     | Data Type     | Nullable | Description                          |
|-----|-----------------|---------------|----------|--------------------------------------|
| PK  | `CustomerID`    | `INT`         | No       | Unique identifier for each customer  |
|     | `FirstName`     | `VARCHAR(45)` | No       | First name of the customer           |
|     | `MiddleInitial` | `VARCHAR(1)`  | Yes      | Middle initial of the customer       |
|     | `LastName`      | `VARCHAR(45)` | No       | Last name of the customer            |
| FK  | `CityID`        | `INT`         | No       | Reference to `cities.CityID`         |
|     | `Address`       | `VARCHAR(90)` | No       | Residential address of the customer  |

### 4.5 `employees`

| Key | Column Name     | Data Type     | Nullable | Description                          |
|-----|-----------------|---------------|----------|--------------------------------------|
| PK  | `EmployeeID`    | `INT`         | No       | Unique identifier for each employee  |
|     | `FirstName`     | `VARCHAR(45)` | No       | First name of the employee           |
|     | `MiddleInitial` | `VARCHAR(1)`  | Yes      | Middle initial of the employee       |
|     | `LastName`      | `VARCHAR(45)` | No       | Last name of the employee            |
|     | `BirthDate`     | `DATE`        | No       | Date of birth of the employee        |
|     | `Gender`        | `VARCHAR(10)` | No       | Gender of the employee               |
| FK  | `CityID`        | `INT`         | No       | Reference to `cities.CityID`         |
|     | `HireDate`      | `DATE`        | No       | Date when the employee was hired     |

### 4.6 `products`

| Key | Column Name    | Data Type      | Nullable | Description                                    |
|-----|----------------|----------------|----------|------------------------------------------------|
| PK  | `ProductID`    | `INT`          | No       | Unique identifier for each product             |
|     | `ProductName`  | `VARCHAR(45)`  | No       | Name of the product                            |
|     | `Price`        | `DECIMAL(4,0)` | No       | Price per unit of the product                  |
| FK  | `CategoryID`   | `INT`          | No       | Reference to `categories.CategoryID`           |
|     | `Class`        | `VARCHAR(15)`  | Yes      | Classification of the product                  |
|     | `ModifyDate`   | `DATE`         | Yes      | Last modified date                             |
|     | `Resistant`    | `VARCHAR(15)`  | Yes      | Product resistance category                    |
|     | `IsAllergic`   | `VARCHAR`      | Yes      | Indicates whether the item is an allergen      |
|     | `VitalityDays` | `DECIMAL(3,0)` | Yes      | Product vitality/shelf-life classification     |

### 4.7 `sales`

| Key | Column Name         | Data Type       | Nullable | Description                                |
|-----|---------------------|-----------------|----------|--------------------------------------------|
| PK  | `SalesID`           | `INT`           | No       | Unique identifier for each sale            |
| FK  | `SalesPersonID`     | `INT`           | No       | Reference to `employees.EmployeeID`        |
| FK  | `CustomerID`        | `INT`           | No       | Reference to `customers.CustomerID`        |
| FK  | `ProductID`         | `INT`           | No       | Reference to `products.ProductID`          |
|     | `Quantity`          | `INT`           | No       | Number of units sold                       |
|     | `Discount`          | `DECIMAL(10,2)` | Yes      | Discount applied to the sale               |
|     | `TotalPrice`        | `DECIMAL(10,2)` | No       | Final sale price after discounts           |
|     | `SalesDate`         | `DATETIME`      | No       | Date and time of the sale                  |
|     | `TransactionNumber` | `VARCHAR(25)`   | No       | Unique identifier for the transaction      |

## 5. Entity Relationships

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│  countries   │──────<│    cities    │──────<│  customers   │
│  (PK: ID)    │ 1   N │  (PK: ID)    │ 1   N │  (PK: ID)    │
└──────────────┘       │  (FK: Ctry)  │       │  (FK: City)  │
                       └──────────────┘       └──────┬───────┘
                              │                      │
                              │ 1                    │ 1
                              │                      │
                              ▼ N                    ▼ N
                       ┌──────────────┐       ┌──────────────┐
                       │  employees   │──────>│    sales     │
                       │  (PK: ID)    │ 1   N │  (PK: ID)    │
                       │  (FK: City)  │       │  (FK: Emp)   │
                       └──────────────┘       │  (FK: Cust)  │
                                              │  (FK: Prod)  │
┌──────────────┐       ┌──────────────┐       └──────┬───────┘
│  categories  │──────<│   products   │──────────────┘
│  (PK: ID)    │ 1   N │  (PK: ID)    │ 1          N
└──────────────┘       │  (FK: Cat)   │
                       └──────────────┘
```

### 5.1 Foreign Key Constraints

| Child Table  | Child Column     | Parent Table | Parent Column  | Relationship |
|--------------|------------------|--------------|----------------|--------------|
| `cities`     | `CountryID`      | `countries`  | `CountryID`    | N:1          |
| `customers`  | `CityID`         | `cities`     | `CityID`       | N:1          |
| `employees`  | `CityID`         | `cities`     | `CityID`       | N:1          |
| `products`   | `CategoryID`     | `categories` | `CategoryID`   | N:1          |
| `sales`      | `SalesPersonID`  | `employees`  | `EmployeeID`   | N:1          |
| `sales`      | `CustomerID`     | `customers`  | `CustomerID`   | N:1          |
| `sales`      | `ProductID`      | `products`   | `ProductID`    | N:1          |

## 6. Data Characteristics

### 6.1 Confirmed Information

- **Temporal Coverage**: Sales transactions span from 2018-01-01 to 2018-05-09
- **Data Nature**: Simulated (synthetic) data, not actual business transactions
- **Geographic Scope**: Multiple cities across multiple countries
- **Transaction Granularity**: Each row in `sales.csv` represents a transaction
- **Currency**: USD

### 6.2 Unspecified Information

The following details are **not documented** in the repository:

| Property                        | Status       |
|---------------------------------|--------------|
| Total record counts per table   | Unspecified  |
| Data generation methodology     | Unspecified  |
| Timezone for `SalesDate`        | Unspecified  |
| Business rules for `Discount`   | Unspecified  |
| Meaning of `Class` values       | Unspecified  |
| Meaning of `Resistant` values   | Unspecified  |
| Meaning of `VitalityDays` values| Unspecified  |
| Whether `TransactionNumber` groups multiple line items | Unspecified |

## 7. Assumptions and Limitations

### 7.1 Assumptions (Implicit but Inferable)

- `TotalPrice` = `Price` × `Quantity` − `Discount` (standard retail calculation)
- `SalesPersonID` references `EmployeeID` (employees act as salespersons)
- Each `TransactionNumber` may contain multiple `SalesID` records (multi-item transactions)

### 7.2 Known Limitations

- **Short Time Window**: Only ~4 months of data limits long-term trend analysis
- **Simulated Data**: May not reflect real-world distribution patterns
- **No Inventory Data**: Stock levels, replenishment, or out-of-stock events not tracked
- **No Returns/Refunds**: Dataset appears to contain only positive sales transactions
- **Single Price Point**: No historical price tracking per product

## 8. Analytical Use Cases

The following analyses are supported by this dataset:

| Use Case                        | Required Tables                                      |
|---------------------------------|------------------------------------------------------|
| Monthly sales trends            | `sales`                                              |
| Product performance ranking     | `sales`, `products`                                  |
| Category-level revenue analysis | `sales`, `products`, `categories`                    |
| Customer segmentation           | `sales`, `customers`                                 |
| Customer geographic distribution| `customers`, `cities`, `countries`                   |
| Employee sales performance      | `sales`, `employees`                                 |
| Regional sales analysis         | `sales`, `customers`, `cities`, `countries`          |
| Discount impact analysis        | `sales`                                              |

## 9. Data Quality Notes

| Check                           | Status       | Notes                                |
|---------------------------------|--------------|--------------------------------------|
| Primary key uniqueness          | Assumed      | Not verified against actual data     |
| Foreign key referential integrity | Assumed   | Not verified against actual data     |
| Null handling                   | Unverified   | Nullable columns marked as "Yes" above are assumed |
| Data type conformance           | Unverified   | Schema derived from documentation    |

---

**Document Metadata**

| Property        | Value                    |
|-----------------|--------------------------|
| Last Updated    | 2025-12-20               |
| Version         | 2.0                      |
| Purpose         | AI/LLM reference documentation |
