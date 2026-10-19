-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT(market)
FROM dim_customer 
WHERE customer = 'Atliq Exclusive' AND region = 'apac';

-- -----------------------------------------------------------------------------------------------------------
-- What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields,
-- 	unique_products_2020
-- 	unique_products_2021
-- 	percentage_chg

SELECT sales_20.count_20 AS unique_products_2020 ,sales_21.count_21 AS unique_products_2021, 
CONCAT(ROUND((sales_21.count_21 - sales_20.count_20)/ sales_20.count_20 * 100,2), "%") AS percentage_chg
FROM 
	(SELECT COUNT(DISTINCT(product_code)) AS count_20
    FROM fact_sales_monthly
	WHERE fiscal_year = 2020)AS sales_20,
	(SELECT COUNT(DISTINCT(product_code)) AS count_21 
    FROM fact_sales_monthly
	WHERE fiscal_year = 2021) AS sales_21;

-- -----------------------------------------------------------------------------------------------------------
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains 2 fields,
-- segment
-- product_count

SELECT segment, COUNT(DISTINCT(product_code)) AS product_count 
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- -----------------------------------------------------------------------------------------------------------

-- Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

WITH sales_20 AS (
	SELECT p.segment, COUNT(DISTINCT(s.product_code)) AS product_count_2020
	FROM dim_product p
	JOIN fact_sales_monthly s
	ON p.product_code = s.product_code
	WHERE s.fiscal_year = 2020
	GROUP BY p.segment
),
sales_21 AS(
	SELECT p.segment, COUNT(DISTINCT(s.product_code)) AS product_count_2021
	FROM dim_product p
	JOIN fact_sales_monthly s
	ON p.product_code = s.product_code
	WHERE s.fiscal_year = 2021
	GROUP BY p.segment
)
SELECT s1.segment, s1.product_count_2020, s2.product_count_2021
, (s2.product_count_2021 - s1.product_count_2020) AS difference
FROM sales_20 s1 
JOIN sales_21 s2
ON s1.segment = s2.segment
ORDER BY difference DESC;

-- -----------------------------------------------------------------------------------------------------------

-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

SELECT p.product_code, p.product, ROUND(m.manufacturing_cost,2) AS manufacturing_cost
FROM dim_product p 
JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code
WHERE m.manufacturing_cost IN 
(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
UNION
SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

-- -----------------------------------------------------------------------------------------------------------

-- Generate a report which contains the top 5 customers who received an
-- above average pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

WITH pre_discount_custs_tbl AS(
	SELECT c.customer_code, c.customer, c.market, i.pre_invoice_discount_pct 
	FROM dim_customer c 
	JOIN fact_pre_invoice_deductions i
	ON c.customer_code = i.customer_code 
	WHERE market = "India" AND i.fiscal_year = 2021
)
SELECT customer_code, customer, CONCAT(ROUND(pre_invoice_discount_pct*100,2), "%") AS pre_invoice_discount_pct
FROM pre_discount_custs_tbl
WHERE pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM pre_discount_custs_tbl)
ORDER BY pre_invoice_discount_pct DESC 
LIMIT 5;

-- -----------------------------------------------------------------------------------------------------------

-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

SELECT CONCAT(MONTHNAME(s.date), "-", YEAR(s.date)) AS month_name, s.fiscal_year, 
CONCAT(ROUND(SUM(g.gross_price * s.sold_quantity)/100000,2), "M") AS gross_sales_amt_mln
FROM fact_sales_monthly s 
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN fact_gross_price g
USING (product_code, fiscal_year)
GROUP BY month_name,  fiscal_year
ORDER BY fiscal_year DESC;

-- -----------------------------------------------------------------------------------------------------------

-- In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

SELECT 
	CASE
		WHEN MONTH(date) BETWEEN 9 AND 11 THEN "Q1"
        WHEN MONTH(date) IN( 12,1, 2) THEN "Q2"
        WHEN MONTH(date) BETWEEN 3 AND 5 THEN "Q3"
        WHEN MONTH(date) BETWEEN 6 AND 8 THEN "Q4"
	END AS fiscal_quarter_2020,
    CONCAT(ROUND(SUM(sold_quantity)/1000000,2) , "M") AS total_sold_quantity_mln
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY fiscal_quarter_2020;

-- -----------------------------------------------------------------------------------------------------------

-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

WITH gross_sales AS(
	SELECT c.channel, ROUND(SUM(g.gross_price * s.sold_quantity),2) AS gross_sales_amt
	FROM fact_sales_monthly s 
	JOIN dim_customer c
	ON s.customer_code = c.customer_code
	JOIN fact_gross_price g
	USING (product_code, fiscal_year)
	WHERE fiscal_year = 2021
	GROUP BY c.channel
    ORDER BY gross_sales_amt DESC
)
SELECT channel, CONCAT(ROUND((gross_sales_amt/1000000),2), "M") AS gross_sales_amt_mln, 
(	CONCAT(ROUND((gross_sales_amt *100)/
	(SELECT SUM(g.gross_price * s.sold_quantity)
	FROM fact_sales_monthly s 
	JOIN fact_gross_price g
	USING (product_code, fiscal_year)),2), "%")
) AS percentage
FROM gross_sales;

-- -----------------------------------------------------------------------------------------------------------

-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order

WITH division_sales AS(
	SELECT p.division, s.product_code, p.product, SUM(s.sold_quantity) AS total_sold_quantity
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON s.product_code = p.product_code
	WHERE fiscal_year = 2021
	GROUP BY division, p.product_code, product
), 
division_rank AS(
	SELECT division, product_code, product, total_sold_quantity,
	DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
	FROM division_sales
    )
SELECT 
division, product_code, product, total_sold_quantity, rank_order
FROM division_rank 
WHERE rank_order <= 3;





