/*
SQL_project.sql: první projekt do Engeto Online Data Akademie
author: Markéta Svěráková Wallo
email: marketa.wallo@gmail.com
discord: marketasverakova_37252
Výstupní tabulky:
t_marketa_sverakova_project_SQL_primary_potraviny
t_marketa_sverakova_project_SQL_secondary_potraviny
*/


-- 2/ Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

SELECT
    tms.industry_branch_code,
    tms.industry_name,
    tms.avg_salary AS avg_salary_2006,
    AVG(CASE WHEN tms.category_code = '111301' THEN tms.avg_price END) AS avg_price_bread_2006,
    AVG(CASE WHEN tms.category_code = '114201' THEN tms.avg_price END) AS avg_price_milk_2006,
    ROUND(tms.avg_salary / 
          AVG(CASE WHEN tms.category_code = '111301' THEN tms.avg_price END)) AS bread_quantity_2006,
    ROUND(tms.avg_salary / 
          AVG(CASE WHEN tms.category_code = '114201' THEN tms.avg_price END)) AS milk_quantity_2006,
    
    tms2.avg_salary AS avg_salary_2018,
    AVG(CASE WHEN tms2.category_code = '111301' THEN tms2.avg_price END) AS avg_price_bread_2018,
    AVG(CASE WHEN tms2.category_code = '114201' THEN tms2.avg_price END) AS avg_price_milk_2018,
    ROUND(tms2.avg_salary / 
          AVG(CASE WHEN tms2.category_code = '111301' THEN tms2.avg_price END)) AS bread_quantity_2018,
    ROUND(tms2.avg_salary / 
          AVG(CASE WHEN tms2.category_code = '114201' THEN tms2.avg_price END)) AS milk_quantity_2018,
    
    -- Flags:
    CASE WHEN (tms.avg_salary / 
               AVG(CASE WHEN tms.category_code = '111301' THEN tms.avg_price END)) 
          < (tms2.avg_salary / 
             AVG(CASE WHEN tms2.category_code = '111301' THEN tms2.avg_price END)) 
         THEN 1 ELSE 0 END AS flag_bread,
    CASE WHEN (tms.avg_salary / 
               AVG(CASE WHEN tms.category_code = '114201' THEN tms.avg_price END)) 
          < (tms2.avg_salary / 
             AVG(CASE WHEN tms2.category_code = '114201' THEN tms2.avg_price END)) 
         THEN 1 ELSE 0 END AS flag_milk
FROM 
    t_marketa_sverakova_project_SQL_primary_potraviny tms
JOIN 
    t_marketa_sverakova_project_SQL_primary_potraviny tms2 
ON 
    tms.industry_branch_code = tms2.industry_branch_code 
WHERE 
    tms.`year` = 2006 
    AND tms2.`year` = 2018
GROUP BY 
    tms.industry_branch_code, 
    tms.industry_name, 
    tms.avg_salary, 
    tms2.avg_salary
ORDER BY 
    tms.industry_branch_code;
