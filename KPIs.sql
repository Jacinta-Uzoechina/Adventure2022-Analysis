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
