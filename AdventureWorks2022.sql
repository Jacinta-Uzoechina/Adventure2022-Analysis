USE AdventureWorks2022;
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS;
--Query for KPIs for dashboard
-- Total products
SELECT COUNT(DISTINCT ProductID) AS TotalProducts
FROM Production.Product;
-- Total product category
SELECT COUNT(DISTINCT ProductCategoryID) AS TotalCategories
FROM Production.ProductCategory;
-- Total product subcategories
SELECT COUNT(DISTINCT ProductSubcategoryID) AS TotalSubcategories
FROM Production.ProductSubcategory;
-- Product category and total subcatories 
SELECT PC.Name AS CategoryName, 
       COUNT(DISTINCT PSC.ProductSubcategoryID) AS TotalSubcategories
FROM Production.ProductCategory AS PC
LEFT JOIN Production.ProductSubcategory AS PSC ON PC.ProductCategoryID = PSC.ProductCategoryID
GROUP BY PC.ProductCategoryID, PC.Name;
-- Total Customers
SELECT COUNT(DISTINCT CustomerID)
FROM Sales.Customer;
-- Total Sales
SELECT SUM(LineTotal) AS TotalSalesAmount
FROM Sales.SalesOrderDetail;
-- Total Orders
SELECT COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader;
-- Total Stores
SELECT COUNT(DISTINCT BusinessEntityID)
FROM Sales.Store;
--Total Expenses  
SELECT SUM(StandardCost) AS TotalExpenses
FROM Sales.SalesOrderDetail As SOD
JOIN Production.ProductCostHistory AS PCH ON SOD.ProductID = PCH.ProductID;
-- Total Profit
WITH TotalProfit AS 
        (SELECT SUM(LineTotal - UnitPriceDiscount) AS TotalSales,
        (SELECT SUM(StandardCost) FROM Production.ProductCostHistory AS PCH
		JOIN Sales.SalesOrderDetail AS SOD ON PCH.ProductID = SOD.ProductID) AS TotalCost
		FROM Sales.SalesOrderDetail)
SELECT TotalSales - TotalCost AS TotalProfit
FROM TotalProfit;
-- Profit Margin
WITH TotalProfit AS 
        (SELECT SUM(LineTotal - UnitPriceDiscount) AS TotalSales,
        (SELECT SUM(StandardCost) FROM Production.ProductCostHistory AS PCH
		JOIN Sales.SalesOrderDetail AS SOD ON PCH.ProductID = SOD.ProductID) AS TotalCost
		FROM Sales.SalesOrderDetail)
SELECT (TotalSales - TotalCost) / TotalSales * 100 AS TotalProfit
FROM TotalProfit;
-- Analysis for Insights 
-- Customers Analysis
-- One Time Customers
WITH OneTimeCustomers AS 
					(SELECT CustomerID 
		            FROM Sales.SalesOrderHeader
					GROUP BY CustomerID
					HAVING COUNT(*) = 1)
SELECT COUNT (*) AS TotalOrder
FROM OneTimeCustomers;
-- High Spending Customers
SELECT TOP 10 CONCAT(FirstName, ' ', LastName) AS Name, ROUND(SUM(SOD.TotalDue), 2) AS TotalSpent
FROM Sales.SalesOrderHeader AS SOD
JOIN Sales.Customer AS C ON SOD.CustomerID = C.CustomerID
JOIN Person.Person AS P ON C.PersonID = P.BusinessEntityID
GROUP BY SOD.CustomerID, CONCAT(FirstName, ' ', LastName) 
ORDER BY TotalSpent DESC;
-- Frequent Orders
SELECT TOP 20 CONCAT(FirstName, ' ', LastName) AS Name, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader AS SOD
JOIN Sales.Customer AS C ON SOD.CustomerID = C.CustomerID
JOIN Person.Person AS P ON C.PersonID = P.BusinessEntityID
GROUP BY SOD.CustomerID, CONCAT(FirstName, ' ', LastName) 
ORDER BY TotalOrders DESC;
-- Products Analysis
-- Products that did not Sell
SELECT COUNT(*)
FROM (SELECT ProductID
FROM Production.Product
EXCEPT 
SELECT ProductID
FROM Sales.SalesOrderDetail) AS ProductsWithNoSales
-- Top 10 selling Products
SELECT TOP 10 P.Name AS ProductName, SUM(SOD.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY P.Name
ORDER BY TotalRevenue DESC;
-- Total revenue by product 
SELECT P.Name AS ProductName, SUM(SOD.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY P.Name
ORDER BY TotalRevenue DESC;
-- Total revenue product category
SELECT PC.Name AS ProductCategory, SUM(SOD.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY PC.Name;
-- Profit margins per Product category
WITH OverallProfit AS 
(
    SELECT SUM(SOD.LineTotal) - SUM(PCH.StandardCost) AS TotalProfit
    FROM Sales.SalesOrderDetail AS SOD
    JOIN Production.ProductCostHistory AS PCH ON SOD.ProductID = PCH.ProductID
),
ProductRevenue AS 
(
    SELECT
        PC.Name AS ProductCategory,
        SUM(SOD.LineTotal) AS Revenue,
        SUM(SOD.LineTotal) - SUM(PCH.StandardCost) AS ProductProfit
    FROM Sales.SalesOrderDetail AS SOD
    JOIN Production.ProductCostHistory AS PCH ON SOD.ProductID = PCH.ProductID
	JOIN Production.Product AS P ON PCH.ProductID = P.ProductID
    JOIN Production.ProductSubcategory AS PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
    JOIN Production.ProductCategory AS PC ON PS.ProductCategoryID = PC.ProductCategoryID
    GROUP BY PC.Name
)
SELECT
    PR.ProductCategory,
    PR.ProductProfit / OP.TotalProfit * 100 AS ProfitMargin
FROM ProductRevenue AS PR
CROSS JOIN OverallProfit AS OP;
-- Profit margins by product 
WITH OverallProfit AS 
(
    SELECT SUM(SOD.LineTotal) - SUM(PCH.StandardCost) AS TotalProfit
    FROM Sales.SalesOrderDetail AS SOD
    JOIN Production.ProductCostHistory AS PCH ON SOD.ProductID = PCH.ProductID
),
ProductRevenue AS 
(
    SELECT
        P.Name AS ProductName,
        SUM(SOD.LineTotal) AS Revenue,
        SUM(SOD.LineTotal) - SUM(PCH.StandardCost) AS ProductProfit
    FROM Sales.SalesOrderDetail AS SOD
    JOIN Production.ProductCostHistory AS PCH ON SOD.ProductID = PCH.ProductID
	JOIN Production.Product AS P ON PCH.ProductID = P.ProductID
    JOIN Production.ProductSubcategory AS PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
    JOIN Production.ProductCategory AS PC ON PS.ProductCategoryID = PC.ProductCategoryID
    GROUP BY P.Name
)
SELECT
    PR.ProductName,
    PR.ProductProfit / OP.TotalProfit * 100 AS ProfitMargin
FROM ProductRevenue AS PR
CROSS JOIN OverallProfit AS OP;
-- profit Margin by Product Subcategory
WITH OverallProfit AS 
(
    SELECT SUM(SOD.LineTotal) - SUM(PCH.StandardCost) AS TotalProfit
    FROM Sales.SalesOrderDetail AS SOD
    JOIN Production.ProductCostHistory AS PCH ON SOD.ProductID = PCH.ProductID
),
ProductRevenue AS 
(
    SELECT
        PS.Name AS ProductSubcategory,
        SUM(SOD.LineTotal) AS Revenue,
        SUM(SOD.LineTotal) - SUM(PCH.StandardCost) AS ProductProfit
    FROM Sales.SalesOrderDetail AS SOD
    JOIN Production.ProductCostHistory AS PCH ON SOD.ProductID = PCH.ProductID
	JOIN Production.Product AS P ON PCH.ProductID = P.ProductID
    JOIN Production.ProductSubcategory AS PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
    JOIN Production.ProductCategory AS PC ON PS.ProductCategoryID = PC.ProductCategoryID
    GROUP BY PS.Name
)
SELECT
    PR.ProductSubcategory,
    PR.ProductProfit / OP.TotalProfit * 100 AS ProfitMargin
FROM ProductRevenue AS PR
CROSS JOIN OverallProfit AS OP;
-- Sales Analysis
-- Monthly sales trends
SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth, SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY YEAR(OrderDate), MONTH(OrderDate);
--Yearly sales Trend
SELECT YEAR(OrderDate) AS OrderYear, SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate);
-- Sales Under No Demographic
SELECT ROUND(SUM(SOD.TotalDue), 2) AS TotalSpent
FROM Sales.SalesOrderHeader AS SOD
JOIN Sales.Customer AS C ON SOD.CustomerID = C.CustomerID
JOIN Sales.vPersonDemographics AS PD ON C.PersonID = PD.BusinessEntityID
WHERE Gender IS NULL;
-- Sales with Demographic
SELECT ROUND(SUM(SOD.TotalDue), 2) AS TotalSpent
FROM Sales.SalesOrderHeader AS SOD
JOIN Sales.Customer AS C ON SOD.CustomerID = C.CustomerID
JOIN Sales.vPersonDemographics AS PD ON C.PersonID = PD.BusinessEntityID;