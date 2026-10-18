# 02 — GRAVESHADE CHARACTER GAMEPLAY SPEC

## Identity
**Name:** Graveshade (placeholder; tránh dùng Punisher trong public assets). **Class:** ADC, subclass Tactical Suppressor / Heavy Gunner. **Fantasy:** tay súng áo giáp chiến thuật, nhiều loại vũ khí, áp chế bằng hỏa lực, bom và mìn. Khác Vex (mobile duelist, crit/ricochet): Graveshade chậm hơn, kiểm soát vị trí, burst theo loạt và area denial. Nguồn tạo hình: áo chống đạn tối, áo khoác tactical, hai tông than/xám/trắng, khăn đỏ nhỏ hoặc biểu tượng gốc; không sao chép logo đầu lâu đặc trưng.

## Demo default (dữ liệu, chỉnh qua resource)
HP 115; move speed 210 px/s; attack range 340 px; base damage 15; attack interval 0.36s; crit chance 5%; crit multiplier 1.5; projectile velocity 680 px/s; bullet ammo: **không dùng ammo cho basic demo**, hệ thống `reload` chỉ là cosmetic/casting trừ khi đã có shared ammo interface. Cấp 1 có đánh thường; J lv3, K lv6, L lv9, I lv11. Mốc cấp tự mở khóa miễn phí nếu core gameplay hiện hành quy định thế; sau đó chọn 1/3 lõi.

## Basic — Tactical Round (Auto)
Bắn 1 viên đạn vào enemy gần nhất trong tầm, đường thẳng, có muzzle flash, streak và hit spark. Khi không có target hợp lệ không bắn. Host/gameplay tạo projectile và hit; renderer chỉ vẽ. Chọn asset pistol/AK từ SFF nếu có. Capabilities `PROJECTILE`, `DIRECTIONAL`, `SPLITTABLE`, `PIERCEABLE`, `ON_HIT`, `ECHOABLE`, `CRIT_COMPATIBLE`; projectiles sinh từ augment dùng event budget. SFX source `PlaySnd` tương ứng sau kiểm chứng, có pooling để tránh chồng âm.

## J — Suppression Burst (lvl3) | đề xuất từ Beretta / Uzi / P90
Chọn target gần nhất, bắn một loạt đạn hình quạt hẹp, mỗi viên là projectile thật; giữ vị trí hoặc giảm tốc nhẹ lúc nổ súng; ưu tiên animation rush (súng tự động). CD base 6.2s, 5 viên × 12 dmg, spread 22°, mỗi mục tiêu nhận tối đa 5 hit/activation. Ranks: 1) 5 rounds; 2) 7 rounds; 3) vòng đầu xuyên 1 target; 4) nếu ít nhất 3 viên trúng cùng mục tiêu, apply `EXPOSED` +12% dmg từ người chơi trong 3s. VFX đạn vệt trắng-vàng, shell ejection có giới hạn.

## K — Frag Deployment (lvl6) | từ grenade / molotov / tear gas
Ném lựu đạn tại điểm dự báo quanh cụm quái (Auto) hoặc hướng aim/target (Manual), projectile ballistic chỉ là hình ảnh; sau fuse 0.7s gây AOE 80 dmg, radius 105 px, knockback nhẹ thường, boss không bị đẩy. CD 11s. Ranks: 1) Frag; 2) radius +20%; 3) tạo `BURNING_GROUND` 3s, mỗi giây 16 dmg; 4) split thành 2 vụ nổ phụ 50% ở hai phía **không kích hoạt recursive on-explosion**. MUGEN ưu tiên grenade/motov effects nếu decoded; khác loại chỉ là style, không mặc định là các nâng cấp riêng trong UI.

## L — Tactical Minefield (lvl9) | từ Land Mine
Đặt 2 mìn ở vị trí hợp lệ gần người chơi, chọn góc tránh obstacle; arm 0.5s, lifetime 12s; trigger radius 42 px, explosion radius 78 px; damage 65; CD 16s. Tồn tại tối đa 6 quả của mỗi người, quả cũ nhất bị thu hồi không phát nổ khi vượt cap. Ranks: 1) 2 mines; 2) 3 mines; 3) khi nổ áp dụng Slow 30% trong 2s; 4) mìn đầu tiên trong loạt gây chain detonation ở mìn khác trong phạm vi 120 px (mỗi mìn tối đa 1 detonation/event). Boss damage 70% hiệu lực để cân bằng, tùy test.

## I — Heavy Ordnance (lvl11) | từ Bazooka hyper
Phóng 1 tên lửa nặng theo hướng ưu tiên boss hoặc mật độ quái. Projectile tốc độ 460 px/s, chạm mục tiêu hoặc hết quãng bay sẽ nổ: 260 dmg, radius 145 px, distance 650 px; cooldown 28s, cast windup 0.45s. Ranks: 1) 1 rocket; 2) thêm 2 rocket phụ góc ±12° mỗi quả 45% dmg, mỗi enemy tối đa 2 rocket hits/cast; 3) nổ chính tạo thêm 3 nhịp cluster strike (40% dmg, tick cách 0.25s), bảo đảm giới hạn hit. Cần marker telegraph rõ và SFX không chồng gây clip âm.

## Alternatives (không mặc định)
`Shotgun Breach` thay J bằng cone shotgun có damage falloff, `Smokescreen` thay K bằng tear-gas slow/debuff, `Crack Shot` biến ultimate thành tuyến đạn xuyên nhiều đối tượng. Những thay đổi này chỉ làm qua Signature Evolution với conflict groups; không tự chuyển bộ chiêu sau khi xem asset.

## Combat safety
- Tất cả damage, CC, explosion hit list do CombatSystem chung quyết định.
- Projectile collision bởi physics layer chung; dùng hit dedup key `(cast_id, projectile_id, target_id)`.
- AOE multi-stage cần `(effect_id, tick_index, target_id)` và không tự proc damage-trigger vòng lặp vô hạn.
- Tất cả vị trí spawn kiểm tra obstacle; dash/knockback không đưa quái vào tường.
- Auto/Manual áp dụng chung logic, khác selection intent. No friendly fire. Boss telegraph không bị VFX che.
