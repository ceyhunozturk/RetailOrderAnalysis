use OrderDetails
select * from df_orders


-- find the 10 highest revenue generating products

SELECT TOP 10 product_id
	,sum(quantity * sale_price) revenue
FROM df_orders
GROUP BY product_id;


-- find the 5 highest selling products in each region


    WITH region_sales AS (
    SELECT
        region,
        product_id,
        SUM(quantity * sale_price) OVER (PARTITION BY region, product_id) AS sales
    FROM df_orders
),
ranked_sales AS (
    SELECT
        region,
        product_id,
        sales,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales DESC) AS rk
    FROM region_sales
)
SELECT
      region,product_id,sales
FROM ranked_sales
where rk<=5


-- find month over month growth comparison for 2022 and 2023 sales

WITH cte
AS (
	SELECT year(order_date) Sales_Year
		,month(order_date) Sales_Month
		,SUM(quantity * sale_price) sales
	FROM df_orders
	GROUP BY year(order_date)
		,month(order_date)
	)
	,cte2
AS (
	SELECT Sales_Month
		,sum(CASE 
				WHEN Sales_Year = 2022
					THEN sales
				ELSE 0
				END) sales_2022
		,sum(CASE 
				WHEN Sales_Year = 2023
					THEN sales
				ELSE 0
				END) sales_2023
	FROM cte
	GROUP BY Sales_Month
	)
SELECT *
	,round((sales_2023 - sales_2022) / sales_2022 * 100, 0) MoM_growth
FROM cte2
ORDER BY Sales_Month ASC


--for each category which month had highest sales

WITH cte
AS (
	SELECT category
		,format(order_date, 'yyyyMM') AS order_year_month
		,sum(sale_price * quantity) AS sales
	FROM df_orders
	GROUP BY category
		,format(order_date, 'yyyyMM')
	)
SELECT *
FROM (
	SELECT *
		,row_number() OVER (
			PARTITION BY category ORDER BY sales DESC
			) rk
	FROM cte
	) x
WHERE rk = 1


--which sub category had highest growth by profit in 2023 compare to 2022?

WITH cte
AS (
	SELECT sub_category
		,year(order_date) AS order_year
		,sum(sale_price * quantity) AS sales
	FROM df_orders
	GROUP BY sub_category
		,year(order_date)
	)
	,cte2
AS (
	SELECT sub_category
		,sum(CASE 
				WHEN order_year = 2022
					THEN sales
				ELSE 0
				END) AS sales_2022
		,sum(CASE 
				WHEN order_year = 2023
					THEN sales
				ELSE 0
				END) AS sales_2023
	FROM cte
	GROUP BY sub_category
	)
SELECT TOP 1 *
	,round((sales_2023 - sales_2022) / sales_2022, 2) growth
FROM cte2
ORDER BY (sales_2023 - sales_2022) DESC