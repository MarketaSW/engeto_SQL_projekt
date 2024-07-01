/*
SQL_project.sql: první projekt do Engeto Online Data Akademie
author: Markéta Svěráková Wallo
email: marketa.wallo@gmail.com
discord: marketasverakova_37252
*/


/* Výstupní tabulky:
t_{jmeno}_{prijmeni}_project_SQL_primary_final (pro data mezd a cen potravin za Českou republiku sjednocených
na totožné porovnatelné období – společné roky) a t_{jmeno}_{prijmeni}_project_SQL_secondary_final (pro dodatečná
data o dalších evropských státech).
*/

-- do průvodní listiny: popis mezivýsledků (průvodní listinu) a informace o výstupních datech (například kde chybí hodnoty apod.)

/* Výzkumné otázky

- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
- Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
- Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
- Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce,
projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?

Tabulky s datovými obdobími:
ČR 
czechia_payroll - payroll_year
czechia_price - date_from, date_to
*/

-- 1/ Sjednocení časových období:

SELECT DISTINCT
MIN(payroll_year) AS min_cp,
MAX(payroll_year) AS max_cp
FROM czechia_payroll cp 
UNION
SELECT DISTINCT 
MIN(date_from) AS min_cp2,
MAX(date_to) AS max_cp2
FROM czechia_price cp2 ;

-- -> Jednotné časové období: 2006 - 2018

-- 2/ ROZDÍL ROČNÍCH MEZD PRO JEDNOTLIVÁ ODVĚTVÍ:

-- Výběr hodnoty dle číselníku:
SELECT *
FROM czechia_payroll_value_type cpvt ;
-- -> 5958 Průměrná hrubá mzda na zaměstnance

-- Průměrné mzdy po letech:
SELECT 
	ROUND(AVG(cp.value)) AS avg_salary,
	cp.industry_branch_code,
	cp.payroll_year 	
	FROM czechia_payroll cp 
	WHERE cp.value_type_code = '5958' 
	AND cp.payroll_year BETWEEN 2006 AND 2018 
	AND cp.industry_branch_code IS NOT NULL
	GROUP BY industry_branch_code , payroll_year
;

-- Rozdíly po letech:

WITH AvgSalaries AS (
	SELECT 
	ROUND(AVG(cp.value)) AS avg_salary,
	cp.industry_branch_code,
	cp.payroll_year 	
	FROM czechia_payroll cp 
	WHERE cp.value_type_code = '5958' 
	AND cp.payroll_year BETWEEN 2006 AND 2018 
	AND cp.industry_branch_code IS NOT NULL
	GROUP BY industry_branch_code , payroll_year
	)
SELECT a.industry_branch_code,
	a.payroll_year,
	a.avg_salary AS current_salary,
	b.avg_salary AS previous_salary,
	(a.avg_salary - b.avg_salary) AS yearly_difference
	FROM AvgSalaries a
	LEFT JOIN AvgSalaries b ON a.industry_branch_code = b.industry_branch_code 
	AND a.payroll_year = b.payroll_year + 1
;
   
-- Nárust vs. pokles:

   WITH AvgSalaries AS (
    SELECT 
        ROUND(AVG(cp.value)) AS avg_salary,
        cp.industry_branch_code,
        cp.payroll_year 	
    FROM czechia_payroll cp 
    WHERE cp.value_type_code = '5958' 
        AND cp.payroll_year BETWEEN 2006 AND 2018 
        AND cp.industry_branch_code IS NOT NULL
    GROUP BY cp.industry_branch_code, cp.payroll_year
),
YearlyDifference AS (
    SELECT 
        a.industry_branch_code,
        a.payroll_year,
        a.avg_salary AS current_salary,
        b.avg_salary AS previous_salary,
        (a.avg_salary - b.avg_salary) AS yearly_difference
    FROM AvgSalaries a
    LEFT JOIN AvgSalaries b 
        ON a.industry_branch_code = b.industry_branch_code 
        AND a.payroll_year = b.payroll_year + 1
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
    industry_branch_code,
    cib.name,
    years_increasing,
    years_decreasing,
    CASE 
        WHEN years_increasing > years_decreasing THEN 1
        ELSE 0
    END AS overall_increasing
FROM 
    YearlyTrends
JOIN czechia_payroll_industry_branch cib ON industry_branch_code = cib.code    
ORDER BY 
    industry_branch_code;

-- Ve všech odvětvích mzdy rostly.

-- 3/ - Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
   
-- Průměrná roční mzda za rok 2006 a 2018 po odvětvích
   
   SELECT 
    cp.industry_branch_code,
    ROUND(AVG(CASE WHEN cp.payroll_year = 2006 THEN cp.value END)) AS avg_salary_2006,
    ROUND(AVG(CASE WHEN cp.payroll_year = 2018 THEN cp.value END)) AS avg_salary_2018
FROM 
    czechia_payroll cp 
WHERE 
    cp.value_type_code = '5958' 
    AND cp.payroll_year IN (2006, 2018)
    AND cp.industry_branch_code IS NOT NULL
GROUP BY 
    cp.industry_branch_code;

-- Průměrná roční cena za litr mléka a kg chleba v roce 2006 a 2018
   
   SELECT *
   FROM czechia_price_category cpc 
   WHERE name LIKE '%chléb%';
-- ->   chléb: 111301
  
  SELECT *
   FROM czechia_price_category cpc 
   WHERE name LIKE '%mléko%';
-- -> mléko: 114201

SELECT
cp.category_code,
ROUND(AVG(CASE WHEN YEAR(cp.date_from) = 2006 AND category_code = 111301 THEN cp.value END),2) AS avg_price_bread_2006,
ROUND(AVG(CASE WHEN YEAR(cp.date_from) = 2018 AND category_code = 111301 THEN cp.value END),2) AS avg_price_bread_2018,
ROUND(AVG(CASE WHEN YEAR(cp.date_from) = 2006 AND category_code = 114201 THEN cp.value END),2) AS avg_price_milk_2006,
ROUND(AVG(CASE WHEN YEAR(cp.date_from) = 2018 AND category_code = 114201 THEN cp.value END),2) AS avg_price_milk_2018
FROM czechia_price cp
;


-- mzda/cena za potravinu = jednotek
WITH AvgSalaries AS (
    SELECT 
        cp.industry_branch_code,
        cib.name,
        ROUND(AVG(CASE WHEN cp.payroll_year = 2006 THEN cp.value END)) AS avg_salary_2006,
        ROUND(AVG(CASE WHEN cp.payroll_year = 2018 THEN cp.value END)) AS avg_salary_2018
    FROM 
        czechia_payroll cp 
    JOIN czechia_payroll_industry_branch cib ON cp.industry_branch_code = cib.code    
    WHERE 
        cp.value_type_code = '5958' 
        AND cp.payroll_year IN (2006, 2018)
        AND cp.industry_branch_code IS NOT NULL
    GROUP BY 
        cp.industry_branch_code
),
AvgPrices AS (
    SELECT
        ROUND(AVG(CASE WHEN YEAR(cpr.date_from) = 2006 AND cpr.category_code = 111301 THEN cpr.value END), 2) AS avg_price_bread_2006,
        ROUND(AVG(CASE WHEN YEAR(cpr.date_from) = 2018 AND cpr.category_code = 111301 THEN cpr.value END), 2) AS avg_price_bread_2018,
        ROUND(AVG(CASE WHEN YEAR(cpr.date_from) = 2006 AND cpr.category_code = 114201 THEN cpr.value END), 2) AS avg_price_milk_2006,
        ROUND(AVG(CASE WHEN YEAR(cpr.date_from) = 2018 AND cpr.category_code = 114201 THEN cpr.value END), 2) AS avg_price_milk_2018
    FROM 
        czechia_price cpr 
)
SELECT 
    s.industry_branch_code AS industry,
    s.name,
    s.avg_salary_2006,
    s.avg_salary_2018,
    p.avg_price_bread_2006,
    p.avg_price_bread_2018,
    p.avg_price_milk_2006,
    p.avg_price_milk_2018,
    ROUND(s.avg_salary_2006 / p.avg_price_bread_2006) AS bread_2006,
    ROUND(s.avg_salary_2018 / p.avg_price_bread_2018) AS bread_2018,
    CASE WHEN (s.avg_salary_2006 / p.avg_price_bread_2006) < (s.avg_salary_2018 / p.avg_price_bread_2018) THEN 1 ELSE 0 END AS flag_bread,
    ROUND(s.avg_salary_2006 / p.avg_price_milk_2006) AS milk_2006,
    ROUND(s.avg_salary_2018 / p.avg_price_milk_2018) AS milk_2018,
    CASE WHEN (s.avg_salary_2006 / p.avg_price_milk_2006) < (s.avg_salary_2018 / p.avg_price_milk_2018) THEN 1 ELSE 0 END AS flag_milk
FROM 
    AvgSalaries s,
    AvgPrices p    
ORDER BY 
    s.industry_branch_code;
