# Atyu — browser nguồn MUGEN (P1–P2)

## Mở để kiểm tra trực tiếp

Chạy **`D:\SelfProject\RougeLite\LaunchAtyu.cmd`**. Đây là project Godot riêng, không phải PLAY. `Launch.cmd` của game vẫn mở Fix03 như trước.

- Gõ ID để lọc action; mỗi khai báo trùng ID có số occurrence riêng.
- Play/Pause, Prev/Next và thanh tua dùng để kiểm tra từng frame; tốc độ chuẩn60 tick/giây, có chỉnh tốc độ.
- Zoom nguyên1–8x, Mirror và Boxes để xem điểm chân/collision nguồn; kéo chuột phải để di chuyển vùng xem nếu VFX quá lớn.
- Bật **Inspect raw sprite table** và đổi SFF entry để xem từng mục gốc, kể cả các biến thể trùng group/index. Chế độ này bỏ transform AIR để xem hình nguyên bản.
- ID có ích để bắt đầu:0,20,200,210–213,1406,2001,10190,8065,8067. Đây là ID nguồn, chưa phải mapping chiêu Atyu đã duyệt.

## Đã thực hiện

- Decoder giới hạn phạm vi cho định dạng thực tế trong gói: SFF2 raw/RLE8/LZ5, sprite liên kết và palette liên kết. Giữ axis, palette index, table index, kích thước và hash pixel. Không chạy mã CNS/CMD của mod.
- **3.679/3.679 mục sprite giải mã thành texture runtime**, không có lỗi giải nén. Có3.669 khóa group/index khác nhau;10 khóa trùng được giữ nguyên đủ biến thể. AIR lookup mặc định dùng mục đầu bảng và cảnh báo khi trùng; đây là quy ước của browser, không khẳng định mô phỏng chính sách duplicate của MUGEN.
- **684 khai báo AIR /679 ID /4.916 dòng frame**, giữ offset, tick, flip, alpha, scale, angle, loop-start, indefinite hold, collision boxes và dòng chưa hiểu.
- Browser áp dụng các directive interpolation được khai báo trong AIR cho offset/scale/angle/blend ở bước60Hz; không tự thêm frame smoothing. Có270 frame mang directive interpolation.
- Blend A/S/AS được hiển thị bằng shader riêng; sai khác pixel tuyệt đối so với engine MUGEN chưa được chứng minh. Không gắn hitbox hay sát thương Godot vào các collision box nguồn.
- Texture cache giới hạn số mục; tải hình khi chọn thay vì nạp toàn bộ archive lên GPU. Không nén hay tự căn giữa từng sprite.

## Lỗi và giới hạn của nguồn

-4.684 dòng frame có sprite;160 dòng rỗng là frame chờ;72 dòng còn lại tham chiếu59 khóa sprite không có trong SFF. Chi tiết trong `docs/atyu_audit/conversion.json`. Browser ghi **UNRESOLVED SPRITE**, không tạo hình giả để báo chuyển đổi thành công.
- Có tiêu đề `Begin Action 1127]` thiếu dấu mở ngoặc, được giữ và cảnh báo trong action1126; không tự sửa file nguồn.
- Các frame có hình trong nhóm ứng viên0/20/200/210–213/1406/2001/10190/8065/8067 đều tìm được sprite. Riêng1150 và2044 chỉ có frame rỗng; phải kiểm tra Helper/Explod/CNS trước khi dùng chúng như hiệu ứng.
- Browser chỉ phát một action AIR. Chưa chạy đồng thời Helper/Explod, logic chiêu, âm thanh SND, camera MUGEN hoặc palette swap lúc chạy. Chưa xác minh hình nào thực sự là Yuta/Rika bằng nghiệm thu trực quan.
- Chưa có Atyu trong PLAY và chưa chứng minh animation Bắc/Nam hay góc nhìn top-down. Các vấn đề gameplay/bảng rank/CC boss ở `ATYU_AUDIT.md` vẫn còn trước P3 trở đi.

## Kiểm thử và phạm vi

Python:8 bài kiểm tra packet RLE/LZ, backreference/bounds, palette cycle và AIR offset/duplicate/loop/hold/collision. Godot headless:duyệt684 actions/4.916 frame, kiểm tra tick, mirror, hold và alpha weights. GUI mở bằng Godot4.7.2 GL Compatibility, gồm action8067 để kiểm tra shader. Log lưu ở `docs/atyu_audit/`.

Không xuất ảnh/video nghiệm thu. Các PNG trong `experiments/mugen_atyu/data/sprites` là **texture cần để browser chạy**, không phải ảnh báo cáo. Texture và metadata tái tạo nằm ngoài Git; `.gdignore` tách cả experiment và nguồn tham khảo khỏi import/release của game chính. Không đưa asset MUGEN vào gói Windows hiện tại. Credits nguồn vẫn chưa phải giấy phép được xác minh.

Nguồn tham khảo định dạng: tài liệu AIR của Elecbyte https://elecbyte.com/mugendocs-11b1/air.html ; cấu trúc SFF được đối chiếu với bản triển khai công khai https://github.com/nitsuboy/SFF-sprite-extractor/blob/main/sff2.py . Decoder/browser được viết cục bộ, không cài thêm engine hay thư viện trả phí. Python/Pillow/Godot dùng bộ đã có của project.

## Tái tạo

Chạy Python runtime có Pillow:

```
python tools/mugen_import/decode_sff.py --source "D:/SelfProject/RougeLite/assets/characters/atyu/Yuta Manga v1/Ichigo_Bankai.sff" --out experiments/mugen_atyu/data
python tools/mugen_import/parse_air.py --source "D:/SelfProject/RougeLite/assets/characters/atyu/Yuta Manga v1/Ichigo_Bankai.air" --out experiments/mugen_atyu/data/actions.json
python tools/mugen_import/test_decoder.py
```

Converter tự tạo `.gdignore` trong thư mục data để tránh import hàng nghìn texture không cần thiết; browser đọc PNG trực tiếp. Không tuyên bố decoder hỗ trợ các encoding SFF khác chưa có trong gói. Bước tiếp theo là người dùng xem nguồn trong browser, sau đó chọn mapping body/VFX và quyết định gameplay còn thiếu trước khi tích hợp.
