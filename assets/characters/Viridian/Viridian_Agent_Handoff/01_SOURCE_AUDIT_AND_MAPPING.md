# 01 — Source audit and M.U.G.E.N state mapping

## Archive configuration — CONFIRMED_SOURCE_TEXT
- Archive: `MVC2_DrDoom-AI(Maro).zip`.
- Base: `MVC2_DrDoom.def` refers to `MVC2_DrDoom.sff`, `.air`, `.snd`, base `.cns`, medium `.cmd`.
- AI variant: `MVC2_DrDoom-AI(Maro).def` references `Maro/MVC2_DrDoom.air`, `Maro/MVC2_DrDoom.cns`, `Maro/MVC2_DrDoom.cmd`, extra AI CNS, while reusing parent SFF/SND.
- Primary animation/skill analysis should start with **base** configuration; use Maro only for cross-checking and additional effects. No character AI needed in Endless Survival.
- Base CNS contains recognizable labels and associated `Statedef` IDs below. The sprite shape, palette and sounds have **not** yet been confirmed by decoding SFF/SND.

| Source label | State ID candidates | Planned usage | Verification |
|---|---|---|---|
| Photon Shot | 1510,1511 | Emerald Bolt auto attack | Source text confirmed; VFX candidate |
| Plasma Beam | 1450,1460,1470 | J Plasma Lance | Source text confirmed; visual candidate |
| Unibeam | 1240,1250,1260 | J alternate visual / beam fallback | Source text confirmed; visual candidate |
| Electric Cage | 3000–3019 (inspect exact existing IDs) | K Arcane Prison | Source text confirmed; bounds to verify |
| Molecular Shield | 1480–1500, 3120–3121 (inspect exact existing IDs) | L Molecular Orbit | Source references confirmed; bounds to verify |
| Photon Array | 3080–3099 (inspect exact existing IDs) | I Photon Cataclysm | Candidate range; verify each state |
| Sphere Flame | 3040–3049 (inspect exact existing IDs) | Optional extra VFX / passive | Source text confirmed |
| Warp | 1400–1425 (inspect exact existing IDs) | Not part of current kit; optional future alternate | Source text confirmed |

**Do not assume state number == action number or sprite group.** Parse CNS controller references (ChangeAnim, Explod, Helper, Projectile, PalFX, PlaySnd, ChangeState), inspect referenced AIR action frames, and locate actual SFF sprite group/index. Helper states may reside in another CNS file.

## Extraction pipeline
1. Validate archive hashes; unpack to isolated `tools/mugen_sources/viridian_original/`; never modify source.
2. Parse DEF and resolve referenced file paths for both base and Maro variants; flag missing relative references.
3. Extract SFF (preserve group,index, offsets, palette/alpha; transparent PNG). Record SFF version and extraction errors.
4. Parse AIR preserving frame duration, index, group, offsets, flips, collision boxes and loop points.
5. Decode SND, retain original group/index IDs, inspect audio duration and waveforms, export WAV or OGG as permitted.
6. Build dependency graph CMD input -> CNS state -> ChangeAnim/AIR -> SFF frames; collect Explod/Helper/Projectile and PlaySnd triggers.
7. Generate **offline** HTML browsable catalogs with animation playback and SFX playback; export CSV mapping and sample clips.
8. Reviewer confirms actual preview for each mapping; store verified/fallback status in `viridian_import_manifest.json`.

## Required source evidence per asset
`source_archive_sha256`, `definition_variant`, `cns_path`, `state_id`, `controller_type`, `air_action_id`, `sprite_refs[]`, `sound_refs[]`, `source_license_status`, `verified_by_preview`, `fallback_required`, `notes`.

## Gating rules
- Mark missing sprite groups/animations as `UNVERIFIED`; do not invent source IDs.
- Imported artwork is a *visual test*, not a combat system import.
- Screen-space 2D fighter frames do not provide 4-direction top-down art. Show a clear mismatch report with direction coverage and silhouette issues.
- No extracting textures/audio from unauthorized online downloads; operate on user-provided archive and licensed assets only.
