/*
SQL_project.sql: první projekt do Engeto Online Data Akademie
author: Markéta Svěráková Wallo
email: marketa.wallo@gmail.com
discord: marketasverakova_37252
Výstupní tabulky:
t_marketa_sverakova_project_SQL_primary_potraviny
t_marketa_sverakova_project_SQL_secondary_potraviny
*/


-- 1/ Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

WITH YearlyDifference AS (
    SELECT 
    	a.industry_branch_code,
    	a.`year`,
        a.avg_salary AS current_salary,
        b.avg_salary AS previous_salary,
        (a.avg_salary - b.avg_salary) AS yearly_difference
    FROM t_marketa_sverakova_project_SQL_primary_potraviny a
    JOIN t_marketa_sverakova_project_SQL_primary_potraviny b 
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
    t_marketa_sverakova_project_SQL_primary_potraviny tms
JOIN YearlyTrends yt ON tms.industry_branch_code = yt.industry_branch_code 
GROUP BY
	tms.industry_branch_code
ORDER BY 
    tms.industry_branch_code;
