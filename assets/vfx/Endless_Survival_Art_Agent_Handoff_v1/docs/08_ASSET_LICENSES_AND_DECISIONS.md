# 08 — LICENSES, OPEN QUESTIONS, DECISION CONTROL

## Locked by owner
- Free-first toolchain; Godot 4/GDScript; Pixel Art top-down 3/4; Astra is male Mage, Vex western dual pistol ADC, Boros gritty huge-sword Brute; no direct copyrighted character or proprietary sprite copying.
- Owner only reviews and playtests; agent responsible for source, files, code, screenshots, QA and fixes.
- Basic auto nearest enemy; active Auto/Manual; WASD and remappable J/K/L/I; level skill unlock 3/6/9/11; generic augment/capability system; boss level 10 multiples; map change post-boss.
- Previous approved character ability mappings stay authoritative even when image concept shows altered versions.

## Demo defaults NOT final balance or locked art facts
- 128×128 frames, 32×32 tiles, 640×360 logical resolution, cardinal 4-view art, 24-color main palette, specific particles/shake durations, camera zoom, 3 map themes, exact VFX colors, 16 retries, art-budget limits.
- If existing project has a coherent tested art scale, Agent may adapt these values while documenting side-by-side why; never change gameplay distances/collision merely to fit art.

## License ledger schema
`asset_id,asset_path,source_url,author,license,license_url,modifications,commercial_use_allowed,attribution_required,verification_date,notes`
- For wholly generated original assets, `source_url=internal-generated`, author recorded as project/automation, and seed/source-code path noted; verify training/reference use policy as applicable.
- CC0 attribution legally optional but provenance should still be logged. CC-BY requires attribution. CC-BY-SA may introduce obligations; agent must not import incompatible licenses by default. Don't assume everything on itch.io/OpenGameArt is free to redistribute.
- No rasterized screenshots, ripped game sprites, traced art from recognizable IPs, trademark badges or text from commercial games. Concepts in this bundle are mood references and the user-approved artistic direction, not necessarily sprite atlases.

## Change control / uncertainty
- Visual improvement without altering mechanics: agent may implement and document.
- Any skill change, alternate skill mapping, core eligibility, hitbox dimensions, boss cadence, gameplay statistics, or new paid dependency: require owner approval.
- When free resources can't yield acceptable result: generate transparent placeholders + diagnostic visuals, disclose quality gap and offer human review, never fabricate success.
- Maintain `docs/ART_DECISIONS.md` appended with decision ID, date, status, rationale, affected files, and test evidence.

## Release requirements
- Runnable Windows export (if export templates installed) or tested Godot project. No broken external asset URLs at runtime; all final assets included locally; reproducible from source using documented command.
- Complete license ledger, generated assets reproducible, no missing dependencies, performance logs, animation atlas tests, screenshots and known limitations.
