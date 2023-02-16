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
    GROUP_CONCAT(CATEGORY) as CATEGORY
FROM cat
GROUP BY COUNTRY;

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
ORDER BY country, missing_category;

-- Week 2: 
-- Calculate the sales amount for the company in the years 2016, 2017 and 2018 using 'order' and 'order details' tables and separate the sales amounts into 3 categories (low, medium and high sales).
-- Teamleader will decide the threshold of each category.

-- Week 2, Baha's input based on cluster analysis

--	High sales		Medium sales			Low sales
--	>75,000			21,500 - 75,000			<21,500

WITH annual_report AS (
	SELECT
		strftime('%Y', o.OrderDate) as year,
		o.ShipCountry,
		c.CategoryName,
		SUM(od.UnitPrice * od.Quantity * (1- od.Discount)) as actual_sales
	FROM "orders" o
	JOIN "Order Details" od ON o."OrderID" = od."OrderID"
	JOIN "Products" p ON p."ProductID" = od."ProductID"
	JOIN "Categories" c ON c."CategoryID" = p."CategoryID"
	GROUP BY YEAR, ShipCountry
)

SELECT *,
CASE
	WHEN (actual_sales >= 75000) THEN 2
	WHEN (actual_sales BETWEEN 21500 AND 75000) THEN 1
	WHEN (actual_sales < 21500) THEN 0
END AS sales_level
FROM annual_report
ORDER BY year ASC, sales_level DESC;

-- Week 3
-- Calculate the top 3 selling products

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

-- How to check what regions employees do NOT cover? 
-- There are a boatload of regions they cover, really hard to compare

-- Week 4
-- Number of territories each employee responsible for
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
select
ROUND(SUM(UNITPRICE * QUANTITY * (1- DISCOUNT)),2) as ActualSales,
REGION,
group_concat(distinct CATEGORY) as 'Categories per region'
from cat
group by REGION 
having ActualSales  < 30000
order by ActualSales DESC