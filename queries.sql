-- Week 1:
-- What countries does the company sell its products to and what are the categories sold to each country? 

-- Concatenates all categories into one column
-- NOTE: Now sorts the categories

-- CREATE VIEW IF NOT EXISTS week_1 AS 
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
    GROUP_CONCAT(CATEGORY) as CATEGORY
FROM cat
GROUP BY COUNTRY;

-- WEEK 1, extra 
-- Countries that have missing categories, and what categories they're missing

-- CREATE VIEW IF NOT EXISTS week_1_missing AS 
WITH all_combos AS (
	SELECT 
		DISTINCT (o.ShipCountry || ':' || c.categoryname) AS combo 
	FROM Orders o
	CROSS JOIN Categories c 
	ORDER BY ShipCountry, CategoryName
), 
actual_list AS (
	SELECT
		DISTINCT (o.ShipCountry || ':' || c.categoryname) AS actual 
	FROM Categories c 
	JOIN Products p ON c.CategoryID = p.CategoryID 
	JOIN "Order Details" od ON p.ProductID = od.ProductID 
	JOIN Orders o ON od.OrderID = o.OrderID 
	ORDER BY o.ShipCountry, c.CategoryName
)
SELECT 
	SUBSTR(combo,1,INSTR(combo,':') -1) AS country, 
	SUBSTR(combo,INSTR(combo,':') +1) AS missing_category 
FROM all_combos a 
LEFT OUTER JOIN actual_list b ON a.combo = b.actual
WHERE b.actual IS null
ORDER BY country, missing_category;

-- Week 2: 
-- Calculate the sales amount for the company in the years 2016, 2017 and 2018 using 'order' and 'order details' tables and separate the sales amounts into 3 categories (low, medium and high sales).
-- Teamleader will decide the threshold of each category.

-- Week 2, Baha's input based on cluster analysis

--	High sales		Medium sales			Low sales
--	>75,000			21,500 - 75,000			<21,500

-- NOTE: This view is needed for week 5's codes
-- CREATE VIEW IF NOT EXISTS week_2 AS 
WITH annual_report AS (
	SELECT
		strftime('%Y', o.OrderDate) as year,
		o.ShipCountry,
		SUM(od.UnitPrice * od.Quantity * (1- od.Discount)) as actual_sales
	FROM "orders" o
	JOIN "Order Details" od ON o."OrderID" = od."OrderID"
	JOIN "Products" p ON p."ProductID" = od."ProductID"
	JOIN "Categories" c ON c."CategoryID" = p."CategoryID"
	GROUP BY YEAR, ShipCountry
)

SELECT 
	*,
	CASE
		WHEN (actual_sales >= 75000) THEN 2
		WHEN (actual_sales BETWEEN 21500 AND 75000) THEN 1
		WHEN (actual_sales < 21500) THEN 0
	END AS sales_level
FROM annual_report
ORDER BY year ASC, sales_level DESC;

-- Week 3
-- Calculate the top 3 selling products

-- CREATE VIEW IF NOT EXISTS week_3 AS 
SELECT 
	p.ProductName as "Products",
	sum(quantity) as "Number of Sales"
FROM Orders o 
JOIN "Order Details" od ON o.OrderID = od.OrderID 
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY od.ProductID 
ORDER BY "Number of sales" DESC LIMIT 3;

-- Week 4
-- Employee's performance according to sales amount, decreasing ORDER 

-- last 4 people are in the same group (under employeeID nr 5), should investigate why this is
-- maybe they operate low income areas?

-- CREATE VIEW IF NOT EXISTS week_4_employee_performance AS 
SELECT 
	e.EmployeeID,
	e.FirstName || ' ' || e.LastName AS name,
	ROUND(SUM((od.UnitPrice * od.Quantity) - (od.UnitPrice * od.Quantity) * od.Discount),2) AS profit,
	e.ReportsTo
FROM Employees e 
JOIN Orders o ON e.EmployeeID = o.EmployeeID 
JOIN "Order Details" od ON o.OrderID = od.OrderID 
GROUP BY e.EmployeeID
ORDER BY profit DESC;

-- Week 4
-- Number of territories each employee responsible for

-- CREATE VIEW IF NOT EXISTS week_4_employee_territories AS 
SELECT  
	ET.EmployeeID, 
	LastName, 
	FirstName, 
	COUNT(TerritoryID) as "Number of Territories" 
FROM EmployeeTerritories ET 
JOIN Employees E ON ET.EmployeeID = E.EmployeeID
GROUP BY ET.EmployeeID 
ORDER BY "Number of Territories" DESC;

-- Week 4 
-- Andrei's code - For low-sales regions what is the shipped category there?

-- CREATE VIEW IF NOT EXISTS week_4_low_sale_categories AS 
WITH cat AS (
	SELECT
		DISTINCT 
		O.ShipCountry AS COUNTRY,
		O.ShipRegion AS REGION,
		OD.UnitPrice AS UNITPRICE,
		OD.Quantity AS QUANTITY,
		OD.Discount AS DISCOUNT,
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
	ROUND(SUM(UNITPRICE * QUANTITY * (1- DISCOUNT)),2) as ActualSales,
	REGION,
	group_concat(distinct CATEGORY) as 'Categories per region'
FROM cat
GROUP BY region 
HAVING ActualSales < 30000
ORDER BY ActualSales DESC;



-- Week 5
-- Find the average shipping date for each category for low sales region and compare it with the Required date of the order 
-- (using shipped date - order date)

-- Code by Dan and Baha to show all instances of delayed shipping

-- CREATE VIEW IF NOT EXISTS week_5_avg_delay AS 
WITH late_deliveries AS 
(
	SELECT
		o.OrderID,
		o.OrderDate,
		o.RequiredDate,
		o.ShippedDate,
		o.ShipCountry,
		c.CategoryID,
		c.CategoryName,
		JULIANDAY(o.ShippedDate) - JULIANDAY( o.RequiredDate) AS delay_in_days
	FROM Orders o
	JOIN 'Order details' od ON o.OrderID = od.OrderID
	JOIN Products p ON od.ProductID = p.ProductID
	JOIN Categories c ON p.CategoryID = c.CategoryID
	WHERE o.ShippedDate > o.RequiredDate 
)
SELECT 
	ld.CategoryName AS 'Category', 
	ROUND(AVG(ld.delay_in_days),2) AS avg_delay_days
FROM late_deliveries ld
JOIN week_2 w2 ON ld.ShipCountry = w2.ShipCountry
WHERE w2.sales_level = 0
GROUP BY category
ORDER BY avg_delay_days DESC;