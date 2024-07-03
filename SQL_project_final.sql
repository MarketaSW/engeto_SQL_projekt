-- Primární tabulka:

CREATE TABLE t_marketa_sverakova_project_SQL_primary_final (
    year INT,
    industry_branch_code VARCHAR(10),
    industry_name VARCHAR(255),
    avg_salary DECIMAL(10, 2),
    avg_price_bread DECIMAL(10, 2),
    avg_price_milk DECIMAL(10, 2),
    GDP DECIMAL(15, 2)
);

-- Mzdy a ceny pro srovnatelné období a odvětví:

SELECT DISTINCT
MIN(payroll_year) AS min_cp,
MAX(payroll_year) AS max_cp
FROM czechia_payroll cp 
UNION
SELECT DISTINCT 
MIN(date_from) AS min_cp2,
MAX(date_from) AS max_cp2
FROM czechia_price cp2 ;

SELECT *
FROM czechia_payroll_value_type cpvt ;

INSERT INTO t_marketa_sverakova_project_SQL_primary_final (year, industry_branch_code, industry_name, avg_salary, avg_price_bread, avg_price_milk)
WITH AvgSalaries AS (
    SELECT 
        cp.industry_branch_code,
        cib.name,
        cp.payroll_year,
        ROUND(AVG(cp.value)) AS avg_salary
    FROM 
        czechia_payroll cp
    JOIN 
        czechia_payroll_industry_branch cib ON cp.industry_branch_code = cib.code
    WHERE 
        cp.value_type_code = '5958'
        AND cp.payroll_year BETWEEN 2006 AND 2018
        AND cp.industry_branch_code IS NOT NULL
    GROUP BY 
        cp.industry_branch_code, cp.payroll_year
),
AvgPrices AS (
    SELECT 
        YEAR(cpr.date_from) AS `year`,
        ROUND(AVG(CASE WHEN cpr.category_code = 111301 THEN cpr.value END), 2) AS avg_price_bread,
        ROUND(AVG(CASE WHEN cpr.category_code = 114201 THEN cpr.value END), 2) AS avg_price_milk
    FROM 
        czechia_price cpr 
    WHERE 
        YEAR(cpr.date_from) BETWEEN 2006 AND 2018
    GROUP BY 
        YEAR(cpr.date_from)
)
SELECT 
    a.payroll_year AS year,
    a.industry_branch_code,
    a.name,
    a.avg_salary,
    p.avg_price_bread,
    p.avg_price_milk
FROM 
    AvgSalaries a
JOIN 
    AvgPrices p ON a.payroll_year = p.year;
   
-- GDP:

UPDATE t_marketa_sverakova_project_SQL_primary_final t
JOIN (
    SELECT 
        e.year,
        e.GDP
    FROM 
        economies e
    WHERE 
        e.country = 'Czech Republic' 
        AND e.year BETWEEN 2006 AND 2018
) g
ON t.year = g.year
SET t.GDP = g.GDP;

-- 1/ ROZDÍL ROČNÍCH MEZD PRO JEDNOTLIVÁ ODVĚTVÍ:

WITH YearlyDifference AS (
    SELECT 
    	a.industry_branch_code,
    	a.`year`,
        a.avg_salary AS current_salary,
        b.avg_salary AS previous_salary,
        (a.avg_salary - b.avg_salary) AS yearly_difference
    FROM t_marketa_sverakova_project_SQL_primary_final a
    JOIN t_marketa_sverakova_project_SQL_primary_final b 
        ON a.industry_branch_code = b.industry_branch_code 
        AND a.`year` = b.`year` + 1   
),
YearlyTrends AS (
    SELECT 
    	industry_branch_code,
        SUM(CASE WHEN yearly_difference > 0 THEN 1 ELSE 0 END) AS years_increasing,
        SUM(CASE WHEN yearly_difference < 0 THEN 1 ELSE 0 END) AS years_decreasing
    FROM YearlyDifference
    GROUP BY industry_branch_code
)
SELECT
	tms.industry_branch_code,
    tms.industry_name,
    yt.years_increasing, 
    yt.years_decreasing,
    CASE WHEN years_increasing > years_decreasing THEN 1 ELSE 0 END AS overall_increasing
FROM 
    t_marketa_sverakova_project_SQL_primary_final tms
JOIN YearlyTrends yt ON tms.industry_branch_code = yt.industry_branch_code 
GROUP BY
	tms.industry_branch_code
ORDER BY 
    tms.industry_branch_code;

/* 2/ KOLIK JE MOŽNÉ SI KOUPIT LITRŮ MLÉKA A KILOGRAMŮ CHLEBA ZA PRVNÍ A POSLEDNÍ SROVNATELNÉ
 * OBDOBÍ V DOSTUPNÝCH DATECH CEN A MEZD?
*/
   
SELECT
    tms.industry_branch_code,
    tms.industry_name,
    tms.avg_salary AS avg_salary_2006,
    tms.avg_price_bread AS avg_price_bread_2006,
    tms.avg_price_milk AS avg_price_milk_2006,
    ROUND(tms.avg_salary / tms.avg_price_bread) AS bread_quantity_2006,
    ROUND(tms.avg_salary / tms.avg_price_milk) AS milk_quantity_2006,
    CASE WHEN (tms.avg_salary / tms.avg_price_bread) < (tms2.avg_salary / tms2.avg_price_bread) THEN 1 ELSE 0 END AS flag_bread,
    tms2.avg_salary AS avg_salary_2018,
    tms2.avg_price_bread AS avg_price_bread_2018,
    tms2.avg_price_milk AS avg_price_milk_2018,
    ROUND(tms2.avg_salary / tms2.avg_price_bread) AS bread_quantity_2018,
    ROUND(tms2.avg_salary / tms2.avg_price_milk) AS milk_quantity_2018,
    CASE WHEN (tms.avg_salary / tms.avg_price_milk) < (tms2.avg_salary / tms2.avg_price_milk) THEN 1 ELSE 0 END AS flag_milk
FROM 
    t_marketa_sverakova_project_SQL_primary_final tms
JOIN 
    t_marketa_sverakova_project_SQL_primary_final tms2 
ON 
    tms.industry_branch_code = tms2.industry_branch_code 
WHERE 
    tms.`year` = 2006 AND tms2.`year` = 2018
ORDER BY 
    tms.industry_branch_code;
   
-- 3/ KTERÁ KATEGORIE POTRAVIN ZDRAŽUJE NEJPOMALEJI (je u ní nejnižší percentuální meziroční nárůst)?   


WITH PriceIncrease AS ( 
	SELECT 
    	a.`year`,
    	ROUND((a.avg_price_bread - b.avg_price_bread) / b.avg_price_bread * 100, 2) AS diff_bread_pct,
    	ROUND(((a.avg_price_milk - b.avg_price_milk) / b.avg_price_milk) * 100, 2) AS diff_milk_pct
	FROM 
    	t_marketa_sverakova_project_SQL_primary_final a
	JOIN 
    	t_marketa_sverakova_project_SQL_primary_final b 
        ON a.`year` = b.`year` + 1
	GROUP BY 
    	a.`year`
)
SELECT 
	ROUND(AVG(p.diff_bread_pct), 2) AS avg_increase_bread,
	ROUND(AVG(p.diff_milk_pct), 2) AS avg_increase_milk
FROM 
    PriceIncrease p ;

-- -> Nejpomaleji zdražuje mléko - 2.98%
   
-- 4/ EXISTUJE ROK, VE KTERÉM BYL MEZIROČNÍ NÁRUST CEN POTRAVIN VÝRAZNĚ VYŠŠÍ NEŽ RŮST MEZD (větší než 10 %)?

   
WITH AvgPrice AS (
	SELECT 
		`year`,
		ROUND((avg_price_bread + avg_price_milk)/2, 2) AS avg_price
	FROM 
		t_marketa_sverakova_project_SQL_primary_final
),
AvgPriceDiff AS (
	SELECT
		a.`year`,
		ROUND((a.avg_price - b.avg_price) / b.avg_price * 100, 2) AS price_diff_pct
	FROM 
    	AvgPrice a
	JOIN 
    	AvgPrice b 
    	ON a.`year` = b.`year` + 1
),		
AvgSalaryDiff AS (
    SELECT
        a.`year`,
        ROUND(((a.avg_salary - b.avg_salary) / b.avg_salary) * 100, 2) AS payroll_diff_pct
    FROM 
        t_marketa_sverakova_project_SQL_primary_final a
    JOIN 
        t_marketa_sverakova_project_SQL_primary_final b ON a.`year` = b.`year` + 1
) 
SELECT 
	p.`year`,
	p.price_diff_pct,
	s.payroll_diff_pct,
	CASE WHEN (p.price_diff_pct - s.payroll_diff_pct) > 10 THEN 1 ELSE 0 END AS flag_10_pct
FROM AvgPriceDiff p
JOIN AvgSalaryDiff s ON p.`year` = s.`year`
GROUP BY p.`year`
;
-- -> V roce 2011 narostly ceny potravin o více než 10% oproti mzdám.

/* 5/ MÁ VÝŠKA HDP VLIV NA ZMĚNY VE MZDÁCH A CENÁCH POTRAVIN?
 * Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin
 * či mzdách ve stejném nebo následujícím roce výraznějším růstem?   */

WITH 
YearlyData AS (
    SELECT 
        a.`year`,
        ROUND(((a.GDP - b.GDP) / b.GDP) * 100, 2) AS GDP_diff_pct,
        ROUND((a.avg_price_bread + a.avg_price_milk) / 2, 2) AS avg_price,
        ROUND((b.avg_price_bread + b.avg_price_milk) / 2, 2) AS prev_avg_price,
        ROUND(((a.avg_salary - b.avg_salary) / b.avg_salary) * 100, 2) AS payroll_diff_pct
    FROM 
        t_marketa_sverakova_project_SQL_primary_final a
    LEFT JOIN 
        t_marketa_sverakova_project_SQL_primary_final b 
    ON 
        a.`year` = b.`year` + 1
),
Flags AS (
    SELECT 
        yd.`year`,
        CASE WHEN ABS(yd.GDP_diff_pct) > 3 THEN 1 ELSE 0 END AS flag_GDP_change,
        CASE WHEN ABS(ROUND((yd.avg_price - yd.prev_avg_price) / yd.prev_avg_price * 100, 2)) > 5 THEN 1 ELSE 0 END AS flag_price_5_pct,
        CASE WHEN ABS(yd.payroll_diff_pct) > 5 THEN 1 ELSE 0 END AS flag_salary_5_pct
    FROM 
        YearlyData yd
)
SELECT 
    f.`year`,
    f.flag_GDP_change,
    CASE WHEN f.flag_GDP_change = 1 AND f.flag_price_5_pct = 1 THEN 1 ELSE 0 END AS impact_price_1Y,
    CASE WHEN f.flag_GDP_change = 1 AND f2.flag_price_5_pct = 1 THEN 1 ELSE 0 END AS impact_price_2Y,
    CASE WHEN f.flag_GDP_change = 1 AND f.flag_salary_5_pct = 1 THEN 1 ELSE 0 END AS impact_salary_1Y,
    CASE WHEN f.flag_GDP_change = 1 AND f2.flag_salary_5_pct = 1 THEN 1 ELSE 0 END AS impact_salary_2Y
FROM 
    Flags f
JOIN 
    Flags f2 ON f.`year` = f2.`year` + 1
GROUP BY 
    f.`year`;
/* -> S jistotou lze říci, že pokud nedojde ke změně v HDP nad 3%, nedojde ani ke změně v cenách a mzdách o více jak 5%. 
 * Naopak pokud se HDP zvýší o více jak 3%, lze v následujícím roce nebo dvou sledovat i proměnu v cenách a mzdách o více jak 5%.
 */
   
 -- 6/ Jako dodatečný materiál připravte i tabulku s HDP, GINI koeficientem a populací dalších evropských států ve stejném období, jako primární přehled pro ČR.
 
   
   -- a) vyhledání zemí v Evropě

SELECT
    country
FROM
    countries c 
WHERE
   	CAST(independence_date AS INT) <= 2006
    AND continent = 'Europe'
;

-- b) sekundární tabulka

CREATE TABLE t_marketa_sverakova_project_SQL_secondary_final (
    country VARCHAR(100),
    year INT,
    GDP DECIMAL(15, 2),
    GINI DECIMAL(10, 2),
    population BIGINT
);

INSERT INTO t_marketa_sverakova_project_SQL_secondary_final (country, year, GDP, GINI, population)
WITH Europe AS (
	SELECT
    	country
	FROM
    	countries 
	WHERE
   		CAST(independence_date AS INT) <= 2006
    	AND continent = 'Europe'
)
SELECT 
	e.country,
	e.`year`,
	e.GDP,
	e.gini,
	e.population
FROM
	economies e
JOIN 
	Europe eu ON e.country = eu.country 
WHERE e.`year` BETWEEN 2006 AND 2018
ORDER BY e.country, e.`year`;

SELECT *
FROM t_marketa_sverakova_project_SQL_secondary_final;
