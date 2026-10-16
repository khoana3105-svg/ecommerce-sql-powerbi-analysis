# Cách mình học và đọc bài này

Mình dùng dữ liệu giả lập để luyện SQL cơ bản và học thêm Power BI. Mục tiêu là hiểu cách nối bảng và tính chỉ tiêu đúng, sau đó mới đưa lên dashboard.

## Thứ tự đọc

1. Đọc README để biết quy tắc chọn đơn và phân biệt giá trị bán, tổng thanh toán, giá trị dòng hàng.
2. Chạy file 01 theo hướng dẫn để tạo database riêng. Mở file 02 và học lần lượt `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `JOIN`.
3. Chọn một đơn có nhiều dòng hàng, xem vì sao cộng lại tiền đơn sau JOIN có thể làm kết quả bị nhân lên.
4. Đối chiếu 250 đơn hợp lệ và SalesValue 61.041,13 trên toàn bộ dữ liệu. Nếu khác, kiểm tra bộ lọc trước khi sửa công thức.
5. Làm theo `powerbi/BUILD_GUIDE.md`: nhập dữ liệu, tạo quan hệ, thêm từng measure và dựng hai trang báo cáo.
6. Kiểm tra KPI khi chưa lọc và khi có bộ lọc, rồi lưu PBIX và ảnh dashboard thực tế.

## Phạm vi hỗ trợ và trạng thái

- Mình cung cấp dữ liệu, bài thực hành và hướng làm. Mình đang học các câu SQL cơ bản trong bài.
- AI hỗ trợ hoàn thiện bản portfolio, mô hình dữ liệu Power BI, DAX, script xuất dữ liệu và đối chiếu tự động.
- SQL và các bảng đầu vào đã có kết quả kiểm tra trong `VALIDATION.md`. Điều này không có nghĩa mình đã tự thực hiện mọi phần.
- Chưa có PBIX hoàn chỉnh; DAX và thao tác lọc còn cần kiểm tra trong Power BI Desktop.
- Chỉ mô tả phần mình đã chạy và giải thích được khi đưa lên CV. Dữ liệu giả lập không thể dùng để tuyên bố tác động kinh doanh thực tế.

## English

This is a beginner SQL project with a Power BI learning extension. The author supplies the dataset, existing exercise and direction. AI assists with the data model, DAX, exports and automated validation. SQL evidence is available, but the Power BI report is unfinished and its measures still require Desktop validation. Personal CV claims should reflect queries the author can rerun and explain.
