# 01 — CORE ARCHITECTURE
**Endless Survival RPG · Implementation-ready technical contract · v1.0 · 2026-10-15**

> Normative language: **MUST** = bắt buộc; **SHOULD** = mặc định tuân theo, ngoại lệ cần ghi lý do; **MAY** = tùy chọn. `LOCKED` = được người dùng chốt, `DEMO DEFAULT` = giả định được chọn để AI Agent có thể làm việc, không phải quyết định của người dùng. Tham khảo `05_DECISIONS.md`.

## 0. Product contract and boundaries
- Game 2D top-down action roguelite survival, chạy trên Windows với **Godot 4.x stable + GDScript**, architecture exportable to browser later (không dùng C#). PC keyboard-first; single player offline.
- 3 playable prototype characters: **Astra/Mage**, **Vex/ADC**, **Boros/Brute**; tên, tạo hình là placeholder nguyên bản; **không dùng Riot game assets, names, animations, UI, audio**.
- WASD movement, basic attack automatically selects nearest eligible enemy **within attack range**, action skill hotkeys J/K/L/I by default, customizable, Auto/Manual mode user-selectable.
- Skills unlock at player levels 3/6/9/11 for slots 1/2/3/4. Skill max ranks 4/4/4/3 **including initial unlock**. Unlocks free; level-up offer still happens.
- Every normal player level: show **three distinct, valid upgrade options**, select one. Stat cores repeat indefinitely; passive mechanic cores max 5 ranks (unless catalog explicitly says 4); Signature one rank; skill rank capped. Boss spawns at player 10/20/30/... and unlocks next map transition on defeat.
- Architecture goal: **one mechanic implementation across all compatible characters**. A directional skill is *not necessarily* a splittable projectile. Augment eligibility requires capabilities backed by real runtime interfaces, not only tags.
- Demo proves three characters, boss at 10/20 (minimum one boss archetype, second variant preferable), maps cycling, augment combinations, and eventual stable endless loop. Target first playable vertical slice Astra 1–10.

## 1. Architectural invariants — NON-NEGOTIABLE
1. NO character-name or character-id branching inside shared combat/augment executors. Character-specific behavior resides in data resources or bounded custom components.
2. NO mutable runtime state in shared `Resource` definitions. Instantiate `SkillRuntime`, `AugmentRuntime`, `StatRuntime`, `RunState` per run/actor.
3. NO direct writes to `SkillDefinition` after load. Augments write modifier registry/runtime, never definition files.
4. NO separate player/enemy damage formulas; use the same `DamageResolver` with faction/team and target defense.
5. NO augment activation without eligibility check. Capabilities must correspond to concrete supported executor operations; fail closed.
6. NO implicit augmentation recursion. Spawn/cast events carry origin, depth, trigger policy and budgets.
7. NO singletons as dumping ground. Godot autoload only for `AppSettings`, `ContentRegistry`, optionally `SceneRouter`; per-run systems belong to `RunRoot`.
8. NO game simulation performed in UI components; UI reacts to events and dispatches typed commands.
9. MUST persist keybinds/settings separately from run data. Save/load run optional for demo.
10. MUST provide automated tests for every shared mechanic across at least 2 compatible actors and 1 incompatible case; stable deterministic test seeds.
11. MUST keep content IDs stable (`character.astra`, `skill.astra.j`, `augment.projectile_split`, etc.) even if display name changes.
12. MUST document additions and changes in decision log, and update automated tests alongside contract changes.

## 2. Proposed Godot project tree
```text
project.godot
assets/{sprites,vfx,ui,sfx,music}/
scenes/{bootstrap,menus,run,arena,characters,enemies,bosses,projectiles,fx,ui}/
scripts/
  app/{settings,content_registry,scene_router}.gd
  core/{ids,rng,game_clock,event_bus,combat_context,spawn_context}.gd
  data/{character_definition,skill_definition,augment_definition,
        projectile_definition,enemy_definition,boss_definition,map_definition,
        upgrade_offer_definition,stat_curve}.gd
  actors/{actor,player_actor,enemy_actor,actor_stats,health,status_controller,
          target_sensor,movement_controller}.gd
  combat/{attack_controller,skill_controller,skill_runtime,skill_executor,
          targeting_service,damage_resolver,hit_resolver,projectile_manager,
          status_effect_resolver,cooldown_clock}.gd
  augments/{augment_manager,augment_runtime,eligibility_evaluator,
            modifier_registry,offer_generator,augment_effect,
            effects/{stat_modifier,projectile_split,multishot,pierce,
              echo_cast,area_expand,shield_reflect,explosion_on_hit}}.gd
  progression/{xp_orb,xp_manager,level_manager,boss_gate}.gd
  world/{map_manager,arena_generator,obstacle_validator,enemy_spawn_director,
          spawn_zone_validator}.gd
  ui/{hud,upgrade_picker,keybind_screen,pause_menu,run_summary}.gd
content/{characters,skills,augments,enemies,bosses,maps,progression}/
tests/{unit,integration,scenes,fixtures}/
docs/{01_CORE_ARCHITECTURE.md,02_GAMEPLAY_SPEC.md,03_AGENTS.md,
      04_TASKS.md,05_DECISIONS.md}
```
Use `.gd` and `.tres` names consistent with project idiom. `README.md` must explain Godot version, how to launch, run tests, and export constraints. Paths may be adapted only by recording mapping in decisions.

## 3. Module responsibility and ownership
| Module | Owns | MUST NOT own |
|---|---|---|
| `RunRoot` | start/end run, wiring subsystem dependencies, phase state | individual damage math |
| `PlayerActor` | physical body, actor signals, player state | implementation of individual augment |
| `InputController` | raw keys/mouse + settings bindings | damage, cooldown, targeting algorithm |
| `TargetingService` | nearest in-range valid target, optional line-of-sight, tie break | attack resolution |
| `SkillController` | slots, unlocks, mode, cooldown, request to cast | hard-coded per-character upgrade choices |
| `SkillExecutor` | apply target selection, create effect/projectile/AOE/shield | checking user input |
| `AugmentManager` | equipped augmented effects and per-skill bindings | manually mutating shared resource assets |
| `EligibilityEvaluator` | validity and reason diagnostics | hidden RNG |
| `ModifierRegistry` | deterministic composition of numeric and behavioral modifiers | UI |
| `CombatEventBus` | typed event dispatch | recursive, unbounded event loops |
| `DamageResolver` | damage pipeline, resistance and crit | visual effects |
| `LevelManager` | EXP thresholds, pending XP, level transactions | boss AI |
| `BossGate` | threshold trigger and release, suppress concurrent transitions | enemy spawn location |
| `MapManager` | selection, persistent map phase, transition | character progression reset |
| `SpawnDirector` | pacing/caps and valid spawn candidates | moving player to accommodate spawn |
| `ContentRegistry` | indexed immutable content definitions, validation | scene-specific mutable state |

## 4. Data and type contracts
Suggested typed `Resource` contracts:
```gdscript
class_name CharacterDefinition extends Resource
@export var id: StringName
@export var display_name: String
@export var class_id: StringName
@export var base_stats: ActorStatDefinition
@export var basic_attack: SkillDefinition
@export var active_skills: Array[SkillDefinition] # exact 4 slots J K L I

class_name SkillDefinition extends Resource
@export var id: StringName
@export var unlock_level: int
@export var max_rank: int
@export var tags: Array[StringName]
@export var declared_capabilities: Array[StringName]
@export var executor: SkillExecutorDefinition
@export var targeting: TargetingDefinition
@export var rank_scaling: Array[SkillRankDefinition]

class_name AugmentDefinition extends Resource
@export var id: StringName
@export var max_rank: int
@export var scope: StringName # GLOBAL / CLASS_WEIGHTED / SKILL_TARGETED / SIGNATURE
@export var requirements: RequirementDefinition
@export var effects: Array[AugmentEffectDefinition]
@export var rarity_weight: float
```
Above is a contract sketch; implementation can use actual Godot typed resources split into files. `CharacterDefinition` is shared immutable content; `SkillRuntime` includes owner actor id, rank, cooldown state, chosen augments, targeting policy. Each definition enforces globally unique IDs, no cyclic content references, non-negative cooldown and sensible max-rank. `ContentRegistry.validate_all()` must surface actionable errors early on launch.

### Runtime state model
```text
RunState(seed, elapsed_simulation_seconds, current_level, current_xp,
         xp_pending_during_boss, stage_index, map_id, boss_gate_state,
         run_upgrades, alive, run_phase)
ActorRuntime(id, faction, position, health, stats, statuses, team)
SkillRuntime(definition_id, owner_id, rank, cooldown_left,
             chosen_augment_ids, cast_sequence_number)
AugmentRuntime(augment_id, rank, target_skill_id?, cooldown/proc state)
```
Use entity IDs or `WeakRef`/instance-id checked for validity; projectiles cannot assume target remains alive after a timer. Do not serialize Node object references.

## 5. Capability model and execution validation
A skill has descriptive `tags` (`damage`, `magic`, `physical`, `cc`, `directional`, `projectile`, `area`, `shield`, `dash`, `channeled`) and executable `capabilities` (`spawn_projectile_pattern`, `modify_projectile_count`, `modify_projectile_angle`, `pierce_hit`, `repeat_cast`, `resize_area`, `modify_shield`, `apply_status`, `on_hit_hook`, `on_kill_hook`). **No compatibility based on `directional` alone.**

- Capability derived from or validated against executor/effect graph at load. If `ProjectileSplit` requests projectile pattern but executor is beam/raycast without adapter, it is ineligible.
- Eligibility pipeline: content loaded → requirements checked → unlocked/owned skill checked → capability check → augment below rank cap → exclusion/synergy requirements → offer candidate.
- If a skill has multiple compatible targets, represent different **bound options** in pool, e.g. `projectile_split@skill.astra.j` and `projectile_split@skill.astra.l`. Each card names target; a no-choice ambiguity is prohibited.
- Rank attached to `(augment_id, target_skill_id)` for targeted augments, not simply augment ID. Global augments rank attached to `(augment_id, null)`.
- Class should generally weight rarity, not hard-gate generic capability augments. Signature requires exact character ID by explicit content policy.

## 6. Ordered combat pipeline
`input/auto intent → validate actor/state/mode → select or verify target → cooldown/resources → OnCastRequested → PreCast modifier snapshot → target geometry → projectile/effect pattern → OnSkillCast (once per root cast) → spawn effects → movement/collision → ResolveHit → DamageResolver → statuses → OnHit/OnCrit/OnKill → post-hit/passive effects → visuals`.

**Damage computation demo:** raw = ability base + stat scaling; apply additive damage bonuses; then grouped multiplicative bonuses; crit if eligible; target mitigation; clamp to >= 0; shield absorbs first; remainder reduces HP; record applied damage; compute lethal kill exactly once. Use deterministic rounding (`roundi` only at display boundary) and document damage type/resistance in gameplay spec. No direct `hp -= raw` outside resolver.

### Event envelope and safety
```text
CombatContext {
  root_cast_id, event_id, owner_actor_id, source_skill_id,
  source_augment_id?, parent_event_id?, generation_depth,
  proc_budget_remaining, tags, flags[is_secondary, can_trigger_on_hit,
  can_trigger_on_kill, is_echo], rng_stream_id
}
```
- Events MUST be dispatchable without emitting a nested infinitely recursing chain. `MAX_CHAIN_DEPTH=3`, `MAX_SECONDARY_PROCS_PER_ROOT=32`, `MAX_PROJECTILES_PER_ROOT_CAST=64` are **DEMO DEFAULTS**, tune through config.
- `PRIMARY_ONLY` effects ignore secondary generated events; `ONCE_PER_ROOT_CAST` uses root cast dedupe key; `ALLOW_SECONDARY` consumes proc budget. Status effects cannot trigger damage recursively unless explicitly whitelisted.
- Modifier order deterministic: base → flat additions → percent additions (within same category sum) → multiplicative categories in ordered order → caps → final clamp. No modifier application by arbitrary signal subscription order.
- Each collision carries `(root_cast_id, projectile_id, target_id)` so pierce, explosion and on-hit deduping can be implemented.

## 7. RNG / determinism / optimization
One run seed; derive independent RNG streams for maps, obstacles, spawns, offers, combat procs; no calls to global random inside tested systems. Serialize seed in run summary. Offer-generation and map layouts deterministic given seed, player state, and content version. Avoid frame-rate-driven proc frequencies; use delta simulation and fixed physics update. Object pooling recommended for projectiles, XP orbs, hit VFX; cap world actors/projectiles and degrade gracefully when budgets reached. Use collision layers and groups (`player`, `enemies`, `obstacles`, `xp_orbs`), but actual targeting only validated by team, health, spatial query.

## 8. Auto/manual contract and keybinds
- WASD movement; J/K/L/I active slots; menu/pause Esc; configurable remap persisted to `user://settings.cfg` using `InputMap` and config settings.
- `SkillController.request_cast(slot, target_override=null)` shared public entrypoint; Auto planner submits request when ready, Manual handler submits requests on key pressed. Both pass through same validation/cast pipeline.
- Auto targeting picks nearest valid target within skill-specific acquisition radius, stable tie-break by actor ID. AoE targets point near nearest eligible enemy. Dash needs explicit fallback (toward enemy, or movement direction if no enemy). If no target: do not cast target-dependent attacks. Defensive buffs can auto-cast on condition, default when enemy within threat radius, configurable.
- Manual directional skills use mouse aim if mouse position is available; when absent use nearest enemy direction; no automatic cast on skill cooldown in manual mode. UI shows mode and key mappings.
- Basic attack ALWAYS auto, irrespective of skill mode.

## 9. Level-up and encounter transaction semantics
- XP orb collision triggers one collection and optional magnetization; LevelManager loops threshold checks without skipping pending levels.
- At levels 3/6/9/11: unlock designated skill rank 1, then present one 3-choice upgrade offer. If same-level upgrade can target freshly unlocked skill, yes.
- During offer: **pause combat simulation** (`get_tree().paused` with UI process mode Always or domain pause controller). Never let an enemy damage player behind a modal.
- Boss trigger at exact level divisible by 10. On reaching: first resolve level-up upgrade (including queued offers), then activate BossGate. No second boss until defeated. During boss, newly collected XP is banked; player level may be held at threshold until boss cleared. On victory: map transition, restore/preserve actor state per gameplay spec, settle banked XP one level at a time, including offers; prevent next boss trigger before queue fully drained and world stabilized.
- If dead at same frame as level-up, death takes precedence before new offer; victory only if boss defeated and player alive. Test frame-order race.

## 10. Map and enemy spawn correctness
Map template has bounds, player-safe spawn anchors, obstacle placement zones, spawn candidate zones, hazard zones, navigation connectivity. Obstacle generator samples seeded, verifies: player initial position unblocked; minimum traversable path from actor to at least 2 escape routes; nav graph connected for ground enemies; spawn locations avoid obstacle intersection and player safety radius; boss arena keeps minimum viable free area. Fail candidate and reroll bounded N times, otherwise load safe authored fallback layout. Do not let obstacles create permanent traps around stationary boss or player.

## 11. Testing expectations (architecture)
- Unit: definitions validation, eligibility, rank caps, modifier stacking, repeated offers, trigger depths, damage, deterministic RNG.
- Integration: split augmented projectile works Astra J and Vex L, does not appear Boros J if not projectile-capable; max 64 projectile limit; no recursive explosions; Auto vs Manual same damage once cast; dynamic key remap persists after restart.
- Gameplay: lvl3/6/9/11 unlock; skill caps; boss triggers at 10 exactly once, bank XP, migrate next map without wiping upgrades; no spawn within forbidden radius, no unreachable enemies after obstacle generation.
- Performance: typical combat 100 simultaneous enemies / 300 projectiles at target ~60 FPS on reference midrange Windows PC is a **DEMO TARGET**, not hard guarantee. Log min/median frame time and profile spikes; platform hardware unspecified.
- Tests MUST run headless where possible (`godot --headless --path . --script ...`) and have an in-editor smoke-test run. If no third-party testing library installed, implement a simple native assert runner and exit code.

## 12. Dependency boundaries / extension recipes
To add new character: add CharacterDefinition, base stats, four SkillDefinitions, sprite/animations and target capabilities; register data; expected no changes to generic augment modules. To add augment: AugmentDefinition, reusable EffectDefinition/EffectRuntime (only if novel mechanic), requirements and tests against two compatible skills; no character edits. To add boss: boss/enemy data, state-driven attack patterns, telegraphs, scene and tests; avoid per-boss changes to generic DamageResolver.

## 13. Forbidden shortcuts and PR rejection conditions
Reject changes that: embed `if character_name ==` branches in augment engine; mutate `.tres` definitions during run; add random within deterministic system outside RNG service; emit unbounded OnHit events; advertise incompatible augments; allow 3 identical offer options; count boss killed without actual encounter; fake screenshots/tests; swallow errors; add non-free asset dependencies without approval; use LoL/Riot characters/assets.

## 14. Exit criterion (architecture ready)
- Can author data-only new projectile skill and apply already implemented generic split/pierce/echo without code changes.
- One full run plays on Windows from selection → fight → EXP → 3-choice level-up → boss → map transition → death summary for each of 3 characters.
- All automated acceptance checks in `04_TASKS.md` pass and documented manual steps verified.
