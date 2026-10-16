# 07 — BUILD ROADMAP / DEPENDENCIES / DEFINITION OF DONE

## Deliverable milestones (complete in sequence unless existing project already satisfies gate)
| ID | Work | Automated gate | Owner review point |
|---|---|---|---|
| A0 | Inspect Godot repo; snapshot files; read prior gameplay docs; map existing assets/scenes/scripts | complete inventory + zero overwritten originals | none |
| A1 | Implement manifest schemas, PNG validator, deterministic art generator/importer, contact-sheet script | 100% schema tests pass; forced invalid frames fail correctly | 1 screenshot of asset QC dashboard |
| A2 | Produce all 3 original four-way actor silhouettes and idle/run/basic sprites, weapon sprites, Pixel Art import resources | scenes run, visual directions aligned; no frame overlap | compare all 3 to concept refs |
| A3 | Implement reusable VFX runtime and basic/J/K/L/I visuals for Astra | 5 effect event tests and battle preview | review Astra |
| A4 | Produce Vex VFX, projectile patterns, dash, pierce and Bullet Storm visuals | no invented hits; all sprite resources valid | review Vex |
| A5 | Produce Boros VFX, slam/shield/charge/titan buff visuals | no split on slam, physics/visual agreement | review Boros |
| A6 | Generate 3 coherent tilemap themes, seeded obstacles and proper Nav | 100 seeds/theme reachability, 3 screenshots/theme | map readability review |
| A7 | Integrate all art with existing game/skill/augment, build UI action preview and full state transitions | Auto/Manual, upgrades and boss transitions retain integrity | complete run playtest |
| A8 | Stress, polish, attribution, Windows build and optional Web export | no blocker warnings, all runtime test reports, ledger, release archive | final acceptance |

## Strict DoD for each character
- Uses source-generation process reproducible from fresh checkout and produces RGBA PNGs with alpha, animation manifest, weapon sockets and Godot scene.
- Idle/run/basic cardinal facings and state fallback; frame indices never show neighboring frame/duplicate strip; no weapon clipping into background, wrong facing or sprite jitter.
- Basic + 4 skills show intentional, clearly different animated VFX with timing, origin, cleanup and bounded count. For levels before unlock, VFX never fires.
- Demo shows actual `SkillRuntime` stats: rank changes alter appropriate radius/quantity/width/tempo, never just decorative damage numbers.
- Four-direction contact sheet + five skill screenshots + a demo sample video/GIF, all stored as artifacts.

## Test matrix (MUST implement, not merely document)
| Case | Expected |
|---|---|
| ASTRA_J with projectile_split | actual spawned projectiles all get snare trails and hit status VFX only on confirmed hit |
| VEX_L with projectile_split | same universal split modifier and VFX factory, orange tracer |
| BOROS_J with projectile_split | offer ineligible and no VFX |
| ASTRA_I | beam aligned with attack geometry, split not offered |
| VEX_K dash obstructed | dust trail ends where physics dash stops |
| BOROS_K absorbed damage | shield impact, no fake reflected projectile unless gameplay fires reflect |
| BOROS_I buff expiry | aura and scale restored to baseline, no stale hitbox mismatch |
| 4 way movement | animation and sword/gun/staff attachment faces movement, not cursor (unless skill aiming explicitly cursor-controlled) |
| enemy crowd & loot | player visible and EXP orbs distinguishable |
| 3 maps × 100 seeds | obstacle collision, safe zones, navigation reachability |
| rapid deaths/scene reload | no orphan VFX, crash, Resource state leakage |
| manually remapped keys | animation/UI driven from actions, not hardcoded J/K/L/I scanning in visual scripts |

## No-trick acceptance
A pass requires an executable Godot scene/application, not just concept art, screenshots, or placeholder functions. If agent lacks image-generation access, its fallback procedural sprites must still be original, visually coherent and properly declared *prototype art*. Art-pipeline automation can be considered implemented without falsely claiming visual quality is complete.
