# K?t qu? ch?y th?c t? tr?n SQL Server

?? ch?y tr?n database `EcommerceBasicPractice`, SQL Server 16.0.1000.6. C?c file CSV d??i ??y l? k?t qu? th?c thi, kh?ng ph?i d? li?u gi? l?p th?m. Ngu?n ban ??u v?n l? b? d? li?u e-commerce gi? l?p.

??i chi?u: [verification.json](verification.json). Th?ng tin th?c thi: [execution.json](execution.json).

| File | S? d?ng | C?c c?t k?t qu? |
|---|---:|---|
| [result_01.csv](result_01.csv) | 1 | ImportedTables |
| [result_02.csv](result_02.csv) | 5 | TableName, TotalRows |
| [result_03.csv](result_03.csv) | 1 | FirstOrderDate, LastOrderDate |
| [result_04.csv](result_04.csv) | 10 | id, created_at, user_id, subtotal, discount_amount, tax_amount, shipping_cost, total |
| [result_05.csv](result_05.csv) | 6 | status_name, OrderCount, RecordedOrderTotal |
| [result_06.csv](result_06.csv) | 3 | status, PaymentCount, RecordedPaymentAmount |
| [result_07.csv](result_07.csv) | 1 | TotalFormulaMismatch |
| [result_08.csv](result_08.csv) | 0 | id, subtotal, ItemGross, tax_amount, ItemTax |
| [result_09.csv](result_09.csv) | 1 | PaymentAmountMismatch |
| [result_10.csv](result_10.csv) | 1 | OrdersBeforeUserCreated |
| [result_11.csv](result_11.csv) | 1 | CompletedPaymentOnCancelledOrRefunded |
| [result_12.csv](result_12.csv) | 1 | OrdersWithoutPayment |
| [result_13.csv](result_13.csv) | 1 | OrdersWithoutItems |
| [result_14.csv](result_14.csv) | 1 | MinQuantity, MaxQuantity, MinUnitPrice, MaxUnitPrice, NonpositiveQuantity, NegativeUnitPrice |
| [result_15.csv](result_15.csv) | 1 | EligibleOrders, DistinctEligibleOrders, ItemGrossValue, OrderDiscount, SalesValue, TaxAmount, ShippingCost, TotalBilled, AverageOrderSalesValue, CustomersWithEligibleOrders |
| [result_16.csv](result_16.csv) | 10 | OrderID, OrderDate, UserID, OrderStatus, SalesValue, TotalBilled |
| [result_17.csv](result_17.csv) | 60 | SalesYear, SalesMonth, EligibleOrders, SalesValue, TotalBilled, AverageOrderSalesValue |
| [result_18.csv](result_18.csv) | 20 | SalesYear, SalesQuarter, EligibleOrders, SalesValue, TotalBilled |
| [result_19.csv](result_19.csv) | 5 | SalesYear, EligibleOrders, SalesValue, AverageOrderSalesValue |
| [result_20.csv](result_20.csv) | 10 | ProductID, ProductName, UnitsSold, ItemGrossValue, OrderCount |
| [result_21.csv](result_21.csv) | 10 | ProductID, ProductName, UnitsSold, ItemGrossValue |
| [result_22.csv](result_22.csv) | 22 | CategoryID, CategoryName, UnitsSold, ItemGrossValue, OrderCount |
| [result_23.csv](result_23.csv) | 10 | UserID, EligibleOrders, SalesValue, FirstEligibleOrderDate, LastEligibleOrderDate |
| [result_24.csv](result_24.csv) | 56 | UserID, EligibleOrders, SalesValue |
| [result_25.csv](result_25.csv) | 1 | PurchasingCustomers, RepeatCustomers, RepeatCustomerPct |
| [result_26.csv](result_26.csv) | 4 | UserID |
| [result_27.csv](result_27.csv) | 60 | PaymentYear, PaymentMonth, CompletedPayments, CompletedPaymentAmount |
| [result_28.csv](result_28.csv) | 1 | CorrectTotalBilled |
| [result_29.csv](result_29.csv) | 1 | RepeatedTotalAfterItemJoin_DoNotUse |
| [result_30.csv](result_30.csv) | 1 | ItemGrossFromLines |
| [result_31.csv](result_31.csv) | 1 | ItemGrossFromOrders |

`result_15.csv`: KPI t?ng; `result_17.csv`: th?ng; `result_18.csv`: qu?; `result_20.csv`: top s?n ph?m theo gi? tr?; `result_23.csv`: top kh?ch h?ng.

`result_29.csv` c? ? minh h?a t?ng ti?n b? l?p khi JOIN sai; kh?ng d?ng n? l?m KPI. `result_08.csv` c? 0 d?ng l? k?t qu? ki?m tra kh?ng ph?t hi?n ??n l?ch t?ng h?ng/thu?.
