# Humanitarian_programme_sql_analysis


## Overview
This project simulates a real-world humanitarian data analysis scenario in Kenya. Development and humanitarian organizations often operate across **counties, sub-counties, and villages**, collecting data on beneficiaries served. The challenge is integrating these datasets to evaluate **program reach, coverage, and partner performance** for monitoring, evaluation, and reporting to donors or government agencies.

This repository contains the **MySQL database schema, sample data, and advanced SQL queries** to analyze humanitarian program impact.

---

##  Objectives
- Design normalized relational tables with constraints and cascading rules.
- Integrate population, partner, and jurisdiction data.
- Standardize household counts into individuals (1 Household = 6 Individuals).
- Generate insights on:
  - Partner reach and performance
  - Coverage rates per village, sub-county, and county
  - Identification of underserved or overserved areas
  - Districts and partners exceeding thresholds

---

##  Database Schema
### 1. `jurisdiction_hierarchy`
Represents the administrative structure (County → Sub-County → Village).
- **id**: Primary Key, Auto Increment  
- **name**: Unique jurisdiction name  
- **level**: Must be `County`, `Sub-County`, or `Village`  
- **parent**: References parent jurisdiction (`ON DELETE CASCADE`)  

### 2. `village_locations`
Stores population data for each village.
- **village_id**: Primary Key, Auto Increment  
- **village**: Unique, references `jurisdiction_hierarchy(name)`  
- **total_population**: Non-negative integer  

### 3. `beneficiary_partner_data`
Tracks program implementation data by partner.
- **partner_id**: Primary Key, Auto Increment  
- **partner**: Partner organization name  
- **village**: References `village_locations(village)`  
- **beneficiaries**: Non-negative integer  
- **beneficiary_type**: Must be `Individuals` or `Households`  

---

##  Key SQL Queries
### Aggregate Analysis
- Total beneficiaries per partner (standardized to individuals).
- Villages served per partner.
- Partners serving more than 5,000 beneficiaries.
- Villages with multiple partners.

### Coverage & Joins
- Coverage per village = beneficiaries ÷ population.
- District-level summaries with CTEs.
- County roll-ups for population vs beneficiaries.

### Advanced Analytics
- Villages above average coverage.
- Partners dominating a district (highest beneficiaries).
- Districts exceeding 10,000 beneficiaries.
- Partners operating in more than 3 villages.

### Window Functions
- Rank partners by total beneficiaries.
- Rank districts by coverage.
- Identify top-performing partner per district.

---

## Features
- **Constraints & Cascades**: Enforces hierarchy rules and automatic deletion of dependent records.
- **CASE WHEN Logic**: Converts households into individuals for standardized reporting.
- **CTEs & Window Functions**: Enables advanced ranking and roll-up analysis.
- **Views**: Provides reusable summaries (`district_summary`, `partner_summary`).
- **Triggers**: Prevents invalid inserts (e.g., negative beneficiaries).
- **Stored Procedures**: Parameterized reports for partners and districts.

---

##  How to Run
1. Create the database:
   ```sql
   CREATE DATABASE HumanitarianProgramDB;
   USE HumanitarianProgramDB;
