task for week 1:
What countries does the company sell its products to and what are the categories sold to each country? 
-- Used group_concat function to ensure all the categories are listed


task for week 2:
calculating the sales amount for the company 2016
2017-2018 using order and order details tables and seperate the sales amounts for 3 categories low-medium-high team leader will decide the threshold of each category according to the Normal distribution of the sales
Using percentile ranking 

--High sales		Medium sales				Low sales
--Above 84%		Between 84% and 16%			Below 16%
--(38105.675)		(38105.675 - 2691.7)			(2691.7)


SELECT
    strftime('%Y', order_date) as year,
    ordered_country,
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
            (od."UnitPrice" * od."Quantity") sales,
            (od."UnitPrice" * od."Quantity") * od."Discount" as total_discount
        FROM
            "Order Details" od
            JOIN Orders o ON od."OrderID" = o."OrderID"
    )
GROUP BY
    1,
    2
ORDER BY
    1 