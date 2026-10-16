# 02 — GAMEPLAY SPECIFICATION
**Endless Survival RPG · Demo gameplay source of truth · v1.0**

> Values tagged `DEMO DEFAULT` are provisional balancing values deliberately filled in to unblock AI Agent. Do not silently reinterpret them as user-approved. Gameplay decisions listed as `LOCKED` in `05_DECISIONS.md` take precedence.

## 1. Game rules
Single-player top-down, one life/run, randomly selected map from pool; moving via WASD; Auto/Manual skills; basic attack automatically targets nearest enemy in range. Start character level 1 with basic attack. Unlock slots J at 3, K at 6, L at 9, I at 11; each non-ultimate rank cap 4, ultimate rank cap 3. Every level-up gets exactly one option among three unique, valid offers, with free skill unlocks at milestone levels. Stat cores can stack indefinitely; each mechanic passive has max 5 ranks by demo default. Boss at level 10,20,30,... and map changes only on boss defeat. Run ends at 0 HP; endless after demo milestone.

## 2. Controls
| Function | Default | Behavior |
|---|---|---|
| Move | W/A/S/D | normalized diagonal vector, speed unaffected by FPS |
| Active 1 | J | manual cast skill 1 |
| Active 2 | K | manual cast skill 2 |
| Active 3 | L | manual cast skill 3 |
| Ultimate | I | manual cast skill 4 |
| Aim | Mouse | manual directional aim at cursor; fallback toward nearest enemy |
| Switch mode | UI toggle (demo) | applies to active slots; basic always auto |
| Pause | Esc | pause menu, settings and key mapping |

No input binding may collide with another gameplay action in the same context without confirmation. Save control map persistently; validate restart.

## 3. Combat stats & definitions
Provisional base stats below are **DEMO DEFAULT** and can be edited in data resources, not hard-coded. Damage values are abstract game points.

| Stat | Astra (Mage) | Vex (ADC) | Boros (Brute) |
|---|---:|---:|---:|
| Max HP | 130 | 150 | 260 |
| Move speed px/s | 240 | 270 | 205 |
| Armor | 5 | 8 | 18 |
| Basic raw damage | 14 magic | 12 physical | 25 physical |
| Basic interval seconds | 0.82 | 0.38 | 0.95 |
| Basic range px | 420 | 490 | 85 |
| Base crit chance | 0.05 | 0.10 | 0.03 |
| Base crit multiplier | 1.5 | 1.5 | 1.5 |

- HP must be >0 to act. Damage types: PHYSICAL / MAGIC / TRUE. Simplified mitigation demo: `actual = raw * 100/(100+max(resistance, -50))` if resistance >= 0; for negative armor use `raw * (2-100/(100-resistance))`, clamp final multiplier [0.5, 2]. Alternative more robust agreed implementation allowed if documented consistently.
- Shields absorb post-mitigation damage before HP, consume in FIFO order; damage count and kill credit once. Basic attack may crit. Skill crit only when augment permits or explicitly tagged.
- Attack speed increases attacks per second, cooldown reduction separately affects active skills. Cooldown reduction cap 60% (`DEMO DEFAULT`). Attack frequency cap 6 attacks/sec; movement speed cap 550 px/s. Crit chance cap 100%, chance>=0. Crit multiplier minimum 1.0.
- General stat stacking: add percent bonuses in each category, then multiply by independent categorized effects; stat cores have diminishing returns through one category to avoid exponential runaway. UI must show effective not base stats.

## 4. Character skills and upgrade ranks
Rank 1 is unlocked automatically at required level. Rank 2+ acquired via `SkillRankUp` offer. Numerical values are DEMO DEFAULT; all of them must be exposed through `SkillRankDefinition`.

### Astra — Light Weaver / Mage
**Basic Light Bolt:** homing projectile to nearest in 420px, raw 14 MAGIC, speed 650px/s; projectile capability supports split/pierce unless its homing adapter explicitly excluded.

| Slot & unlock | Rank 1 | Rank 2 | Rank 3 | Rank 4 |
|---|---|---|---|---|
| J: Radiant Snare, Lv3 | CD 7s, 36 magic, 1.25s root, 620px range, 780px/s projectile | 44 dmg, 2 targets pierced | 54 dmg, 1.65s root | 65 dmg; trapped enemy death triggers 30 dmg 80px pulse |
| K: Prism Guard, Lv6 | CD 13s, shield 48 for 4s, +15% move speed for 3s | shield 68 | blocked hit produces 15 dmg close pulse with 1s internal CD | shield 95; expiration gives 45 dmg 110px blast |
| L: Solar Field, Lv9 | CD 9s, 160px diameter, 7 magic per 0.5s for 4s | diameter 200px | duration 5.5s | applies 10% slow; damage 10 per tick |
| I: Celestial Beam, Lv11 | CD 23s, 120 magic beam, 600px long, 75px wide | CD 20s, beam width 100px | leaves 3s line burn 12 dmg/0.5s | — |

J projectile splittable; L area resizable; I uses beam executor and **is not projectile-splittable** unless an adapter is deliberately added. Targeting manual J/I along cursor; L aimed 350px max at mouse position or enemy center; K self-cast.

### Vex — Gunslinger / ADC
**Basic Dual Shot:** auto shot nearest enemy in 490px, raw 12 physical, CD 0.38s, projectile 930px/s; supports projectile split/pierce (balance scale applies).

| Slot & unlock | Rank 1 | Rank 2 | Rank 3 | Rank 4 |
|---|---|---|---|---|
| J: Quick Barrage, Lv3 | CD 8s, 4 shots x 15 physical, spread 6°, 0.12s spacing | 5 shots | 6 shots, +10% crit chance | 7 shots; crit shots gain pierce 1 |
| K: Tactical Roll, Lv6 | CD 12s, dash 190px/0.28s, +20% attack speed for 3s | +30% attack speed | next basic after dash fires 2 projectiles | killing enemy within buff reduces remaining CD by 1.5s (once per roll) |
| L: Piercing Round, Lv9 | CD 10s, 65 physical, 680px range, pierce 3 | pierce 5 | +35% vs boss | hits apply mark for 3s; marked target takes +12% player damage |
| I: Bullet Storm, Lv11 | CD 25s, 18 shots x 10 physical over 3s | 25 shots | 15% chance hit bounces to one distinct enemy with 50% dmg | — |

J/L/I projectile capability yes. K is dash, not splittable. J and I multicasting must observe projectile budgets.

### Boros — Juggernaut / Brute
**Basic Heavy Strike:** 85px melee arc auto nearest, 25 physical, CD 0.95s; melee arc is **not** projectile.

| Slot & unlock | Rank 1 | Rank 2 | Rank 3 | Rank 4 |
|---|---|---|---|---|
| J: Ground Slam, Lv3 | CD 8s, 55 physical within 140px AOE, 25% slow 1.5s | radius 170px | bonus damage equal 3% max HP (capped 30 vs boss) | second ring triggers 0.4s later, 45% original damage |
| K: Iron Resolve, Lv6 | CD 16s, shield 70, 25% damage reduction for 3.5s | shield 95 | reflect 15% post-mitigation incoming damage, budgeted | expiration heals 20% damage blocked, capped 60 |
| L: Crushing Charge, Lv9 | CD 11s, charge 230px, 60 physical along path | charge 300px | hit enemy stuns 0.7s (boss stagger only) | leaves 2s trail with 10 dmg per 0.5s |
| I: Titan's Fury, Lv11 | CD 30s, +40% max HP (temporary without percent healing exploit), melee range +45%, duration 7s | duration 9s | basics create radius 85px pulse at 35% basic dmg | — |

Boros J is area effect, not projectile; Boros L is dash, not projectile. Split projectile must not appear for either unless architecture is deliberately expanded.

## 5. Status effects and control
Root: blocks movement but not attacks unless specified; Slow: additive within source category, final movement multiplier >=0.35; Stun: disables skills/movement/basic, player immunity while damage freeze not assumed. Boss hard CC converts into short stagger (0.15s) with 4s stagger internal cooldown (`DEMO DEFAULT`) instead of full root/stun, preserving some CC value.
Shield is time-limited and expires; self-shield effects may protect during skill windup. Damage-over-time ticks use simulation clock, no tick while paused. Status refresh policy per definition (replace strongest, refresh duration, stack cap) and must not create indefinite duplicates.

## 6. Universal augment catalog — implementable MVP
Each of following has `augment_id`, effect, scope, ranks, eligibility and budget. Rank progressions below are DEMO DEFAULT. Skill-targeted cores are offered with chosen slot in card. A targeted augment applied to different slots counts as separate rank stack.

### Infinite stat cores (8)
| ID | Each pick (+ additive to baseline category) | Caps/notes |
|---|---|---|
| stat.max_hp | +8% max HP | existing HP increases by matching delta fraction; no free full heal |
| stat.damage | +7% outgoing damage | additive within stat damage bonus |
| stat.attack_speed | +8% attack frequency | effective cap 6/s |
| stat.move_speed | +5% speed | cap 550px/s |
| stat.crit_chance | +4 percentage points | cap 100% |
| stat.crit_damage | +10 percentage points crit multiplier | minimum 100% |
| stat.cooldown_reduction | +4 percentage points CDR | cap 60% |
| stat.pickup_radius | +12% pickup distance | softcap 420px recommended |

Always at least 3 distinct stat IDs available to guarantee offers. Duplicate cards in same three-choice set forbidden; re-selecting stat on later levels allowed indefinitely.

### Reusable mechanic augments
| ID | Max | Required capability | Rank effects / restrictions |
|---|---:|---|---|
| augment.projectile_split | 5 | modify_projectile_angle, spawn_projectile_pattern | ranks: 2 bonus shots @ 40% damage; 2 @50%; 4 @50%; 4 @65%; secondary shots inherit skill status effects; primary per-skill/root cast; respects max projectiles |
| augment.multishot | 5 | modify_projectile_count | +1,+2,+3,+4,+5 total projectiles, same root cast; overflow capped; applies to projectile-bearing executor |
| augment.pierce | 5 | pierce_hit | +1,+2,+3,+4,+5 additional unique target hits; per-target max once for each projectile |
| augment.homing | 5 | projectile_steering | turning strength +10/20/30/40/50%; cannot attach to instant beam or area |
| augment.echo_cast | 5 | repeat_cast | echo after 0.6s, echo damage 35/40/45/50/55%; echo may not generate echo recursively, echo secondary proc budget |
| augment.area_expand | 5 | resize_area | +12/24/36/48/60% area **radius** (not damage automatically); for ground AOE or blast, not beams unless beam width adapter |
| augment.explosion_on_hit | 5 | on_hit_hook + damage | explosion radius 55/65/75/85/95px, raw 15/20/25/30/35, once per distinct target per root cast, secondary explosion cannot retrigger itself |
| augment.on_kill_burst | 5 | on_kill_hook | enemy kill triggers burst 20/25/30/35/40 damage, 65px radius; primary-only; exclude spawned auxiliary summons |
| augment.cooldown_refund | 5 | cooldown_manage | eligible skill hit has 8/10/12/14/16% chance return 10% of **base** cooldown; max once per root cast |
| augment.shield_reflect | 5 | modify_shield + damage_taken_hook | reflect 8/11/14/17/20% of absorbed damage; reflects non-recursively, cap per hit vs bosses |
| augment.dash_shockwave | 5 | dash_completed_hook | dash completion AOE 25/35/45/55/65 physical around endpoint, 90px radius |
| augment.execute | 5 | damage | +10/15/20/25/30% damage if victim under 25% health; effective damage calculation once |

`projectile_split` and `multishot`: each modifies root projectile pattern at different ordered steps: base pattern → extra multishot lanes → split each eligible *primary lane* once. Secondary split projectiles never split again. Both obey cast budget; deterministic truncate last-generated shots first. `echo_cast` repeats root attack once but tags it `is_echo`; echo does not auto-repeat; cooldown not charged for echo. For AOE hit explosion, dedupe per root cast/target prevents severe runaway.

### Class-influenced weight catalog
Generic augment eligibility must not be tied to class. Proposed **DEMO DEFAULT** weights: Mage bias to area_expand/echo/shield; ADC to projectile_split/multishot/pierce; Brute to shield_reflect/dash_shockwave/execute. Class weighting is a *bonus to offer probability*, not a hard gate. For first MVP, no exclusive signature cores necessary; character signature augments may be added later after generic system passes.

## 7. Upgrade offering rules
- Level-up flow: pause, generate all candidate `(augment_id, target_id)` and skill ranks, reject unavailable/capped, weighted sample without replacement to produce 3 distinct cards, show full current→next rank tooltip, pick exactly one, resume.
- Option weighting: Common 55, Rare 30, Epic 12, Legendary 3 as provisional rarity distribution; do **not** filter entire catalog to an unavailable tier; fallback to globally valid stats. Need deterministic RNG per run and fairness testing.
- Skill rank option available iff slot unlocked, current rank < max, and actor alive. Rank-up cards identify skill and `Lv N→N+1`.
- At level 3/6/9/11 free unlock occurs **before** candidate calculation. Player can receive rank 2 immediately if selected.
- Reroll: demo default 1 reroll every 10 levels, unused tokens carry forward to max 3; same rarity rules but disallow previous same card if enough candidates. UI key/button.
- No mandatory limit on count of *different* passive augment IDs equipped; per-augment rank max 5. Infinite stats use tierless repeats.

## 8. EXP curve, mobs and encounter pacing
All below DEMO DEFAULT until playtesting. Player starts Lv1 XP 0. XP needed to go from current Lv `L` to `L+1`: `round(25 + 12*(L-1) + 1.8*(L-1)^1.45)`; expose config curve. Each killed normal enemy drops 6 XP; fast runner 8 XP; ranged enemy 10 XP; tank 15 XP; elite 45 XP; boss 100 XP banked until map transition. XP orbs persist at least 45s, can merge by spatial pooling; magnetize within base radius 90px, collect on overlap.

Spawn pacing: sample every ~2.5s initial, gradually increase count; pressure coefficient `1+0.06*(playerLevel-1)+0.01*elapsedMinutes`, max concurrent 110 enemies (`DEMO DEFAULT`). Kill reward uses XP. Spawn must satisfy player distance >= 550 px, <= 950px when possible, offscreen when viewport permits, no overlap obstacle, connected traversable region. Failure to find candidate after 30 attempts → defer spawn rather than violate safety. Boss spawns at accessible telegraphed anchor >= 550px; boss arena must have escape lanes.

Mobs: Chaser HP 35 speed 110 melee 8; Runner HP 22 speed 180 melee 6; Spitter HP 45 speed 95 range attack 10 interval 2.2s; Tank HP 120 speed 75 melee 14; Elite Brute HP 320 speed 90 damage 22. Each actor health+damage scales by stage. `stage= floor((playerLevel-1)/10)`; enemy HP multiplier `1+0.28*stage+0.025*(level-1)`; damage multiplier `1+0.15*stage+0.015*(level-1)`; boss scaling separate.

## 9. Boss mechanics and BossGate
- Boss threshold exactly `level % 10 == 0` starting 10, **one and only one** boss instance/gate per threshold. Gate state transitions `IDLE→PENDING→ACTIVE→DEFEATED→TRANSITIONING→IDLE`, or `DEAD` if failed.
- On threshold level-up: apply upgrade, then boss spawns; no map transition until boss defeat. Bank any further XP while gate ACTIVE; no new level threshold/boss until clear. On boss death, optionally award XP; transition map, settle banked XP with upgrade offers one at a time. If banked XP crosses another threshold, schedule next boss only after transitions settle, no nested gate.
- Boss I demo `Stone Warden`: Lv10 HP 1600, contact 20, movement 100px/s; radial shockwave 100 raw (?) **use 24 physical** in radius 170 with 1s telegraph, every 5s; cone strike 30 physical width 90°, range 240 every 7s. Below 40% HP attacks 20% quicker (floor cooldown 2s). No unavoidable attacks without telegraph.
- Boss II demo `Ember Sentinel`: Lv20 HP 2700, contact 30, movement 120; laser 24 magical every 6.5s with 1.2s telegraph, rectangular width 75; summons 3 chasers every 9s subject enemy cap. Below 40% HP adds two sequential lanes with dodge gaps.
- Later bosses MAY recycle archetype variants scaling by stage; do not block infinite runs due to finite boss content. Boss HP multiplier for stages after designed encounter: `1 + 0.45 * max(0, stage-2)`; damage `1 + 0.25 * max(0, stage-2)`; enforce telegraphs.

## 10. Maps and obstacle generation
At run start sample one of three templates with no immediate map repetition until all three have appeared where possible. Boss victory transitions to another random map; different layouts and obstacle seeds each visit.

| Map | Gameplay characteristic | Hazard policy |
|---|---|---|
| Ruined Temple | pillars, long narrow lanes, some open circles | no damage hazard first demo |
| Enchanted Forest | tree clusters, diagonal paths, more obstructions | slow patches optional |
| Volcanic Arena | mostly open, lava strips telegraphed | lava 5 damage every 0.5s **DEMO DEFAULT**, never unavoidable spawn damage |

Arena `~2200×1500px`, bounds/template dimensions data driven. Obstacles sampled from authored candidate regions and checked for actor collider overlap, player spawn safe area radius >=250px, >=2 escape routes, navigation reachability. Spawn safety vs player >=550px; defer if impossible. For transitions: freeze combat, remove temporary projectiles/enemies, preserve HP ratio and permanent statuses? **DEMO DEFAULT:** preserve current HP ratio (min 1 if alive), clear only temporary statuses/shields, restore 15% of *max HP* as healing (capped); preserve stat and passive upgrades, active skill cooldowns reset; spawn in new map safe anchor. Document each transient reset in UI.

## 11. UI and state transitions
Menu → Character Select (Astra/Vex/Boros) → Run → Upgrade pause (repeated) → Boss warning → Boss Combat → Map transition → Run → Game Over summary. HUD: HP/shield bars, Lv/EXP bar, current map, basic attack indicator, J/K/L/I icons, lock/level/cooldown, Auto/Manual indicator, keybind hint, pause/settings. Upgrade cards show rarity, name, eligible target, current/next rank, numeric effect and limitation; always 3 distinct and one selected. Game Over shows level, time alive, bosses defeated, max DPS optional, map count, current seed, acquired augments.

## 12. Death, edge cases and ordering
- At simultaneous death and boss kill in same physics tick, if player HP<=0, loss priority; no double victory.
- Player cannot level while upgrade menu open; XP queued; chain level-ups present sequentially after previous choice and UI closed.
- Multiple EXP orbs colliding same tick collected exactly once; no XP from kill events twice.
- Pressing J before level 3 must not cast; pressing during cooldown / stun / pause no cast and no resource spent.
- If no target in auto mode, targeted skill waits; self shield casts on threat condition; when manual aimed outside max range clamp aim point to allowed range.
- Avoid spawn-kills when changing maps: 2s invulnerability **DEMO DEFAULT**, player input may move instantly, damage immunity only not collision immunity.

## 13. Balance knobs and playtest metrics
Editable parameters: base stats, XP threshold curve, orb pickup radius, mob caps, spawn periods/distances, enemy scaling, boss HP/damage/phase thresholds, active skill cooldowns and ranks, augment proc budgets, rarity weights, reroll tokens, map hazards. Log run metrics: survival time, levels/minute, damage taken/minute, boss TTK, upgrade selection frequency, offer invalid-card count (must 0), avg projectiles spawned, max event depth, frame time 95p. Balance is provisional; no false claim that defaults are tuned.

## 14. Acceptance scenarios
1. Astra level 3 unlock J for free and sees exactly 3 cards; no lost level-up choice.
2. Vex skill L and Astra skill J both accept same generic `projectile_split` implementation; Boros J does not.
3. Passive split rank cannot go from 5→6; rank max 4/4/4/3 for skills.
4. In manual mode J never auto-casts; in auto mode J casts valid target on cooldown; basic always auto.
5. Lv10 triggers exactly one boss; boss survives while player runs; kills boss, transitions map and still has upgrades.
6. SpawnDirector never spawns enemy inside obstacle or within player exclusion zone; if no valid site, no spawn.
7. `split + multishot + echo + explosion` obeys projectile/proc budgets with no hang or duplicate kill count.
8. In endless level >30, even after many capped cores, level-up always offers exactly 3 distinct stat/valid cards.
