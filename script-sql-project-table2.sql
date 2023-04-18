
/***Jako dodatečný materiál připravte i tabulku s 
HDP, GINI koeficientem a populací dalších evropských států ve stejném období, jako primární přehled pro ČR***/ 


CREATE OR REPLACE TABLE t_martin_snajdr_project_sql_secondary_final AS 
SELECT 
	e.`year`,
	c.country,
	e.GDP,
	e.gini,
	e.population,
	c.region_in_world 
FROM economies e
LEFT JOIN 
	countries c ON c.country = e.country 
HAVING e.`year` >=2000 AND c.country IS NOT NULL AND c.region_in_world  IN ('Eastern Europe', 'Western Europe', 'Southern Europe', 'Nordic Countries', 'British Isles',
		'Baltic Countries', 'Central and Southeast Europe')
ORDER BY 
	e.`year`,
	c.region_in_world ASC  ;




 
