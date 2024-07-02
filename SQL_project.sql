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

-- a) Výběr hodnoty dle číselníku:
SELECT *
FROM czechia_payroll_value_type cpvt ;
-- -> 5958 Průměrná hrubá mzda na zaměstnance

-- b) Průměrné mzdy po letech:
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

-- c)Rozdíly po letech:

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
   
-- d) Nárust vs. pokles:

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

-- 3/ - KOLIK JE MOŽNÉ SI KOUPIT LITRŮ MLÉKA A KILOGRAMŮ CHLEBA ZA PRVNÍ A POSLEDNÍ SROVNATELNÉ OBDOBÍ V DOSTUPNÝCH DATECH CEN A MEZD?
   
-- a) Průměrná roční mzda za rok 2006 a 2018 po odvětvích
   
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

-- b) Průměrná roční cena za litr mléka a kg chleba v roce 2006 a 2018
   
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


-- c) mzda/cena za potravinu = jednotek
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
   
-- 4/ KTERÁ KATEGORIE POTRAVIN ZDRAŽUJE NEJPOMALEJI (je u ní nejnižší percentuální meziroční nárůst)? 

-- a) průměrná roční cena u jednotlivých kategorií:
   
   SELECT 
	ROUND(AVG(cpr.value), 2) AS avg_price,
	cpr.category_code ,
	cpr.date_from 	
	FROM czechia_price cpr
	WHERE YEAR(cpr.date_from) BETWEEN 2006 AND 2018 
	AND YEAR(cpr.date_to) BETWEEN 2006 AND 2018
	GROUP BY cpr.category_code, YEAR(cpr.date_from) ;

-- b) meziroční změna:
   
WITH AvgPrices AS (
    SELECT 
        ROUND(AVG(cpr.value), 2) AS avg_price,
        cpr.category_code,
        YEAR(cpr.date_from) AS `year`
    FROM 
        czechia_price cpr
    WHERE 
        YEAR(cpr.date_from) BETWEEN 2006 AND 2018
    GROUP BY 
        cpr.category_code, YEAR(cpr.date_from)
)
SELECT 
    a.category_code,
    a.`year`,
    a.avg_price AS current_price,
    b.avg_price AS previous_price,
    (a.avg_price - b.avg_price) AS yearly_diff,
    ROUND(((a.avg_price - b.avg_price) / b.avg_price) * 100, 2) AS yearly_diff_pct
FROM 
    AvgPrices a
LEFT JOIN 
    AvgPrices b ON a.category_code = b.category_code 
    AND a.`year` = b.`year` + 1
ORDER BY 
    a.category_code, a.`year`;
   
   -- c) výše meziročního procentuálního nárustu
      
WITH AvgPrices AS (
    SELECT 
        ROUND(AVG(cpr.value), 2) AS avg_price,
        cpr.category_code,
        YEAR(cpr.date_from) AS `year`
    FROM 
        czechia_price cpr
    WHERE 
        YEAR(cpr.date_from) BETWEEN 2006 AND 2018
    GROUP BY 
        cpr.category_code, YEAR(cpr.date_from)
),
YearlyDiff AS ( 
	SELECT 
    	a.category_code,
    	a.`year`,
    	a.avg_price AS current_price,
    	b.avg_price AS previous_price,
    	(a.avg_price - b.avg_price) AS yearly_diff,
    	ROUND(((a.avg_price - b.avg_price) / b.avg_price) * 100, 2) AS yearly_diff_pct
	FROM 
    	AvgPrices a
	LEFT JOIN 
    	AvgPrices b ON a.category_code = b.category_code 
    	AND a.`year` = b.`year` + 1
	ORDER BY 
    	a.category_code, a.`year`)
SELECT 
	category_code,
	cpc.name,
	ROUND(AVG(yearly_diff_pct), 2) AS avg_annual_increase
    FROM 
        YearlyDiff
    JOIN czechia_price_category cpc ON category_code = cpc.code     
    GROUP BY 
        category_code, cpc.name
    ORDER BY
   		avg_annual_increase
   	;
   
-- -> Nejpomaleji zdražuje krystalový cukr.

/* 5) EXISTUJE ROK, VE KTERÉM BYL MEZIROČNÍ NÁRUST CEN POTRAVIN VÝRAZNĚ VYŠŠÍ NEŽ RŮST MEZD
 * (větší než 10 %)? */

-- a) meziroční nárust cen potravin po kategoriích:
   
     
WITH AvgPrices AS (
    SELECT 
        ROUND(AVG(cpr.value), 2) AS avg_price,
        YEAR(cpr.date_from) AS `year`
    FROM 
        czechia_price cpr
    WHERE 
        YEAR(cpr.date_from) BETWEEN 2006 AND 2018
    GROUP BY 
    	YEAR(cpr.date_from)
    	)
SELECT 
    a.`year`,
   	ROUND(((a.avg_price - b.avg_price) / b.avg_price) * 100, 2) AS yearly_price_diff_pct
FROM 
    AvgPrices a
LEFT JOIN 
    AvgPrices b ON a.`year` = b.`year` + 1
;
   
--   b) meziroční nárust mezd:
   
   WITH AvgSalaries AS (
	SELECT 
	ROUND(AVG(cp.value)) AS avg_salary,
	cp.payroll_year 	
	FROM czechia_payroll cp 
	WHERE cp.value_type_code = '5958' 
	AND cp.payroll_year BETWEEN 2006 AND 2018 
	GROUP BY payroll_year
	)
SELECT
	a.payroll_year,
	ROUND(((a.avg_salary - b.avg_salary) / b.avg_salary) * 100, 2) AS yearly_payroll_diff_pct
	FROM AvgSalaries a
	LEFT JOIN AvgSalaries b ON a.payroll_year = b.payroll_year + 1
;

-- c) porovnání procentuálního růstu cen potravin a mezd:

WITH AvgPrices AS (
    SELECT 
        ROUND(AVG(cpr.value), 2) AS avg_price,
        YEAR(cpr.date_from) AS `year`
    FROM 
        czechia_price cpr
    WHERE 
        YEAR(cpr.date_from) BETWEEN 2006 AND 2018
    GROUP BY 
    	YEAR(cpr.date_from)
    ),
AvgPriceDiff AS (
   	SELECT 
    	a.`year`,
   		ROUND(((a.avg_price - b.avg_price) / b.avg_price) * 100, 2) AS yearly_price_diff_pct
	FROM 
    	AvgPrices a
	LEFT JOIN 
    	AvgPrices b ON a.`year` = b.`year` + 1	
   ),
AvgSalaries AS (
	SELECT 
		ROUND(AVG(cp.value)) AS avg_salary,
		cp.payroll_year 	
	FROM czechia_payroll cp 
	WHERE cp.value_type_code = '5958' 
	AND cp.payroll_year BETWEEN 2006 AND 2018 
	GROUP BY payroll_year
	),
AvgSalaryDiff AS (
	SELECT
		a.payroll_year,
		ROUND(((a.avg_salary - b.avg_salary) / b.avg_salary) * 100, 2) AS yearly_payroll_diff_pct
	FROM AvgSalaries a
	LEFT JOIN AvgSalaries b ON a.payroll_year = b.payroll_year + 1
	)
SELECT 
	p.`year`,
	p.yearly_price_diff_pct,
	s.yearly_payroll_diff_pct,
	(p.yearly_price_diff_pct - s.yearly_payroll_diff_pct) AS yearly_difference,
	CASE WHEN (p.yearly_price_diff_pct - s.yearly_payroll_diff_pct) > 10 THEN 1 ELSE 0 END AS flag_10_pct
FROM AvgPriceDiff p
JOIN AvgSalaryDiff s ON p.`year` = s.payroll_year
WHERE p.yearly_price_diff_pct IS NOT NULL
ORDER BY yearly_difference DESC
;

-- Takový rok neexistuje, nejblíž je tomu rok 2013, kde nárust cen byl vyšší o 7%.

   