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
-- Store Analysis
WITH StoreSales AS 
(
    SELECT DISTINCT SalesPersonID, SUM(TotalDue) AS SalesPerStore
    FROM Sales.SalesOrderHeader 
	GROUP BY SalesPersonID
),
StoreName AS 
(
    SELECT Name AS StoreName
    FROM Sales.Store 
)
SELECT
    SN.StoreName,
    SS.SalesPerStore
FROM StoreSales AS SS
CROSS JOIN StoreName AS SN;










