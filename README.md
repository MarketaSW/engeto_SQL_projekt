# engeto_SQL_projekt

autor: Markéta Svěráková Wallo
email: marketa.wallo@gmail.com
discord: marketasverakova_37252
github repozitář: github.com/MarketaSW/engeto_SQL_projekt

Čtvrtý projekt akademie Engeto ukazuje použití SQL na MariaDB v programu DBeaver. Úkolem bylo vytvořit si vlastní datové podklady z datových sad a následně pomocí dotazů získat odpovědi na 5 výzkumných otázek.

#Analýza Dostupnosti Potravin v České Republice

Projekt porovnává dostupnost potravin na základě průměrných příjmů za sjednocené období let 2006 - 2018.

##Datové Sady Použité pro Projekt
1/ t_marketa_sverakova_project_SQL_primary_potraviny: Tato tabulka obsahuje data mezd a cen potravin za Českou republiku, sjednocená na totožné porovnatelné období – společné roky.
2/ t_marketa_sverakova_project_SQL_secondary_potraviny: Tato tabulka obsahuje dodatečná data o dalších evropských státech, včetně HDP, GINI koeficientu a populace.Tabulka obsahuje data o státech Evropy včetně České republiky. Pro Liechtensteinsko jsou známy pouze údaje o populaci a také HDP z roku 2010. V 16 dalších zemích nebylo možné získat údaje o GINI koeficientu.

##SQL Skripty a výstupy
Pro práci s daty byly vytvořeny SQL skripty, které jsou uloženy v GitHub repozitáři: [engeto_SQL_projekt](https://github.com/MarketaSW/engeto_SQL_projekt) .

##Odpovědi na výzkumné otázky
###1/ Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
Ve všech odvětvích převažuje růst nad poklesem. Nejhůře je na tom odvětví Těžba a dobývání, kde mzdy rostly 8 let z 12.

###2/ Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
V roce 2006 na tom bylo nejhůř odvětví Ubytování, stravování a pohostinství, kde si za průměrnou měsíční mzdu bylo možné koupit 707 kg chleba a 789 l mléka. Naopak nejlépe na tom bylo odvětví Peněžnictví a pojišťovnictví s 2 462 kg chleba a 2 749 l mléka. V 5 odvětvích z 19 bylo v roce 2018 možné pořídit méně chleba než v roce 2006, u mléka tomu tak bylo pouze v 1 odvětví (již zmiňovaném Peněžnictví). V roce 2018 na tom bylo nejhůř také odvětví Ubytování, stravování a pohostinství, kde si za průměrnou měsíční mzdu bylo možné koupit 774 kg chleba a 947 l mléka. Nejlépe na tom bylo odvětví Informační a komunikační činnosti s 2 314 kg chleba a 2 831 l mléka. Rozdíly se tedy nepatrně zmenšují.

###3/ Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
Ze dvou porovnávaných kategorií chleba a mléka pomaleji zdražuje mléko - 2.98% ročně.

###4/ Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
V roce 2011 narostly ceny potravin o více než 10% oproti mzdám.

###5/ Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
S jistotou lze říci, že pokud nedojde ke změně v HDP nad 3%, nedojde ani ke změně v cenách a mzdách o více jak 5%. Naopak pokud se HDP zvýší o více jak 3%, lze v následujícím roce nebo dvou sledovat i proměnu v cenách a mzdách o více jak 5%, nemá ovšem jasný vzorec.

##Závěr
Závěrem lze říci, že životní úroveň daná dostupností základních potravin se mezi léty 2006 - 2018 zvýšila u odvětví na spodní hranici, naopak u nejlépe placených odvětví došlo k poklesu. Růst cen potravin odpovídal růstu mezd, za povšimnutí stojí pouze rok 2011, kdy ceny potravin narostly o více než 10% oproti mzdám. To, jak se dařilo ekonomice, mělo vliv i na ceny a mzdy. Nejhůře rostoucím odvětvím byla Těžba a dobývání, kde se mzdy zvedaly jen 8 let z 12.
