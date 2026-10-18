# 07 — AGENT RUNBOOK (AUTONOMOUS ART PRODUCTION)

## Mission
Deliver playable Wizard-of-Legend–inspired **original** pixel graphics in the existing Endless Survival Godot project for Astra, Vex and Boros. Agent handles all implementation/art tooling; user only plays/tests/reviews. No user manual sprite slicing/rigging/scene wiring.

## Procedure
1. Read README + 01..08 + governance docs. Enumerate live paths, working gameplay, existing renderer version, asset baseline, prior bugs.
2. Make isolated Git branch/worktree. Preserve gameplay scripts and existing known-good visuals; record before screenshots and project launch test.
3. Detect installed Godot, Python, Pillow, Pixelorama/LibreSprite, Blender and video capture tools. Install only from official trusted sources if capability/permissions allow; do not claim installed if not verified.
4. Stage A1: verify test sprite sample with 4 directions, transparent alpha, feet anchor and import. Render at 1×. Create style board: concept poster identity vs simplified gameplay sprite.
5. Stage A2–A5 Astra first. Run gameplay to confirm basic+J/K/L/I and augment interactions. Evaluate with crowds, not empty scene.
6. Show art-review output (screenshots and concise movie) before expanding to Vex/Boros. On user rejection, revise same art system without adjusting combat.
7. Stage A6–A8: Vex/Boros and biomes. Reuse shared tooling and VFX primitives; never copy character-specific gameplay logic into art modules.
8. Stage A9–A10: benchmark, low VFX accessibility mode, build, evidence index, audit licensing and diffs.

## Allowed independent decisions
Fine-tune art palettes, animation frame counts, easing, glow/particle budgets, tile decorative patterns, camera visual shake intensity (with default restraint) if reported as DEMO DEFAULT changes and no gameplay behavior changes. Any change to locked gameplay, geometry interpretation, skill naming/slot, class, module boundaries or licensed source policy needs user approval.

## Blocker escalation
- No suitable free clean licensed character art: create original simplified layered pixel frames procedurally, supply screenshots and note compromise; do not silently scrape/trace commercial assets.
- Insufficient auto-generated animation quality: simplify style and produce consistent cutouts; test before trying Blender fallback. If impossible, report quality blocker rather than promise exact concept fidelity.
- No Blender: proceed 2D primary route, no blocker. No Godot: identify path and ask for access/setup when missing tool permissions.
- Godot import/scripts fail: fix root cause; don't mark milestone accepted.
- Existing game has different skill set from governing docs: compare latest explicit accepted decisions and seek clarification; avoid editing gameplay without approval.

## Iteration and progress report format
At each gate report: `scope`, `changed files`, `source licenses`, `commands + exit codes`, `test pass/fail`, `screenshots/video paths`, `performance metrics`, `known defects`, `remaining tasks`, `requires user approval?`. Save in repo reports. Never infer approval from silence. No work in background without supported execution environment.

## Acceptance handoff
User should be able to launch Windows demo, select Astra/Vex/Boros, move WASD, use Auto/Manual skills with J/K/L/I remap (existing gameplay contract), see visual skills and augments, play on three map styles, and examine generated QA media without editing an asset manually.
