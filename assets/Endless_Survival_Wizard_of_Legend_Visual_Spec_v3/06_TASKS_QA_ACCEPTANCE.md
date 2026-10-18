# 06 — MILESTONES, TEST MATRIX AND ACCEPTANCE v3.0

## Gate policy
Build must pass technical gates; art signoff belongs to user. Mark each task: `NOT_STARTED/IN_PROGRESS/BLOCKED/TECH_PASSED/ART_REVIEWED/ACCEPTED`. No status 'done' without evidence. A screenshot of static splash art does not meet gameplay gate.

| Gate | Work | Machine checks | Human artifact |
|---|---|---|---|
| A0 | Baseline repo/git/assets/license/engine inventory | report paths, git clean/backups | original gameplay screenshot |
| A1 | Pixel style guide + toolchain + manifests/validators | one generated test asset imports and renders | style comparison board at native zoom |
| A2 | Astra body idle/run/basic 4 dirs + weapons | frame & runtime tests | 10–20s 4-direction movement video |
| A3 | Astra J/K/L/I VFX & skill sync | VFX follows real events/geometry | skill reel; screenshots onset/active/end |
| A4 | One arena + 20 layout seeds, obstacle collisions | no invalid navigation/spawn | 30-enemy combat recording |
| A5 | Astra Split, Echo, AOE scaling | no ghost bullets, no proc loops | short augment comparison video |
| A6 | Vex visual set + Basic/J/K/L/I | gun sockets/shot counts/dash path | Vex 4-dir combat reel |
| A7 | Boros visual set + Basic/J/K/L/I | sword clipping/charge/Titan test | Boros combat reel |
| A8 | Remaining two arenas + boss transition | seeded path/spawn/transition | map cycle walkthrough |
| A9 | UI clarity/performance/accessibility | frame timing & all automated tests | crowded screenshot video + settings demo |
| A10 | Windows playable packaged demo + final QA | clean import, build boot, input, integrity hashes | approved demo candidate |

## Non-negotiable acceptance tests
1. Character appears the same across facing N/S/E/W at gameplay zoom; weapon correct and feet anchored.
2. 4 skill animations + basic are distinguishable even without full glow; all status overlays expire only on runtime state end.
3. Test with 30 enemies and 20+ cast events; player position, telegraphs and bullets remain readable.
4. Astra J `Projectile Split` generates **one visual for every real projectile**, incompatible skill does not show Split. `Pierce` emits real per-hit sparks only.
5. Exactly one set of VFX on a cast, no orphan particles or event duplicates after death/map transition; errors log = zero on normal smoke test.
6. Boss transition happens only through gameplay BossGate. Visual scene changes cannot skip actual encounter.
7. Seeded obstacle generation reproduces exact placements, keeps connected navigation and safe spawn distance; fallback layout works.
8. No VFX script directly deals damage or changes buffs.
9. Screenshots/video from **running Godot gameplay**, not generated marketing posters.
10. License ledger covers every imported 3rd party asset and tool used; cannot pass with ambiguous license.

## Visual scoring rubric (each 0–5, weights)
- Silhouette/character recognition **25%**
- Animation feel, anticipation/recovery and fluidity **20%**
- VFX feel, clarity and feedback **25%**
- Map polish and cohesion **15%**
- Crowded combat legibility **15%**
**Suggested target** weighted ≥4.0/5, no category <3.0/5; user can reject despite score. Test at 1×, not only portrait at 4×. This is a review rubric not an automatically provable quality promise.

## Performance baseline (DEMO DEFAULT)
Targets (to be validated on actual PC): 60 FPS average in 30-enemy scene at 640×360 2× presentation, no severe spikes and no runaway particle counts across 10 consecutive skill cycles. Record machine, renderer, min/median/p95 FPS, draw calls, node counts, live decorative particles. If target missed, reduce particles and background detail, NEVER cull real hitboxes or simplify combat behavior.

## Required final evidence package
`reports/visual_qa/<runid>/` with `baseline_before.png`, `astra_native.png`, `vex_native.png`, `boros_native.png`, `arena_[...].png`, `skill_reels/*.mp4` or gifs, `augments.mp4`, `tests.json`, `license_ledger.csv`, `build_log.txt`, `known_issues.md`, Godot Windows executable folder/ZIP, provenance report. If no video capture tool available, create PNG frame sequence then encode through locally installed free utility or report blocker.
