# 06 — AGENT.md Rules for the Multiplayer Workstream

## Mission
Add optional 1–4 player LAN/VPN co-op to existing Godot 4 action roguelite without altering skill gameplay, class behavior, art pipeline, or universal Augment mechanics. User only manually tests and approves results.

## MUST
- Inspect project before touching code. Commit/backup on isolated branch. Follow existing `AGENTS.md`, source-of-truth gameplay specs and this network override.
- Implement host authoritative gameplay, separate per-player EXP/level and personal offers. Allow **normal damage while choosing**.
- Add tests for security, repeat RPCs, lifecycle races, player ownership and strict every-180-seconds boss spawn (even with active bosses).
- Keep single-player operational and use shared combat codepaths where possible.
- Log all in-project changes and test executions, including failed steps.
- Use graceful degradation: if VPN service unavailable, validate localhost/LAN and document VPN untested.
- Reuse modules and stable IDs; retain entity provenance and deterministic map seed.

## MUST NOT
- No global pause or immunity during Augment selection; no menu-based reduction in aggro, incoming damage or CC.
- Do not split gameplay authority among clients or trust client-reported damage, XP, enemy hit results, augment rank or cooldown.
- Do not overwrite skill definitions, artwork or VFX to make networking appear successful.
- Do not add Supabase or cloud server without new approval.
- Do not reintroduce shared XP, shared levels, forced team-wide Augment choices, or boss per player.
- Do not state tests passed unless actually executed and logged.

## Escalate
Ask user before changes to EXP ownership policy, strict 180-second spawn cadence and LOCKED single-map-per-run policy, downed/revive behavior, spectator/reconnect support beyond MVP, engine/plugin dependency with new license requirements, gameplay input remapping, or any LOCKED decision. For missing minor parameters choose explicit DEMO DEFAULT and record in `07_DECISIONS_AND_OPEN_ITEMS.md`.

## Deliverable
A runnable Godot project and text-only verification report, with host/join instructions for localhost, LAN and VPN. No screen/video export. Mention latency results factually with hardware and network context.
