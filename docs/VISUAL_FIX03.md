# Bản sửa đồ họa Fix03 — 17/10/2026

Đã tích hợp vào project đang dùng bởi `Launch.cmd`. Tiêu đề cửa sổ: **Three Heroes Pixel v3 Fix03**. Chất lượng hình ảnh chờ người dùng chơi thử và đánh giá.

## Các thay đổi

- **Đi lên:** sửa lớp áo, khăn, tóc và phần gót chân nhìn từ sau của Vex/Boros; vũ khí nằm sau thân ở hướng Bắc. Giữ nguyên kích thước frame và điểm đặt chân.
- **Kiếm Boros:** khi đứng/chạy, hai tay giữ chuôi, lưỡi kiếm chúc xuống cạnh hông theo lựa chọn người dùng. Giữ động tác riêng cho đánh, đỡ và lao.
- **Lướt Vex:** bụi chỉ tồn tại trong cú lướt thật. Buff tốc đánh dùng dấu hiệu nhỏ riêng ở chân, biến mất khi buff kết thúc. Dọn animation lăn mà không xóa lệnh đánh vừa nhận.
- **Tâm khiên/buff:** Astra/Boros dùng chung mốc tâm thân từ sprite. Tâm hiệu ứng cập nhật theo vị trí và kích thước thật, kể cả Boros biến lớn. Vòng phản hồi khi nhận đòn vào khiên lấy kiểu hiệu ứng của người đỡ và bám tâm thân, thay cho vòng lệch xuống chân.

Không đổi sát thương, thời gian kỹ năng, bảng rank, hitbox, di chuyển, sinh quái hay tiến trình. Trong dữ liệu hiện tại, Tactical Roll của Vex nằm ở K; L vẫn là Piercing Round.

## Kiểm tra đã chạy

- Godot 4.7.2: import thành công; **39/39 bộ kiểm thử hồi quy** qua.
- **95 kiểm tra chuyên biệt** qua trên mã nguồn, project Launch và tài nguyên trong gói Windows.
- **151 kiểm tra tư thế/pixel** và **2.382 kiểm tra frame** qua.
- Gói chạy qua kiểm tra ba nhân vật, ba boss, mở giao diện và kiểm tra ZIP.

Kết quả chi tiết: `reports/visual_qa/v3_fix03/regression.json`, `delivery.json` và các log. Mã nguồn trên branch `fix/roster-north-sword-dash`; bản sao khôi phục được ghi trong `deployment.json`.

## Người dùng kiểm tra trực tiếp

Đóng cửa sổ game cũ rồi mở lại `Launch.cmd`. Kiểm tra đi lên và dừng lại của cả hai nhân vật; tư thế kiếm; Vex trong/sau lướt và lúc buff hết; khiên Astra/Boros khi di chuyển, nhận đòn và Boros biến lớn.

Theo yêu cầu mới, không xuất thêm ảnh/video nghiệm thu; thay đổi và kết quả được ghi trong docs. Asset hình ảnh cần thiết cho game vẫn được cập nhật bình thường. Chi tiết khuôn mặt được giản lược; việc duyệt thẩm mỹ do người dùng thực hiện.
