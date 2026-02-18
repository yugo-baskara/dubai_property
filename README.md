# End-to-End Property Listing Data Cleaning & Analytics Pipeline (MySQL)
## Overview

This repository contains an end-to-end SQL data pipeline built on MySQL for a Dubai property listings dataset.  
The project demonstrates how raw property listing data is ingested from a CSV file, validated, standardized, and transformed into an analytical-ready layer for pricing and market analysis.

The pipeline is designed using a layered architecture:

Raw layer → Clean layer → Semantic / Analytics layer

The main focus of this project is:
- data cleaning and standardization of real-world property data,
- handling inconsistent numeric fields (price, area, beds, baths),
- separating unit-level listings from bulk property records,
- and preparing a reliable analytical layer for downstream BI and reporting.

All transformations and analyses are implemented purely in SQL on MySQL.


---


## Architecture Overview

```text

CSV File
   │
   ▼
dubai_property_raw          (Raw ingestion layer)
   │
   ▼
dubai_property_clean        (Clean / analytical base table)
   │
   ├─ v_dubai_property_with_flags
   └─ v_dubai_property_unit_only
   ▼
Ad-hoc analytical queries

```

The architecture separates ingestion, cleaning, and business logic to:
•	preserve the original data,
•	reduce the risk of propagating dirty data into analysis,
•	and support reusable analytical queries.


---


## Data Source
The pipeline ingests data from a flat CSV file:


data/dubai_property.csv


The file is loaded using LOAD DATA INFILE, simulating a batch ingestion process from an external listing system.

The ingestion process assumes a trusted local file system and does not cover cloud object storage or streaming ingestion.


---


## Raw Layer – Data Ingestion

Table: portofolio.dubai_property_raw

The raw table stores the data exactly as delivered by the source system.

Columns include:
•	property type,
•	purpose,
•	furnishing,
•	price,
•	number of bedrooms and bathrooms,
•	area (sqft),
•	and address.

No transformation is applied at this stage.

The goal of this layer is to preserve the original data for validation and traceability.

---


## Ingestion Mechanism

The CSV file is ingested using:
•	comma-separated fields,
•	optional quoted values,
•	and header row skipping.

The ingestion assumes a local MySQL server environment and a valid secure_file_priv configuration.


---


## Initial Data Profiling

### Immediately after ingestion, basic profiling is performed:
•	total number of rows,
•	number of distinct addresses,
•	minimum and maximum values for price and area.

### This step is used to quickly detect:
•	missing values,
•	obvious outliers,
•	and structural issues in the dataset.


---


## Clean Layer – Standardization & Transformation

Table:

```

portofolio.dubai_property_clean

```

This table represents the curated analytical base table.

The following standardization rules are applied:

### Price

•	all non-numeric characters are removed,
•	converted into DECIMAL(18,2),
•	invalid values become NULL.

### Area (sqft)

•	all non-numeric characters except the decimal separator are removed,
•	converted into DECIMAL(10,2).

### Bedrooms

•	values containing the word studio are normalized to 0,
•	other values are converted to integers,
•	invalid values become NULL.

### Bathrooms

•	converted to integer values,
•	invalid values become NULL.

### Text columns

•	trimmed to remove unnecessary whitespace.


---


## Clean Load Validation

After building the clean table, validation queries are executed to check:

•	missing values for price, area, beds, and baths,
•	invalid price values (≤ 0),
•	invalid area values (≤ 0).

This ensures that the clean layer is safe to use for analysis.


---


## Semantic Layer – Business Logic

View: v_dubai_property_with_flags

This view adds a business classification flag:

```sql

is_bulk_property

```

A record is marked as bulk property if the property type is:

•	residential building, or
•	residential floor.

This separates building-level listings from individual unit listings.

---


## View: v_dubai_property_unit_only

This view filters the dataset to contain only unit-level properties.

All analytical queries related to unit pricing and room configuration are built on top of this view.


---


## Analytical Use Cases

All analytical queries are executed on either:

•	dubai_property_clean, or
•	v_dubai_property_unit_only.

The project provides the following analyses:

### 1. Average price by property type

Used to compare market prices across different property categories.

### 2. Average price by number of bedrooms (unit only)

Used to analyze how room configuration affects listing prices.

### 3. Price per square foot by property type (unit only)

Used to normalize prices by size and support fair comparison.

### 4. Furnishing vs price distribution

Used to evaluate the impact of furnishing status on pricing.


---


## Key Engineering Characteristics

This project demonstrates:

•	layered data architecture (raw → clean → semantic),
•	systematic handling of dirty numeric fields using regular expressions,
•	explicit handling of special business cases (studio units),
•	separation of bulk properties from unit-level analysis,
•	and reusable analytical views for BI use.


---


## Assumptions and Scope

•	Each row represents one property listing.
•	The dataset may contain both unit-level and building-level listings.
•	The project focuses on analytical readiness and data quality, not on transactional system design.
•	The pipeline is designed for batch processing.


---


## Technology Stack
- MySQL 8.x	
- SQL (DDL, DML, views, data validation queries)


---


## Repository Structure

```
.
├── data/
│   └── dubai_property.csv
├── sql/
│   └── dubai_property_pipeline.sql
└── README.md

```


---


## How to Run This Project

This project is designed to be executed in the following order:
1.	Create database and raw table.
2.	Load the CSV file into:
```sql

dubai_property_raw

```

3.	Create the clean table:
```sql

dubai_property_clean

```
4.	Run data validation queries.
5.	Create semantic views:
•	v_dubai_property_with_flags
•	v_dubai_property_unit_only
6.	Run analytical queries.


Make sure that:
	the CSV file is located in a directory permitted by secure_file_priv,
	and LOAD DATA INFILE is executed on the MySQL server instance that has access to the file.


---


## Intended Usage

This repository can be used as a reference implementation for:
•	SQL-based data cleaning pipelines,
•	property or real-estate analytical preparation,
•	and layered analytical data modeling in MySQL environments.


---


## 👤 Author

Y. Baskara
Linkedin : https://www.linkedin.com/in/yugobaskara/

---


## 📄 Data Source & Attribution

The dataset used in this project was obtained from the public Kaggle dataset published by the user Ahmad Mubarak.

This project is created strictly for educational and portfolio purposes.
All data processing, transformation logic, and analytical design are original work by the author.


---
