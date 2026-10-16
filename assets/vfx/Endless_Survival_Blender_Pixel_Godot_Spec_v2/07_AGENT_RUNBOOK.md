# 07 — AGENT OPERATING PROCEDURE
## Start-of-run checklist
1. Determine repository root and installed Godot/Blender/Python; do not assume Windows install path. Detect correct CLI and version; preserve repo baseline.
2. Inspect existing art package and earlier architecture documentation. Output discrepancies, unresolved blockers and chosen reversible `DEMO DEFAULT`s.
3. Create Git branch `feature/visual-pipeline-v2` or isolated worktree. No destructive changes or renaming of original assets.
4. Add tooling/manifests/tests *before* replacing visuals. Build standalone smoke test generating four directions of one dummy object, import to Godot and capture view.
5. Generate 3D source assets (or provenance-verified free assets), source + animations then PNGs, then VFX/maps, then game packaging. Never request user to do any manual 3D modeling/atlas slicing/import.
6. Enforce visual review gate before mass expanding from Astra to others; if user inaccessible in current execution, mark pending and continue only reversible technical tasks.

## Tooling checklist
- Blender headless run actually opens `.blend` file after saving, counts required meshes, valid armature and actions.
- Image conversion checker validates colors/transparency/per-frame anchors. Optional Pillow+NumPy pipeline can be substituted for Pixelorama GUI for automation.
- Godot opens and imports new resources in headless mode; no unrecognized import options. Screenshots may require visible/display-capable execution (virtual display if Linux), cannot assume Godot headless can render PNG screenshots.
- Keep screenshots and assets versioned by manifest hash to associate review with a specific build.

## Scope/decision policy
- Locked gameplay → do not change, ask if impossible without it.
- Demo-default art parameters (fps, camera zoom, palette colors) → Agent may adjust with before/after evidence and log rationale.
- Requested high visual fidelity does not authorize paid commercial asset purchases, unlicensed copying of existing anime/game designs, or changing game into 3D.
- If generating a model fully from scratch yields only blocky low-poly placeholders, mark asset stage `placeholder`; do not imply it matches concept. Improve mesh/texture/material or present honest blocker.

## Release handoff report template
```text
Visual Build: <commit> / <date>
Versions: Blender ... / Godot ... / Python ...
Milestone: V...
Files changed: ...
Generated: ... / placeholders: ...
License ledger changes: ...
Commands executed + exit status: ...
Automated test evidence: ...
Visual proofs: <relative PNG/GIF/MP4 paths>
Comparison against reference: ...
Known deficiencies: ...
Needs user's approval: specific question or pass/fail list
Next tasks: ...
```

## Quickstart message to agent
Read `README.md` and documents 01–07 in order. Also load original locked gameplay specs. Your assignment is to implement a reproducible, free, agent-driven Blender → Pixel Art → Godot pipeline and use it to produce original Astra (male celestial mage), Vex (western dual-gun marksman), Boros (dark-fantasy heavy greatsword brute). Generate authentic gameplay-ready 4-direction assets and layered effects that follow actual skill definitions. First establish baseline, scripts, tests and an Astra visual benchmark. Do not fake artistic completion; submit preview evidence for user's visual review. Never ask user to manually rig/model/animate/import, and never rewrite combat just to match the concept posters.
