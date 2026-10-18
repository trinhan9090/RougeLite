# Astra v3 review benchmark

Original compact 2D pixel layers; concept poster is identity reference only.
96px fixed RGBA canvas, (48,76) feet anchor, approximately 48px body,
18-color core palette, dark navy/off-white/gold coat and asymmetrical star staff.
Idle 5fps / run10 / attacks12–14. Separate PNG frames prevent atlas bleeding.
640x360 world presentation, integer1280x720 window, nearest filtering.
UI retains a1280x720 virtual layout at0.5 scale to preserve menu/card contents.
Native coordinates, hitboxes, speed, ranges, cooldowns and boss gates are unchanged.

Frame-sheet VFX use6 integer raster frames per effect. Projectiles belong to the
real projectile node; persistent area belongs to the real timed effect. Shield
and root overlays read actual runtime state. Cosmetic pool80/trail cap120 remain.
Arcane courtyard uses16px quiet floor tiles on the existing ruined_temple map ID.
Enemy pixel presentation reads actor velocity and leaves navigation untouched.

The generated layer PNGs and generator are editable sources. No commercial game
assets, concept cutouts, paid tools or network dependencies are used. Pillow's
MIT-CMU license and installed Godot/Blender notices remain in licenses/.
Blender is used only for H264 encoding, not for character sprites.

Limitations to review: simplified face/coat compared with the concept; no owner
art approval; Vex/Boros and remaining biomes retain their previous visuals.
Per07_AGENT_RUNBOOK step6, review Astra before expanding those characters.
