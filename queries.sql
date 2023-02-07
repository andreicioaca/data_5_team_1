-- Week 1:
-- What countries does the company sell its products to and what are the categories sold to each country? 

-- Concatenates all categories into one column
-- NOTE: Now sorts the categories

WITH cat AS (
SELECT
	DISTINCT 
	O.ShipCountry AS COUNTRY,
	C.CategoryName AS CATEGORY
FROM Orders o
JOIN "Order Details" od ON
	O.OrderID = OD.OrderID
JOIN Products p ON
	P.ProductID = OD.ProductID
JOIN Categories c ON
	C.CategoryID = P.CategoryID
ORDER BY
	O.ShipCountry,
	C.CategoryName
) 
SELECT
	COUNTRY,
	CATEGORY,
	GROUP_CONCAT(CATEGORY)
FROM cat
GROUP BY COUNTRY

-- WEEK 1, extra 
-- Countries that have missing categories, and what categories they're missing

WITH all_combos AS (
	SELECT DISTINCT (o.ShipCountry || ':' || c.categoryname) AS combo FROM Orders o
	CROSS JOIN Categories c 
	ORDER BY ShipCountry, CategoryName
), 
actual_list AS (

select distinct (o.ShipCountry || ':' || c.categoryname) AS actual from Categories c 
        join Products p on c.CategoryID = p.CategoryID 
        join "Order Details" od on p.ProductID = od.ProductID 
        join Orders o on od.OrderID = o.OrderID 
order by o.ShipCountry, c.CategoryName

)

SELECT SUBSTR(combo,1,INSTR(combo,':') -1) AS country, SUBSTR(combo,INSTR(combo,':') +1) AS missing_category FROM all_combos a 
LEFT OUTER JOIN actual_list b ON a.combo = b.actual
WHERE b.actual IS null

-- Week 2: 
-- Calculate the sales amount for the company in the years 2016, 2017 and 2018 using 'order' and 'order details' tables and separate the sales amounts into 3 categories (low, medium and high sales).
-- Teamleader will decide the threshold of each category.

-- Week 2, Peter's code and proposal of what low-medium-high sales should be:

/* 
--High sales		Medium sales				Low sales
--Above 84%		Between 84% and 16%			Below 16%
--(38105.675)		(38105.675 - 2691.7)			(2691.7)
*/

SELECT
    strftime('%Y', order_date) as year,
    ordered_country,
    CategoryName,
    SUM(sales - total_discount) as actual_sales,
    CASE
        WHEN SUM(sales - total_discount) >= 38105.675 THEN 'high sales'
        WHEN SUM(sales - total_discount) < 38105.675
        AND SUM(sales - total_discount) >= 2691.7 THEN 'medium sales'
        WHEN SUM(sales - total_discount) < 2691.7 THEN 'low sales'
    END AS 'sales_rank'
FROM
    (
        SELECT
            o."OrderDate" order_date,
            o."ShipCountry" ordered_country,
            c."CategoryName",
            (od."UnitPrice" * od."Quantity") sales,
            (od."UnitPrice" * od."Quantity") * od."Discount" as total_discount
        FROM
            "orders" o
            JOIN "Order Details" od ON o."OrderID" = od."OrderID"
            JOIN "Products" p ON p."ProductID" = od."ProductID"
            JOIN "Categories" c ON c."CategoryID" = p."CategoryID"
    )

GROUP BY 1, 2, 3
ORDER BY 1


-- Week 3
-- Calculate the top 3 selling products

	select p.ProductName as "Products",
        sum(quantity) as "Number of Sales"
        from Orders o 
        join "Order Details" od on o.OrderID = od.OrderID 
        join Products p on od.ProductID = p.ProductID
        group by od.ProductID 
        order by "Number of sales" desc limit 3



