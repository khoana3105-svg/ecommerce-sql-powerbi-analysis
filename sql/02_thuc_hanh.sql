/* SQL Server basic practice: run 01_tao_va_nap.sql ONCE before this file.
   Read GIAI_THICH.md for metric definitions and interpretation.
   Source data is synthetic. No DELETE/UPDATE is performed here.
   GO separates batches for SSMS; execute the entire file on the first run.
*/
USE EcommerceSalesPortfolio;
GO

-- 01. KIEM TRA DA NAP: bang, so dong va khoang ngay.
SELECT COUNT(*) AS ImportedTables FROM sys.tables WHERE is_ms_shipped = 0;
SELECT N'orders' AS TableName, COUNT(*) AS TotalRows FROM dbo.orders
UNION ALL SELECT N'order_items', COUNT(*) FROM dbo.order_items
UNION ALL SELECT N'products', COUNT(*) FROM dbo.products
UNION ALL SELECT N'users', COUNT(*) FROM dbo.users
UNION ALL SELECT N'payments', COUNT(*) FROM dbo.payments;
SELECT MIN(created_at) AS FirstOrderDate, MAX(created_at) AS LastOrderDate FROM dbo.orders;
SELECT TOP (10) id, created_at, user_id, subtotal, discount_amount, tax_amount, shipping_cost, total
FROM dbo.orders ORDER BY created_at, id;

-- 02. EDA: trang thai don va thanh toan.
SELECT s.status_name, COUNT(*) AS OrderCount, SUM(o.total) AS RecordedOrderTotal
FROM dbo.orders AS o
JOIN dbo.order_statuses AS s ON s.id = o.order_status_id
GROUP BY s.status_name ORDER BY OrderCount DESC, s.status_name;
SELECT status, COUNT(*) AS PaymentCount, SUM(amount) AS RecordedPaymentAmount
FROM dbo.payments GROUP BY status ORDER BY PaymentCount DESC, status;

-- 03. KIEM TRA TONG TIEN: ky vong 0 dong sai.
SELECT COUNT(*) AS TotalFormulaMismatch
FROM dbo.orders
WHERE total <> subtotal - discount_amount + tax_amount + shipping_cost;

-- Gom chi tiet ve MOT DONG / DON truoc khi JOIN: tranh nhan ban tong tien.
SELECT o.id, o.subtotal, i.ItemGross, o.tax_amount, i.ItemTax
FROM dbo.orders AS o
LEFT JOIN (
    SELECT order_id, SUM(quantity * unit_price) AS ItemGross, SUM(tax_amount) AS ItemTax
    FROM dbo.order_items GROUP BY order_id
) AS i ON i.order_id = o.id
WHERE o.subtotal <> COALESCE(i.ItemGross, 0) OR o.tax_amount <> COALESCE(i.ItemTax, 0);

SELECT COUNT(*) AS PaymentAmountMismatch
FROM dbo.payments AS p JOIN dbo.orders AS o ON o.id = p.order_id
WHERE p.amount <> o.total;

-- 04. EDA: du lieu gia lap co the co mau thuan nghiep vu.
SELECT COUNT(*) AS OrdersBeforeUserCreated
FROM dbo.orders AS o JOIN dbo.users AS u ON u.id = o.user_id
WHERE o.created_at < u.created_at;

SELECT COUNT(*) AS CompletedPaymentOnCancelledOrRefunded
FROM dbo.orders AS o
JOIN dbo.order_statuses AS s ON s.id = o.order_status_id
JOIN dbo.payments AS p ON p.order_id = o.id
WHERE p.status = N'completed' AND s.status_name IN (N'cancelled', N'refunded');

SELECT COUNT(*) AS OrdersWithoutPayment
FROM dbo.orders AS o LEFT JOIN dbo.payments AS p ON p.order_id = o.id
WHERE p.id IS NULL;
SELECT COUNT(*) AS OrdersWithoutItems
FROM dbo.orders AS o LEFT JOIN dbo.order_items AS i ON i.order_id = o.id
WHERE i.id IS NULL;

-- Xem so luong/gia bat thuong, chi thong ke chu khong tu xoa.
SELECT MIN(quantity) AS MinQuantity, MAX(quantity) AS MaxQuantity,
    MIN(unit_price) AS MinUnitPrice, MAX(unit_price) AS MaxUnitPrice,
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS NonpositiveQuantity,
    SUM(CASE WHEN unit_price < 0 THEN 1 ELSE 0 END) AS NegativeUnitPrice
FROM dbo.order_items;
GO

-- 05. QUY TAC PHAN TICH: mot dong / don hang du dieu kien.
-- payments.order_id la UNIQUE trong schema nguon: JOIN nay khong nhan dong.
-- SalesValue: subtotal - discount_amount, chua thue/phi ship, chua doi soat refund.
-- Khong tu sua ngay dat don/tao tai khoan trong du lieu gia lap.
CREATE OR ALTER VIEW dbo.v_PracticeSalesOrders AS
SELECT o.id AS OrderID, o.user_id AS UserID, o.created_at AS OrderDate,
    s.status_name AS OrderStatus,
    o.subtotal AS ItemGrossValue, o.discount_amount AS OrderDiscount,
    o.subtotal - o.discount_amount AS SalesValue,
    o.tax_amount AS TaxAmount, o.shipping_cost AS ShippingCost,
    o.total AS TotalBilled
FROM dbo.orders AS o
JOIN dbo.order_statuses AS s ON s.id = o.order_status_id
JOIN dbo.payments AS p ON p.order_id = o.id
WHERE s.status_name IN (N'paid', N'shipped', N'delivered')
    AND p.status = N'completed';
GO

-- 06. DOI SOAT TAP PHAN TICH: ky vong 250 don, SalesValue = 61041.13.
SELECT COUNT(*) AS EligibleOrders,
    COUNT(DISTINCT OrderID) AS DistinctEligibleOrders,
    SUM(ItemGrossValue) AS ItemGrossValue, SUM(OrderDiscount) AS OrderDiscount,
    SUM(SalesValue) AS SalesValue, SUM(TaxAmount) AS TaxAmount,
    SUM(ShippingCost) AS ShippingCost, SUM(TotalBilled) AS TotalBilled,
    SUM(SalesValue) / NULLIF(COUNT(*), 0) AS AverageOrderSalesValue,
    COUNT(DISTINCT UserID) AS CustomersWithEligibleOrders
FROM dbo.v_PracticeSalesOrders;

-- 07. LOC VA SAP XEP: TOP don gia tri cao, khong phai TOP khach hang.
SELECT TOP (10) OrderID, OrderDate, UserID, OrderStatus, SalesValue, TotalBilled
FROM dbo.v_PracticeSalesOrders
WHERE SalesValue > 0
ORDER BY SalesValue DESC, OrderID;

-- 08. GIA TRI BAN HANG THEO THANG: dung nam VA thang.
SELECT YEAR(OrderDate) AS SalesYear, MONTH(OrderDate) AS SalesMonth,
    COUNT(*) AS EligibleOrders, SUM(SalesValue) AS SalesValue,
    SUM(TotalBilled) AS TotalBilled,
    SUM(SalesValue) / NULLIF(COUNT(*), 0) AS AverageOrderSalesValue
FROM dbo.v_PracticeSalesOrders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY SalesYear, SalesMonth;

-- 09. GIA TRI BAN HANG THEO QUY.
SELECT YEAR(OrderDate) AS SalesYear, DATEPART(QUARTER, OrderDate) AS SalesQuarter,
    COUNT(*) AS EligibleOrders, SUM(SalesValue) AS SalesValue, SUM(TotalBilled) AS TotalBilled
FROM dbo.v_PracticeSalesOrders
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY SalesYear, SalesQuarter;

-- 10. TONG THEO NAM: khong suy luan tang truong kinh doanh tu du lieu gia lap.
SELECT YEAR(OrderDate) AS SalesYear, COUNT(*) AS EligibleOrders,
    SUM(SalesValue) AS SalesValue,
    SUM(SalesValue) / NULLIF(COUNT(*), 0) AS AverageOrderSalesValue
FROM dbo.v_PracticeSalesOrders
GROUP BY YEAR(OrderDate) ORDER BY SalesYear;

-- 11. TOP 10 SAN PHAM THEO GIA TRI HANG TRUOC GIAM GIA CAP DON.
-- Dung unit_price luc dat hang, khong dung products.price hien tai.
SELECT TOP (10) p.id AS ProductID, p.name AS ProductName,
    SUM(i.quantity) AS UnitsSold,
    SUM(i.quantity * i.unit_price) AS ItemGrossValue,
    COUNT(DISTINCT i.order_id) AS OrderCount
FROM dbo.order_items AS i
JOIN dbo.v_PracticeSalesOrders AS o ON o.OrderID = i.order_id
JOIN dbo.products AS p ON p.id = i.product_id
GROUP BY p.id, p.name ORDER BY ItemGrossValue DESC, p.id;

-- 12. TOP 10 SAN PHAM THEO SO LUONG: tieu chi xep hang khac muc 11.
SELECT TOP (10) p.id AS ProductID, p.name AS ProductName,
    SUM(i.quantity) AS UnitsSold, SUM(i.quantity * i.unit_price) AS ItemGrossValue
FROM dbo.order_items AS i
JOIN dbo.v_PracticeSalesOrders AS o ON o.OrderID = i.order_id
JOIN dbo.products AS p ON p.id = i.product_id
GROUP BY p.id, p.name ORDER BY UnitsSold DESC, p.id;

-- 13. GIA TRI HANG THEO DANH MUC.
SELECT c.id AS CategoryID, c.name AS CategoryName,
    SUM(i.quantity) AS UnitsSold, SUM(i.quantity * i.unit_price) AS ItemGrossValue,
    COUNT(DISTINCT i.order_id) AS OrderCount
FROM dbo.order_items AS i
JOIN dbo.v_PracticeSalesOrders AS o ON o.OrderID = i.order_id
JOIN dbo.products AS p ON p.id = i.product_id
JOIN dbo.categories AS c ON c.id = p.category_id
GROUP BY c.id, c.name ORDER BY ItemGrossValue DESC, c.id;

-- 14. TOP KHACH HANG: tinh tu view cap don de moi don chi duoc cong mot lan.
SELECT TOP (10) u.id AS UserID, COUNT(*) AS EligibleOrders,
    SUM(o.SalesValue) AS SalesValue,
    MIN(o.OrderDate) AS FirstEligibleOrderDate, MAX(o.OrderDate) AS LastEligibleOrderDate
FROM dbo.users AS u
JOIN dbo.v_PracticeSalesOrders AS o ON o.UserID = u.id
GROUP BY u.id ORDER BY SalesValue DESC, u.id;

-- 15. KHACH MUA LAP: >= 2 don du dieu kien trong toan bo khoang du lieu.
SELECT UserID, COUNT(*) AS EligibleOrders, SUM(SalesValue) AS SalesValue
FROM dbo.v_PracticeSalesOrders GROUP BY UserID HAVING COUNT(*) >= 2
ORDER BY EligibleOrders DESC, UserID;

SELECT COUNT(*) AS PurchasingCustomers,
    SUM(CASE WHEN EligibleOrders >= 2 THEN 1 ELSE 0 END) AS RepeatCustomers,
    100.0 * SUM(CASE WHEN EligibleOrders >= 2 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS RepeatCustomerPct
FROM (
    SELECT UserID, COUNT(*) AS EligibleOrders
    FROM dbo.v_PracticeSalesOrders GROUP BY UserID
) AS CustomerOrders;

-- 16. LEFT JOIN: tai khoan chua co don DU DIEU KIEN, khong dong nghia chua tung dat don.
SELECT u.id AS UserID
FROM dbo.users AS u LEFT JOIN dbo.v_PracticeSalesOrders AS o ON o.UserID = u.id
WHERE o.OrderID IS NULL ORDER BY u.id;

-- 17. THANH TOAN THANH CONG: KPI rieng, dung ngay processed_at.
-- Khong goi tong nay la SalesValue: khac pham vi, ngay va thanh phan tien.
SELECT YEAR(processed_at) AS PaymentYear, MONTH(processed_at) AS PaymentMonth,
    COUNT(*) AS CompletedPayments, SUM(amount) AS CompletedPaymentAmount
FROM dbo.payments WHERE status = N'completed'
GROUP BY YEAR(processed_at), MONTH(processed_at)
ORDER BY PaymentYear, PaymentMonth;

-- 18. DOI SOAT CUOI BAI: expected rows in outputs/.
-- SUM(o.TotalBilled) sau JOIN truc tiep order_items se lap lai tien moi don.
SELECT SUM(TotalBilled) AS CorrectTotalBilled FROM dbo.v_PracticeSalesOrders;
SELECT SUM(o.TotalBilled) AS RepeatedTotalAfterItemJoin_DoNotUse
FROM dbo.v_PracticeSalesOrders AS o JOIN dbo.order_items AS i ON i.order_id = o.OrderID;

-- Doi soat dung: hang tong chi tiet = tong subtotal cap don (61632.94).
SELECT SUM(i.quantity * i.unit_price) AS ItemGrossFromLines
FROM dbo.order_items AS i JOIN dbo.v_PracticeSalesOrders AS o ON o.OrderID = i.order_id;
SELECT SUM(ItemGrossValue) AS ItemGrossFromOrders FROM dbo.v_PracticeSalesOrders;
