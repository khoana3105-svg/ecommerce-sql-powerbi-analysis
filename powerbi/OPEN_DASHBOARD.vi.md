# Mở bản dashboard đã dựng

1. Đóng bản Power BI cũ nếu đang mở. Giữ nguyên `Ecommerce_Sales_Analysis.pbix` và PBIP gốc.
2. Mở `Ecommerce_Dashboard.pbip` bằng Power BI Desktop. Không mở lại PBIX gốc để xem phần mới.
3. Chọn Home → Refresh. Bản sao có sửa YearMonth thành text và thêm ProductLabel, Product Rank nên cần xử lý lại mô hình.
4. Mở hai tab Sales Overview và Product Analysis. Xóa lựa chọn trong slicer trước khi đối chiếu.
5. Kiểm tra: Orders 250; Sales Value 61,041.13; Purchasing Customers 66; AOV 244.16; Repeat Customer % 84.85%; Item Gross Value 61,632.94; Item Orders 235.
6. Thử chọn một năm và một category. Category chỉ tác động các chỉ tiêu cấp dòng hàng ở trang sản phẩm. Top sản phẩm dựa trên rank <= 10; trường hợp đồng hạng có thể hơn 10 sản phẩm.
7. Sau khi xác nhận biểu đồ hoạt động, Save as → PBIX, tên `Ecommerce_Dashboard.pbix`.

## Phần đã làm và giới hạn

- Bản sao gồm hai trang 1440×900, 24 visual/text box, bố cục KPI, biểu đồ, slicer, bảng chi tiết và ghi chú dữ liệu giả lập.
- Giữ các measure và bốn quan hệ của bản gốc; thêm helper Product Rank có AI hỗ trợ, nhãn sản phẩm và sửa kiểu YearMonth trong bản sao.
- JSON PBIR được kiểm tra với schema công khai Microsoft. Đây không phải kiểm chứng render hoặc DAX engine.
- Chưa xác nhận bằng giao diện Power BI Desktop; không coi screenshot hay PBIX là đã có trước khi mở, Refresh và kiểm tra.
- Không upload thư mục `.pbi` hoặc `schema-cache`. PBIP cần đi cùng cả folder `.Report` và `.SemanticModel`; chỉ upload một file PBIP sẽ không đủ.
- Nguồn CSV đang dùng đường dẫn máy hiện tại. Nếu chuyển máy, sửa Data source settings trước khi Refresh.
