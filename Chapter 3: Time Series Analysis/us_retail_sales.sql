SELECT
	urs.*
FROM
	sql_for_data_analysis.us_retail_sales AS urs;

# Trend of monthly retail and food services sales
SELECT
	sales_month,
	sales
FROM
	us_retail_sales
WHERE
	kind_of_business = 'Retail and food services sales, total';

# Trend of yearly total retail and food services sales
SELECT
	YEAR(sales_month) AS sales_year,
	SUM(sales) as sales
FROM
	us_retail_sales urs
WHERE
	kind_of_business = 'Retail and food services sales, total'
GROUP BY
	1;

# Trend of yearly retail sales for sporting goods stores, hobby, toy and game stores; and book stores
SELECT
	YEAR(sales_month) AS sales_year,
	kind_of_business,
	SUM(sales) as sales
FROM
	us_retail_sales urs
WHERE
	kind_of_business IN ('Book stores', 'Sporting goods stores', 'Hobby, toy, and game stores')
GROUP BY
	1,
	2;

# Monthly trend of sales at women's and men's clothing stores
SELECT
	sales_month,
	kind_of_business,
	sales
FROM
	us_retail_sales urs
WHERE
	kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores');

# Yearly trend of salses at women's and mens clothing stores
SELECT
	YEAR(sales_month) as sales_year,
	kind_of_business,
	SUM(sales) as sales
FROM
	us_retail_sales urs
WHERE
	kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
GROUP BY
	1,
	2;

# Pivot data
SELECT
	YEAR(sales_month) as sales_year,
	SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales,
	SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
FROM
	us_retail_sales urs
WHERE
	kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
GROUP BY
	1;

# Percent difference between sales at women's and men's clothing stores
SELECT
	sales_year,
	ROUND((womens_sales / mens_sales - 1) * 100, 2) AS womens_pct_of_mens
FROM
	(
SELECT
	YEAR(sales_month) AS sales_year,
	SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales,
	SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
FROM
	us_retail_sales urs
WHERE
	kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
GROUP BY
	1) a;

# Men's and women's clothing store sales as percent of monthly total
SELECT
	sales_month,
	kind_of_business,
	sales,
	SUM(sales) OVER (PARTITION BY sales_month) AS total_sales,
	ROUND(sales * 100 / SUM(sales) OVER (PARTITION BY sales_month), 2) as pct_total
FROM
	us_retail_sales usr
WHERE
	kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores');