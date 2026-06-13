-- 10 JUNE 2026
-- World Wide Energy Consumption Analysis

CREATE DATABASE  ENERGYDB;
USE ENERGYDB;

-- 1. country table
CREATE TABLE country (
	Country VARCHAR(100) UNIQUE,
    CID VARCHAR(10) PRIMARY KEY
);
SELECT * FROM COUNTRY;
DESC COUNTRY;
ALTER TABLE COUNTRY
MODIFY COUNTRY VARCHAR(100) UNIQUE,
MODIFY CID VARCHAR(10) PRIMARY KEY;

-- 2. emission_3 table
CREATE TABLE emissions (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);
ALTER TABLE EMISSIONS
MODIFY EMISSION DOUBLE;
SELECT * FROM EMISSIONS;


-- 3. population table
CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country(Country)
);


-- 4. production table
CREATE TABLE production (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);
ALTER TABLE production
MODIFY production DOUBLE;


-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country(Country)
);

ALTER TABLE gdp_3
RENAME TO GDP;

-- 6. consumption table
CREATE TABLE consumption (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

ALTER TABLE consumption
MODIFY consumption DECIMAL(10,7);
DESC consumption;
TRUNCATE TABLE CONSUMPTION;

SHOW TABLES; -- 6 TABLES

SELECT * FROM CONSUMPTION
WHERE COUNTRY = 'British Virgin Islands' AND 
YEAR = 2022
ORDER BY YEAR DESC;

SELECT DISTINCT(CONSUMPTION) FROM CONSUMPTION;
SELECT * FROM COUNTRY;
SELECT * FROM EMISSIONS;
SELECT DISTINCT(emission) FROM EMISSIONS;

-- ------------------------------------------------------
#Data Analysis Questions
-- -------------------------------------------------------
/*General & Comparative Analysis*/
/*1. What is the total emission per country for the most recent year available?*/
/*Answer*/
SELECT Country,
year as Recent_Year,
       SUM(emission) AS Total_Emission
FROM emissions
WHERE year = (SELECT MAX(year) FROM emissions)
GROUP BY country,year
ORDER BY total_emission DESC;
/*China	with 92338.18520520002
United States with 38453.994441999996
India	with 20221.3305495 tonnes of CO2 of total emission for the year 2023.*/

/*2. What are the top 5 countries by GDP in the most recent year?*/
/*Answer*/
SELECT COUNTRY, VALUE, 
	   YEAR AS RECENT_YEAR
FROM GDP
WHERE YEAR = 
	(SELECT MAX(YEAR) FROM GDP) 
ORDER BY VALUE DESC
LIMIT 5;
/*China	28673.24	2024
United States	22679.47	2024
India	11660.21	2024
Japan	5179.704	2024
Germany	4463.949	2024*/


/*3. Compare energy production and consumption by country and year. */
/*Answer*/
SELECT P.COUNTRY, P.YEAR, 
SUM(PRODUCTION) AS TOTAL_PRODUCTION,
SUM(CONSUMPTION) AS TOTAL_CONSUMPTION,
SUM(PRODUCTION) - SUM(CONSUMPTION) AS MARGIN
FROM PRODUCTION P
JOIN CONSUMPTION C
ON P.COUNTRY = C.COUNTRY
    AND P.YEAR = C.YEAR
    AND P.energy = C.energy
GROUP BY P.COUNTRY, P.YEAR
ORDER BY MARGIN DESC;


/* 4. Which energy types contribute most to emissions across all countries?*/
#ANSWER
SELECT COUNTRY,ENERGY_TYPE, 
	SUM(EMISSION)  AS TOTAL_EMISSION
FROM EMISSIONS	
GROUP BY ENERGY_TYPE, COUNTRY
ORDER BY TOTAL_EMISSION DESC;


/* 5. Trend Analysis Over Time How have global emissions changed year over year?*/
/*Answer*/
SELECT YEAR, SUM(EMISSION) AS TOTAL_EMISSION,
coalesce(coalesce(SUM(EMISSION),0) 
			- LAG(coalesce(SUM(EMISSION),0)) OVER(ORDER BY YEAR)
		,0) AS DIFF,
CONCAT(coalesce( #coalesce is to turn null to 0
			round(
			(coalesce(coalesce(SUM(EMISSION),0) - 
				LAG(coalesce(SUM(EMISSION),0)) OVER(ORDER BY YEAR),0))*100/
				(LAG(coalesce(SUM(EMISSION),0)) OVER(ORDER BY YEAR))
			,3) -- round to 3 decimals
		,0) 
	,"%") -- concat % symbol to number
AS DIFF_PERCENTAGE FROM EMISSIONS 
GROUP BY YEAR ORDER BY YEAR;


/*6. What is the trend in GDP for each country over the given years?*/
/*Answer*/
SELECT COUNTRY, YEAR, VALUE AS GDP_VALUE,
	round(coalesce((VALUE - 
					LAG(VALUE) 
                    OVER(PARTITION BY COUNTRY ORDER BY YEAR))
			,0)
	,3) AS DIFF_BY_YEAR
FROM GDP
ORDER BY COUNTRY, YEAR;


/*7. How has population growth affected 
total emissions in each country?*/
/*ANSWER*/
WITH POP AS 
(SELECT countries, year, Value TOT_POPULATION
FROM POPULATION
),

EMIS AS 
(SELECT country, year, 
SUM(EMISSION) TOT_EMISSION
FROM EMISSIONS
GROUP BY COUNTRY, YEAR
)
SELECT  P.COUNTRIES, E.YEAR,  
		P.TOT_POPULATION, E.TOT_EMISSION,
        coalesce(
			ROUND(P.TOT_POPULATION -
			LAG(p.TOT_POPULATION)
			OVER(PARTITION BY P.COUNTRIES ORDER BY P.YEAR)
            ,10)
       ,0)
       POPULATION_GROWTH,
       coalesce(
			ROUND(E.TOT_EMISSION -
       LAG(E.TOT_EMISSION)
       OVER(PARTITION BY E.COUNTRY ORDER BY E.YEAR)
			,10)
       ,0)
       EMISSION_GROWTH
FROM POP P 
JOIN EMIS E
ON P.COUNTRIES = E.COUNTRY
AND P.YEAR = E.YEAR;


/* 8. GROWTH AFFECT FOR TOP 5 COUNTRIES BY GDP*/
/*Answer*/
WITH top_countries AS (
    SELECT country
    FROM gdp
    WHERE year = (SELECT MAX(year) FROM gdp)
    ORDER BY value DESC
    LIMIT 5
)
SELECT
    c.country,
    c.year,
    SUM(c.consumption) AS total_consumption,
    coalesce(SUM(c.consumption) -
    LAG(SUM(c.consumption))
    OVER (
        PARTITION BY c.country
        ORDER BY c.year
    ),0) AS consumption_change
FROM consumption c
JOIN top_countries tc
ON c.country = tc.country
GROUP BY c.country, c.year
ORDER BY c.country, c.year;


/* 9. Has energy consumption increased or decreased over the years for major economies?*/
/*Answer*/
SELECT CS.COUNTRY, 
		CS.YEAR,
        SUM(CS.CONSUMPTION) AS CONSUMPTION_BY_YEAR ,
        coalesce(SUM(CS.CONSUMPTION) - LAG(SUM(CS.CONSUMPTION)) 
				OVER(partition by COUNTRY ORDER BY year),0)   AS GROWTH
        FROM CONSUMPTION CS
WHERE CS.COUNTRY IN 
		(SELECT C.COUNTRY 
			FROM 
				(SELECT G.Country,  SUM(G.Value) 
                FROM GDP G
				GROUP BY G.Country
				ORDER BY  SUM(G.Value)  DESC
				LIMIT 5) 
		C)
GROUP BY CS.COUNTRY, CS.YEAR; 
# ONLY FOR COUNTRIES INDIA AND CHINA CONSUMPTION SEEM TO INCREASE YEAR BY YEAR
# FOR REST OF TOP 3 COUNTRIES CONSUMPTION HAS BEEN FLUCTUATING AND GOING 
# DOWN TREND MEANING THEIR CONSUMPTION AND THUS EMISSION FROM PREVIOUS QUERY WE CAN FIND
# HAS BEEN DECREASING.

/*10. What is the average yearly change in emissions per capita for each country?*/
/*Answer*/
WITH t AS
(
SELECT country,
       year,
       SUM(per_capita_emission) per_capita,
       SUM(per_capita_emission)
       -
       LAG(SUM(per_capita_emission))
       OVER(PARTITION BY country ORDER BY year)
       yearly_change
FROM emissions
GROUP BY country,year
)
SELECT country, 
       AVG(yearly_change) avg_yearly_change
FROM t
GROUP BY country;

/*Afghanistan	2020	0.028504384
Afghanistan	2021	0.021378288000000002
Afghanistan	2022	0.021378288000000002
Afghanistan	2023	0.021378288000000002*/


/*Ratio & Per Capita Analysis*/
/* 11. What is the emission-to-GDP ratio for each country by year?*/
/*Answer*/
SELECT G.COUNTRY,G.YEAR, 
SUM(E.EMISSION) AS TOTAL_EMISSION, 
G.VALUE GDP_OF_YEAR ,
SUM(E.EMISSION)/ G.VALUE AS EMISSION_TO_GDP_RATIO
FROM EMISSIONS E
JOIN GDP G
ON G.COUNTRY = E.COUNTRY AND G.YEAR = E.YEAR 
GROUP BY G.COUNTRY,G.YEAR, G.VALUE
ORDER BY YEAR DESC, EMISSION_TO_GDP_RATIO DESC;


/* 12. What is the energy consumption per capita for each country over the last decade?*/
/*Answer*/
SELECT c.country,
       SUM(c.consumption)/MAX(p.value)
       AS consumption_per_capita
FROM consumption c
JOIN population p
ON c.country=p.countries
AND c.year=p.year
WHERE c.year >=( SELECT MAX(year)-10
FROM consumption)
GROUP BY c.country
ORDER BY consumption_per_capita DESC;

/* 13. How does energy production per capita vary across countries?*/
/*Answer*/
SELECT pr.country,
       SUM(pr.production)/SUM(p.value)
       AS production_per_capita
FROM production pr
JOIN population p
ON pr.country=p.countries
AND pr.year=p.year
GROUP BY pr.country
ORDER BY production_per_capita DESC;
 
/* 14. Which countries have the highest energy consumption relative to GDP?*/
/*Answer*/
SELECT c.country,
       SUM(c.consumption) total_consumption,
       SUM(g.value) total_gdp,
       SUM(c.consumption)/SUM(g.value)
       AS consumption_gdp_ratio
FROM consumption c
JOIN GDP g
ON c.country=g.country
AND c.year=g.year
GROUP BY c.country
ORDER BY consumption_gdp_ratio DESC;


/* 15. What is the correlation between GDP growth and energy production growth?*/
/*Answer*/
WITH gdp_growth AS (
    SELECT country, year,
        value -
        LAG(value) OVER(
            PARTITION BY country
            ORDER BY year
        ) AS gdp_growth
    FROM gdp
),

yearly_prod AS (
    SELECT country, year, SUM(production) AS total_production
    FROM production
    GROUP BY country, year
),

prod_growth AS (
    SELECT country, year,
        total_production -
        LAG(total_production) OVER(
            PARTITION BY country ORDER BY year
        ) AS production_growth
    FROM yearly_prod
),

combined AS (
    SELECT g.country, g.year, g.gdp_growth, p.production_growth
    FROM gdp_growth g
    JOIN prod_growth p
        ON g.country = p.country
       AND g.year = p.year
    WHERE g.gdp_growth IS NOT NULL
      AND p.production_growth IS NOT NULL
)

SELECT country,
    (COUNT(*) * SUM(gdp_growth * production_growth)
        - SUM(gdp_growth) * SUM(production_growth)
    )/
    (SQRT( COUNT(*) * SUM(POWER(gdp_growth,2))
            - POWER(SUM(gdp_growth),2)) *
	SQRT(COUNT(*) * SUM(POWER(production_growth,2))
            - POWER(SUM(production_growth),2))
    ) AS correlation_coefficient
FROM combined
GROUP BY country;


### WITH YEAR AND GROWTHS
/* 15. What is the correlation between GDP growth and energy production growth?*/
WITH gdp_growth AS (
    SELECT country, year,
        value -
        LAG(value) OVER(
            PARTITION BY country
            ORDER BY year
        ) AS gdp_growth
    FROM gdp
),
yearly_prod AS (
    SELECT country, year, SUM(production) AS total_production
    FROM production
    GROUP BY country, year
),

prod_growth AS (
    SELECT country, year,
        total_production -
        LAG(total_production) OVER(
            PARTITION BY country
            ORDER BY year
        ) AS production_growth
    FROM yearly_prod
),

combined AS (
    SELECT g.country, g.year, g.gdp_growth, p.production_growth
    FROM gdp_growth g
    JOIN prod_growth p
        ON g.country = p.country
       AND g.year = p.year
    WHERE g.gdp_growth IS NOT NULL
      AND p.production_growth IS NOT NULL
),

corr AS (
    SELECT country,
        ( COUNT(*) * SUM(gdp_growth * production_growth)
            - SUM(gdp_growth) * SUM(production_growth)
        ) /
        (SQRT(COUNT(*) * SUM(POWER(gdp_growth,2))
                - POWER(SUM(gdp_growth),2)
            ) *
		SQRT(COUNT(*) * SUM(POWER(production_growth,2))
                - POWER(SUM(production_growth),2)
            )
        ) AS correlation_coefficient
    FROM combined
    GROUP BY country
)
SELECT c.country, c.year, c.gdp_growth, c.production_growth, cr.correlation_coefficient
FROM combined c
JOIN corr cr
ON c.country = cr.country
ORDER BY c.country, c.year;

/* Global Comparisons*/

/* 16. What are the top 10 countries by population and how do their emissions compare?*/
WITH pop AS
(
SELECT countries,
       SUM(value) total_population
FROM population
GROUP BY countries
)
SELECT p.countries,
       p.total_population,
       SUM(e.emission) total_emission
FROM pop p
JOIN emissions e
ON p.countries=e.country
GROUP BY p.countries,p.total_population
ORDER BY p.total_population DESC
LIMIT 10;

/* 17. Which countries have improved (reduced) their 
per capita emissions the most over the last decade?*/
/*Answer*/
WITH t AS(
SELECT country, year, 
SUM(per_capita_emission) per_capita
FROM emissions
GROUP BY country,year)
SELECT country, 
MAX(per_capita)-MIN(per_capita) AS reduction
FROM t
GROUP BY country
ORDER BY reduction ASC;


/* 18. What is the global share (%) of emissions by country?*/
/*Answer*/
WITH country_emission AS(
SELECT country,
SUM(emission) total_emission
FROM emissions
GROUP BY country)
SELECT country,total_emission,
	ROUND(
       total_emission*100/
       SUM(total_emission) OVER(),2)
	AS global_share_pct
FROM country_emission
ORDER BY global_share_pct DESC;


/* 19. What is the global average GDP, emission, and population by year?*/
/*Answer*/
WITH T1 AS (SELECT YEAR, AVG(G.VALUE) AVG_GDP FROM GDP G
GROUP BY YEAR
ORDER BY AVG_GDP),
T2 AS (SELECT E.YEAR,AVG(E.EMISSION) AVG_EMIS FROM EMISSIONS E
GROUP BY E.YEAR
ORDER BY AVG_EMIS), 
T3 AS (SELECT P.YEAR,AVG(P.VALUE) AVG_POPULATION FROM POPULATION P
GROUP BY P.YEAR
ORDER BY AVG_POPULATION)
SELECT T1.YEAR, T1.AVG_GDP, T2.AVG_EMIS, T3.AVG_POPULATION
	FROM T1
    JOIN T2
    ON T1.YEAR = T2.YEAR
    JOIN T3
    ON T1.YEAR = T3.YEAR
    ORDER BY AVG_GDP DESC;
    
