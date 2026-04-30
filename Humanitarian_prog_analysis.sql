-- Create the database
CREATE DATABASE HumanitarianProgramDB;

-- Use the database
USE HumanitarianProgramDB;

CREATE TABLE jurisdiction_hierarchy (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE,
    level VARCHAR(20) NOT NULL,
    parent VARCHAR(30) ,
		CHECK (level IN ('County','Sub-County','Village')),
		FOREIGN KEY (parent)
		REFERENCES jurisdiction_hierarchy(name)
		ON DELETE CASCADE
);

USE humanitarianprogramdb;
INSERT INTO jurisdiction_hierarchy(name,level,parent)
VALUES
('Nairobi', 'County', NULL),
('Kiambu', 'County', NULL),
('Mombasa', 'County', NULL),
('Westlands', 'Sub-County', 'Nairobi'),
('Kasarani', 'Sub-County', 'Nairobi'),
('Lari', 'Sub-County', 'Kiambu'),
('Gatundu South', 'Sub-County', 'Kiambu'),
('Kisauni', 'Sub-County', 'Mombasa'),
('Likoni', 'Sub-County', 'Mombasa'),
('Parklands', 'Village', 'Westlands'),
('Kangemi', 'Village', 'Westlands'),
('Roysambu', 'Village', 'Kasarani'),
('Githurai', 'Village', 'Kasarani'),
('Kiamwangi', 'Village', 'Lari'),
('Lari Town', 'Village', 'Lari'),
('Kamwangi', 'Village', 'Gatundu South'),
('Kisauni Town', 'Village', 'Kisauni'),
('Mtopanga', 'Village', 'Kisauni'),
('Likoni Town', 'Village', 'Likoni'),
('Shika Adabu', 'Village', 'Likoni');




CREATE TABLE Village_locations(
	Village_id INT PRIMARY KEY AUTO_INCREMENT,
    village VARCHAR(30) NOT NULL UNIQUE,
		FOREIGN KEY(village)
        REFERENCES jurisdiction_hierarchy(name) 
        ON DELETE CASCADE,
	total_population INT NOT NULL CHECK (total_population >= 0)
);

INSERT INTO village_locations ( village, total_population)
 VALUES
( 'Parklands', 15000),
( 'Kangemi', 18000),
( 'Roysambu', 13000),
( 'Githurai', 12500),
( 'Kiamwangi', 12800),
('Lari Town', 9485),
('Kamwangi', 5212),
('Kisauni Town', 20500),
('Mtopanga', 15500),
('Likoni Town', 12000),
('Shika Adabu', 9000);

CREATE TABLE  beneficiary_partner_data(
	partner_id INT PRIMARY KEY AUTO_INCREMENT,
	partner VARCHAR(30)NOT NULL,
	village VARCHAR(30) NOT NULL,
    FOREIGN KEY (village)
    REFERENCES village_locations(village) 
    ON DELETE CASCADE,
	beneficiaries INTEGER NOT NULL CHECK (beneficiaries >= 0),
    beneficiary_type VARCHAR(30)NOT NULL, 
    CHECK (beneficiary_type IN ('Individuals','Households'))
);

INSERT INTO beneficiary_partner_data ( partner, village, beneficiaries, beneficiary_type) 
VALUES
('IRC', 'Parklands', 1450, 'Individuals'),
('NRC', 'Parklands', 50, 'Households'),
('SCI', 'Kangemi', 1123, 'Individuals'),
('IMC', 'Kangemi', 1245, 'Individuals'),
('CESVI', 'Roysambu', 5200, 'Individuals'),
('IMC', 'Githurai', 70, 'Households'),
('IRC', 'Githurai', 2100, 'Individuals'),
('SCI', 'Kiamwangi', 1800, 'Individuals'),
('IMC', 'Lari Town', 1340, 'Individuals'),
('CESVI', 'Kamwangi', 55, 'Households'),
('IRC', 'Kisauni Town', 4500, 'Individuals'),
('SCI', 'Kisauni Town', 1670, 'Individuals'),
('IMC', 'Mtopanga', 1340, 'Individuals'),
('CESVI', 'Likoni Town', 4090, 'Individuals'),
('IRC', 'Shika Adabu', 2930, 'Individuals'),
( 'SCI', 'Shika Adabu', 5200, 'Individuals');

#total benefeciaries per partner

 SELECT partner,
    SUM(CASE 
            WHEN beneficiary_type = 'Households' 
            THEN beneficiaries * 6
            ELSE beneficiaries
        END) AS total_individuals
FROM beneficiary_partner_data
GROUP BY partner;

#VILLAGES SERVED PER PARTNER

SELECT partner,
	COUNT(DISTINCT village) AS villages_served
FROM beneficiary_partner_data
GROUP BY partner;

#AVERAGE BENEFICIARIES PER VILLAGE
SELECT village,
 AVG(
    CASE WHEN beneficiary_type = 'Households' 
    THEN beneficiaries * 6 
    ELSE beneficiaries END
) AS avg_beneficiaries
FROM beneficiary_partner_data
GROUP BY village;

#PARTNERS SERVING MORE THAN 5000 BENEFECIARIES
SELECT partner,
       SUM(CASE WHEN beneficiary_type='Households'THEN beneficiaries*6
       ELSE beneficiaries END) AS total_individuals
FROM beneficiary_partner_data
GROUP BY partner
HAVING total_individuals > 5000;


-- VILLAGES HAVING MULTIPLE PARTENERS

SELECT village, COUNT(DISTINCT partner) AS partner_count
FROM beneficiary_partner_data
GROUP BY village
HAVING partner_count > 1;

-- COVERAGE PER VILLAGE
SELECT 
    v.village,
    v.total_population,
    SUM(CASE WHEN b.beneficiary_type='Households' THEN b.beneficiaries*6 ELSE b.beneficiaries END) AS total_individuals,
    ROUND(SUM(CASE WHEN b.beneficiary_type='Households' THEN b.beneficiaries*6 ELSE b.beneficiaries END)/v.total_population*100,0) AS coverage_pV
FROM village_locations v
LEFT JOIN beneficiary_partner_data b ON v.village = b.village
GROUP BY v.village, v.total_population;

-- combined query showing all villages and partners serving them, including villages with no partners using UNION.


SELECT v.village, b.partner
	FROM village_locations v
	LEFT JOIN beneficiary_partner_data b ON v.village = b.village
	UNION
		SELECT v.village, NULL AS partner
		FROM village_locations v
		WHERE v.village NOT IN (SELECT village FROM beneficiary_partner_data);

#NESTED QUERIES
-- Finding villages where coverage is above the average village coverage.


WITH village_coverage AS (
    SELECT v.village,
           ROUND(
               SUM(CASE WHEN b.beneficiary_type='Households' 
                        THEN b.beneficiaries*6 ELSE b.beneficiaries END) / v.total_population * 100, 2
           ) AS coverage_pct
    FROM village_locations v
    LEFT JOIN beneficiary_partner_data b ON v.village = b.village
    GROUP BY v.village, v.total_population
)
# compare each village to the overall average
SELECT village, coverage_pct
FROM village_coverage
WHERE coverage_pct > (SELECT AVG(coverage_pct) FROM village_coverage);



-- Find partners who serve more than the average number of beneficiaries.
 		
WITH partner_totals AS (
    SELECT partner,
           SUM(CASE WHEN beneficiary_type='Households' 
                    THEN beneficiaries*6 ELSE beneficiaries END) AS total_individuals
    FROM beneficiary_partner_data
    GROUP BY partner
)
#Compare each partner to the average
SELECT partner, total_individuals
FROM partner_totals
WHERE total_individuals > (SELECT AVG(total_individuals) FROM partner_totals);



#CTE
-- district-level summary showing total beneficiaries, total population, coverage using a CTE.

WITH district_summary AS (
    SELECT sc.name AS sub_county,
           SUM(CASE WHEN b.beneficiary_type='Households' THEN b.beneficiaries*6 ELSE b.beneficiaries END) AS total_individuals,
           SUM(v.total_population) AS total_population,
           ROUND(SUM(CASE WHEN b.beneficiary_type='Households' THEN b.beneficiaries*6 ELSE b.beneficiaries END)/SUM(v.total_population)*100,0) AS coverage_pct
    FROM beneficiary_partner_data b
    JOIN village_locations v ON b.village = v.village
    JOIN jurisdiction_hierarchy vh ON v.village = vh.name
    JOIN jurisdiction_hierarchy sc ON vh.parent = sc.name
    GROUP BY sc.name
)
SELECT * FROM district_summary;

-- Rank districts by coverage using a window function inside a CTE.
 
WITH district_summary AS (
    SELECT sc.name AS sub_county,
           SUM(CASE WHEN b.beneficiary_type='Households' 
           THEN b.beneficiaries*6 ELSE b.beneficiaries END) AS total_individuals,
           SUM(v.total_population) AS total_population,
           ROUND(SUM(CASE WHEN b.beneficiary_type='Households' 
           THEN b.beneficiaries*6 ELSE b.beneficiaries END)/SUM(v.total_population)*100,0)AS coverage_pct
		FROM beneficiary_partner_data b
		JOIN village_locations v ON b.village = v.village
		JOIN jurisdiction_hierarchy vh ON v.village = vh.name
		JOIN jurisdiction_hierarchy sc ON vh.parent = sc.name
		GROUP BY sc.name
)
SELECT sub_county, coverage_pct,
       RANK() OVER (ORDER BY coverage_pct DESC) AS coverage_rank
FROM district_summary;

-- Rank partners based on total beneficiaries (RANK() OVER).

SELECT partner,
       SUM(CASE WHEN beneficiary_type='Households' 
       THEN beneficiaries*6 ELSE beneficiaries END) AS total_individuals,
       RANK() OVER (ORDER BY SUM(CASE WHEN beneficiary_type='Households' THEN beneficiaries*6 ELSE beneficiaries END) DESC) AS partner_rank
FROM beneficiary_partner_data
GROUP BY partner;
 

WITH district_partner AS (
    SELECT sc.name AS sub_county,
           b.partner,
           SUM(CASE WHEN b.beneficiary_type='Households' THEN b.beneficiaries*6 ELSE b.beneficiaries END) AS total_individuals,
           ROW_NUMBER() OVER (PARTITION BY sc.name ORDER BY SUM(CASE WHEN b.beneficiary_type='Households' THEN b.beneficiaries*6 ELSE b.beneficiaries END) DESC) AS rn
    FROM beneficiary_partner_data b
    JOIN village_locations v ON b.village = v.village
    JOIN jurisdiction_hierarchy vh ON v.village = vh.name
    JOIN jurisdiction_hierarchy sc ON vh.parent = sc.name
    GROUP BY sc.name, b.partner
)
SELECT sub_county, partner, total_individuals
FROM district_partner
WHERE rn = 1;

#CREATING VIEWS
-- Creating view district_summary with district-level beneficiaries, population, coverage, number of partners.


CREATE VIEW district_summary AS
SELECT sc.name AS sub_county,
       SUM(CASE WHEN b.beneficiary_type='Households' THEN b.beneficiaries*6 ELSE b.beneficiaries END) AS total_individuals,
       SUM(v.total_population) AS total_population,
       ROUND(SUM(CASE WHEN b.beneficiary_type='Households' THEN b.beneficiaries*6 ELSE b.beneficiaries END)/SUM(v.total_population)*100,2) AS coverage_pct,
       COUNT(DISTINCT b.partner) AS partner_count
FROM beneficiary_partner_data b
JOIN village_locations v ON b.village = v.village
JOIN jurisdiction_hierarchy vh ON v.village = vh.name
JOIN jurisdiction_hierarchy sc ON vh.parent = sc.name
GROUP BY sc.name;

SELECT * FROM district_summary;

-- Creating view partner_summary with partner name, villages served, districts reached, total beneficiaries.

CREATE VIEW partner_summary AS
SELECT partner,
       COUNT(DISTINCT village) AS villages_served,
       COUNT(DISTINCT sc.name) AS districts_served,
       SUM(CASE WHEN beneficiary_type='Households' THEN beneficiaries*6 ELSE beneficiaries END) AS total_individuals
FROM beneficiary_partner_data b
JOIN village_locations v ON b.village = v.village
JOIN jurisdiction_hierarchy vh ON v.village = vh.name
JOIN jurisdiction_hierarchy sc ON vh.parent = sc.name
GROUP BY partner;


-- Creating triggers
#Trigger to prevent inserting negative beneficiaries.

DELIMITER $$
CREATE TRIGGER prevent_negative_beneficiaries
BEFORE INSERT ON beneficiary_partner_data
FOR EACH ROW
BEGIN
    IF NEW.beneficiaries < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Beneficiaries cannot be negative';
    END IF;
END$$
DELIMITER ;
#testing the trigger

INSERT INTO beneficiary_partner_data (partner, village, beneficiaries, beneficiary_type)
VALUES ('NRC', 'Parklands', -50, 'Individuals');

#CREATING TRIGGERS
-- create table to log in the data
CREATE TABLE insert_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    partner VARCHAR(30),
    village VARCHAR(30),
    beneficiaries INT,
    beneficiary_type VARCHAR(30),
    insert_time TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER log_insert
AFTER INSERT ON beneficiary_partner_data
FOR EACH ROW
BEGIN
    INSERT INTO insert_log (partner, village, beneficiaries, beneficiary_type, insert_time)
    VALUES (NEW.partner, NEW.village, NEW.beneficiaries, NEW.beneficiary_type, NOW());
END$$
DELIMITER ;

#testing trigger
INSERT INTO beneficiary_partner_data (partner, village, beneficiaries, beneficiary_type)
VALUES ('IRC', 'Kangemi', 200, 'Individuals');

-- check by slecting log table to check data

SELECT * FROM insert_log;

#create procedures
-- GetPartnerReport(partner_name) which returns villages served, districts served, total beneficiaries, partner ranking.

DELIMITER $$

CREATE PROCEDURE GetPartnerReport(IN partner_name VARCHAR(30))
BEGIN
    SELECT 
        b.partner,
        COUNT(DISTINCT b.village) AS villages_served,
        COUNT(DISTINCT sc.name) AS districts_served,
        SUM(CASE WHEN b.beneficiary_type='Households' 
                 THEN b.beneficiaries*6 ELSE b.beneficiaries END) AS total_individuals,
        RANK() OVER (ORDER BY SUM(CASE WHEN b.beneficiary_type='Households' 
                                       THEN b.beneficiaries*6 ELSE b.beneficiaries END) DESC) AS partner_rank
    FROM beneficiary_partner_data b
    JOIN village_locations v ON b.village = v.village
    JOIN jurisdiction_hierarchy vh ON v.village = vh.name AND vh.level='Village'
    JOIN jurisdiction_hierarchy sc ON vh.parent = sc.name
    WHERE b.partner = partner_name
    GROUP BY b.partner;
END$$

DELIMITER ;

CALL GetPartnerReport('SCI');

#creating procedures
-- GetDistrictImpact(district_name) which returns region, district population, total beneficiaries, coverage rate, number of partners.

DELIMITER $$

CREATE PROCEDURE GetDistrictImpact(IN district_name VARCHAR(30))
BEGIN
    SELECT 
        c.name AS county,
        sc.name AS sub_county,
        SUM(v.total_population) AS district_population,
        SUM(CASE WHEN b.beneficiary_type='Households' 
                 THEN b.beneficiaries*6 ELSE b.beneficiaries END) AS total_individuals,
        ROUND(SUM(CASE WHEN b.beneficiary_type='Households' 
                       THEN b.beneficiaries*6 ELSE b.beneficiaries END) / SUM(v.total_population) * 100, 2) AS coverage_rate,
        COUNT(DISTINCT b.partner) AS partner_count
    FROM beneficiary_partner_data b
    JOIN village_locations v ON b.village = v.village
    JOIN jurisdiction_hierarchy vh ON v.village = vh.name AND vh.level='Village'
    JOIN jurisdiction_hierarchy sc ON vh.parent = sc.name
    JOIN jurisdiction_hierarchy c ON sc.parent = c.name
    WHERE sc.name = district_name
    GROUP BY c.name, sc.name;
END$$

DELIMITER ;

CALL GetDistrictImpact('Kasarani');

-- Partners operating more than three villages
SELECT partner, COUNT(DISTINCT village) AS villages_served
FROM beneficiary_partner_data
GROUP BY partner
HAVING COUNT(DISTINCT village) > 3;



SELECT * FROM village_locations ;
SELECT * FROM beneficiary_partner_data;