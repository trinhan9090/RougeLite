# 03 — ART, ANIMATION, VFX & SFX

## Style và pháp lý
Giữ góc nhìn/top-down pixel art lấy cảm hứng Wizard of Legend, nhưng sprite thử nghiệm M.U.G.E.N vẫn side-view. Không ép animation M.U.G.E.N trông như 4 hướng thật nếu source thiếu. Nguồn `.sff` và `.snd` là tài sản bên thứ ba; với thử nghiệm riêng tư cũng không mặc định được phép tái phân phối. Tất cả asset gắn `source_id`, `source_file`, `sprite_group/index` hoặc `snd_group/index`, `provenance_status=unverified_rights`, `usage=local_prototype_only`.

## Visual direction
Silhouette tactical: giáp/áo tối tương phản, súng nổi rõ khi thu nhỏ; tránh trộn súng với body đến mức khó phân biệt. Tông VFX: vàng trắng của muzzle, cam của vụ nổ, khói xám tiết chế, mine marker đỏ. Không dùng màu xanh neon chủ đạo của Viridian, không dùng hiệu ứng loang vàng dày che hết quái.

## Animation minimum
- idle, move/front/back/left/right (thiếu hướng thật => placeholder labeled), basic_fire, J_burst, K_throw, L_deploy, I_bazooka, hit, death; reload animation optional.
- Mỗi clip giữ native source frame durations/offsets qua manifest. Anchors đặt chân chung; muzzle socket là marker theo anim and facing. Projectile không attach vào frame màn hình, lấy muzzle world position.
- Event markers: `cast_started`, `fire_round[n]`, `throw_release`, `mine_armed`, `rocket_spawn`, `cast_finished`. Marker chỉ kích hoạt logic nếu được GameplayController xác nhận; animation không tự gây damage.

## VFX layer stack
- Basic: muzzle flash 2–4 frames, tracer, impact spark 2–4 frames, tiny debris pooling, recoil 2–3 frames.
- J: burst muzzle staccato tương ứng từng viên, shell/casing tối đa 8 active/người, tracer theo projectile thật; không nhân lặp flash sai vị trí.
- K: arc indicator (không phải hitbox), grenade spin, fuse indicator, radial explosion pulse, dust, scorch decal culling.
- L: mine disc + armed blink + proximity ring (không hiện vòng gây nhiễu liên tục), detonation and debris.
- I: anticipatory rocket loader pose, rocket contrail, impact core flash, expanding shockwave, trailing smoke, optional screen shake có accessibility toggle.
- Augment Split: render n bullets sourced from runtime; Pierce: impact and continuation; Echo: ghost muzzle pose but no extra hit unless runtime confirms; Explosion: attached only to authoritative explosion event.

## Audio
SND chưa được nghe. Agent chỉ được gọi các nhóm `gunshot`, `burst`, `throw`, `mine_arm`, `mine_explode`, `rocket_launch`, `rocket_impact`, `hit`, `death` sau khi xuất sound inventory và kiểm tra nội bộ. Set volume per bus, pitch variation nhỏ, cooldown sound gating; 4 players x automatic fire có thể gây clipping nên global sound voice limit (đề xuất 24 SFX đồng thời, ưu tiên skill/boss).

## Import checklist
1) decoder SFF/SND → isolated cache; preserve offsets and action references.
2) metadata AIR → SpriteFrames tracks or AnimationPlayer with per-frame delta; detect nonuniform durations.
3) ensure true alpha, no neighboring-frame bleed, no unscaled mipmap artifacts; Godot nearest filter.
4) validate all sprite refs exist, sound refs exist; generate machine readable report.
5) playtest at 640x360, 30+ enemies, max J projectiles and rocket VFX simultaneously. Không cần export ảnh/video. Report `PASS/FAIL` và cách tái hiện lỗi.
