# Kiểm tra thiết kế và nguồn Atyu — 17/10/2026

> Cập nhật tiếp theo: P1–P2 đã có decoder và browser riêng; xem `ATYU_BROWSER.md`. Nội dung dưới đây là kết quả P0 trước giải mã. Atyu vẫn chưa tích hợp vào PLAY.

Phạm vi: kiểm tra tài liệu, file nguồn và khả năng tích hợp. **Chưa giải mã SFF, chưa xác minh hình ảnh bên trong, chưa thêm Atyu vào PLAY.** Không xuất ảnh/video. Astra/Vex/Boros và bản Launch Fix03 được giữ nguyên.

## Đã đọc và kiểm tra

- `assets/characters/atyu/ATYU_CHARACTER_AND_IMPORT_SPEC.md` và nội dung văn bản DOCX cùng tên. DOCX chứa cùng các mục thiết kế/phạm vi POC; chưa kiểm tra bố cục trình bày.
- Thư mục `Yuta Manga v1`:24 file, gồm bản nguồn chính và backup. Inventory lưu kích thước/SHA-256 từng file trong `docs/atyu_audit/inventory.json`.
- DEF chính ghi `Yuta By MM`, tác giả `Mugen Matias`, nhưng trỏ tới `Ichigo_Bankai.*`.12 tham chiếu ở mục Files đều tồn tại.
- SFF chính:102.417.227 byte; chữ ký `ElecbyteSpr`, bốn byte phiên bản `[0,0,0,2]`. Đây là dữ liệu sprite cần decoder, không phải PNG dùng ngay trong Godot.
- AIR:684 khai báo,679 ID khác nhau,4.916 dòng khung. Các ID trùng:1460,3011,3013,7400,99050; mỗi ID xuất hiện hai lần. Số dòng khung không đồng nghĩa số hình độc lập.
- CNS:432 khối Statedef trong các file được kiểm kê; đây không phải số state ID duy nhất. Chỉ đọc `anim` ở phần đầu Statedef; không nhầm `anim` của controller/helper thành animation chính.
- Có năm palette ACT ngoài archive; DEF ghi mặc định1–6. Chưa kết luận thiếu palette6 vì palette nội bộ SFF chưa được giải mã.

## Liên kết nguồn đã xác minh bằng văn bản

| Nguồn/state | Animation khai báo | Kết luận hiện tại |
|---|---|---|
| Basic200,210–213 | `ID + var(11)` | Phải theo trạng thái biến, chưa được gán cứng một action |
| Especiales1150 | 1150 | Có action AIR tương ứng; hình slash chưa xác minh |
| Especiales1434 | 1406 | Có action; chưa xác minh đây là linh thể mong muốn |
| Ichigo_Bankai930 | 10190 | Có action; tên helper không chứng minh nội dung hình |
| Vizard188100 | 2001 | Có action; chưa xác minh hình |
| Especiales10450 | 8067 | Có action; ứng viên beam |
| Vizard10450 | 9999 | Cùng state ID nhưng khác file/animation; cần giữ ngữ cảnh và thứ tự nạp |
| Vizard81045 | 8065 | Có action; ứng viên beam khác |
| Vizard661502 | 2044 | Có action; không chứng minh có hiệu ứng lời nguyền bằng giọng nói |

`MOVESET.txt` mô tả Getsuga, Zangetsu và Hollow Mask, nên không dùng làm bộ kỹ năng Atyu. Credits ghi nhiều người đóng góp nhưng không kèm giấy phép tái sử dụng được xác minh trong gói. Chưa đưa nguồn này vào bản phát hành.

## Đối chiếu thiết kế với game

Bộ chiêu đề xuất rõ: basic kiếm; J chém quạt; K sóng trói chân; L triệu hồi linh thể; I beam được linh thể hỗ trợ. Mốc mở3/6/9/11 và rank4/4/4/3 phù hợp khung hiện tại.

Các điểm còn thiếu hoặc xung đột:

1. **K với boss:** tài liệu đề xuất root0,6 giây; `scripts/actors/status_controller.gd` hiện chuyển root/stun boss thành stagger0,15 giây, khóa4 giây. Chưa thay chính sách chung; cần chốt cách áp dụng trước triển khai phần này.
2. **Thông số:** chưa có đầy đủ HP/giáp/tốc chạy/chí mạng của Atyu, bảng giá trị từng rank, sát thương linh thể, tầm đánh/tìm mục tiêu, mức tăng cường I khi L hoạt động và quy tắc triệu hồi lại.
3. **Executor:** hệ thống có projectile/area/beam/shield/dash/status/buff; chưa có adapter cone/summon tương ứng toàn bộ thiết kế. Basic melee hiện đánh một mục tiêu; area là vùng tròn, không tự biến thành quạt85 độ. Cần cơ chế dùng chung, không thêm nhánh tên Atyu trong augment engine.
4. **Wind-up:** I yêu cầu0,4 giây; cần xác định snapshot hướng/mục tiêu, hủy khi chết/stun và lúc bắt đầu cooldown. Không lấy timing MUGEN để tự đổi gameplay.
5. **Tên kiến trúc:** tài liệu nhắc CombatEvent/SkillInstance; code thực tế dùng CombatContext/CastIntent/SkillRuntime. Khi triển khai phải ánh xạ theo code hiện tại.
6. **Góc nhìn:** tài liệu tự xác định nguồn chủ yếu nhìn ngang; chưa chứng minh có bộ N/S. Lật trái/phải không tạo góc nhìn từ sau. Trước hết nên kiểm tra bằng browser trong game; chỉ sau giải mã mới biết animation nào thực sự dùng được.
7. **Augment:** tag SUMMON/CONE/ECHOABLE trong thiết kế chưa phải capability runtime được xác minh. Cần khai báo đúng theo executor, ownership, lifecycle và ngân sách sự kiện khi bổ sung.

## Kết quả và bước tiếp theo

**Kiểm tra cấu trúc: đạt. Khả năng chuyển hình/animation: chưa xác minh. Atyu chơi được: chưa triển khai.**

Bước kế tiếp hợp lý là P1: decoder SFF có kiểm chứng và parser AIR đầy đủ, giữ offset/timing/palette/linked sprites, sau đó P2 browser để người dùng xem trực tiếp. Không cần xuất contact sheet/video theo yêu cầu mới. Thử nghiệm riêng trước; chưa sửa bộ ba nhân vật hiện tại.

Kiểm tra đã chạy: Godot `--version` trả4.7.2; utility kiểm kê xác minh chữ ký SFF, DEF dependencies, action/state parsing và hash nguồn. Không chạy lại kiểm thử gameplay vì không sửa runtime; không tuyên bố Atyu đã import hoặc chạy được. Utility này chỉ là kiểm kê cấu trúc, chưa phải bộ chuyển MUGEN hoàn chỉnh và không giải biểu thức/Helper/Explod động.

Lệnh tái lập: `python -X utf8 tools/mugen_import/inspect_local.py --source "D:/SelfProject/RougeLite/assets/characters/atyu/Yuta Manga v1" --out docs/atyu_audit`.
