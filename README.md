# Endless Survival RPG — Windows demo

Godot4.7.2 / GDScript / Compatibility renderer. Three complete character kits,12 reusable mechanic augments,8 infinite stat cores,three seeded map templates and two boss archetypes with endless scaling.

## Play

**Packaged:** extract `builds/EndlessSurvival-Windows.zip`, open `windows`, double-click `Play.cmd`. The included runtime needs no Godot installation, PowerShell7 or internet connection.

**From source:** double-click `Launch.cmd` (or `.\Launch.cmd` in Windows PowerShell). Open the editor with `.\Launch.cmd --editor`. A matching engine already exists locally under ignored `tools/godot/`; on a fresh source checkout supply/install Godot4.7.2 as described by `tools/launch.ps1 -GodotPath <executable>`.

Choose Astra/Mage, Vex/ADC or Boros/Brute. WASD moves; the nearest enemy in range is attacked automatically. Auto uses active skills when valid; Manual uses the last movement/facing direction and J/K/L/I (remappable). Skills unlock for free at3/6/9/11, capped at4/4/4/3 ranks. Every level offers one of3 valid upgrades with explicit skill targets and numeric before/after values. Earn one reroll every10 levels, store at most3.

Esc pauses. The pause menu switches Auto/Manual, remaps skills and toggles fullscreen/windowed. Bosses arrive at10/20/30/...; dodge orange warnings. Boss EXP is banked until victory. Winning changes map, keeps permanent upgrades/ranks, clears temporary effects, resets cooldowns, heals15% maximum HP and gives2s immunity. Death ends the run; Retry preserves settings and resets run progress.

The old level10 preview stop has been removed. Automated accelerated runs reach41 with four real boss deaths/map transitions for every character.

## Verify and reproduce

```powershell
pwsh -NoProfile -File tools/test.ps1 -Graphical -EvidencePrefix m5
pwsh -NoProfile -File tools/package.ps1
# Packaged acceptance without the source tree:
.\EndlessSurvival_console.exe --headless --main-pack EndlessSurvival.pck -- --smoke-release
```

The full verification tool requires PowerShell7; launching the demo does not. It imports/parses scripts, runs isolated suites, checks boot and proves deliberate assertion failure exits1. Normal ERROR/SCRIPT ERROR/WARNING/FAIL diagnostics fail the gate. Graphical tests render actual frames; `tests/scenes/test_performance.gd` measures a100-enemy/300-projectile fixture. Exact results are in `docs/WORK_LOG.md` and `docs/evidence/`.

Windows packaging uses an exported PCK plus the official portable engine executable because stripped export templates are absent. This is a standalone runnable private demo, not a signed public release. The package includes engine/third-party licenses. Web export was attempted and is blocked by missing matching Web templates; it is secondary to Windows.

## Architecture and limits

Only Settings and ContentRegistry are autoloads. Run systems own actor state, RNG streams, progression, BossGate and shared combat services. Immutable rank behavior Resources drive character differences. All compatible skills share the same augment implementations; there are no character-ID branches in shared combat/augment executors. Cast snapshots and shared root budgets cap depth3,32 secondary procs and64 projectiles. Global world caps are110 enemies and300 projectiles.

Character visuals are locally authored articulated geometric placeholders with multiple limb joints; sound is synthesized locally. Polished pixel art, final audio/localization, difficulty tuning and source licensing await owner review. The100/300 stress fixture has not met a stable60FPS target on the measured machine; timings are documented, not presented as a guarantee. No human manual acceptance or long-duration balance certification is claimed by automated tests. See `docs/OPEN_QUESTIONS.md` and `docs/MANUAL_QA.md`.

GitHub publication remains blocked by the previously documented Git/authentication restrictions. No push is claimed. Source distribution rights remain reserved pending the owner's license decision.

## Specification read order

`docs/README.md`, then `05_DECISIONS.md` → `01_CORE_ARCHITECTURE.md` → `02_GAMEPLAY_SPEC.md` → `04_TASKS.md` → `03_AGENTS.md` (also root `AGENTS.md`). Canonical progress/evidence is in docs; original root handoff files are historical snapshots.

Main menu: PLAY starts the selected character (Astra initially). CHARACTER shows portraits, base stats and skill unlock/rank/cooldown details and lets you select a character without starting a run. SETTING contains Auto/Manual, key bindings, seed and fullscreen/window controls. BACK TO MENU returns to the entry screen.

Manual aiming: WASD turns the cyan curved facing arrow. Stopping preserves the last facing. Directional skills cast along this facing at their configured range; self skills remain centered on the player. Mouse position does not change Manual aim. Basics remain automatic; ordinary ranged basics fly straight with launch-time leading, while Homing augments explicitly enable turning.

Vex now uses the user-supplied64px sprite atlas for idle/run/attack/cast/dash/death and the CHARACTER preview, with nearest filtering and left/right mirroring. This cosmetic bow skin retains Vex's current gameplay. Eight-direction art is not supplied. Asset provenance is recorded in ASSET_LICENSES.md.

Boros now uses the supplied directional greatsword prototype sprites. All three characters share a72px reference visual height; actor collision and gameplay ranges are unchanged. Transformation retains its temporary visual enlargement. Some Boros poses are provisional/reused as documented by the supplied pack.


Boros frame cleanup: imported visuals now use derived strips under assets/sprites/characters/boros/cleaned, removing disconnected adjacent-pose fragments baked into original cells. Source PNGs are preserved. Rebuild with Python3/Pillow: tools/clean_boros_sprites.py, then Godot editor import followed by --script res://tools/import_boros_sprites.gd. Run the authoring regression with Python tests/unit/test_sprite_cleanup.py. Gameplay launch has no Python dependency.
