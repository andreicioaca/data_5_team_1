# Week 1:
# What countries does the company sell its products to and what are the categories sold to each country? 

select distinct o.ShipCountry, c.categoryname from Categories c 
        join Products p on c.CategoryID = p.CategoryID 
        join "Order Details" od on p.ProductID = od.ProductID 
        join Orders o on od.OrderID = o.OrderID 
order by o.ShipCountry, c.CategoryName; 

# Extra code that concatinates all categories into one column
# NOTE: does NOT sort the categories - needs to be updated

/*

SELECT DISTINCT  o.ShipCountry country, GROUP_CONCAT(DISTINCT c.CategoryName) categories FROM Orders o
	JOIN "Order Details" od  ON od.OrderID = o.OrderID 
	JOIN Products p ON od.ProductID = p.ProductID 
	JOIN Categories c on c.CategoryID = p.CategoryID
GROUP BY o.ShipCountry 
ORDER BY  o.ShipCountry;

*/



# Week 2: 
# Calculate the sales amount for the company in the years 2016, 2017 and 2018 using 'order' and 'order details' tables and separate the sales amounts into 3 categories (low, medium and high sales).
# Teamleader will decide the threshold of each category.

# Input from Peter Agunbiade - his definition of what low-medium-high sales should be:

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



# Week 3
# Calculate the top 3 selling products

# (under construction)

SELECT GROUP_CONCAT(ProductName) as "Products" ,  "Number of Sales"  
FROM  (SELECT COUNT(od.ProductID) as  "Number of Sales", productName, od.ProductID 
FROM Orders o 
JOIN 'Order Details' od on o.OrderID = od.orderid
JOIN Products p on p.ProductID = od.ProductID
GROUP BY ProductName)
GROUP BY "Number of Sales" ORDER BY "Number of Sales" DESC LIMIT 3
