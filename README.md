# AtliQ-Hardware-Ad-Hoc-Insights-SQL-Project
Consumer Goods Ad_Hoc Insights

📌 **Project Overview**

This project focuses on analyzing AtliQ Hardware's sales database to solve 10 business-oriented questions using MySQL. 
The project demonstrates how SQL can be used to transform business requirements into analytical queries and actionable recommendations for management.

🎯 **Project Objectives**

- Analyze product portfolio growth and segment-level product distribution.

- Identify products with the highest and lowest manufacturing costs.

- Evaluate customer discount patterns in the Indian market.

- Analyze monthly gross sales and quarterly sales quantities.

- Measure sales channel contribution to gross sales.

- Identify the top-performing products by quantity sold within each division.

- Translate query results into actionable business recommendations.

🛠️ **Tools & Technologies**
- MySQL : Database querying and analysis
- SQL : Joins, CTEs, subqueries, aggregations, and window functions
- Power BI : Visualization of analytical findings

📊 **Business Questions & SQL Solutions**

Q1. APAC Market Analysis

- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

```
SELECT DISTINCT(market)
FROM dim_customer 
WHERE customer = 'Atliq Exclusive' AND region = 'apac';
```

- Key Insights
  - Identified eight markets in APAC region: India, Indonesia, Japan, Philippines, South Korea, Australia, New Zealand, and Bangladesh.

Q2. Unique Product Growth: 2020 vs. 2021

- What is the percentage of unique product increase in 2021 vs. 2020?

```
SELECT sales_20.count_20 AS unique_products_2020 ,sales_21.count_21 AS unique_products_2021, 
CONCAT(ROUND((sales_21.count_21 - sales_20.count_20)/ sales_20.count_20 * 100,2), "%")
AS percentage_chg
FROM 
	(SELECT COUNT(DISTINCT(product_code)) AS count_20
    FROM fact_sales_monthly
	WHERE fiscal_year = 2020)AS sales_20,
	(SELECT COUNT(DISTINCT(product_code)) AS count_21 
    FROM fact_sales_monthly
	WHERE fiscal_year = 2021) AS sales_21;
```

- Key Insights:
  - Unique products increased from 245 in 2020 to 334 in 2021.
  - The product portfolio grew by 36.33%, an increase of 89 unique products.

Q3. Product Count by Segment

- Provide a report with all unique product count for each segment, sorted in descending order of product count?

```
SELECT segment, COUNT(DISTINCT(product_code)) AS product_count 
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;
```

- Key Insights: 
  - Notebook: 129 products.
  - Accessories: 116 products.
  - Peripherals: 84 products.
  - Networking had the smallest product count, with 9 products.

Q4. Segment with the Highest Increase in Unique Products

- Which segment had the most increase in unique products in 2021 vs 2020? 

```
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
```

- Key Insights:
  - Accessories recorded the largest absolute increase, adding 34 unique products.
  - Networking products ended at last with count increased from 6 to 9.

Q5. Products with the Highest and Lowest Manufacturing Costs

- Get the products that have the highest and lowest manufacturing costs.

```
SELECT p.product_code, p.product, ROUND(m.manufacturing_cost,2) AS manufacturing_cost
FROM dim_product p 
JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code
WHERE m.manufacturing_cost IN 
(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
UNION
SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);
```

- Key Insights:
  - Lowest manufacturing cost: AQ Master wired x1 Ms — $ 0.89.
  - Highest manufacturing cost: AQ HOME Allin1 Gen 2 — $ 240.54.

Q6. Top Five Customers Receiving Above-Average Pre-Invoice Discounts
- Generate a report which contains the top 5 customers who received an above average pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

```
WITH pre_discount_custs_tbl AS(
	SELECT c.customer_code, c.customer, c.market, i.pre_invoice_discount_pct 
	FROM dim_customer c 
	JOIN fact_pre_invoice_deductions i
	ON c.customer_code = i.customer_code 
	WHERE market = "India" AND i.fiscal_year = 2021
)
SELECT customer_code, customer, CONCAT(ROUND(pre_invoice_discount_pct*100,2), "%")
AS pre_invoice_discount_pct
FROM pre_discount_custs_tbl
WHERE pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM pre_discount_custs_tbl)
ORDER BY pre_invoice_discount_pct DESC 
LIMIT 5;
```

- Key Insights:
  - Flipkart had the highest displayed average discount at 30.83%.
  - Viveks, Ezone, Croma, and Amazon were also among the top five customers.

Q7. **Monthly Gross Sales for AtliQ Exclusive**

- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.

```
SELECT CONCAT(MONTHNAME(s.date), "-", YEAR(s.date)) AS month_name, s.fiscal_year, 
CONCAT(ROUND(SUM(g.gross_price * s.sold_quantity)/100000,2), "M")
AS gross_sales_amt_mln
FROM fact_sales_monthly s 
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN fact_gross_price g
USING (product_code, fiscal_year)
GROUP BY month_name,  fiscal_year
ORDER BY fiscal_year DESC;
```

- Key Insights:
  - December 2020 recorded gross sales of 2,196.22M in the displayed results.
  - June 2021 recorded gross sales of 1,165.55M in the displayed results.

Q8. **Quarter with the Highest Total Sold Quantity in 2020**
- In which quarter of 2020, got the maximum total_sold_quantity? 

```
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
```

- Key Insights:
  - Q1 recorded the highest quantity sold at 7.01 million units.
  - Q3 recorded the lowest quantity sold at 2.08 million units.

Q9. **Sales Channel Contribution in Fiscal Year 2021**
- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

```
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
SELECT channel, CONCAT(ROUND((gross_sales_amt/1000000),2), "M")
AS gross_sales_amt_mln, 
(	CONCAT(ROUND((gross_sales_amt *100)/
	(SELECT SUM(g.gross_price * s.sold_quantity)
	FROM fact_sales_monthly s 
	JOIN fact_gross_price g
	USING (product_code, fiscal_year)),2), "%")
) AS percentage
FROM gross_sales;
```

- Key Insights:
  - Retailer contributed 55.40% of gross sales.
  - Direct contributed 11.70%.
  - Distributor contributed 8.54%.

Q10. **Top Three Products by Quantity Sold in Each Division**
- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 

```
WITH division_sales AS(
	SELECT p.division, s.product_code, p.product, SUM(s.sold_quantity)
	AS total_sold_quantity
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON s.product_code = p.product_code
	WHERE fiscal_year = 2021
	GROUP BY division, p.product_code, product
), 
division_rank AS(
	SELECT division, product_code, product, total_sold_quantity,
	DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC)
	AS rank_order
	FROM division_sales
    )
SELECT 
division, product_code, product, total_sold_quantity, rank_order
FROM division_rank 
WHERE rank_order <= 3;
```

- Key Insights:
  - AQ Pen Drive 2 IN 1 ranked first in N&S, with 701,373 units sold.
  - AQ Gamers Ms ranked first in P&A, with 428,498 units sold.
  - AQ Digit ranked first in PC, with 17,434 units sold.
