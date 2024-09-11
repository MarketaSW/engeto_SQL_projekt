/*
SQL_project.sql: první projekt do Engeto Online Data Akademie
author: Markéta Svěráková Wallo
email: marketa.wallo@gmail.com
discord: marketasverakova_37252
Výstupní tabulky:
t_marketa_sverakova_project_SQL_primary_potraviny
t_marketa_sverakova_project_SQL_secondary_potraviny
*/


-- 3/ Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

WITH PriceIncrease AS (
    SELECT 
        a.year,
        a.category_code,
        a.category_name,
        ROUND(((a.avg_price - b.avg_price) / b.avg_price) * 100, 2) AS yoy_percent_change
    FROM 
        t_marketa_sverakova_project_SQL_primary_potraviny a
    JOIN 
        t_marketa_sverakova_project_SQL_primary_potraviny b 
        ON a.category_code = b.category_code 
        AND a.year = b.year + 1
)
SELECT 
    category_code,
    category_name,
    ROUND(AVG(yoy_percent_change), 2) AS avg_yoy_percent_change
FROM 
    PriceIncrease
GROUP BY 
    category_code, category_name
ORDER BY 
    avg_yoy_percent_change ASC
LIMIT 1;
