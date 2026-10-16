/* Power BI: moi bang chi co mot grain. Khong lap SalesValue tren dong hang.
   Du lieu gia lap; don vi tien chua duoc xac minh.
*/
USE EcommerceSalesPortfolio;
GO
CREATE OR ALTER VIEW dbo.bi_FactOrders AS
SELECT OrderID, UserID, CAST(OrderDate AS date) AS OrderDate,
    OrderStatus, ItemGrossValue, OrderDiscount, SalesValue,
    TaxAmount, ShippingCost, TotalBilled
FROM dbo.v_PracticeSalesOrders;
GO
CREATE OR ALTER VIEW dbo.bi_FactOrderItems AS
SELECT i.id AS OrderItemID, i.order_id AS OrderID, i.product_id AS ProductID,
    i.quantity AS Quantity, i.unit_price AS UnitPrice,
    i.quantity * i.unit_price AS ItemGrossValue
FROM dbo.order_items AS i
JOIN dbo.v_PracticeSalesOrders AS o ON o.OrderID = i.order_id;
GO
CREATE OR ALTER VIEW dbo.bi_DimProducts AS
SELECT p.id AS ProductID, p.name AS ProductName, c.id AS CategoryID, c.name AS CategoryName
FROM dbo.products AS p JOIN dbo.categories AS c ON c.id = p.category_id;
GO
CREATE OR ALTER VIEW dbo.bi_DimCustomers AS
SELECT id AS UserID FROM dbo.users;
GO

-- Doi soat: 250 don, 66 khach, SalesValue=61041.13, TotalBilled=70317.71.
SELECT COUNT(*) AS EligibleOrders, COUNT(DISTINCT OrderID) AS UniqueOrderIDs,
    COUNT(DISTINCT UserID) AS PurchasingCustomers,
    SUM(SalesValue) AS SalesValue, SUM(TotalBilled) AS TotalBilled
FROM dbo.bi_FactOrders;
SELECT SUM(ItemGrossValue) AS ItemGrossFromItems FROM dbo.bi_FactOrderItems;
SELECT SUM(ItemGrossValue) AS ItemGrossFromOrders FROM dbo.bi_FactOrders;
GO
