# 07 — Agent launch instructions

## Task
Implement **Viridian the Control Mage**, inspired by visual material in user-provided M.U.G.E.N Dr. Doom pack, into Endless Survival Godot 4 with green magic auto attack and J Plasma Lance, K Arcane Prison, L Molecular Orbit, I Photon Cataclysm.

## Non-negotiables
1. First read repository governance, then all docs in this pack; give precedence to already LOCKED gameplay.
2. Do not rewrite Astra, Vex, Boros, combat core, VFX factory or augment core. Reuse shared executors.
3. Do not use source state IDs as guaranteed sprite/animation IDs; verify through SFF/AIR and visual preview.
4. Do not claim SND audio identity without listening/preview validation.
5. Do not force horizontal fighting assets into four-direction top-down; report actual available coverage and create original temporary sprites for missing directions if permitted.
6. All numeric tuning is DEMO DEFAULT, not user-approved final balance.
7. The core profile must support Auto/Manual, remappable J/K/L/I and nearest-enemy auto attacks.
8. Keep third-party assets isolated and document licensing; private gameplay does not constitute blanket permission to distribute.
9. All mechanics must have hitbox-event-VFX-SFX lifecycle and deterministic cleanup.
10. Keep stage statuses truthful; export visual evidence before asking for approval.

## Initial execution
- Milestones V0–V2 only at first pass. Generate asset catalog with source verification; show which M.U.G.E.N art corresponds to five moves; list sprite direction coverage and audio candidates.
- Then implement V3–V5 in the current Godot architecture, no unapproved changes to shared components.
- Finish tests V6–V8 and provide side-by-side preview with stage/state refs.

## Report format
`Changed files | Reused modules | Verified M.U.G.E.N source IDs | Generated original assets | Test commands/results | Known limitations | Needs user approval`.
