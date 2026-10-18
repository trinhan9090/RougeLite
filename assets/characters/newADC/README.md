# GRAVESHADE — Tactical Suppressor | ADC M.U.G.E.N → Godot v1.0

## Nhiệm vụ
Thêm nhân vật ADC nguyên bản **Graveshade** (tên tạm), lấy cảm hứng từ phong cách lính đánh thuê/tác chiến đô thị của Punisher. Ưu tiên asset trong `marvel P.rar` cho thử nghiệm riêng tư, không mặc định có quyền tái phân phối. **Không xuất screenshot, contact sheet, ảnh hoặc video nghiệm thu cho người dùng.** Chỉ chạy game và kiểm thử tại chỗ; ghi báo cáo văn bản, log, test case và file thay đổi. Những công cụ kiểm tra asset có thể dùng output tạm nội bộ nhưng không đưa vào deliverables.

## Thứ tự đọc
1. `01_SOURCE_AUDIT.md` — sự thật nguồn M.U.G.E.N.
2. `02_CHARACTER_GAMEPLAY.md` — bộ chiêu và cấp nâng cấp.
3. `03_VISUAL_AUDIO_IMPORT.md` — sprite, âm thanh và VFX.
4. `04_GODOT_INTEGRATION.md` — kiến trúc và tính tương thích.
5. `05_AUGMENTS.md` — lõi dùng chung và nhánh xung đột.
6. `06_TASKS_AND_TESTS.md` — milestone và nghiệm thu.
7. `AGENTS.md` — quy tắc bắt buộc.
8. `SOURCE_STATE_INVENTORY.csv` — state gốc để điều tra.

## Tiền đề
Dự án Godot đang tồn tại: KHÔNG làm lại project, hệ thống combat, Universal Augment, EXP, boss hay map. Giữ Astra/Vex/Boros/Viridian. Ưu tiên hoàn thiện VFX ba nhân vật gốc trước multiplayer. Đăng ký Graveshade qua character registry, không làm lệch thứ tự ưu tiên đã chốt. Phím WASD, J/K/L/I tùy chỉnh, Auto/Manual, auto basic attack mục tiêu gần nhất trong tầm, mở skill 3/6/9/11, skill J/K/L tối đa rank 4, ultimate rank 3. Chỉ thay visual nếu combat đã có controller chung.

## Confidence taxonomy
`VERIFIED_TEXT`: trực tiếp đọc từ file CMD/CNS/AIR/MOVELIST; `CANDIDATE`: state liên quan từ text nhưng chưa decode hình/âm; `DESIGN`: cơ chế do tài liệu đề xuất; `VISUAL_VERIFIED`: Agent xác nhận sau khi decode và playback. Không biến CANDIDATE thành verified.
