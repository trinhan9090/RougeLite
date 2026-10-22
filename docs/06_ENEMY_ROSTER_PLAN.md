# 06 — Time-Gated Enemy Roster Expansion: Step-by-Step Implementation Plan

> Source of truth: `AGENTS.md` (five archetypes + host-authoritative roster).
> This document is the concrete execution plan mapped onto the **real** code of this repo.
> Nothing here is "already implemented" — every phase below still has to be executed and tested.

---

## 0. Audit findings (what actually exists today)

| Area | Reality in this repo | File |
|---|---|---|
| Enemy content | One `EnemyDefinition` (stats, damage, xp_reward, attack_interval) and **one** enemy: `enemy.chaser` (HP 35, spd 110, dmg 8, xp 6) | `scripts/data/enemy_definition.gd`, `content/enemies/chaser.tres` |
| Enemy runtime | `EnemyActor` = hardcoded chase-to-target steering + one shared `AttackController` driven from the run root | `scripts/actors/enemy_actor.gd` |
| Enemy scene | `scenes/enemies/chaser.tscn` (CharacterBody2D + circle r13) | `scenes/enemies/chaser.tscn` |
| Enemy skill | `content/skills/enemy_chaser_basic.tres` (`executor.basic_melee`, range 32, cd 1, dmg 8) | `content/skills/enemy_chaser_basic.tres` |
| Spawning | `CombatRunRoot.spawn_enemy()` hardcodes chaser scene + chaser skill; HP/damage scaled by **player level**; cap from `EnemySpawnDirector.population_cap()` (level-based) | `scripts/core/combat_run_root.gd:234-259` |
| Spawn sampling | `EnemySpawnDirector.sample()`: exclusion 550, max 950, 30 attempts, off-camera, `arena.spawn_clear` + `navigable` + 32px actor separation | `scripts/world/enemy_spawn_director.gd` |
| Spawn policy data | `SpawnDefinition` (period 2.5, max_enemies 110, initial_enemy_cap 40, cap_growth_per_level 2) | `scripts/data/spawn_definition.gd`, `content/progression/spawn.tres` |
| Clock | `RunState.elapsed_simulation_seconds` advanced only while `run_phase == RUNNING` (so it **freezes during augment selection**) | `scripts/core/run_state.gd`, `combat_run_root.gd:197-232` |
| Boss schedule (solo) | **Level-based**: `BossGate` fires at every 10th level (10/20/30…), `boss_gate_state` PENDING→ACTIVE→DEFEATED→TRANSITIONING | `scripts/progression/boss_gate.gd`, `combat_run_root.gd:319-324` |
| Boss schedule (MP) | `TimeEncounterDirector` = strict 180 s cadence, but its client RPCs are `pass` stubs — **not wired to the real boss system** | `multiplayer/net/time_encounter_director.gd` |
| Match clock (MP) | `MatchClockAuthority` — host-authoritative tick clock, frozen at GAME_OVER | `multiplayer/net/match_clock_authority.gd` |
| MP combat | `MultiplayerCombatRun` instantiates the **same** `CombatRunRoot`; enemies/damage are still simulated **locally per peer** | `multiplayer/scenes/multiplayer_combat_run.gd` |
| Combat pipeline | `CombatService.hit()` → `DamageResolver.resolve()` (faction check, armor, shield, status, budget). `radial_hit()` for AoE, `spawn_projectile()` for shots. Contexts carry `root_cast_id`/`event_id` | `scripts/combat/combat_service.gd`, `scripts/combat/damage_resolver.gd` |
| Telegraph | `BossTelegraph` (circle/cone/rect, `contains()`, resolves at timer end) — boss-flavoured orange drawing | `scripts/combat/boss_telegraph.gd` |
| VFX | `combat.visual_event` dictionary stream → `CombatVisualFactory` → pooled `CombatVisualEffect` / `PixelVisualEffect` / `CelestialVisualEffect`; colour+style+renderer per skill via `assets/vfx/generated/*.json` | `scripts/ui/combat_visual_factory.gd` |
| Enemy art | `EnemyPixelVisual` draws 1 hardcoded sheet `assets/art_v3/world/shade_enemy.png` (128x160 = 4 frames x 4 facings, 32x40 cells) | `scripts/ui/enemy_pixel_visual.gd` |
| SFX | Procedural `AudioStreamWAV` tones (`AudioFeedback.tone()`); spatial voices pooled per actor (`ActionAudio`, 12 voices) | `scripts/ui/audio_feedback.gd`, `scripts/ui/action_audio.gd` |
| Content registry | `ContentCatalog` → `ContentDefinition` graph. `references()` **must** return `ContentDefinition` only (anything else = validation error). `definition_copy()` deep-duplicates | `scripts/app/content_registry.gd`, `scripts/data/content_definition.gd` |
| Tests | `tests/run_all.gd` runs 48 suites in separate processes; any `ERROR:`/`WARNING:`/`failures=0` gate fails the suite | `tests/run_all.gd` |

---

## 1. Locked decisions for this implementation

### 1.1 Boss schedule — **unchanged** (explicit deviation from AGENTS.md wording)

AGENTS.md §0.4/§3.1 describes a 180/360/540 s boss cadence, but this repo's **shipped** boss cadence is
level-based (`BossGate`, every 10 levels). AGENTS.md §8 says: *"inspect actual boss scheduler and preserve its
defined numbering"*, and `EN_REG_01` requires the boss timer to keep working.

**Decision:** the boss schedule is **not touched**. The new roster is an **independent axis** keyed to elapsed
match time. The stubbed MP `TimeEncounterDirector` 180 s cadence is left exactly as-is (not wired, not
modified). Recorded in `docs/05_DECISIONS.md` as a documented assumption.

### 1.2 Offline is the primary path; replication is an optional layer (new user mandate)

- The encounter system, all five archetypes, VFX and SFX must work in a **pure single-player run with no
  network session of any kind** (no ENet peer, no coordinator, no lobby).
- `EnemyDefinition`, behaviour modules, `EnemyEncounterDirector`, telegraph and audio code must have **zero**
  dependency on multiplayer nodes.
- Multiplayer adds a thin **authority layer** on top: the host runs the scheduler and publishes decisions;
  clients apply them. If the layer is absent, the local instance is the authority (offline).
- Match clock is host-agnostic: offline it is a local always-processing clock node; online it is fed by
  `MatchClockAuthority`.

### 1.3 Match clock semantics

New `RunState.elapsed_match_seconds`, advanced by an always-processing clock node
(`process_mode = PROCESS_MODE_ALWAYS`) so that it:

- **advances during augment selection** (tree is paused by the existing upgrade flow) — "the match does not
  pause for augment selection";
- **freezes during an explicit player pause** (`run_phase == PAUSED`, Esc menu) — fairness;
- **never resets** when a boss dies / the map changes / a run restarts (reset only in `_start_run()`);
- is the **single** time source for roster gating — never `elapsed_simulation_seconds`, never player level.

Existing `RunState.elapsed_simulation_seconds` is kept untouched (scoreboard + existing tests).

### 1.4 Guardrails honoured

- No player-only skill/augment logic enters enemy code.
- No parallel Combat System: all damage goes through `CombatService.hit()` / `radial_hit()` /
  `spawn_projectile()` with a real `CombatContext`.
- No display-name branching inside shared systems: behaviour is selected by `behavior_id`, colour/VFX by
  `visual_profile`, audio by `audio_profile`.
- Shared Resources are never mutated at runtime (`ActorStats` already copies scalars — we keep it that way).
- One randomized map per match (existing `_change_map()` behaviour) is left as-is.

---

## 2. Data model (content layer)

### 2.1 New resources

| New file | Class | Purpose |
|---|---|---|
| `scripts/data/enemy_visual_profile.gd` | `EnemyVisualProfile` (plain `Resource`) | sheet path, frame size, pivot, action list + frame counts, tint, accent colour |
| `scripts/data/enemy_audio_profile.gd` | `EnemyAudioProfile` (plain `Resource`) | per-cue procedural tone parameters |
| `scripts/data/enemy_behavior_settings.gd` | `EnemyBehaviorSettings` (plain `Resource`) | windup/recovery/range/radius/telegraph/prime/lunge numbers |

All three are **plain Resources on purpose**: `ContentDefinition.references()` may only return
`ContentDefinition` instances, and `definition_copy()` deep-duplicates — a `Texture2D` field would be
duplicated as well. The visual profile therefore stores a **path string** that is `load()`ed lazily by the
visual node.

### 2.2 `EnemyDefinition` extension (`scripts/data/enemy_definition.gd`)

```gdscript
@export_group("Roster")
@export var min_match_seconds: float = 0.0     # unlock gate (match seconds)
@export var spawn_weight: float = 1.0           # relative weight once unlocked
@export var max_alive: int = 10                # concurrent cap for this type
@export_group("Scaling")
@export var hp_multiplier: float = 1.0         # x basic enemy
@export var move_speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export_group("Behaviour")
@export var behavior_id: StringName = &"chase_contact"
@export var behavior_settings: EnemyBehaviorSettings
@export var attack_skill: SkillDefinition      # ContentDefinition -> safe in references()
@export var visual_profile: EnemyVisualProfile
@export var audio_profile: EnemyAudioProfile
```

`references()` override returns `super.references() + [attack_skill]` (skill is a `ContentDefinition`, so the
registry graph stays valid). `validate()` gains: multipliers finite/positive, `max_alive >= 1`,
`min_match_seconds >= 0`, `behavior_settings != null`, `visual_profile != null`, `audio_profile != null`,
`attack_skill != null` **only when `behavior_id != &"chase_contact"`** (the legacy chaser keeps its existing
external skill to avoid changing shipped behaviour).

### 2.3 `SpawnDefinition` extension (`scripts/data/spawn_definition.gd`)

```gdscript
@export var base_spawn_rate: float = 0.7        # enemies/second at 00:00
@export var peak_spawn_rate: float = 2.2        # enemies/second at 12:00
@export var ramp_seconds: float = 720.0         # 12 minutes
@export var time_tier_seconds: Array[float] = []   # [0,120,240,360,540,720]
@export var time_tier_caps: Array[int] = []        # [45,55,70,85,95,110]
@export var difficulty_step_seconds: float = 180.0
@export var difficulty_step_bonus: float = 0.06
@export var max_difficulty_multiplier: float = 3.0
```

New static helpers in `EnemySpawnDirector`: `time_population_cap(definition, elapsed)`,
`spawn_rate(definition, elapsed)`, `difficulty_multiplier(definition, elapsed)`.
The existing level-based `population_cap()` is **kept** (boss-summon path and existing tests still use it).

### 2.4 New content files

```
content/enemies/bulwark.tres        content/enemies/bulwark_visual.tres      content/enemies/bulwark_audio.tres
content/enemies/skitter.tres        content/enemies/skitter_visual.tres      content/enemies/skitter_audio.tres
content/enemies/marksman.tres       content/enemies/marksman_visual.tres     content/enemies/marksman_audio.tres
content/enemies/ritualist.tres      content/enemies/ritualist_visual.tres    content/enemies/ritualist_audio.tres
content/enemies/bomber.tres         content/enemies/bomber_visual.tres       content/enemies/bomber_audio.tres
content/skills/enemy_bulwark_slam.tres
content/skills/enemy_skitter_lunge.tres
content/skills/enemy_marksman_shot.tres
content/skills/enemy_ritualist_rune.tres
content/skills/enemy_bomber_blast.tres
scenes/enemies/bulwark.tscn  skitter.tscn  marksman.tscn  ritualist.tscn  bomber.tscn
```

All 5 enemy definitions + 5 skills are added to `content/catalog.tres` (the visual/audio/behavior-settings
resources are *not* catalog entries; they are plain sub-resources of the definitions).

### 2.5 DEMO DEFAULT balance table (relative to the basic chaser: HP 35 / spd 110 / dmg 8 / xp 6)

| ID | Display | Archetype | Unlock | HP x | Spd x | Damage x | Concrete HP / Spd / Dmg | XP | max_alive |
|---|---|---|---|---:|---:|---:|---|---:|---:|
| `enemy.chaser` | Chaser | basic melee | 00:00 | 1.00 | 1.00 | 1.00 | 35 / 110 / 8.0 | 6 | (global) |
| `enemy.bulwark` | Iron Bulwark | slow tank | 02:00 | 4.00 | 0.50 | 1.80 | 140 / 55 / 14.4 | 18 | 6 |
| `enemy.skitter` | Razor Skitter | fast melee | 04:00 | 0.55 | 1.80 | 0.70 | 19.25 / 198 / 5.6 | 4 | 25 |
| `enemy.marksman` | Hollow Marksman | ranged single | 06:00 | 1.10 | 0.85 | 0.90 | 38.5 / 93.5 / 7.2 | 9 | 12 |
| `enemy.ritualist` | Cinder Ritualist | ranged AoE | 09:00 | 1.45 | 0.70 | 1.25 | 50.75 / 77 / 10.0 | 12 | 6 |
| `enemy.bomber` | Volatile Husk | proximity bomb | 12:00 | 0.85 | 1.15 | 1.60 | 29.75 / 126.5 / 12.8 | 10 | 10 |

Spawn weights / global caps follow AGENTS.md §3.1 exactly (Basic 100 → … → Basic 38 / Bulwark 14 / Skitter 20 /
Marksman 13 / Ritualist 8 / Bomber 7; global cap 45 → 110). Weights are **relative**, normalised at roll time.

---

## 3. Runtime architecture (new files)

```
scripts/enemies/enemy_behavior.gd                  # base class + context struct
scripts/enemies/enemy_behavior_registry.gd         # behavior_id -> factory (no display-name branching)
scripts/enemies/behaviors/chase_contact_behavior.gd    # legacy basic enemy (exact current behaviour)
scripts/enemies/behaviors/chase_slam_behavior.gd        # E1 Bulwark
scripts/enemies/behaviors/lunge_melee_behavior.gd       # E2 Skitter
scripts/enemies/behaviors/kite_shoot_behavior.gd        # E3 Marksman
scripts/enemies/behaviors/telegraph_aoe_behavior.gd    # E4 Ritualist
scripts/enemies/behaviors/proximity_bomb_behavior.gd   # E5 Bomber
scripts/enemies/enemy_encounter_director.gd        # weighted roster scheduler + caps (host/offline agnostic)
scripts/enemies/enemy_roster_spawner.gd            # applies "spawn decisions" to the scene
scripts/enemies/enemy_telegraph.gd                 # archetype-coloured telegraph (distinct from BossTelegraph)
scripts/enemies/enemy_audio_service.gd              # pooled spatial voices, procedural SFX, polyphony caps
scripts/enemies/enemy_match_clock.gd                # PROCESS_MODE_ALWAYS match clock (offline authority)
scripts/ui/enemy_pixel_effect.gd                    # new "enemy_pixel" VFX renderer
```

Multiplayer-only (optional layer):

```
multiplayer/net/encounter_authority.gd             # host: owns the director, publishes decisions
```

### 3.1 Behaviour contract

```gdscript
class_name EnemyBehavior extends RefCounted
var actor: EnemyActor
var combat: CombatService
var navigation: Callable
func setup(actor: EnemyActor, combat: CombatService) -> void
func tick(delta: float) -> void        # state machine, timers, attack resolution
func steering() -> Vector2             # movement direction for this frame
func desired_range() -> float          # distance the archetype wants to hold
func on_interrupted() -> void          # death / stun -> fade out any telegraph
```

`EnemyActor._physics_process` is refactored to delegate steering + timing to `behavior` when present and to
keep the **exact current code path** when `behavior_id == &"chase_contact"` (so the basic enemy is provably
unchanged — `EN_REG_01`).

Attack resolution always goes through `CombatService`:
`combat.next_context(actor, skill_id)` → `combat.hit(...)` / `combat.radial_hit(...)` /
`combat.spawn_projectile(...)`, giving every hit a `root_cast_id`, `event_id` and a faction check.

### 3.2 Encounter director contract

```gdscript
class_name EnemyEncounterDirector extends RefCounted
func configure(registry, state: RunState, spawn_config: SpawnDefinition) -> void
func reset() -> void
func advance(delta: float) -> Array[Dictionary]   # returns spawn DECISIONS (not nodes)
func eligible(elapsed: float) -> Array[EnemyDefinition]
func roll_type(elapsed: float, alive_by_type: Dictionary) -> StringName
func note_spawned(type_id: StringName) -> void
func note_removed(type_id: StringName) -> void
```

- **Decision-only.** It never touches the scene tree → the host can serialise decisions and the offline path
  can apply them locally. This is what makes replication an *optional* layer.
- Spawn rate: `lerp(0.7, 2.2, clamp(elapsed/720))` enemies/second, consumed by a **budget accumulator**
  (no burst on tier change).
- Weighted roll over eligible types, honouring `max_alive` per type and the time-tier global cap.
- Bounded retry: if a type is at cap, roll an alternative among eligible types (max 3 retries), else skip.
- Deterministic: uses `state.rng.stream(&"encounter")`.

### 3.3 Spawner contract

```gdscript
class_name EnemyRosterSpawner extends Node
func apply_decision(decision: Dictionary) -> EnemyActor   # {type_id, position, spawn_seq, run_id}
func spawn(type_id: StringName, position: Vector2) -> EnemyActor
```

The spawner owns: scene instantiation, per-archetype stat scaling
(`hp_multiplier`, `move_speed_multiplier`, `damage_multiplier` × time difficulty multiplier),
behaviour setup, visual/audio profile wiring, target assignment, and the death → XP orb path (reusing the
existing `_on_enemy_died` logic so EXP drops are unchanged).

Safe-spawn rules (per type, in addition to the existing checks):
- ≥ 1.5 × the archetype's AoE radius away from every living player (bomber: ≥ 1.5 × 110 = 165 px);
- not inside an obstacle, not in a hazard, on a navigable cell;
- ≥ 32 px from other actors, never on top of a boss;
- **never** spawned already-primed / already inside its own trigger radius.

---

## 4. Step-by-step execution phases

### Phase 0 — Baseline & guardrails (no behaviour change)
1. `git status` baseline snapshot; confirm the tree is clean apart from the known uncommitted menu/hub work.
2. Run the full test runner and record the baseline: **48 suites / 1 known failure**
   (`test_fullscreen_attack_aim` — pre-existing `window/size/mode=2` vs expected `3`; owner preference, not a
   regression).
3. Re-run `--headless --editor --quit --path .` import to confirm a clean import.
4. Record a "no-change" proof for the basic enemy: a scripted 60 s solo run that logs spawn counts, kills and
   boss timings to compare after the refactor.

**Exit:** baseline numbers recorded in `docs/WORK_LOG.md`.

### Phase 1 — Data model + content plumbing
1. Create the three new Resource classes (§2.1) with `validate()`.
2. Extend `EnemyDefinition` + `SpawnDefinition` (§2.2, §2.3).
3. Create the 5 `.tres` enemy definitions, their visual/audio/behavior resources and the 5 skill resources.
4. Register the 5 enemies + 5 skills in `content/catalog.tres`.
5. `CombatRunRoot._ready()` already aborts on `registry.validate_all()` errors → this phase proves the graph.

**Exit:** `ContentRegistry.validate_all()` empty; `enemy.bulwark`…`enemy.bomber` resolvable via
`definition_copy()`. **Test:** `EN_REG_01` (content graph intact), new unit suite `test_enemy_content.gd`.

### Phase 2 — Match clock + encounter director (offline, no enemies yet)
1. `scripts/enemies/enemy_match_clock.gd`: `PROCESS_MODE_ALWAYS`, accumulates into
   `RunState.elapsed_match_seconds` only while `state.alive` and `run_phase ∈ {RUNNING, UPGRADE, TRANSITIONING}`;
   frozen in `PAUSED`/`DEAD`/`RESTARTING`; `reset()` on run start.
2. `scripts/enemies/enemy_encounter_director.gd` (decision-only, §3.2).
3. `EnemySpawnDirector.time_population_cap()`, `spawn_rate()`, `difficulty_multiplier()`.
4. Unit-testable seams: the director takes an injected clock value, so tests can drive 0 s / 119 s / 120 s /
   720 s without waiting.

**Exit:** `EN_TIME_01`…`EN_TIME_06`, `EN_TIME_08` pass against the director in isolation.

### Phase 3 — Spawner + integration into the solo run root
1. `scripts/enemies/enemy_roster_spawner.gd`; per-archetype stat scaling; safe spawn validation
   (per-type safe radius, boss exclusion, trigger-radius rule).
2. `CombatRunRoot`: replace the hardcoded chaser spawn with
   `director.advance(delta) -> decisions -> spawner.apply_decision(decision)`.
3. Keep the **existing** chaser path bit-identical when only the basic enemy is eligible (it always is, weight
   100 at 00:00 → first tier is Basic 100, so 00:00–01:59 behaviour must be unchanged).
4. Boss summon path (`boss.summon_requested` → `spawn_enemy()`) keeps using the basic enemy + the level-based
   cap, unchanged.
5. `spawn_enemy()` becomes a thin wrapper over the spawner (no other call site breaks).

**Exit:** a 3-minute offline run shows only chasers before 02:00 and Bulwarks appear at 02:00.
**Tests:** `EN_TIME_01`…`EN_TIME_08`, `EN_REG_01`.

### Phase 4 — Behaviour framework + E1 Iron Bulwark (vertical slice)
1. `EnemyBehavior` base + `EnemyBehaviorRegistry` (id → script; no display-name special-casing).
2. `chase_contact_behavior.gd` = the current chaser logic verbatim (regression guard).
3. `chase_slam_behavior.gd` (E1):
   - chase nearest living player via the shared flow field; retarget every 0.75 s;
   - inside range → **0.55 s wind-up** (telegraph footprint drawn on the ground, exact hit radius = collider
     radius), then **one** slam (1.8× baseline damage), then **1.7 s** recovery;
   - interruptible: death during wind-up cancels the slam and fades the telegraph.
4. `EnemyTelegraph` (`scripts/enemies/enemy_telegraph.gd`): circle/cone shapes with **per-archetype colour and
   shape**, drawn above cosmetic VFX (`z_index = 20`, same rule as `BossTelegraph`) and **distinct from the
   boss orange telegraph**.
5. Bulwark VFX: ember-orange cracks in the armour (drawn by the profile-driven visual), ground dust ring +
   short-lived fractured-earth decal on impact.
6. Bulwark SFX: low armour clank on steps, rising rocky scrape on wind-up, dry bass impact + pebble rattle,
   heavy collapse on death — pooled spatial voices, no bass stacking (cap 3 concurrent Bulwark impacts).
7. Sprite sheet `assets/art_v3/world/enemy_bulwark.png` generated in-project (see §5).

**Exit:** `EN_AI_01` (visibly slower, survives more hits, slam resolves only after the telegraph),
`EN_VFX_01` (bulwark), `EN_SFX_01` (bulwark), `EN_REG_01`.

### Phase 5 — E2 Razor Skitter
- 0.22 s lunge after entering pre-attack range (displacement clamped, collision-checked with
  `Actor.test_move`), single strike, 1.2 s cooldown, 0.70× damage, 0.55× HP, 1.80× speed.
- Cyan/teal speed streaks along the dash trajectory + 1–2 pooled afterimages (visual only — **never** extra
  hitboxes).
- High-pitched scratchy footfalls, positional whoosh, sharp claw tick, dry squeal on death; crowd-spawn
  polyphony cap.

**Exit:** `EN_AI_02` (faster, lower HP, lunge respects walls, exactly one damage application).

### Phase 6 — E3 Hollow Marksman
- Standoff radius; retreat/sidestep with bounded pathing when the player closes (never teleport).
- 2.2 s cycle → **0.4 s aim** (violet reticle/aim line) → one authoritative projectile
  (speed ≈ 1.5× basic enemy move speed = 165 px/s, wall collision, one hit max).
- Max engagement distance + line-of-sight check; if blocked, reposition instead of shooting through walls.
- Violet/magenta projectile core + trail, distinct from player shots; metallic aim click, arcane rifle crack,
  zipping projectile, crisp light hit spark.

**Exit:** `EN_AI_03` (one authoritative projectile, walls block, retreat works, misses deal no damage).

### Phase 7 — E4 Cinder Ritualist
- Maintains distance; picks a **ground position snapshot near a valid player** at cast time (the telegraph
  never homes afterwards); 1.25 s circle telegraph; AoE 1.25× baseline at expiry; 5.0 s cooldown.
- Each eligible player hit **once per cast** (faction filter via `CombatService.radial_hit` + an id set).
- Centre may not be placed inside an impassable cell (`arena.navigable`).
- Tall caster silhouette, amber/red inscribed rune circle filling clockwise, central spark/flame pillar, scorch
  decal fade; reverse inhale + rune chimes + punchy flame burst.
- Distance-scaled volume (not per-hit-count scaling).

**Exit:** `EN_AI_04` (lock at cast, radius == hitbox, one hit per target).

### Phase 8 — E5 Volatile Husk
- Chase; inside the trigger radius → **PRIMING** for 0.8 s (movement stopped, accelerating beep/whine,
  expanding dashed lime-yellow danger ring of the exact AoE radius) → **one** explosion (1.6× baseline) that
  damages each living player in range **once**, then the enemy leaves via the normal death lifecycle
  (**no** repeated detonation, **no** duplicate XP).
- Killed before the charge completes → **no explosion** (extinguish hiss instead of a blast).
- Never spawned already inside a player's trigger radius (grace period after spawn).
- Enemies/allies are never damaged by the blast.

**Exit:** `EN_AI_05` (pre-explosion death cancels, one application, no self-respawn).

### Phase 9 — Shared integration passes
1. `EN_AI_06`: all five die to each hero's basic/skills/augments and drop XP through the existing
   `XpOrb` path (no double XP for the bomber's self-removal).
2. `EN_AI_07`: replaying `attack_resolved`/damage events does not duplicate hits, XP or explosions (idempotence
   key per cast).
3. `EN_AI_08`: the revive channel (F) still disables attacks/casts for the reviver while enemies may still
   target and damage them.
4. `EN_REG_01`: basic enemy, boss timer, map rotation, personal EXP/level, auto/manual skills, augment
   selection and revival all still work.

### Phase 10 — Art & audio pipeline (production pass)
1. `tools/generate_enemy_sheets.py` (Pillow 12.3 available) generates 5 original sprite sheets:
   4 facings × 6 action blocks (idle 2, walk 4, wind-up 2, attack 2, hit 1, death 3), nearest-neighbour
   friendly, palette consistent with the existing enemy art, **distinct silhouettes** (wide armoured / small
   angular / long-barrel / tall caster / round unstable core).
   Provenance: **generated in-project, original** → recorded in `docs/ART_CHANGELOG.md`,
   `docs/art_asset_ledger.csv` and a per-sheet `manifest.json`.
2. `EnemyPixelVisual` becomes profile-driven (sheet path, frame size, feet pivot, action list, tint/accent) and
   supports the new action states; the legacy chaser keeps its current sheet and look byte-for-byte.
3. `EnemyAudioService`: pooled spatial voices (16), per-cue cooldown, per-archetype polyphony caps,
   procedural `AudioStreamWAV` generation (22050 Hz, 16-bit — same convention as `AudioFeedback.tone()`),
   headless-safe (no playback when `DisplayServer.get_name() == "headless"`).
4. `scripts/ui/enemy_pixel_effect.gd` + `assets/vfx/generated/enemy_<type>.json` manifests → the existing
   `CombatVisualFactory` pipeline gains an `enemy_pixel` renderer (dust ring + cracked earth / speed streaks /
   violet tracer / amber rune circle / lime shockwave). Gameplay telegraphs stay readable regardless of the
   VFX budget (`LIMIT = 80`).

**Exit:** `EN_VFX_01`, `EN_SFX_01`, `EN_REG_01`.

### Phase 11 — Multiplayer (optional authority layer)
1. `multiplayer/net/encounter_authority.gd` (host only):
   - owns an `EnemyEncounterDirector`;
   - publishes every decision as a reliable-ordered RPC
     (`run_id`, monotonic `spawn_seq`, `enemy_type_id`, `position`, `server_tick`, `visual_seed`);
   - clients **never** schedule enemies — they apply the received decisions through the same
     `EnemyRosterSpawner`.
2. Client side: `MultiplayerCombatRun` disables the local director when it is not the host
   (`authority_mode = HOST_ONLY` vs `LOCAL_OFFLINE`).
3. Attack telegraph replication: the host publishes `enemy_telegraph_started(enemy_id, kind, position, radius,
   duration)` and `enemy_attack_resolved(enemy_id, kind)`; clients render them locally and never derive damage
   from their own timing.
4. Late join / reconnect: `AuthoritativeWorld` snapshot is extended with the active roster (type + id + position)
   and the active telegraphs, so threat state is not lost. Duplicate instance ids are rejected by `run_id` +
   `spawn_seq`.
5. **Documented scope:** enemy *scheduling* becomes host-authoritative. Enemy *AI/damage resolution* still runs
   in the local `CombatRunRoot` on each peer (that is how multiplayer combat works in this repo today). This is
   recorded in `docs/MULTIPLAYER_IMPLEMENTATION.md` as an open item with the next step (server-side damage
   adjudication + client prediction/reconciliation).
6. **Offline guarantee:** if no session is active, `authority_mode = LOCAL_OFFLINE` and everything above is
   bypassed — the local instance is the authority.

**Exit:** `EN_NET_01`…`EN_NET_03` (as far as the current MP architecture allows), plus a **new**
`test_enemy_offline.gd` proving a full offline run with zero network nodes.

### Phase 12 — Performance profiling + tuning
1. Late-game scenario: 4-player host at the 12:00+ tier (cap 110 normal enemies + boss), measure host frame
   time, AI time, live enemy/projectile counts, bandwidth, active audio voices.
2. Optimise as needed: throttled retargeting (0.5–1.0 s), no per-frame O(N²) scans, pooled telegraph/VFX
   objects, audio polyphony caps, `state.rng.stream()`-separated streams so the roster RNG never perturbs
   combat RNG.
3. Tune the normal-enemy caps only. **The boss schedule is never touched** (§1.1).

**Exit:** `EN_PERF_01` with recorded numbers; caps adjusted (never the boss cadence).

### Phase 13 — Docs + final report
- `docs/04_TASKS.md` — EN-* task rows; `docs/05_DECISIONS.md` — the assumptions in §1;
  `docs/BALANCE_LOG.md` — the DEMO DEFAULT table + what was tuned; `docs/ART_CHANGELOG.md` +
  `docs/art_asset_ledger.csv` — provenance of the generated sheets; `docs/WORK_LOG.md` — chronological log;
  `docs/06_ENEMY_ROSTER_PLAN.md` — this plan (kept, updated with the as-built deltas).
- Final **text-only** report per AGENTS.md §9: Implemented / assets+provenance / unlock timeline /
  files changed / test commands+results / 2- and 4-player networking result / late-game metrics /
  known issues + balancing knobs. Everything not executed is labelled **NOT TESTED**.

---

## 5. Art generation spec (original, in-project)

- Tool: `tools/generate_enemy_sheets.py` (Python 3.14 + Pillow 12.3, already present in this environment).
- Output: `assets/art_v3/world/enemy_<type>.png`, 4 facings × 6 action blocks, cell size per archetype:
  bulwark 40×44, skitter 24×28, marksman 32×44, ritualist 28×48, bomber 32×36. Pivot = feet.
- Palette is derived from the existing enemy/terrain palette so density and contrast match; silhouettes are
  deliberately different per archetype (readable in grayscale).
- Provenance: **100 % original, generated inside this repository** — no third-party sprite packs, no M.U.G.E.N
  or anime assets. Recorded in the asset ledger with filename, origin, licence (project-owned) and attribution
  ("generated in-project").
- Import: nearest-neighbour filter, `assets/art_v3/world/*.png.import` regenerated by the headless import.

---

## 6. Test plan (suite → AGENTS.md IDs)

| New suite | IDs | What it proves |
|---|---|---|
| `tests/integration/test_enemy_content.gd` | EN_REG_01 (part) | content graph validates; all 5 archetypes registered with unique ids |
| `tests/integration/test_enemy_roster.gd` | EN_TIME_01…08 | unlock gates, cumulative eligibility, weights (deterministic seed, eligibility assertions — not exact random counts), caps, no scheduling outside RUNNING, reset once, safe spawn, no infinite loops / RPC flood |
| `tests/integration/test_enemy_behaviors.gd` | EN_AI_01…08 | per-archetype combat correctness, one-hit rules, telegraph/collider match, idempotence, revive lockout |
| `tests/integration/test_enemy_visuals.gd` | EN_VFX_01 | distinct sheets/actions/pivots/hazard colours per archetype; chaser unchanged |
| `tests/integration/test_enemy_audio.gd` | EN_SFX_01 | distinct cue sets per archetype, polyphony cap, no sound after despawn |
| `tests/integration/test_enemy_offline.gd` | (new, offline mandate) | a complete offline run with **no** network session: all five types spawn, damage, die, drop XP; exiting stops spawning and resets the encounter state |
| `tests/integration/test_enemy_net.gd` | EN_NET_01…03 | host publishes decisions; clients apply them and never schedule; late-join snapshot; duplicate ids rejected |

Registration: all new suites appended to `tests/run_all.gd` (each suite is its own Godot process).
Baseline gate: the runner must stay at **48 + N suites / 1 known failure** (`test_fullscreen_attack_aim`).

Commands:

```
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --editor --quit --path .
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_all.gd
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/integration/test_enemy_roster.gd
```

---

## 7. Risk register / open items

| Risk | Mitigation |
|---|---|
| Refactoring `EnemyActor` breaks the basic enemy | `chase_contact_behavior` reproduces the current code path verbatim; `EN_REG_01` + a baseline comparison run |
| `ContentDefinition.references()` rejects non-ContentDefinition | visual/audio/behavior settings are plain Resources, **not** in `references()`; only the `SkillDefinition` is referenced |
| `definition_copy()` deep-duplicates textures | the visual profile stores a **path string**, loaded lazily |
| Augment selection pauses the tree → roster clock stalls | `PROCESS_MODE_ALWAYS` clock node; `elapsed_match_seconds` keeps counting during `UPGRADE` |
| 110 enemies at 60 Hz | throttled retargeting, pooled VFX, capped voices, per-type caps, time-tier global cap |
| Bomber exploding on its own death event (double XP / double blast) | single `exploded` flag per bomber + `cast_id` idempotence; death path never re-fires the blast |
| Telegraph/collider mismatch under lag | telegraph radius is read from the same `EnemyBehaviorSettings` value used by the hit test |
| MP conversion scope | scheduling becomes host-authoritative; full server-side damage adjudication is documented as the next milestone (matches the repo's current MP architecture) |

## 8. Definition of Done (checklist)

- [ ] Five archetypes registered, unlocked at 02:00 / 04:00 / 06:00 / 09:00 / 12:00, cumulative.
- [ ] Distinct silhouettes, action sets, VFX and SFX per archetype (not recolours of the chaser).
- [ ] Weighted roster with per-type + global caps, safe spawns, seeded RNG.
- [ ] Boss schedule **unchanged**; basic enemy behaviour unchanged.
- [ ] Offline run works with **no** network session; exiting resets the encounter state.
- [ ] Multiplayer: host schedules, clients apply; no client-side scheduling.
- [ ] All EN_* suites executed; results reported verbatim, NOT TESTED items labelled.
- [ ] Text-only final report; no screenshots/videos as deliverables.
