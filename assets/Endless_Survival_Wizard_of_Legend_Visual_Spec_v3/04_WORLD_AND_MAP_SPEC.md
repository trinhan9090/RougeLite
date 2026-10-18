# 04 — WORLD AND MAP ART PIPELINE v3.0

## Overall direction
Compact top-down pixel tilework; arenas feel authored but vary by seeded obstacle layouts. Use `TileMapLayer` and `TileSet` with original/licensed pixel tiles, clear floor/wall separation, Y-sorted props/actors, sparse decals and readable boss zones. Do not replicate Wizards of Legend room layouts or tile assets.

## Demo biome pack
| Arena | Ground | Props & blocking | Palette | Distinguishing gameplay-compatible cue |
|---|---|---|---|---|
| Forest Ruins | earth/grass/stone | trees, crumbled pillars, shrubs | desaturated moss + slate | alternate open areas and chokepoints |
| Arcane Courtyard | geometric tiles | statues, columns, broken plinths | charcoal/navy + antique gold | rune motif and symmetrical landmarks |
| Volcanic Remains | cracked stone | basalt, vents, low walls | muted grey + orange accents | hazardous-looking ground only hazardous if runtime says so |

## Tile and prop production
Tile module 16×16, prefabs 32×32/48×48 as needed. Source tiles may be drawn in Pixelorama/LibreSprite or generated programmatically. For intricate statue or column, Blender *optional* orthographic pixel export, match projection and palette. All imagery in-game should share coarse pixel density, directional shadows, neutral ambient brightness. Avoid random every-tile decoration; distribute features by clusters and curated anchor points.

## Scene hierarchy
`ArenaRoot -> GroundLayer(TileMapLayer), DetailFloorLayer(TileMapLayer), PropsBack(Node2D), Collision/Props(Node2D), YSortActors(Node2D), PropsFront(Node2D), TelegraphLayer(Node2D), DecorationFx(Node2D), SpawnDirector`. Keep object collision bodies separate from render tiles when necessary. Follow Godot version-specific `TileMapLayer` APIs. Test occlusion (walking behind a pillar / ahead of a pillar) and enemy navigation.

## Generator requirements (seeded)
1. `MapDefinition` provides `tile_set_id`, `bounds`, `safe_player_region`, `obstacle_groups`, `density`, `minimum_clearance`, `spawn_annulus`, `boss_arena_region`, `seed`.
2. Layout generation: select template, stamp floor/terrain, preserve authored visual anchor regions, place obstacle clusters with spatial constraints, ensure connected walkable region, then style with nonblocking decor.
3. Reject obstacles within player safe radius and boss telegraph buffer. Verify player size + worst-case Brute charge clearance (per gameplay); recompute navigation/occupancy deterministically.
4. Avoid spawn-kill: spawn only outside validated exclusion radius, not overlapping player, enemies or obstacles; random selection must be repeatable by seed. Never spawn into blocked or unreachable region.
5. Record failed seeds; retry up to configurable number, then load validated fallback map. Never load illegal layout or silently teleport boss into collision.
6. Transition every 10 levels **after authoritative boss defeat gate**; visual fade/map swap cannot skip or alter EXP or boss conditions.

## Asset workflow / tests
- Produce floor tile preview, terrain seam atlas, prop contact sheet, static screenshots with 0/15/30 enemies, 20 fixed seeds per biome and one obstacle-rich stress seed.
- Automated checks: tiles nonempty, valid collision primitives, player safe position, path connectivity, no unreachable enemy spawn, boss clearance, no decor masking telegraphs.
- Visual checks: no harsh high-frequency tile repetition, foreground does not hide character, background less saturated than VFX, maps remain visibly distinct in grayscale.
