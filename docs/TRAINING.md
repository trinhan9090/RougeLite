# TRAINING / Luyện tập

Mở lại `D:\SelfProject\RougeLite\Launch.cmd`. Chọn nhân vật trong CHARACTER rồi bấm TRAINING ở menu chính. Phòng tập dùng đúng nhân vật/VFX/điều khiển hiện tại và render1080p.

- Nhân vật luôn đầy HP; boss đứng yên, không đánh, bất tử thật. Đòn vượt HP không tạo kill/EXP hay chuyển map.
- J/K/L/I mở sẵn ở hạng1, hồi0s ngay sau khi chấp nhận thi triển. Tốc độ đánh thường giữ nguyên để thử nhịp animation. Các giới hạn thực thi vẫn có hiệu lực: không chồng hai cú dash đang chạy, không gọi hai linh thể đồng thời, v.v.
- Bảng bên phải đổi giữa Astra/Vex/Boros/Atyu và hạng1–4; I tự giới hạn hạng3. Đổi lựa chọn dựng lại phòng tập.
- Space gọi đánh thường qua cùng nhịp đánh/nhắm mục tiêu. Tắt ô **Tự đánh thường** để thử từng đòn bằng Space; PLAY thường vẫn tự đánh như trước. Có thể đổi phím trong SETTING hoặc Esc.
- HP/EXP hiện số hiện tại/tối đa; HP có1 chữ số thập phân, EXP dùng số điểm nguyên. Sát thương nổi ngay trên mục tiêu, crit màu vàng có dấu !; các số dùng damage sau giáp.
- Nút đặt lại dựng lại phòng tập, xóa toàn bộ đạn/chiêu trễ/buff/linh thể, khôi phục vị trí và bộ đếm.
- Đòn trúng, sát thương gần nhất, tổng sát thương sau giáp và DPS được đo qua DamageResolver thật. Boss giữ HP đầy nên HP mất thực tế bằng0; con số thử sát thương là damage sau giáp, không phải lượng HP đã trừ.
- Esc tạm dừng; trong đó đổi Auto/Manual, phím, fullscreen hoặc về menu như game thường. TRAINING không tự sửa settings. Auto thử chiêu theo nhịp0.25s để tránh tạo hàng chục barrage kéo dài trong mỗi giây; cooldown vẫn0. Manual không phải chờ hồi chiêu.

Phòng tập là bản đồ đền trống, không có quái thường, EXP/upgrade, boss wave hoặc dung nham. PLAY bình thường vẫn bắt đầu cấp1, mở kỹ năng3/6/9/11 và giữ cooldown/HP/progression cũ. Chỉ phòng tập sử dụng TrainingHealth.

Kỹ thuật: TrainingRun/Boss/Health/Panel riêng; không sửa asset hoặc số liệu content. DamageResolver ghi kết quả HP/death từ trạng thái Health sau commit, tránh phát kill giả khi trúng boss bất tử. Bộ kiểm tra dùng boss/chiêu thật cho cả4 nhân vật, hit sát thương cực lớn, cooldown tức thì, reset/rank/hero/pause, đo sát thương và PLAY đối chứng. Log và kết quả cuối tại WORK_LOG và `docs/atyu_audit/training_*.log`. Không xuất ảnh/video; người dùng chơi thử trực tiếp.
