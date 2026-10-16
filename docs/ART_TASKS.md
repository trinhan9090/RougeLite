# Art implementation backlog

Canonical roadmap: assets/vfx/Endless_Survival_Art_Agent_Handoff_v1/docs/07_TASKS_AND_ACCEPTANCE.md.
Checkboxes here record execution evidence; subjective visual acceptance remains owner-only.

- [x] A0 Inventory and pre-change snapshot; preserve supplied originals. Evidence: art_baseline/inventory.csv, pre_art_source.zip, original_integrity.json (241 original asset files, zero changed).
- [x] A1 Manifest schemas, strict validators, deterministic generators/importer and QC dashboard. Evidence: art_baseline/python_tests.log (6 tests), frames_import.log; screenshots/art/asset_qc.png. Supported schema keywords explicitly scoped in ART_PIPELINE.md.
- [x] A2 Three original four-direction prototype heroes, weapons, profile-driven controller and previews. Evidence: art_baseline/art_frames_test.log (228 checks), three run contact sheets and GIFs. Subjective polish/approval pending.
- [x] A3 Astra five action VFX with actual-event/geometry verification. Evidence: art_baseline/art_vfx_test.log (41 checks across all kits), astra_basic/j/k/l/i.png.
- [x] A4 Vex five action VFX, actual projectile/split binding. Evidence: same VFX suite and retained gameplay matrix, vex_basic/j/k/l/i.png.
- [x] A5 Boros five action VFX, actual shield/slam/charge/buff state. Evidence: same VFX suite, negative split eligibility and full-kit/edge regressions; boros_basic/j/k/l/i.png.
- [x] A6 Three tile themes; 100 seeds/theme, collision/reachability evidence and captures. Evidence: regression_final.log, art maps 3300 checks; map captures at seeds1/42/999.
- [x] A7 Integrate Auto/Manual, upgrades, bosses, preview and scene transitions. Evidence: regression_final.log (33 suites failures0, no error/warning diagnostics), capture.log; CHARACTER → Art preview.
- [ ] A8 Stress/performance logs, provenance, regression and runnable Windows package.

A8 delivery components are implemented: functional100/200/400 stress with300 actual projectiles, provenance ledger, standalone Windows smoke for3 profiles/3 boss victories. Remaining gate: stable60FPS at100/300 (final median16.256ms, p9523.555ms), plus owner visual acceptance. See ART_ACCEPTANCE.md and ART_ISSUES.md. No balance/cap reduction was used.

Owner visual approval: PENDING. No checkbox represents subjective art approval.
