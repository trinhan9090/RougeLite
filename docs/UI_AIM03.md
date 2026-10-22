# Native1080p và điều hướng sau đòn đánh

Mở lại `D:\SelfProject\RougeLite\Launch.cmd` sau khi đóng phiên đang chơi. Project render gốc1920×1080, cửa sổ mặc định1920×1080 và mở fullscreen. Không còn render640×360 rồi phóng nguyên khung. HUD/menu dùng tọa độ native1:1; mở modal,20 ô nhân vật và resize cửa sổ đều theo viewport thực tế. SETTING vẫn có nút đổi fullscreen/windowed.

Pixel art nguồn giữ nguyên; camera thế giới zoom2 để nhân vật có kích thước trên màn hình gần bản trước. Đây là camera trên viewport1080p, không phải tăng độ chi tiết PNG. Nới góc nhìn không nới phạm vi đánh. Phép kiểm tra quái ngoài màn hình đổi sang kích thước world viewport/camera.zoom; bán kính an toàn550 và mọi thông số sinh quái giữ nguyên.

MANUAL/AUTO: vòng tròn hitbox màu xanh dẹt trên mặt đất dưới chân, vẽ sau sprite, luôn hiển thị khi nhân vật còn sống. Bán kính lấy từ collider thân nhân vật; kẻ địch chạm vòng này có thể gây sát thương. Không còn con trỏ/mũi tên mặt đất. Hướng chiêu Manual lấy từ đòn đánh được chấp nhận gần nhất; di chuyển/WASD và chuột không xoay hướng. Đòn/chiêu bị từ chối không thay đổi hướng. Khi chưa tấn công, mặc định sang phải. Áp dụng chung cả6 nhân vật.

Ngoại lệ nhắm mục tiêu hiện hữu giữ nguyên: Astra L vẫn ưu tiên quái gần nhất trong tầm; nếu trống, Manual đặt ở rìa tầm theo hướng đánh gần nhất, Auto theo hướng di chuyển. Chiêu đặt vùng/buff không bị biến thành đạn.

Kiểm thử và giới hạn: xem WORK_LOG và ADR-2026-007. GUI test xác nhận fullscreen thật và texture render1920×1080 trên RTX3050 Compatibility, không xuất ảnh/video. Không tuyên bố texture sprite thành art HD hoặc đạt60FPS stress. Chất lượng và cảm giác điều hướng chờ người dùng thử trực tiếp.
