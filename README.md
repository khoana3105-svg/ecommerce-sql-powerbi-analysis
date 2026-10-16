# E-commerce Sales Analysis — SQL Server & Power BI

**Nguyễn Anh Khoa · SQL Server / SSMS · SQL cơ bản · Chuẩn bị Power BI**

Mình làm bài này để luyện SQL trên database bán hàng có nhiều bảng. Mình muốn biết có bao nhiêu đơn hợp lệ, giá trị bán là bao nhiêu và sản phẩm nào được mua nhiều. Sau phần SQL, mình dùng dữ liệu đã chuẩn bị để học dựng dashboard bằng Power BI.

**Dữ liệu giả lập**, không phải hoạt động một doanh nghiệp thật. Bản portfolio được hoàn thiện với hỗ trợ AI từ dữ liệu và bài thực hành mình cung cấp. Notebook Kaggle chỉ là tham khảo cách tổ chức; kết quả và data khác. [English version](README.en.md).

## Phần mình học và phần được hỗ trợ

Mình đang học SQL cơ bản, tập trung vào `SELECT`, `WHERE`, `GROUP BY`, `HAVING` và cách nối bảng bằng `JOIN`. Mình dùng các câu hỏi trong bài để tập đọc kết quả và giải thích vì sao tổng tiền có thể bị nhân lên khi nối sai bảng.

AI hỗ trợ phần ngoài kiến thức cơ bản: chuẩn bị mô hình dữ liệu cho Power BI, DAX, script xuất dữ liệu và kiểm tra tự động. Các file này là tài liệu để mình học và làm tiếp. Hiện chưa có dashboard Power BI hoàn chỉnh. Xem [hướng dẫn đọc bài](docs/LEARNING_AND_CONTRIBUTIONS.md).

## Mình muốn trả lời gì?

1. Tập đơn đủ điều kiện có bao nhiêu đơn, bao nhiêu khách và giá trị bán bao nhiêu?
2. Tổng tháng/quý có khớp tổng toàn kỳ không?
3. Sản phẩm/danh mục nào đóng góp nhiều theo số lượng hoặc giá trị hàng?
4. Khách có đơn mua lặp chiếm bao nhiêu trong khoảng dữ liệu đang chọn?
5. Vì sao JOIN dòng hàng có thể làm tổng tiền đơn bị nhân lên?

## Nguồn và grain

File người dùng cung cấp: `data/source/ecommerce-sample-database-v1-sql-mssql.sql`. Header ghi synthetic sample data, seed `flagship:ecommerce-sample-database:1k`, CC0-1.0; thông tin quyền này được ghi nhận từ file, chưa xác minh nhà xuất bản.

Có 31 bảng, 360 đơn, 1.000 dòng hàng, 400 sản phẩm và 70 tài khoản. Đơn vị tiền chưa được xác nhận; không tự gắn USD hoặc VND. Thời gian đặt đơn trong mẫu nằm ở 2021–2025, không phải dữ liệu vận hành đang cập nhật.

`orders` là cấp đơn; `order_items` là cấp dòng hàng. `payments.order_id` là UNIQUE trong nguồn này, nên JOIN payment không nhân đơn. Không mang giả định đó sang database khác mà không kiểm tra.

## Định nghĩa và kết quả đối chiếu

Đơn đủ điều kiện: status paid/shipped/delivered **và** payment completed. Đây là quy tắc phân tích đã chọn, không phải chính sách ghi nhận doanh thu kế toán.

| Chỉ tiêu | Kết quả chưa lọc |
|---|---:|
| Đơn đủ điều kiện | 250 |
| Khách có đơn đủ điều kiện | 66 |
| SalesValue: subtotal − discount | 61.041,13 |
| TotalBilled: gồm thuế và ship | 70.317,71 |
| ItemGrossValue: trước giảm giá cấp đơn | 61.632,94 |
| Giá trị bán trung bình/đơn | 244,16452 |
| Khách có ít nhất 2 đơn đủ điều kiện | 56 |

Giữ riêng các chỉ tiêu vì chúng có định nghĩa khác nhau. Chưa trừ hoàn tiền từng phần, chưa có cost/COGS nên không tính lợi nhuận. Không gọi tất cả tài khoản là khách đã mua.

## File cần mở

- [sql/01_tao_va_nap.sql](sql/01_tao_va_nap.sql): tạo database **EcommerceSalesPortfolio** và nạp mẫu, chặn nạp trùng.
- [sql/02_thuc_hanh.sql](sql/02_thuc_hanh.sql): 18 mục thực hành SELECT/WHERE/CASE/GROUP BY/HAVING/JOIN, view và đối chiếu.
- [sql/03_powerbi_views.sql](sql/03_powerbi_views.sql): tách bảng fact/dimension đúng grain.
- [docs/METRIC_DEFINITIONS.md](docs/METRIC_DEFINITIONS.md): định nghĩa và giới hạn.
- [powerbi/BUILD_GUIDE.md](powerbi/BUILD_GUIDE.md): hướng dẫn dựng report và kiểm tra filter.
- [powerbi/measures.dax](powerbi/measures.dax): measure; [columns.dax](powerbi/columns.dax): nhãn sản phẩm có ID.
- [powerbi/validation.json](powerbi/validation.json): mốc KPI để đối chiếu trong Power BI.
- [docs/VALIDATION.md](docs/VALIDATION.md): trạng thái kiểm tra.

## Chạy trong SSMS

1. Kết nối SQL Server 2017+ bằng tài khoản của bạn.
2. Chạy toàn bộ file 01 trên database portfolio riêng, không chạy thêm file dump gốc. Nếu database đã có bảng, dừng và dùng dữ liệu đã nạp; không tự xóa bảng.
3. Chạy file 02, xem các kết quả EDA, JOIN và KPI.
4. Chạy file 03. Dựng Power BI từ view hoặc các CSV đã xuất tại `powerbi/data/`.

Script này dùng INSERT trực tiếp, không yêu cầu BULK INSERT hoặc Python để làm SQL trong SSMS. Python chỉ phục vụ đối chiếu và chuẩn bị CSV ngày.

## Power BI: phần đã có và phần cần tự dựng

Đã chuẩn bị **FactOrders, FactOrderItems, DimProducts, DimCustomers, DimDate**, quan hệ một chiều, DAX và hướng dẫn hai trang. Bảng đầu vào được xuất từ SQL Server và đối chiếu tổng.

Đã có ảnh dashboard

Không trộn SalesValue cấp đơn vào dòng hàng. Category/product filter áp dụng cho chỉ tiêu cấp item; hướng dẫn giải thích vì sao nó không tự lọc ngược tiền cấp đơn.

## Những vấn đề dữ liệu mình ghi nhận

108 đơn có ngày trước ngày tạo tài khoản; 56 đơn cancelled/refunded có payment completed; 22 đơn không có dòng hàng, trong đó 15 đơn thuộc tập phân tích. Mình giữ nguồn và định nghĩa rõ phạm vi, không tự sửa để làm số liệu đẹp. Không dùng các ngày tài khoản này cho cohort/retention đáng tin cậy.

## Đưa lên GitHub

Giữ cấu trúc root, sql/, src/, docs/, data/source/, powerbi/ và các output đối chiếu được rà soát. Không upload credentials hay môi trường Python. Các file nguồn có nhãn synthetic; không trình bày tên/email giả lập như khách hàng thật. Xem [upload và CV](docs/UPLOAD_AND_CV.md).
