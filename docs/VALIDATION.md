# Kiểm chứng / Validation

## Đã thực hiện ngày 16/10/2026

- Tạo database **EcommerceSalesPortfolio** từ dump giả lập trong project, tách khỏi `EcommerceBasicPractice` gốc. Không xóa bảng/database cũ hoặc đổi server settings.
- Nạp và đối chiếu số dòng 31 bảng, 36 khóa ngoại được bật/trusted.
- Chạy file 02, xuất 31 result sets; đối chiếu bằng Python Decimal với đáp án độc lập.
- Đối chiếu 60 tháng, 20 quý, KPI tổng, top sản phẩm/khách, phân nhóm mua lặp, trạng thái và ví dụ JOIN gây nhân tiền.
- Chạy file 03 và xuất CSV thực tế từ view cho Power BI: 250 FactOrders, 696 FactOrderItems, 400 DimProducts, 70 DimCustomers; tạo DimDate bằng standard library.
- Kiểm tra khóa, quan hệ fact/dim, tổng tiền dòng hàng so với đơn, PurchasingCustomers=66 và RepeatCustomers=56. Có 10 tên sản phẩm gắn nhiều mã; hướng dẫn dùng ProductLabel kèm mã.

## Minh chứng

- [Kết quả SQL Server](../outputs/sql_server/verification.json)
- [Metadata lần thực thi](../outputs/sql_server/execution.json)
- [CSV và KPI Power BI đối chiếu](../powerbi/validation.json)
- `outputs/historical_sql_server/` giữ minh chứng từ bài gốc; không coi đó là lần chạy mới của database portfolio.

## Chưa thực hiện

Chưa mở Power BI Desktop, chưa tạo/chạy DAX trong engine Power BI, chưa tạo PBIX, chưa kiểm tra slicer/visual hoặc xuất screenshot Power BI. Hướng dẫn và DAX là bản tham khảo để bạn dựng và kiểm tra theo mốc đã chuẩn bị. Không khẳng định dashboard hoàn chỉnh hoặc publish đã tồn tại.

Nguồn dump tự ghi synthetic/CC0; chưa xác minh nguồn xuất bản độc lập. Không suy luận hiệu quả kinh doanh thật. Script Python và SQL không tạo dữ liệu giả thay thế khi không khớp.

## English

Executed and reconciled the dedicated SQL Server 2022 database, source table/FK counts, 31 result sets, independent aggregates and Power BI CSV inputs. Power BI Desktop/DAX execution, PBIX construction, visual/filter QA and publication remain unperformed. CSV checks validate inputs and baseline definitions, not the rendered report. Detailed source hashes and execution times are in the linked receipts.
