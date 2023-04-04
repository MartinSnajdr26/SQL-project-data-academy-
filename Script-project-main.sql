/***otazky_1_az_5***/

SELECT
	cp.payroll_year AS year,
	gdp.GDP,
	gdp.GDP_change,
	gdp.GDP_pct_change,
	gdp.salary_food_diff_ten_plus,
    cpib.name AS industry, 
    ROUND(AVG(cp.value), 2) AS average_salary, 
    CASE 
        WHEN AVG(cp.value) > prev_avg_salary 
            THEN 'increased'
        WHEN AVG(cp.value) < prev_avg_salary 
            THEN 'decreased'
        ELSE 'unchanged'
    END AS salary_trend,
    CASE 
        WHEN prev_avg_salary IS NULL 
            THEN NULL 
        ELSE ROUND((AVG(cp.value) - prev_avg_salary) / prev_avg_salary * 100, 2)
    END AS yearly_salary_percentage_change,
    f.name  AS food_product,
    f.average_value_food  AS food_value_avg,
    CASE 
    	WHEN f.TBC IS NOT NULL 
            THEN ROUND(AVG(cp.value) / f.average_value_food)
    	ELSE NULL 
    END AS salary_food_ratio,
    f.avg_percent_change_total AS avg_percent_change_food_total
FROM 
    czechia_payroll cp
JOIN 
    czechia_payroll_industry_branch cpib ON cp.industry_branch_code = cpib.code
JOIN 
    czechia_payroll_value_type cpvt ON cp.value_type_code = cpvt.code 
JOIN 
    czechia_payroll_calculation cpc ON cp.calculation_code = cpc.code 
JOIN 
    czechia_payroll_unit cpu ON cp.unit_code = cpu.code 
LEFT JOIN 
	v_ms_gdp_food_salary gdp ON cp.payroll_year = gdp.`year` 
LEFT JOIN 
    v_ms_yearly_food_avg1 f ON cp.payroll_year = f.YEAR
LEFT JOIN 
    (SELECT 
         cpib.name AS industry,
         cp.payroll_year,
         AVG(cp.value) AS prev_avg_salary
     FROM 
         czechia_payroll cp
     JOIN 
         czechia_payroll_industry_branch cpib ON cp.industry_branch_code = cpib.code
     WHERE 
         cp.value IS NOT NULL 
     GROUP BY 
         cpib.name,
         cp.payroll_year
     ) AS prev_salary ON cpib.name = prev_salary.industry AND cp.payroll_year = prev_salary.payroll_year + 1
WHERE 
    cp.value IS NOT NULL 
GROUP BY 
    cpib.name,
    cp.payroll_year,
    prev_avg_salary,
    f.name,
    f.average_value_food ,
    f.tbc
ORDER BY 
    industry,
    cp.payroll_year ASC;

   
/***otazky_4_az_5***/


SELECT
	e.country,
	e.`year`,
	e.GDP,
CASE
	WHEN e.GDP > prev.GDP 
		THEN 'increase' 
	WHEN e.GDP = prev.GDP 
		THEN 'same'
	ELSE 'decrease'
END AS GDP_change
FROM economies e
LEFT JOIN 
	economies prev ON e.country = prev.country
AND e.year = prev.year + 1
WHERE e.country = 'Czech Republic'
ORDER BY e.`year` DESC ;


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
GROUP BY 
    cp1.payroll_year;


SELECT 
  f1.`YEAR`, 
  round(avg(f1.average_value_food), 2) AS avg_food, 
  round(((avg(f1.average_value_food) - avg(f2.average_value_food)) / avg(f2.average_value_food)) * 100, 2) AS yearly_food_change
FROM v_ms_yearly_food_avg1 f1
LEFT JOIN v_ms_yearly_food_avg1 f2 ON f1.`YEAR` = f2.`YEAR` + 1
GROUP BY f1.`YEAR`

CREATE OR REPLACE VIEW v_ms_gdp_food_salary AS 
SELECT 
	gdp.`year`,
	gdp.GDP,
	gdp.GDP_change,
	round((gdp.GDP - lag(gdp.GDP) over (partition by gdp.country order by gdp.`year`)) / lag(gdp.GDP) over (partition by gdp.country order by gdp.`year`) * 100, 2) AS GDP_pct_change,
	f.avg_food AS yearly_avg_food_total,
	f.yearly_food_change AS yearly_food_change_total, 
	s.average_salary AS yearly_avg_salary_total,
	s.salary_increase AS yearly_salary_change_total,
	CASE 
		WHEN f.yearly_food_change - s.salary_increase > 10 THEN 'YES'
		ELSE 'NO'
	END AS salary_food_diff_ten_plus
FROM v_ms_gdp gdp
LEFT JOIN 
	v_ms_yearly_food_increase_total f ON f.`YEAR` = gdp.`year`
LEFT JOIN 
	v_ms_yearly_salary_increase_total s ON s.payroll_year = gdp.`year` 
WHERE gdp.`year` > 1999

