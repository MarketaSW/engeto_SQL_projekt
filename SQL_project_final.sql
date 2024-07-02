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

   
