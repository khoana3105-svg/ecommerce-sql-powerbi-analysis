# Dựng dashboard Power BI / Build the Power BI report

## 1. Mình muốn dashboard trả lời gì?

Mình xem **giá trị bán hàng theo đơn đủ điều kiện**, diễn biến theo thời gian, khách mua lặp và sản phẩm đóng góp nhiều theo giá trị hàng. Dữ liệu là giả lập, nên dashboard minh họa cách đo và kiểm tra; không đề xuất quyết định cho doanh nghiệp thật.

**Đầu ra đã chuẩn bị:** 5 CSV, measure DAX, mô hình quan hệ và mốc đối chiếu. **Chưa tạo hoặc chạy file `.pbix`**. Làm xong các bước dưới đây rồi lưu report của bạn và chụp ảnh dashboard để bổ sung GitHub.

## 2. Nhập 5 bảng

Power BI Desktop → **Get data → Text/CSV**, chọn từng file trong `powerbi/data/`:

| Table | Grain / khóa | Kiểu dữ liệu quan trọng |
|---|---|---|
| `FactOrders` | Một đơn đủ điều kiện; `OrderID` duy nhất | IDs: Whole number; OrderDate: Date; các trường giá trị: Fixed decimal number |
| `FactOrderItems` | Một dòng hàng; `OrderItemID` duy nhất | IDs/Quantity: Whole number; UnitPrice/ItemGrossValue: Fixed decimal number |
| `DimProducts` | Một sản phẩm; `ProductID` duy nhất | IDs: Whole number; tên: Text |
| `DimCustomers` | Một tài khoản; `UserID` duy nhất | UserID: Whole number |
| `DimDate` | Một ngày; `Date` duy nhất | Date: Date; Year/Quarter/MonthNumber/YearMonthSort: Whole number; YearMonth: Text |

Chọn **Transform Data** và kiểm tra kiểu trước khi Close & Apply. CSV dùng ngày `yyyy-MM-dd` và dấu chấm thập phân; nếu tự nhận dạng sai, dùng **Change Type → Using Locale → English (United States)** cho bước chuyển kiểu. Đổi tên query đúng tên trong bảng, không để đuôi `.csv`.

Không import `monthly_expected.csv` rồi cộng tiếp cùng `FactOrders`: đó là tổng hợp đối chiếu, không phải fact bổ sung. Không làm phẳng hai fact thành một bảng để cộng `SalesValue`.

## 3. Tạo quan hệ một chiều

Trong Model view, đặt đúng **one-to-many, single direction**, từ phía `1` sang phía `*`:

```text
DimDate[Date]          1 → * FactOrders[OrderDate]
DimCustomers[UserID]   1 → * FactOrders[UserID]
FactOrders[OrderID]    1 → * FactOrderItems[OrderID]
DimProducts[ProductID] 1 → * FactOrderItems[ProductID]
```

Đây là mô hình hai grain, không phải một flat table. Chọn `DimDate` làm Date table bằng cột Date. Chọn `DimDate[YearMonth]`, dùng **Sort by column → YearMonthSort** để tháng xếp đúng.

**Điểm dễ sai:** filter sản phẩm/danh mục chỉ đi tới `FactOrderItems`, không lọc ngược lên `FactOrders`. Không bật bidirectional để làm card nhìn như khớp. Nếu lọc sản phẩm mà vẫn muốn tính tiền đơn, cần định nghĩa cách phân bổ giảm giá/đơn nhiều sản phẩm — chưa có trong project này.

## 4. Tạo measure

Home/Modeling → **New measure**, thêm từng công thức trong `measures.dax`. Các công thức là định nghĩa riêng, không dán toàn file vào cùng một measure.

Trong `DimProducts`, thêm **New column** theo `columns.dax` để tạo `ProductLabel` gồm mã và tên. Có 10 tên sản phẩm gắn với nhiều ProductID trong dữ liệu; dùng mỗi ProductName sẽ gộp chúng. Dùng ProductLabel làm trục xếp hạng sản phẩm.

- Sales Value = subtotal − order discount, trước thuế/ship, chưa xử lý hoàn tiền từng phần.
- Total Billed = tổng đơn gồm thuế/ship; không thay thế Sales Value.
- Item Gross Value = quantity × unit price tại lúc đặt hàng, trước giảm giá cấp đơn.
- Repeat Customer % = khách có ít nhất 2 đơn trong bộ lọc hiện tại / khách có đơn trong cùng bộ lọc; không phải retention rate hoặc cohort.

Format Repeat Customer % là Percentage; giá trị tiền là số có 2 chữ số thập phân, **không gắn USD/VND** vì nguồn chưa xác nhận tiền tệ. Không nhân thêm 100 vào measure tỷ lệ.

## 5. Trang 1 — Tổng quan đơn hàng / Order overview

- Slicer: `DimDate[Year]`, khoảng ngày; dùng DimDate cho toàn bộ lọc thời gian.
- Cards: Orders, Sales Value, Average Order Value, Purchasing Customers.
- Line chart: YearMonth → Sales Value; tooltip có Orders, Average Order Value.
- Column chart: YearMonth → Orders, để đọc giá trị bán cùng số đơn thay vì chỉ nhìn tổng tiền.
- Table: UserID, Orders, Sales Value; chỉ hiển thị khách có đơn, có thể Top N theo Sales Value.
- Card bổ sung: Repeat Customer %, kèm chú thích “trong khoảng ngày đang chọn”.

Không đặt category/product slicer ở trang này vì nó không lọc các measure cấp đơn qua quan hệ một chiều.

## 6. Trang 2 — Sản phẩm / Product mix

- Slicer: năm và category (`DimProducts[CategoryName]`).
- Bar chart: ProductLabel → Item Gross Value, Top 10 trong filter hiện tại.
- Bar chart: CategoryName → Item Gross Value; không gọi là Sales Value sau chiết khấu.
- Cards: Item Gross Value, Units Sold, Item Orders (chỉ đơn có dòng hàng khớp filter).
- Table: ProductID, ProductName, CategoryName, Units Sold, Item Gross Value.

Không dùng Sales Value/Orders từ FactOrders như card chịu category filter. Giữ label và grain rõ ràng. Có 15 đơn đủ điều kiện không có dòng hàng; chúng vẫn ở trang cấp đơn, không xuất hiện ở bảng item. Vì các đơn đó có giá trị hàng bằng 0 trong snapshot, đối chiếu tổng hàng vẫn khớp, nhưng số đơn hai phía không bằng nhau.

## 7. Đối chiếu trước khi chụp ảnh

Bỏ mọi filter rồi đối chiếu `validation.json`:

| Measure | Mong đợi |
|---|---:|
| Orders | 250 |
| Sales Value | 61,041.13 |
| Total Billed | 70,317.71 |
| Average Order Value | 244.16452 (hiển thị 244.16) |
| Purchasing Customers | 66 |
| Repeat Customers | 56 |
| Repeat Customer % | 84.84848…% |
| Item Gross Value | 61,632.94 |

Đối chiếu một năm, một tháng và một category với SQL; sau mỗi phép thử bỏ filter để về baseline. Kiểm tra category chỉ thay measure cấp item như đã thiết kế. Không chụp ảnh hoặc ghi kết quả Power BI “đã pass” trước khi tự đối chiếu trong Power BI Desktop.

## 8. Lưu và đưa lên GitHub

Lưu `Ecommerce_Sales_Analysis.pbix` trên máy. Để có minh chứng nhẹ, xuất/chụp `overview.png` và `product_mix.png` vào `powerbi/screenshots/`; chưa có ảnh dựng Power BI trong bản chuẩn bị này. Khi muốn chia sẻ PBIX, kiểm tra dữ liệu và đường dẫn nguồn trước, đồng thời bỏ quy tắc ignore `*.pbix` có chủ đích.

CSV là snapshot được xuất từ SQL Server, không phải kết nối live. Khi dữ liệu thay đổi, chạy lại export, validate CSV rồi Refresh report. Có thể dùng **Get Data → SQL Server → Import** để đọc trực tiếp các view `dbo.bi_*`; vẫn cần cùng mô hình và measure.

## English handoff

Import the five CSV tables, apply the exact types, create the four single-direction relationships, mark DimDate as the date table and sort YearMonth by YearMonthSort. Create each measure separately. Build one order-level overview and one item-level product page. Do not use product/category filters to imply filtered order revenue: discounts are not allocated to items and the model intentionally does not back-filter FactOrders. Validate unfiltered totals and several filtered slices before saving screenshots/PBIX. Currency is unspecified; records are synthetic. No PBIX or executed Power BI validation is claimed by this package.

References: [Microsoft — Power BI data sources](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-data-sources), [star schema guidance](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema), [relationship guidance](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-relationships-understand).
