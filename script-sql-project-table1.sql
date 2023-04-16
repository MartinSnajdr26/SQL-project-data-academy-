/**Martin S.#9097**/

SELECT e.*, 
CASE
	WHEN e.GDP > prev.GDP 
		THEN 'increase' 
	WHEN e.GDP = prev.GDP 
		THEN 'same'
	ELSE 'decrease'
END AS GDP_change
FROM economies e
LEFT JOIN economies prev
ON e.country = prev.country
AND e.year = prev.year + 1
WHERE e.country = 'Czech Republic';


/*salary_yearly_increase/decrease*/
CREATE OR REPLACE VIEW v_ms_yearly_salary_increase_total1 AS  
SELECT 
    cp1.payroll_year,
    ROUND(AVG(cp1.value)) AS average_salary,
    ROUND((AVG(cp1.value) - AVG(cp2.value)) / AVG(cp2.value) * 100, 2) AS salary_increase
FROM 
    czechia_payroll cp1
JOIN 
    czechia_payroll cp2 ON cp1.unit_code = cp2.unit_code 
        AND cp1.industry_branch_code = cp2.industry_branch_code
        AND cp1.payroll_year = cp2.payroll_year + 1
JOIN 
    czechia_payroll_industry_branch cpib ON cpib.code = cp1.industry_branch_code 
JOIN 
    czechia_payroll_unit cpu ON cpu.code = cp1.unit_code 
WHERE cp1.value_type_code != '316'
GROUP BY 
    cp1.payroll_year;

CREATE OR REPLACE VIEW v_ms_yearly_food_increase_total1 AS 
SELECT
    CONCAT(YEAR(cp.date_from)) AS year_range,
    ROUND(AVG(cp.value), 2) AS food_avg,
    ROUND((AVG(cp.value) / LAG(AVG(cp.value)) OVER (PARTITION BY cpc.name ORDER BY YEAR(cp.date_from))) * 100 - 100, 2) AS pct_change
FROM
    czechia_price cp
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code
GROUP BY
    year_range;


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


SELECT 
	f.name,
	f.`year`,
	f.average_value_food,
	f.percent_change,
	CASE 
        WHEN f.name IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované') AND f.`year` IN (2006, 2018) THEN 'yes'
        ELSE 'no'
    END AS question2
FROM v_ms_food_increase f
GROUP BY f.name, f.`year` 


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


SELECT 
	s.payroll_year,
	gdp.GDP,
	gdp.GDP_change,
	gdp.is_difference_greater_than_10_salary_food_ratio,
	s.name AS indistry,
	s.avg_salary_per_industry,
	s.salary_change_pct,
	s.salary_trend,
	f.name AS food,
	f.average_value_food,
	f.percent_change AS food_change_pct,
	f2.salary_food_ratio AS salary_food_ratio_for_milk_and_bread
FROM v_ms_question_1 s
LEFT JOIN 
	v_ms_gdp_food_salary_4_5 gdp ON s.payroll_year = gdp.`year` 
LEFT JOIN 
	v_ms_question_2 f ON f.YEAR = s.payroll_year
LEFT JOIN 
	v_ms_question_two f2 ON f2.food = f.name
	
	
SELECT *
FROM v_ms_gdp_food_salary_4_5 
	
