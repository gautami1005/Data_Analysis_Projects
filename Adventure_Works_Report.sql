use adventure_works;

-- 0. Union of Fact Internet sales and Fact internet sales new
CREATE TABLE sales_union AS 
  SELECT * FROM fact_internet_sales
    UNION
  SELECT * FROM fact_internet_sales_new;
  
SELECT * FROM sales_union;

-- 1.Lookup the productname from the Product sheet to Sales sheet.

SELECT s.ProductKey, p.EnglishProductName FROM dim_product p
INNER JOIN sales_union s ON
p.ProductKey = s.ProductKey;

-- 2.Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet.

SELECT s.ProductKey, p.EnglishProductName, s.UnitPrice, c.CustomerKey,
concat(c.FirstName, ' ', c.MiddleName, ' ', c.LastName)  AS CustomerFullName
FROM dim_product p
	INNER JOIN 
		(sales_union s INNER JOIN dim_customer c 
        ON
		s.CustomerKey = c.CustomerKey)
	ON 
	p.ProductKey = s.ProductKey;

-- 3.calcuate the following fields from the Orderdatekey field ( First Create a Date Field from Orderdatekey)

	-- Creating a new column for Converted Date Field
ALTER TABLE sales_union
ADD OrderDateKeyConverted date;

	-- Copying values from OrderDateKey column to new column using where clause
 -- SET SQL_SAFE_UPDATES = 0;
UPDATE sales_union SET OrderDateKeyConverted = OrderDateKey;
-- SET SQL_SAFE_UPDATES = 1;

--    A.Year
ALTER TABLE sales_union
ADD OrderDateKeyYear int;
UPDATE sales_union SET OrderDateKeyYear = YEAR(OrderDateKeyConverted);
SELECT * FROM sales_union;

SELECT distinct(OrderDateKeyYear) FROM sales_union;

--    B.Monthno
ALTER TABLE sales_union
ADD OrderDateKeyMonth int;
UPDATE sales_union SET OrderDateKeyMonth = MONTH(OrderDateKeyConverted);

--    C.Monthfullname
SELECT OrderDateKeyConverted, MONTHNAME(OrderDateKeyConverted) AS MonthName FROM sales_union;

--    D.Quarter(Q1,Q2,Q3,Q4)
SELECT OrderDateKeyConverted, QUARTER(OrderDateKeyConverted) AS Quarter FROM sales_union;

--    E. YearMonth ( YYYY-MMM)
SELECT DATE_FORMAT(OrderDateKeyConverted, '%Y-%b') AS YearMonth FROM sales_union;

--    F. Weekdayno
SELECT OrderDateKeyConverted, WEEKDAY(OrderDateKeyConverted) AS WeekDay FROM sales_union;

--    G.Weekdayname
SELECT OrderDateKeyConverted, DAYNAME(OrderDateKeyConverted) AS WeekDayName FROM sales_union;

--    H.FinancialMOnth
SELECT OrderDateKeyConverted,
    CASE 
        WHEN MONTH(OrderDateKeyConverted) between 3 and 12 THEN month(OrderDateKeyConverted) -3
        WHEN MONTH(OrderDateKeyConverted) between 1 and 3 THEN month(OrderDateKeyConverted) +9
    END AS FinancialMonth
FROM 
    sales_union;

--    I. Financial Quarter 
SELECT OrderDateKeyConverted,
    CASE 
        WHEN MONTH(OrderDateKeyConverted) IN (1, 2, 3) THEN 'Q4'
        WHEN MONTH(OrderDateKeyConverted) IN (4, 5, 6) THEN 'Q1'
        WHEN MONTH(OrderDateKeyConverted) IN (7, 8, 9) THEN 'Q2'
        WHEN MONTH(OrderDateKeyConverted) IN (10, 11, 12) THEN 'Q3'
    END AS FinancialQuarter
FROM sales_union;


-- 4.Calculate the Sales amount uning the columns(unit price,order quantity,unit discount)
ALTER TABLE sales_union
ADD Sales_Amount int;
Update Sales_union set sales_amount=unitprice*orderquantity*(1-unitpricediscountpct);
SELECT ProductKey, CustomerKey, OrderQuantity, UnitPrice, UnitPriceDiscountPct, Sales_Amount FROM sales_union;

-- 5.Calculate the Productioncost uning the columns(unit cost ,order quantity)
ALTER TABLE sales_union
ADD Production_Cost int;
Update Sales_union set Production_Cost=orderquantity*totalproductcost;
SELECT ProductKey, CustomerKey, OrderQuantity, UnitPrice, UnitPriceDiscountPct, Sales_Amount,Production_Cost FROM sales_union;

-- 6.Calculate the profit.
SELECT Sales_amount,Production_Cost,(Sales_amount-Production_Cost) as Profit from Sales_Union;
-- 7.Create a Pivot table for month and sales (provide the Year as filter to select a particular Year)

SELECT 
    month(OrderDateKeyConverted) AS Ordermonthnew,
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 1 THEN Sales_Amount ELSE 0 END) AS "January",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 2 THEN Sales_Amount ELSE 0 END) AS "February",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 3 THEN Sales_Amount ELSE 0 END) AS "March",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 4 THEN Sales_Amount ELSE 0 END) AS "April",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 5 THEN Sales_Amount ELSE 0 END) AS "May",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 6 THEN Sales_Amount ELSE 0 END) AS "June",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 7 THEN Sales_Amount ELSE 0 END) AS "July",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 8 THEN Sales_Amount ELSE 0 END) AS "August",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 9 THEN Sales_Amount ELSE 0 END) AS "September",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 10 THEN Sales_Amount ELSE 0 END) AS "October",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 11 THEN Sales_Amount ELSE 0 END) AS "November",
    SUM(CASE WHEN MONTH(OrderDateKeyConverted) = 12 THEN Sales_Amount ELSE 0 END) AS "December"
FROM 
    sales_Union
WHERE
    YEAR(OrderDateKeyConverted) = 2011 -- Replace with the desired year to filter by
GROUP BY
    Ordermonthnew
order by Ordermonthnew asc;

#8.Create a Bar chart to show yearwise Sales
SELECT YEAR(OrderDateKeyConverted) AS yearwise, SUM(Sales_amount) AS total_sales
FROM sales_union
GROUP BY YEAR(OrderDateKeyConverted)
ORDER BY yearwise ASC;

#9.Create a Line Chart to show Monthwise sales
SELECT MONTH(OrderDateKeyConverted) AS monthwise, SUM(Sales_amount) AS total_sales
FROM sales_union
GROUP BY MONTH(OrderDateKeyConverted)
ORDER BY monthwise ASC;

#10.Create a Pie chart to show Quarterwise sales
SELECT QUARTER(OrderDateKeyConverted) AS quarterwise, SUM(Sales_amount) AS total_sales
FROM sales_union
GROUP BY QUARTER(OrderDateKeyConverted)
ORDER BY quarterwise ASC;

#11.Create a combinational chart (bar and Line) to show Salesamount and Productioncost together
SELECT YEAR(OrderDateKeyConverted) AS yearwise, 
       SUM(Sales_amount) AS total_sales, 
       SUM(Production_Cost) AS total_production_cost
FROM sales_union
GROUP BY YEAR(OrderDateKeyConverted)
ORDER BY yearwise ASC;

