# Asset licenses

2026-10-16 art pipeline: active Astra/Vex/Boros frames, weapons, terrain tiles and VFX are original procedural **prototype** assets generated from `tools/art_pipeline`. No concept/reference pixels are sampled, cropped or traced. Their rights remain with the project under LICENSE_PROJECT.txt; no CC0 grant or external creator license is inferred. Exact file provenance is recorded in docs/art_asset_ledger.csv. Godot's bundled font/runtime notices remain included in the Windows package.

Legacy supplied Vex/Boros resources and reference pack are retained unchanged for recovery/tests, removed from active loadout references, and excluded from Windows/Web export. Historical integration notes below describe older builds only. Their unresolved source licenses are not represented as verified.

M0 has no third-party art, audio, fonts or character assets. Menu uses Godot's built-in UI/default font. Godot engine is MIT licensed; engine distribution contains its own license information. Source licensing for this project has not been chosen by the owner; no project license is implied.

M1 uses locally authored geometric placeholders for player, chaser, projectiles, EXP diamonds and arena pillars. No downloaded character sprites, animations or external IP are included. These are temporary gameplay visuals, not the final joint/sprite animation system.

M3-M5 assets: jointed_character.gd is locally authored procedural geometry (articulated shoulders/elbows/hips/knees/torso/head and staff/pistols/hammer), with idle, movement, attack, dash and transformation feedback. audio_feedback.gd synthesizes its own short sine-wave hit/kill tones. There are no downloaded character sprites, animations, music or third-party game IP. These remain demo placeholders, not a polished pixel-art asset pack.

The exact executing Godot binary's MIT text, copyright list and third-party license text are extracted by tools/write_engine_notices.gd into docs/licenses/GODOT_LICENSE.txt and GODOT_THIRD_PARTY.json, then bundled with the Windows demo. Official license reference: https://godotengine.org/license/ . The project's own source/art license remains reserved pending the owner's decision; LICENSE_PROJECT.txt does not grant an open-source license.

2026-10-15 - Vex user-supplied art: assets/sprites/characters/vex/vex/{spritesheet.png,spritesheet.aseprite,projectile.png}. User placed these files locally and explicitly requested use. Original creator/source/license were not supplied; no public-domain or permissive-license claim is made. Used as a local demo cosmetic atlas; retain original files. Public redistribution rights require source/license confirmation. Earlier statements that all art is procedural describe the pre-ART-01 version only.

2026-10-15 - Boros supplied pack: assets/sprites/characters/boros/boros_sprite_pack, including README and metadata. User explicitly requested integration. Pack labels itself a visual prototype with reused/generated pose sources and provisional timing/anchors. Creator/license not supplied; no open-license claim. Source strips preserved; blank hurt frames are replaced by held neighboring poses in SpriteFrames references only. Earlier all-procedural art statements no longer describe Vex/Boros.

2026-10-16 - Boros derived strips under assets/sprites/characters/boros/cleaned are generated from the user-supplied prototype with tools/clean_boros_sprites.py, removing disconnected neighbouring-pose fragments. Original files remain intact; same source provenance/license limitations apply. No newly licensed external art added.
