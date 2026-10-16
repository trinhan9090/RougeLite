# 06 — MILESTONES / TESTS / VISUAL ACCEPTANCE
## 1. Quality definition
`TECHNICAL_PASS` requires automation tests and runnable project. `ART_REVIEW_PENDING` requires user's eyes on 1× gameplay clips. `APPROVED` only when user confirms art direction. Do NOT mark all completed due to green unit tests.

## 2. Milestones and evidence
| ID | Objective | Dependencies | Agent evidence / exit gate |
|---|---|---|---|
| V0 | Inventory project, licenses, baseline screenshot, branch | none | baseline hashes, project opens, files unchanged, dependency mapping |
| V1 | Automated toolchain and pixel standard | V0 | Blender+Godot versions pinned; smoke render; unit tests validator; manifests pass schema |
| V2 | Astra model+rig 4-dir idle/run | V1 | `.blend`, PNG exports, 1×/4× contact sheets and turntable; no drift, silhouette review |
| V3 | Astra basic J K L I animation + layered VFX | V2 | visual gameplay clips for five actions; damage unchanged, root/shield/AOE/beam visible |
| V4 | Temple arena / collision / lighting | V1 | five seeds, tile seam proof, safe spawn, 1-min stress clip |
| V5 | Astra benchmark approval gate | V3,V4 | side-by-side concept/actual in-game at same scale; user feedback addressed |
| V6 | Vex rig/moves/VFX | V5 | twin muzzle correct, dash afterimage not sprite bleed, barrage and pierced impacts |
| V7 | Boros rig/moves/VFX | V5 | greatsword consistent, grounded swing timing, J slam/K shield/L charge/I Titan correct |
| V8 | Forest + Volcanic maps | V4 | five seeds each, seed replay, visible hazards distinction, no blocked corridors |
| V9 | Universal augment visual propagation and integration | V3,V6,V7 | Split Astra J & Vex projectile with real hitboxes; beam/cone rejected; VFX adapts AoE/range; conflicts checked |
| V10 | Packaging and performance | V8,V9 | Windows build, at-scale footage, cold boot, profiling, zero error logs, known issues |

## 3. Automated test matrix
- **Frames:** expected dimensions/alpha/direction count; no full opaque background; bounding-box validation excludes intentionally extended attack frames; duplicated frames warn, fail only if violates frame variability requirement.
- **Animation:** all 4 directions, FPS declared, loops correct, no missing events, source weapon fits visual bbox; run feet y jitter <= 2 px when no hop (DEMO), idle jitter <= 1 px, camera-scene anchored feet stable.
- **Renderer:** nearest filter, dark/light alpha test, no texture sampling bleed; 1× frame after load matches manifest anchor; shadow layer doesn't become gameplay collision.
- **Game:** auto/manual both trigger correct pose; basic nearest attack; locked skills hidden until 3/6/9/11; pause pauses animation/VFX as required; cap and status after transitions.
- **Augments:** Astra J projectile Split and Vex projectile Split spawn N real projectiles + N matching tracers; Boros J area cannot Split; Astra beam cannot Split by default; geometric area/beam VFX match effective shapes under upgrades; no recursive visual explosions.
- **Map:** five valid seeds per biome; navigation flood-fill; obstacle collisions no intersect safe player start; enemy spawn outside minimum safety zone; fallback map used after invalid seeds; boss transition keeps visuals alive only if run state says so.
- **Performance:** measure average, p95 frame time, 1% lows, memory, particles/projectile counts on named hardware; store logs with thresholds per test scene; no frame-time degradation > approved tolerance after VFX upgrade.

## 4. User-facing visual gates
Astra/ Vex / Boros each has:
1. 4-facing static turnaround on consistent checker and neutral backgrounds.
2. 5–10s loops idle, run, basic, J, K, L, I; montage with damage overlays off.
3. 30–60s full-combat clip at 1× actual gameplay zoom, including groups, boss telegraph and 3+ simultaneous effects.
4. 1× and 4× nearest screenshots; color/silhouette versus corresponding concept reference.
5. Explicit table `PASS / NEEDS_REVISION / NOT_REVIEWED` for silhouette, weapon, readability, motion, visual impact, map unity and VFX-vs-hitbox accuracy.

## 5. Practical concept proximity rubric (not fully automatable)
Score 1–5 by user:
- Character recognizable from reference at game zoom (weight 25%)
- Cohesive directional animation and anatomy (20%)
- VFX layering and punch, not excessive bloom (25%)
- Scene/map depth and art cohesion (15%)
- Combat legibility under density (15%)
Proposed gate: weighted score >=4.0/5 and **no category below 3/5**, plus all technical checks passed. This score is an evaluation aid; user approval remains authoritative. If below goal, agent revises only visuals while preserving gameplay contracts.

## 6. Non-negotiable regression examples
- Boros duplicated visual strip to right during run: fail; inspect atlas rects, alpha bbox and pivot, rebuild sprites from individual PNGs.
- Vex shooting one gun while muzzle flash exits other hand: fail.
- Astra beam VFX shown longer/wider than actual hitbox without telegraph: fail.
- Environment traps player or enemy spawns next to player: fail.
- Frame drops hide hostile attack telegraph or EXP: fail.
- Concept art claimed imported as game-ready sprites simply by cropping from poster: fail.
