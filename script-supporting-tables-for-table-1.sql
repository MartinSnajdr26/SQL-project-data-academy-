/**1.Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?**/
SELECT
	cp.payroll_year,
	cpib.name,
	ROUND(AVG(cp.value), 2) AS avg_salary_per_industry,
	 ROUND(
    100 * (
      AVG(cp.value) / LAG(AVG(cp.value)) over (partition by cpib.name order by cp.payroll_year) - 1
    ),
    2
  ) AS salary_change_pct,
  CASE 
    WHEN AVG(cp.value) / LAG(AVG(cp.value)) over (partition by cpib.name order by cp.payroll_year) > 1 THEN 'Increasing'
    WHEN AVG(cp.value) / LAG(AVG(cp.value)) over (partition by cpib.name order by cp.payroll_year) < 1 THEN 'Decreasing'
    ELSE 'Unchanged'
  END AS salary_trend
FROM czechia_payroll cp
JOIN czechia_payroll_calculation cpc ON cpc.code = cp.calculation_code 
JOIN czechia_payroll_industry_branch cpib ON cpib.code = cp.industry_branch_code 
JOIN czechia_payroll_unit cpu ON cpu.code = cp.unit_code 
JOIN czechia_payroll_value_type cpvt ON cpvt.code = cp.value_type_code 
WHERE cp.value_type_code != '316' AND cp.value IS NOT NULL 
GROUP BY cp.payroll_year, cpib.name 
ORDER BY cpib.name, cp.payroll_year 

/**2.Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?**/
SELECT
	q1.payroll_year,
	q1.name AS industry,
	q2.name AS food,
	CASE 
    	WHEN q2.question2 = 'yes' 
            THEN ROUND(q1.avg_salary_per_industry / q2.average_value_food)
    	ELSE NULL 
    END AS salary_food_ratio
FROM v_ms_question_1 q1
LEFT JOIN 
	v_ms_question_2 q2 ON q1.payroll_year = q2.YEAR 
HAVING salary_food_ratio IS NOT NULL ;

/**3.Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?**/
SELECT *
FROM v_ms_food_increase 

/**4.Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?**/
SELECT 
	gdp.`year`,
	gdp.GDP,
	gdp.GDP_change,
	s.average_salary,
	f.food_avg,
	CASE 
	    WHEN ABS(s.salary_increase - f.pct_change) > 10 THEN 'Yes'
        ELSE 'No'
    END AS is_difference_greater_than_10_salary_food_ratio
FROM v_ms_gdp gdp
LEFT JOIN 
	v_ms_yearly_food_increase_total1 f ON f.year_range = gdp.`year` 
LEFT JOIN 
	v_ms_yearly_salary_increase_total1 s ON s.payroll_year = gdp.`year` 
WHERE gdp.`year` >= 2000;

/**5.Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, 
pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?**/
SELECT *
FROM v_ms_gdp_food_salary_4_5 
