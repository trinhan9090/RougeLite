# 04 — MAP & WORLD ART PIPELINE
## 1. World philosophy
Build *hand-authored structural layout templates* combined with seeded procedural vegetation, rubble, collision-capable obstacles, decoration variants and ambient VFX. Do not generate an unconstrained full random noise grid. Gameplay map pool transitions after beating bosses at 10/20/30 etc; art layer shall not trigger boss/transition on its own.

## 2. Three biomes
**Ruined Temple:** slate stone floor, moss, broken columns, fallen statuary, soft moon/blue fill + golden torches; safe traversal loop and distinct boss arena. **Enchanted Forest:** grass/mud/roots, tree canopy occluders, logs, firefly particles; warm foliage/teal shadows, readable walkability. **Volcanic Ruins:** ash charcoal floor, cracked warm orange lava edges, broken basalt arches, smoke; hazards only if existing gameplay spec/config defines actual damage — *no decorative lava misleadingly damaging users*.

## 3. Blender source asset kit
- Produce one base scene with same orthographic view as characters for 3D-assisted props; render transparent props to pixel layers with metadata: `prop_id`, `origin_feet`, `collision_footprint_px`, `occlusion_mask`, `shadow_layer`, `variants`.
- Ground terrain belongs in Godot TileSet/TileMapLayer, with consistent 32px texels per cell; Blender prop renders as separate `PackedScene` Sprite2D or atlas. Make at least 2 types of floor + 3 variation tiles + 3 collision props per biome before expansion; avoid repetitive identical crate patterns.
- Texture materials may be authored with noise but require deliberate pixel cleanup. Each tile has seamless edges and proper 2×2 adjacency screenshots, no obvious border seams.
- Separate physical blocks from decorative props; high rock visual does not mean whole sprite hitbox is solid; foot-level collider smaller than overhanging silhouette. For tree, front canopy can occlude player but trunk collision remains small.

## 4. Node hierarchy
```text
ArenaRoot(Node2D)
  GroundLayer(TileMapLayer)
  TerrainLayer(TileMapLayer)
  ShadowLayer(TileMapLayer)
  ObstacleLayer(TileMapLayer)
  DecalLayer(TileMapLayer)
  Props(Node2D)
  ForegroundOccluders(Node2D)
  AmbientVFX(Node2D)
  EnemySpawner(Node2D)
  SpawnDebugOverlay(Node2D) # debug builds only
```
Set `z_index`/Y-sorting and layering per scene; decals under feet, props behind if below Y threshold, UI always separate CanvasLayer.

## 5. Deterministic procedural placement
- Input: map ID, seed, phase/level, procedural density policy and safe zone radius from gameplay config. Record seed and map version.
- Derive candidate cells; reserve player spawn safe disk, boss arena, critical path and at least 2 egress routes. Scatter props with seeded RNG constrained by density, min-spacing, biome tags and slope/wall masks.
- Validate collision grid by flood fill (spawn to arena and enemy approach areas), corridors at least 2 player diameters wide (DEMO DEFAULT), enemy navigation accessibility and collision non-overlap. Re-roll up to 10 times (DEMO DEFAULT), then use approved static fallback layout and log warning.
- Enemy spawn must be outside camera visible or safety radius when feasible, not inside obstacles, reachable, and far enough not to spawn-kill. Retain spawn gate owned by gameplay manager; visual map provides navigability/candidate spawn API.
- Dynamic obstacle changes trigger navigation refresh only on safe batches; avoid full navmesh rebuild every frame.

## 6. Environmental lighting & effects
- Godot `PointLight2D` sparingly (torches/star stones), modulate ambient via CanvasModulate/WorldEnvironment where supported, baked soft prop shadows via sprite underlayers for performance. Do not rely on real-time per-pixel dynamic shadow casting for all props.
- Floor contrast not so busy it hides EXP drops/projectiles/telegraphs. Reserve strong color white for hit/skills and yellow-green for EXP; map highlights should not be confused with loot.
- Explicit QA: at least 5 deterministic seeds per biome; daytime/night bright variation only if requested; prove reachable enemy zones, obstacle collision, visible player at all corners, no tile seams and stable transition after boss kill.
