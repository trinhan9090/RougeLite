# ATYU — M.U.G.E.N → GODOT CHARACTER & VFX PROOF OF CONCEPT

**Version:** 1.0 (17 October 2026)  
**Purpose:** Technical experiment for Endless Survival RPG (Godot 4, 2D action pixel-art, top-down 3/4).  
**Status:** SPECIFICATION — not a completed sprite conversion.  
**Priority:** Reuse the actual assets and timing from the supplied `Yuta_Manga_v1.zip` wherever feasible, without mistaking side-view art for top-down animation.  
**Distribution:** Local/private evaluation only unless appropriate licenses and permissions are obtained.

## 1. Objective and boundaries

Build an additional experimental Brute/Fighter character, **Atyu**, inspired by the sword-and-spirit combat style previously discussed. This is an **isolated import experiment** and must NOT replace Astra, Vex or Boros or alter the locked combat/augment specification. The experiment tests whether original M.U.G.E.N animation sequences, sprite offsets, timing, VFX layers and summon behavior can be adapted into Godot while preserving motion quality. Atyu is not considered production-ready until top-down compatibility and legal permissions are resolved.

### Required outcomes
1. Identify and extract the package's sprite archive, animation definitions, audio and relevant state/action mappings.
2. Create a deterministic **MUGEN-to-Godot converter** and a separate **Atyu demo scene**.
3. Demonstrate idle, movement, basic sword attack, J wide cleave, K command immobilize, L spirit invocation and I energy beam using **genuine assets from the archive wherever verified**; fill any missing visuals with clearly labeled Godot-generated placeholders.
4. Preserve original action frame timing, per-frame offsets and VFX layering in the first faithful side-view preview; adapt subsequently to gameplay's top-down 3/4 view.
5. Produce provenance reports at the level of individual animation and sprite group; explicitly list missing art, unsupported directions, imperfect adaptations and copyright status.

## 2. Actual supplied package — evidence and uncertainty

ZIP: `Yuta_Manga_v1.zip` (~84 MiB compressed), folder `Yuta Manga v1/`. Verified inventory:

| Path inside character folder | Meaning | Finding |
|---|---|---|
| `Yuta Manga v1.def` | Primary character metadata | `name="Yuta By MM"`, `displayname="Yuta Manga¡"`, `author="Mugen Matias"`, date 2021-07-01; references `Ichigo_Bankai.*` |
| `Ichigo_Bankai.sff` | Sprites/VFX archive | Approx. 97.7 MiB extracted; must decode + visualize before claiming its contents |
| `Ichigo_Bankai.air` | Action frames, offsets, timing and collision boxes | 684 `[Begin Action]` declarations, including some duplicate IDs; do not treat all as 684 unique actions |
| `Ichigo_Bankai.snd` | Sound archive | Approx. 13.5 MiB; audio conversion is optional and licensed separately |
| `Ichigo_Bankai.cmd` | Inputs and transitions | Includes Rika-related states, reverse-cursed comments; verify linkage through state transitions |
| `Ichigo_Bankai.cns` | Basic attacks and state definitions | State IDs for multiple attacks, movement and VFX |
| `Especiales.cns`, `Supers.cns`, `Vizard.cns`, `IA.cns` | Special/super/helper behaviors | Includes Rika, giant beam, slash effects, statuses; some labels may be inherited |
| `MOVESET.txt` | Text moveset | **Looks stale/inherited:** explicitly lists Ichigo, Getsuga Tenshou, Hollow Mask, etc. Do not use it as authoritative for Yuta/Atyu |
| `Credits.txt` | Provenance | Credits Ichigo Bankai/Vizard from Knightmare404/VegettoMods and other contributors; does not provide a reuse license |
| `1.act`–`5.act` | Palette data | Extract and inspect if relevant |
| `backup/`, `jjj.gif` | Backup/extra images | Do not include automatically in final animation imports |

**Important observation:** Internal assets have mixed Ichigo and Yuta labels. This may represent a modified or derivative character. Verify images manually through a sprite contact sheet before assigning them to Atyu. Filename alone is never evidence that a specific frame depicts Yuta, Rika or a particular skill.

### Concrete state candidates found in source files (TO VERIFY VISUALLY)

| Candidate | File | Description from source | What Agent must confirm |
|---|---|---|---|
| `200`, `210`, `211`, `212`, `213`, `300`–`340` | `Ichigo_Bankai.cns` | Basic attack sequences, labeled A/B slash variants | Match state → `anim` → `.air` → SFF images; identify best sword slash |
| `400`–`435` | `Ichigo_Bankai.cns` | C attack variations and multiple slashes | Determine available wide/sweeping slash FX |
| `1150` | `Especiales.cns` | `Slash FX` | Determine visuals, scale, hit timing |
| `1434` | `Especiales.cns` | Labelled `Rika: Libera` | Determine whether summon art and effects are present |
| `930` (helper reference) | `Supers.cns` | Helper named `Rika` | Resolve helper definition and its linked animation |
| `188100` | `Vizard.cns` | Comment `Rika porra!` | Check actual animation and attacks before reusing |
| `10450` | `Especiales.cns` | `Beam Gigante`, uses `anim=8067` | Beam VFX candidate, inspect actual SFF group |
| `81045` | `Vizard.cns` | `Beam Gigante`, uses `anim=8065` | Alternate large-beam candidate |
| `661502` | `Vizard.cns` | Comment `Stun`, uses `anim=2044` | Character/target stun visuals, not automatically a speech-root effect |
| `153000` | `Supers.cns` | `domain expansion - shrine` | Not part of Atyu's initial kit; do not import as default skill |

These are **search targets**, not certified mappings of specific sprites to the requested four abilities. Source comments are frequently inconsistent; visually cross-check each action.

## 3. Atyu character identity (prototype)

- **Code ID:** `atyu`; display name `Atyu`; **Class:** Brute, offensive spellblade subclass.
- **Role:** close-range cleave, crowd control, spirit-assisted beam burst.
- **MUGEN-first look:** recover the principal swordsman frames from the actual SFF and use their authentic silhouette as the baseline for this POC. Do not synthesize a new detailed appearance until extraction is assessed.
- **Design goal in Endless Survival:** readable compact black-haired swordsman, light upper clothing over dark trousers, katana-style blade and a conspicuous spectral ally; visual style ultimately normalized to Wizard of Legend-inspired compact 2D pixel art.
- **Signature palette:** dark navy/black, pale ivory, violet/blue spectral energy; **provisional only**, because archive palette/frames must be inspected first.
- **Scene scale:** target character height 32–48 visible pixels *after* conversion; source resolution and original motion should be preserved in diagnostic previews. Use nearest-neighbor integer upscale for display.
- **Facing:** package is primarily side-view; **sideways movement and left/right flip only in raw M.U.G.E.N preview**. North/South require original newly produced art or approved alternate presentation. Do not fake a top-down back view by flipping a front view.
- **Foot anchor:** use the M.U.G.E.N action offsets, then map to Godot feet-relative anchor with a reproducible transform; never auto-center each frame independently.

## 4. Exact gameplay specification for Atyu

**Important:** Prior conversation defined four active buttons J/K/L/I. The four skills remain locked as character goals even when the archive lacks matching visuals. Do not replace the user-requested skill with a different move simply because M.U.G.E.N contains it. Instead prioritize M.U.G.E.N artwork as a **visual source** and report gaps.

| Slot | Core mechanic | Level unlock | Source asset priority | Fallback |
|---|---|---:|---|---|
| Basic | Short sword-line slash toward nearest target in reach | 1 | verified low/strong sword attack frames (states 200–340) and slash VFX | procedural pixel slash trail |
| J — Wide Cleave | Large melee cone slash, hits multiple enemies | 3 | multi-slash/crescent candidates (`400`–`435`, `1150`) | draw fan arc using reusable SlashVFX |
| K — Command Seal | Directional cursed-voice wave immobilizes enemies (root) | 6 | verified wave/seal/speech/rune assets if actually found; `Stun` state does **not** prove speech | Godot-generated rune pulse and root glyph |
| L — Spirit Manifest | Temporarily summon companion/guardian; attacks nearby enemies | 9 | Rika-related helper/actions (`930`, `1434`, `188100`) | temporary spectral silhouette with clearly marked placeholder status |
| I — Cursed Light Burst | Straight large damaging beam; companion empowers it when active | 11 | `Beam Gigante` candidates (`10450`, `81045`; animations 8067/8065) | shader/mesh beam with pixel-art mask |

### Default gameplay tuning (temporary, independent of art conversion)

| Action | Starting spec | Notes |
|---|---|---|
| Basic | 22 damage, 0.85 s attack interval, 110 px reach, narrow sweep | hitbox follows attack direction; do not derive from M.U.G.E.N collision directly |
| J | 55 damage, 5.5 s cooldown, 140 px radius, ~85° cone | AoE; max 4 ranks including unlock |
| K | 0 base damage, 11 s cooldown, 240 px range, 1.4 s root normal enemy, 0.6 s elite/boss | make root duration data driven; max 4 ranks |
| L | 16 s cooldown, summon up to 8 s, companion strikes every 1.2 s | max 4 ranks; summon uses scene instance, not a cosmetic animation only |
| I | 160 damage, 24 s cooldown, 420 px length, 34 px width, 0.4 s wind-up | max 3 ranks; damage & visuals tied to same beam geometry |

All values above are **DEMO DEFAULT**, not authoritative M.U.G.E.N balance. Runtime remains governed by the game's common `SkillDefinition`, `CombatEvent`, `SkillInstance` and augment architecture. Auto/Manual toggles and key remapping remain supported.

## 5. Animation production and mapping protocol

### 5.1 Extract first, assign names second

1. Read primary DEF file to locate the SFF, AIR, CMD, CNS and SND assets.
2. Decode `Ichigo_Bankai.sff` using an SFF v2-compatible decoder (e.g. compatible Fighter Factory/export utility or a converter validated by checksum and visual inspection). If decoder isn't installed, report blocker; do **not** relabel opaque SFF data as PNG.
3. Export sprites to `raw_sprite/{group}_{index}.png` preserving original image dimensions and alpha where possible, palette references and raw sprite offsets.
4. Parse AIR actions: for each row retain group/index, X/Y offset, duration in ticks, H/V flip, alpha flags, layer, collision definitions, loop position. Treat -1 sprite references as non-visual wait frames.
5. Build an audit report (`source_action_map.csv`) listing every action, row, referenced sprite, source CNS state, associated helper and confidence score.
6. Render a **contact sheet** of candidate core attacks, skill effects and helper animations. Label with raw source IDs and never crop labels into pixel frames.
7. Only then assign semantic names such as `atyu_attack_basic`, `atyu_j_cleave`, etc.

### 5.2 Godot animation requirements

- Keep raw source frame durations exactly for diagnostic preview. For game adaptation, timings may be retimed but changes must be recorded.
- Use `AnimationPlayer` for simultaneous body sprite, slash/VFX overlay, muzzle/hand anchors, summon and sound timing; `AnimatedSprite2D` for sprite-only sequences.
- Separate `VisualRoot` from `CombatController`, with animation requests routed via `VisualController`.
- Sword attack visuals can be flipped for left/right only when sprite's asymmetrical details remain acceptable; hand and weapon attachment must flip coherently.
- Animation events should emit `attack_window_open`, `attack_window_close`, `vfx_started`, `vfx_finished`; **host game logic still owns hit registration**.
- VFX should be instances of reusable skill-capability scenes (`SlashArcVFX`, `RootPulseVFX`, `SummonVFX`, `BeamVFX`) rather than embedding logic into Atyu sprites.
- No automatic interpolation, subpixel camera placement or bilinear filtering of pixel frames.

### 5.3 Orientation mismatch: mandatory experimental split

**POC-A (faithful archive test):** Spawn Atyu in a simple side-view exhibition scene, left/right animations and four visual attacks. This tests SFF/AIR conversion fidelity.

**POC-B (Endless Survival integration):** Spawn Atyu in top-down 3/4 map, 4-way WASD. Permit temporary test placeholders for N/S but overlay a conspicuous debug warning; these are **not acceptable as completed character art**. Do not allow 2D side-view sprites to be mislabeled as 4-direction native top-down sprites. If the 4-way look fails, the correct conclusion is partial feasibility, not project failure.

## 6. Detailed VFX implementation

### Basic sword attack
- Source: inspect normal A/B slashes, hit sparks; play precise body pose + separate blade trail at correct hand pivot.
- Telegraph 0.08–0.12 s, active 0.08–0.15 s, recovery 0.15–0.25 s as initial tuning.
- Visual layers: blade silhouette → pale crescent → violet edge spark → hit burst + 1–2 frames hitflash.
- Damage uses melee sweep overlap in Godot. M.U.G.E.N `Clsn1` is only reference for timing/relative shapes.

### J Wide Cleave
- Shape: 85° cone sampled or deterministic analytic wedge, centered on casting direction.
- Visual uses biggest verified sweeping slash from SFF if legible. One VFX event per cast; scaling to radius does not scale player body.
- VFX follows dynamic augmented radius and width. Multihit immunity keyed by `(cast_id, target_id)`.

### K Command Seal
- Shape: wave traveling forward or a narrow cone after decision; **demo recommendation: directional wave**, but actual MUGEN speech art may be absent.
- Front-edge pulse colored violet + small command glyph above root-affected enemies + ring on ground.
- On hit: apply `ROOT`; don't reuse M.U.G.E.N victim animations as a Godot target's pose unless licensed and compatible.
- In Auto mode target nearest eligible enemy in range; Manual uses player's facing/aim direction.

### L Spirit Manifest
- Source: inspect Rika actions and helper definitions; don't infer that any randomly named `Rika` helper depicts the correct sprite.
- In Godot implement separate `SpiritCompanion.tscn`, visually tethered or following player. Render above/below layer as intended, with shadow and opacity controls.
- Summon effect: portal/flicker → silhouette emerges → stable outline + glow → dissipate. During summon, attack with a light slash every configured interval.
- If asset doesn't decode into clean sprite layers, use a conspicuous silhouette placeholder instead of passing low-quality extraction as final.

### I Cursed Light Burst
- Source: check whether SFF animations `8065` and `8067` visually correspond to `Beam Gigante` states; parse any helper and Explod layers.
- Cast: wind-up rune 0.4 s → beam core + noisy edges + impact bursts → fade. Beam visual dimensions and combat collision segment must share parameters.
- Beam should consist of pixel core, edge noise, impact particle bursts and ground illumination; avoid full-screen blur. If L active, add secondary burst/sigil **without changing action ownership**.
- On multiple enemies, hit each eligible target once per cast or at designed pulse frequency; use cast identifiers for deduplication.

### Augment compatibility
- Basic and J: `MELEE`, `CONE`, `ECHOABLE`, `AREA_EXPANDABLE`, `ON_HIT` where executor supports.
- K: `DIRECTIONAL`, `ROOT`; `SPLITTABLE` **only if implemented with independent projectiles/waves** and runtime capability explicitly provided.
- L: `SUMMON`, `DURATION_SCALABLE`, `SUMMON_MODIFIABLE`.
- I: `BEAM`, `WIDTH_EXPANDABLE`, `ECHOABLE`; **NOT automatically projectile SPLIT**.
- No per-character special case in AugmentManager. M.U.G.E.N source FX are only visual implementations of common gameplay effects.

## 7. Scene and directory layout

```text
res://characters/atyu/
  atyu_definition.tres
  atyu_visual.tscn
  atyu_visual_controller.gd
  anim/atyu_spriteframes.tres
  vfx/atyu_skill_visual_map.tres
  source_manifest.json
res://vfx/common/
  slash_arc_vfx.tscn
  root_pulse_vfx.tscn
  summon_vfx.tscn
  beam_vfx.tscn
res://experiments/mugen_atyu/
  sideview_test.tscn
  topdown_test.tscn
  debug_action_browser.tscn
assets_external/mugen_atyu/      # never auto-publish with release
  raw_sprite/
  raw_audio/
  action_map.csv
  source_action_map.csv
  contact_sheets/
  license_report.md
scripts/mugen_import/
  inspect_archive.py
  extract_sff.py
  parse_air.py
  resolve_states.py
  build_atlas.py
  generate_godot_resources.py
  validate_conversion.py
```

Keep source archive and extracted copyrighted sprites in the private experiment area; exclude from public distribution and automated asset bundle uploads unless permission is documented.

## 8. Conversion tool contracts

**`inspect_archive.py --zip ZIP --out DIR`**: produce inventory with byte sizes, SHA-256 file hashes, DEF references, state lists, action IDs, palette file list and source-license notes.

**`extract_sff.py --input SFF --out DIR`**: use tested decoder, emit PNGs + `sprites.json` with group/index, source offsets and palette information, along with a failed-sprite list.

**`parse_air.py --input AIR --out JSON`**: parse action blocks, duplicate action IDs and MUGEN duration/flip/alpha syntax. Preserve unknown tokens verbatim; flag unsupported operators.

**`resolve_states.py --cns ... --cmd ... --air ...`**: follow `Statedef → anim → AIR → SFF`, and `Helper/Explod → stateno/anim` references where statically resolvable. Dynamic `var()`, expressions and runtime branching become unresolved edges in report, never fabricated mappings.

**`generate_godot_resources.py`**: generate `SpriteFrames`/`AnimationLibrary`, source metadata, and visual-only scene components, without overriding original combat/skill logic.

**`validate_conversion.py`**: verify all referenced frames exist, no null textures, no unexpected transparent strips, offsets stable at planted foot, valid durations and successful scene load. Do not mistake image similarity for artistic correctness.

## 9. Step-by-step task backlog

| Phase | Task | Deliverable | Pass criterion |
|---|---|---|---|
| P0 | Archive + source inspection | `inventory.json`, file hash report, license notes | Every referenced file found or explicitly missing |
| P1 | Decode SFF and AIR | PNG export, `actions.json` | ≥95% of selected candidate animation frames resolved; precise failures logged |
| P2 | Source animation browser | `debug_action_browser.tscn` + contact sheets | Can scrub frames; compare action ID/ticks visually |
| P3 | Basic sword and J | Side-view previews, slash VFX | Sprite timing/offset matches source; damage fired once/cast |
| P4 | K root and L summon | 2 scene previews, source/fallback flags | Root actually affects enemies; helper animation visually audited |
| P5 | I beam | Beam scene and gameplay hook | Beam uses same geometry as damage, no visual desync |
| P6 | 4-way top-down test | Character in arena with controls | Missing N/S clearly flagged; no claim of full compatibility |
| P7 | Augment integration | J echo, width; K compatible logic; I beam width | Shared AugmentSystem works, no special character condition |
| P8 | Stability and evidence | Test report, GIF/MP4/screenshot, performance log | Godot launch succeeds, no missing textures/errors, 30-enemy smoke test |

### Suggested visual acceptance tests

- Three test scenes: isolated animation browser, side-view faithful source, top-down in actual game.
- Show **actual native pixel resolution and 4× enlarged nearest-neighbor crop**.
- Compare idle/walk/sword pose with extracted AIR contact sheet.
- Stress with 30 enemies and repeated skills, watching draw-call/particle pressure and FPS.
- Display on-screen labels `SOURCE_VERIFIED`, `SOURCE_ADAPTED`, `PLACEHOLDER` for each showcased skill.
- Deliver precise list of animation/action IDs selected, source sprite identifiers, sprite timing deltas, workarounds and unresolved dependencies.

## 10. Risks, constraints and intellectual property

1. **Legal:** Yuta/Jujutsu Kaisen, Ichigo/Bleach, original mod sprites, sound and contributions may each have distinct rights. Included credit lines are **not a license**. Never include package assets in a public/commercial game without verified permission. Using names/character likenesses can also raise IP issues. Test privately and replace with original licensed art for release.
2. **Perspective:** Side-view cannot be converted into true 4-/8-direction top-down animation merely via flip or rotation. This is a core acceptance blocker for the art pipeline.
3. **Package provenance:** File names reference Ichigo while primary DEF references Yuta. Do not assert a single coherent authorship or animation roster.
4. **Data formats:** SFF v2 decompression, palettes, linked sprites, MUGEN AIR interpolation and SND extraction may require additional tooling.
5. **Performance:** Large high-resolution source effects can violate compact pixel-art style. Downsample per effect using nearest neighbor or custom pixel cleanup; preserve readable silhouettes.
6. **Gameplay divergence:** The current Atyu kit (especially speech-root, summon and beam) is an original Godot gameplay design. The mod might not provide a one-to-one exact skill for every action. Do not lie about provenance.
7. **Do not change** core gameplay, locked skill unlock levels, or priority of completing Astra/Vex/Boros VFX. Atyu is a secondary experiment.

## 11. Explicit agent instructions

1. Read existing `AGENTS.md`, `CORE_ARCHITECTURE.md`, `GAMEPLAY_SPEC.md` and this file; this experiment is lower priority than Astra/Vex/Boros production VFX.
2. Work in a separate experimental branch/path; never overwrite player art or core Skill/Combat/Augment classes.
3. Use only tools already installed or installable free tools; log version and exact commands. Do not claim extraction succeeded without PNG output and contact sheets.
4. If source action/state is ambiguous, mark `UNVERIFIED` and show its image before integrating it. Where skills are not present, create clear procedural placeholders.
5. In every PR include: changed files, commands run, test outputs, example source/action provenance, legal limitations, and screenshot/video proof.
6. Stop and ask user approval only when facing architecture-changing decisions or authorizations to distribute third-party assets; continue normal technical troubleshooting autonomously.

## 12. Agent launch prompt

> Inspect `Yuta_Manga_v1.zip` and implement only P0–P2 first. Decode `Ichigo_Bankai.sff` and parse `Ichigo_Bankai.air` without conflating Yuta and Ichigo metadata. Build sprite/action contact sheets and a Godot source-animation browser. Then map actual verified attacks to Atyu's basic, J, K, L, I. Use faithful MUGEN art as the primary source for this **private test**, and clearly mark missing skills as generated placeholders. Preserve existing game architecture and Astra/Vex/Boros work. Produce evidence and do not declare four-direction support unless actual sprites exist.

---

**Verification record:** ZIP structure, text metadata, 684 AIR action declarations and source state candidates were inspected directly. **Sprite images in the SFF were not decoded and visually verified during preparation of this specification.** The next step is real SFF extraction, not assuming those candidates are correct.
