# Atyu — bản chơi riêng, nhân vật thứ tư

Mở `D:\SelfProject\RougeLite\Launch.cmd`, vào CHARACTER. Có20 ô: Astra, Vex, Boros, Atyu và16 ô `?` bị khóa. Bấm avatar xem chi tiết; bấm SELECT để chọn rồi PLAY. Di chuột lên thông tin chiêu để xem bảng chỉ số từng hạng. Không cần tự import hay xử lý asset.

Giữ WASD, đánh thường tự tìm quái gần nhất, Auto/Manual và phím có thể đổi. Manual dùng hướng tấn công gần nhất; WASD không xoay điều hướng. Art Atyu nhìn ngang, lật trái/phải; khi đi thẳng lên/xuống giữ phía ngang vừa nhìn. Không có model xương hoặc hình mới phía bắc/nam. Không thêm chuỗi phím combo đối kháng.

## Bộ chiêu chuyển thể

| Đòn | Nguồn cụ thể | Hành vi trong game / DEMO DEFAULT |
|---|---|---|
| Đánh thường | AIR200,210,211; CNS basic anim theo state/form |22 physical,0.85s,110px; luân phiên ba tư thế, mỗi lần vẫn một đòn tự động |
| J — Kiếm trảm | AIR210, chuỗi chém kiếm nguồn | Chém nhiều mục tiêu hình quạt85°, trễ0.15s; CD5.5s; damage55/68/82/98, bán kính140/155/170/185 |
| K — Chú ngôn: Trói buộc | Tư thế AIR900; trạng thái khống chế Vizard661502 / AIR2044 trống; vòng nguồn AIR661502 là mặt nạ tròn | CD11s,240px; trói1.4/1.6/1.8/2s,0damage. Vẽ lại vòng ấn cho rõ trạng thái. Boss vẫn stagger0.15s, khóa lặp4s. Manual chọn quái trong quạt hướng tấn công gần nhất, không tự quay ra sau |
| L — Linh thể hộ chiến | Vizard188100 AIR2001 → helper930 AIR10190; đòn helper940 AIR10230 | CD16s, tồn tại8/9/10/11s; strike mỗi1.2s sau xuất hiện0.4s; damage24/30/36/44, tìm quái trong240/260/280/300px tính từ chủ. Một linh thể/chủ; tự hết hạn, hủy khi chủ chết/chuyển map |
| I — Quang chú hợp kích | AIR1406→1401 (Especiales1434→1435), texture năng lượng AIR8067 | CD24s, trễ0.4s,420px; damage160/205/255, bề rộng34/40/46; +25% damage khi linh thể còn tồn tại lúc phóng. Bắn từ thân/tay; không có projectile Split |

Đây là chuyển thể để gần bộ Atyu bạn yêu cầu, không chạy nguyên state machine MUGEN. Không mô phỏng các đòn Domain, siêu dừng toàn màn hình, tung hứng hay hàng trăm hit từ bản đối kháng. K mượn tư thế và ý tưởng control của nguồn; không khẳng định nguồn có nguyên chiêu Chú ngôn tương đương. I tái sử dụng chất liệu năng lượng, xoay/cắt vùng trong suốt và đặt theo hình học tia của game. Không khẳng định ghép helper/CNS đầy đủ hoặc giống từng pixel MUGEN.

Tất cả số mới là giá trị thử nghiệm, không phải thông số cân bằng đã được bạn duyệt. Mốc mở3/6/9/11, tối đa4/4/4/3 giữ nguyên. L dùng strike định kỳ cùng resolver/context/budget, không phải một phe Actor mới, không chặn đường và không bị quái chọn làm mục tiêu.

## Tích hợp và giới hạn

- Cùng ActorSprite, controller, DamageResolver, upgrade engine và kiểm tra eligibility. J/I nhận Area Expand thật; các hiệu ứng trúng đòn vẫn theo root budget. Không quảng cáo Split/Echo chưa được executor hỗ trợ.
-50 frame nhân vật nguồn, canvas256, chân cố định(128,192), kích thước idle55px gần các hero hiện tại48–53px. Không thay đổi collider hoặc stat của ba hero cũ. Nền xanh của helper được loại bằng quy tắc màu ghi trong generator; chi tiết xanh có thể cần người dùng kiểm tra trực tiếp.
- Sprite gốc giữ nguyên. Sinh asset bằng `tools/mugen_import/build_playable.py`, bảng rank bằng `author_loadout.py`; dữ liệu đầu vào từ decoder/browser P1–P2. Pillow12.3/Python3.12 đã có sẵn. Không nhập âm thanh/nhạc MUGEN.
- Asset mod và PNG dẫn xuất chưa có giấy phép phân phối được xác minh: chỉ dùng thử cục bộ. Không phát hành công khai hoặc đóng gói lại như asset nguyên bản. PNG dẫn xuất nằm ngoài Git; cần nguồn cục bộ và generator để tái tạo trên máy khác. Bản ZIP Fix03 cũ giữ nguyên, vẫn chỉ có ba hero.
- Không xuất screenshot/video/contact sheet theo yêu cầu mới nhất. Chất lượng mỹ thuật chờ bạn chơi thử; không tự đánh dấu đạt chất lượng concept.

## Kiểm thử

Các lệnh chạy Godot4.7.2 dùng APPDATA riêng `.local-data`. Log nằm trong `docs/atyu_audit/p3_*.log`; kết quả cuối cùng và triển khai ghi tại WORK_LOG. Các lỗi đầu tiên đã được sửa: null metadata gây log lỗi, fixture Actor không tự tiến status clock, beam fixture thiếu torso, và giữ phía ngang khi đi dọc. Không coi những lần chạy lỗi là thành công.

Thử trực tiếp: chọn Atyu, đi8 hướng, đổi Auto/Manual, lên3/6/9/11, thử J trước/sau lưng, K lên quái/boss, L hết hạn và gọi lại, I lúc có/không linh thể. Thử quay về menu, chọn một trong ba hero cũ để đối chiếu.
