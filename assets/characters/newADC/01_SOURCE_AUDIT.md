# 01 — SOURCE AUDIT & ORIGINAL MOVESET

## Danh mục xác minh
Nguồn đầu vào: `marvel P.rar` (RAR v5), 36 entry, thư mục `Punisher/`. `Punisher.def` khai báo `sprite=P.sff`, `anim=P.air`, `sound=P.snd`, `cmd=P.cmd`, `cns=P.cns`, `st1=throws.cns`, `st2=specials.cns`, `st3=hypers.cns`. `MOVELIST.txt` ghi creator RAHLONNIR; DEF có patch Candido159. Những asset này không tự động open-source.

- `P.sff`: 5.70 MiB sprite + hiệu ứng, chưa giải mã và kiểm tra ảnh trong tài liệu này.
- `P.snd`: 12.24 MiB, chưa nghe/trích xuất từng sound entry.
- `P.air`: 204 khai báo animation action; không đồng nghĩa 204 animation khác biệt hoặc tất cả usable.
- `specials.cns`: 29 StateDef, `hypers.cns`: 25 StateDef (gồm helper/child states), `P.cns`: 52 StateDef.
- `P.cmd`: ánh xạ SPECIAL1→1000, SPECIAL2→1002, SPECIAL3→1004, SPECIAL7→1009, SPECIAL8→1010, SPECIAL9→1011, SPECIAL456→1006; HYPER1→3000, HYPER2→3003, HYPER3→3005, HYPER4→3011 (VERIFIED_TEXT).

## MOVELIST — kỹ năng ghi trong nguồn (VERIFIED_TEXT)
- Basic: bắn súng ở một số đòn strong; dùng Start để reload khi băng rỗng; đổi loại lựu đạn khi crouch+start.
- Rush: Beretta / Shotgun / Uzi.
- Fire in the Hole: grenade / tear gas / molotov.
- AK-47 front fire, AK-47 diagonal fire, FN P90.
- Land Mine; Knife (air).
- Hyper: Crack Shot, Eat Lead, Bazooka, Interrogation.
- Movement: roll, hop back, super jump, recover.

## Mapping hiện trạng cần giải mã
Đừng suy diễn StateDef 1000 = Beretta hoặc 3000 = Crack Shot cho đến khi đối chiếu từng command definition và kiểm tra code/ảnh. CMD ghi mapping `SPECIALn/HYPERn` tới state; MOVELIST ghi đòn theo input; Agent phải nối chuỗi input→command name→StateDef→ChangeAnim/Explod/Helper→SFF sprite→PlaySnd→SND entry. Mọi ID không truy xuất được phải ghi `UNMAPPED`.

## Kiểm toán asset bắt buộc
1. Kiểm chứng checksum archive, an toàn đường dẫn, tách sang thư mục staging, không ghi đè nguồn.
2. Parse DEF và tra tất cả resource reference, missing file.
3. Dùng decoder SFF phù hợp phiên bản để xuất sprite group/index/offset/palette/alpha (giữ offset).
4. Parse AIR frame record, `Begin Action`, timing, loop start và Clsn; giữ đơn vị M.U.G.E.N ticks rồi đổi FPS hợp lý.
5. SND: kiểm kê group/index/duration/sample rate và playback nội bộ, xác nhận sync với PlaySnd.
6. CNS/CMD: quét tất cả PlaySnd, Explod, Helper, Projectile, ChangeAnim, HitDef, PosAdd, VelSet; kể cả state phụ.
7. Với mỗi chiêu tạo mapping có chứng cứ file:line + xác suất tin cậy; không dùng animation khác nếu source thiếu.
8. Các file `*.act` là palette tùy chọn; thử chọn palette có silhouette dễ đọc nhưng đừng tô lại license metadata.

## Rủi ro góc nhìn
Source M.U.G.E.N thiên side-view. Endless Survival top-down 3/4 N/S/E/W. Giữ animation gốc cho phase thử nghiệm ngang, không tự coi flipped sprite là North/South hợp lệ. Có thể dùng hướng bắn được tính riêng khỏi body sprite; cần kiểm tra trực quan trực tiếp trong engine.
