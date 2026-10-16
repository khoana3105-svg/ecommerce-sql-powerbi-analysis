# Định nghĩa trước khi tính / Metric definitions

## Phạm vi

Population: đơn paid/shipped/delivered có payment completed. Toàn mẫu đặt đơn trong 2021–2025; trong dashboard áp dụng cùng filter ngày từ DimDate. Một dòng FactOrders là một đơn; một dòng FactOrderItems là một dòng hàng thuộc tập đơn đó.

| Metric | Công thức và grain | Không được hiểu là |
|---|---|---|
| Orders | COUNTROWS(FactOrders), OrderID duy nhất | Số dòng hàng hoặc tất cả 360 đơn nguồn |
| Sales Value | SUM(subtotal − order discount), cấp đơn | Lợi nhuận hoặc doanh thu kế toán đã đối soát |
| Total Billed | SUM(orders.total), cấp đơn | Sales Value trước thuế/ship |
| AOV | Sales Value / Orders cùng filter | Trung bình của AOV từng tháng |
| Purchasing Customers | DISTINCTCOUNT(UserID) trong FactOrders | Toàn bộ 70 tài khoản |
| Repeat Customers | Số khách có >=2 đơn đủ điều kiện cùng filter | Khách có thể sẽ quay lại trong tương lai |
| Repeat Customer % | Repeat Customers / Purchasing Customers | Retention/cohort rate |
| Item Gross Value | SUM(quantity × unit_price) trên item đủ điều kiện | Doanh thu sản phẩm đã phân bổ giảm giá/hoàn tiền |
| Item Orders | DISTINCTCOUNT(OrderID) trên item đã lọc | Orders toàn tập khi có đơn không có dòng hàng |

Chưa biết đơn vị tiền nên dùng số và nhãn “source currency units”. Ngày không có timezone trong dump nên không đổi timezone. Không có cost/COGS và không có chính sách phân bổ partial refunds, vì vậy không tính gross/net profit, margin hoặc return rate suy đoán.

## JOIN và filter

`orders → order_items` là 1:n. SUM(orders.total) sau JOIN item sẽ lặp tổng tiền đơn. File SQL có cả ví dụ sai được đặt tên rõ và kết quả đúng để đối chiếu; không dùng DISTINCT để che lỗi.

`payments.order_id` UNIQUE là đặc điểm schema của dữ liệu này; khi thay nguồn, phải kiểm tra lại. Tài khoản chưa có đơn đủ điều kiện không đồng nghĩa chưa từng đặt hàng.

## English

All order-level measures use the eligible order population and order-date filter. Item measures use only matching item rows. Recompute ratios from numerator/denominator in the current filter context; do not average period ratios. Do not sum order totals after a one-to-many item join. Preserve unspecified currency and timezone, synthetic-data status and unresolved partial-refund/cost definitions.
