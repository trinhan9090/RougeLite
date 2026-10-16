# 05 — MAP/TILESET GRAPHICS PIPELINE

## Fixed needs
At least three visually distinct map archetypes: ruined forest, broken cathedral/dungeon, volcanic badlands. Each run chooses random template; defeated boss every 10 levels leads to new random map (avoid same immediately when pool>1 by DEMO DEFAULT). The older gameplay doc controls boss spawn and transition timing.

## Technology
- Godot 4 `TileMapLayer` for Ground/Terrain/Decoration and obstacles where sensible. Scene-based `StaticBody2D` obstacle prefabs for complex colliders, destructible variants only if gameplay supports them.
- 32×32 exact atlas cells, nearest filtering; pre-authored tiles for dirt/stone/grass/lava, auto-tiling transition rules, 2D props: pillars, trees, rocks, crates, bones. Keep tiles on integer grid.
- Layers: `Ground`, `Terrain`, `Overlays`, `Obstacles`, `FrontOccluders`, `NavigationRegion2D`/navigation sync, `SpawnMarkers` and `VisualLighting`. Shadows behind objects, unobstructed hero and pickup readability.

## Three themes and asset targets
| Theme | Ground colors | Obstacle visual grammar | Hazards | Clarity |
|---|---|---|---|---|
| Forest ruins | moss/granite, muted green | stumps, roots, standing stone | cosmetic fireflies only in MVP | bright exp orb visible on grass |
| Cathedral ruins | grey slate/ochre cracks | broken columns, sarcophagi, low wall | cosmetic dust only | distinct edge of physical wall vs decal |
| Volcanic badlands | charcoal/terra cotta | basalt stones, broken monuments | only active lava if prior gameplay explicitly supports hazard | enemy red hit warnings remain distinct |

## Deterministic generation procedure
1. Run seed→derived `map_seed` per transition, select template independent from combat RNG.
2. Load authored playable floor mask and border; fill ground, cosmetic terrain patches using tile grouping/weighted variants.
3. Reserve 250px player-safe radius around spawn and boss staging route. Reserve enemy spawn region at least 550px from player as prior spec; use navigation distance and collider overlap, not only Euclidean distance.
4. Generate candidate obstacle placements in zones with per-template weights; use seeded shuffle, spacing, overlap & corridor checks.
5. Flood fill or nav graph test from player spawn to at least 2 distinct escape corridors and validated enemy spawn regions; reject/retry up to 16 times (DEMO DEFAULT), then load a known-good fallback layout.
6. Bake/update navigation after placing colliders, then initialize mobs. Decoration must never introduce invisible collisions. Export map seed to HUD/debug.
7. On map transition, clean temporary VFX, clear pooled object trails, switch tilemaps, reload navigation and safe player spawn. Preserve state as prior gameplay specifies.

## Art asset sourcing policy
- Prefer locally created procedural tiles and explicitly verified CC0 tilesets. Don't mix unrelated styles or pixel density. Any non-CC0 attribution/license must be reviewed against distribution constraints and recorded before use.
- If no approved compatible source pack is available, generate deterministic flat pixel tiles from palette and shapes. A clean placeholder map is preferable to unlicensed attractive art.

## QA cases
- Run 100+ seeds per template, assert no spawn collision, reachable path and two escape corridors; log fallback frequency. Visual capture seeds 1, 42, 999 for deterministic layout regressions.
- Build a map atlas contact sheet showing all tiles at 1×, 2× and game view. Ensure no tile seams, translucent ghost borders, wrong z-order, repeated patterns forming accidental barriers or hidden doors.
- VFX test each class on each environment. Player silhouette, target outlines, skill radii and EXP drops remain visible.
- Camera moves without tile shimmer; collisions match shown obstacle footprint. Decorative foliage may overdraw feet but never hide the entire hero.
