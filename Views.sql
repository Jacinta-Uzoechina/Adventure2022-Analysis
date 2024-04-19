--View for KPIs and Analysis for dashboard
-- Total products
CREATE VIEW Production.vwTotalProducts AS
SELECT COUNT(DISTINCT ProductID) AS TotalProducts
FROM Production.Product;
-- Total product category
CREATE VIEW Production.vwTotalCategories AS
SELECT COUNT(DISTINCT ProductCategoryID) AS TotalCategories
FROM Production.ProductCategory;
-- Total product subcategories
CREATE VIEW Production.vwTotalSubcategories AS
SELECT COUNT(DISTINCT ProductSubcategoryID) AS TotalSubcategories
FROM Production.ProductSubcategory;
-- Product category and total subcatories 
CREATE VIEW Production.vwTotalCatogoriesSubcategories AS
SELECT PC.Name AS CategoryName, 
       COUNT(DISTINCT PSC.ProductSubcategoryID) AS TotalSubcategories
FROM Production.ProductCategory AS PC
LEFT JOIN Production.ProductSubcategory AS PSC ON PC.ProductCategoryID = PSC.ProductCategoryID
GROUP BY PC.ProductCategoryID, PC.Name;
-- Total Customers
CREATE VIEW Sales.vwTotalCustomers AS
SELECT COUNT(DISTINCT CustomerID) AS ToTalCustomers
FROM Sales.Customer;
-- Total Sales
CREATE VIEW Sales.vwTotalSales AS
SELECT SUM(LineTotal) AS TotalSalesAmount
FROM Sales.SalesOrderDetail;
-- Total Orders
CREATE VIEW Sales.vwTotalOrders AS
SELECT COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader;
-- Total Stores
CREATE VIEW Sales.vwTotalStores AS
SELECT COUNT(DISTINCT BusinessEntityID) AS TotalStores
FROM Sales.Store;
--Total Expenses  
CREATE VIEW Production.vwTotalExpenses AS
SELECT SUM(StandardCost) AS TotalExpenses
FROM Sales.SalesOrderDetail As SOD
JOIN Production.ProductCostHistory AS PCH ON SOD.ProductID = PCH.ProductID;
-- Total Profit
CREATE VIEW Sales.vwTotalProfit AS
WITH TotalProfit AS 
        (SELECT SUM(LineTotal - UnitPriceDiscount) AS TotalSales,
        (SELECT SUM(StandardCost) FROM Production.ProductCostHistory AS PCH
		JOIN Sales.SalesOrderDetail AS SOD ON PCH.ProductID = SOD.ProductID) AS TotalCost
		FROM Sales.SalesOrderDetail)
SELECT TotalSales - TotalCost AS TotalProfit
FROM TotalProfit;
-- Profit Margin
CREATE VIEW Sales.vwProfitMargin AS
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
CREATE VIEW Sales.vwOnceSpendingCustomerss AS
WITH OneTimeCustomers AS 
					(SELECT CustomerID 
		            FROM Sales.SalesOrderHeader
					GROUP BY CustomerID
					HAVING COUNT(*) = 1)
SELECT COUNT (*) AS TotalOrder
FROM OneTimeCustomers;
-- High Spending Customers
CREATE VIEW Sales.vwTopSpendingCustomers AS
SELECT TOP 10 CONCAT(FirstName, ' ', LastName) AS Name, ROUND(SUM(SOD.TotalDue), 2) AS TotalSpent
FROM Sales.SalesOrderHeader AS SOD
JOIN Sales.Customer AS C ON SOD.CustomerID = C.CustomerID
JOIN Person.Person AS P ON C.PersonID = P.BusinessEntityID
GROUP BY SOD.CustomerID, CONCAT(FirstName, ' ', LastName) 
ORDER BY TotalSpent DESC;
-- Frequent Orders
CREATE VIEW Sales.vwTotalCustomerOrders AS
SELECT TOP 20 CONCAT(FirstName, ' ', LastName) AS Name, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader AS SOD
JOIN Sales.Customer AS C ON SOD.CustomerID = C.CustomerID
JOIN Person.Person AS P ON C.PersonID = P.BusinessEntityID
GROUP BY SOD.CustomerID, CONCAT(FirstName, ' ', LastName) 
ORDER BY TotalOrders DESC;
-- Products Analysis
-- Products that did not Sell
CREATE VIEW Sales.vwTotalNonSelinngProducts AS
SELECT COUNT(*) AS CountProductsWithNoSales
FROM (SELECT ProductID
FROM Production.Product
EXCEPT 
SELECT ProductID
FROM Sales.SalesOrderDetail) AS ProductsWithNoSales
-- Top 10 selling Products
CREATE VIEW Sales.vwTopSellingproducts AS
SELECT TOP 10 P.Name AS ProductName, SUM(SOD.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY P.Name
ORDER BY TotalRevenue DESC;
-- Total revenue by product 
CREATE VIEW Sales.vwTotalRevenueProduct AS
SELECT P.Name AS ProductName, SUM(SOD.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY P.Name;
-- Total revenue product category
CREATE VIEW Sales.vwTotalRevenueCategories AS
SELECT PC.Name AS ProductCategory, SUM(SOD.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY PC.Name;
-- Profit margins per Product category
CREATE VIEW Sales.vwTotalProfitCategories AS
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
CREATE VIEW Sales.vwTotalProfitProduct AS
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
CREATE VIEW Sales.vwTotalProfitsubcategories AS
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
CREATE VIEW Sales.vwTotalMonthlySales AS
SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth, SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate);
--Yearly sales Trend
CREATE VIEW Sales.vwTotalYearlylySales AS
SELECT YEAR(OrderDate) AS OrderYear, SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate);
-- Sales Under No Demographic
CREATE VIEW Sales.vwTotalSpentWithoutDemographic AS
SELECT ROUND(SUM(SOD.TotalDue), 2) AS TotalSpent
FROM Sales.SalesOrderHeader AS SOD
JOIN Sales.Customer AS C ON SOD.CustomerID = C.CustomerID
JOIN Sales.vPersonDemographics AS PD ON C.PersonID = PD.BusinessEntityID
WHERE Gender IS NULL;
-- Sales with Demographic
CREATE VIEW Sales.vwTotalSpentWithDemographic AS
SELECT ROUND(SUM(SOD.TotalDue), 2) AS TotalSpent
FROM Sales.SalesOrderHeader AS SOD
JOIN Sales.Customer AS C ON SOD.CustomerID = C.CustomerID
JOIN Sales.vPersonDemographics AS PD ON C.PersonID = PD.BusinessEntityID;
-- Store Analysis
CREATE VIEW Sales.vwTotalStoreSales AS
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