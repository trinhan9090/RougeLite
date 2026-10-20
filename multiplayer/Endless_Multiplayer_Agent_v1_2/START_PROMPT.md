# Start prompt for AI Agent

Read the entire `Endless_Multiplayer_Agent_v1` folder in README order, along with existing repository architecture/gameplay specs.

Implement the host-authoritative LAN/VPN multiplayer mode for 1–4 total players in the current Godot 4 project, preserving solo mode and the Universal Augment System. The user has LOCKED: personal EXP and levels, individual Augment choices without pausing anything, and **absolutely no protection while choosing** (normal damage/aggro/CC/death). Ignore superseded old proposals for team XP and global pause.

Begin with MP0 audit; then implement milestones MP1 through MP8 with tests in `05_TASKS_AND_TESTS.md`. Prefer compatible minimal changes over architecture rewrite, and never alter the art/VFX asset source pipeline. Provide only text execution logs and test results, no screenshots/videos. Where spec has DEMO DEFAULTs, record them; ask approval before changing gameplay assumptions such as EXP ownership, strict timed boss schedule or revive mechanic.

IMPORTANT v1.2: Read `08_TIME_BOSS_SCORE_REVIVE_SPEC.md` first. Audit and disable all legacy map-ticket or map-transition pathways for multiplayer, including tests and network messages; do not remove solo-only functionality. Replace any old level-triggered boss gate with strict 180-second encounter schedule in multiplayer. Add authoritative survival score, one host-generated random map per run (no mid-run map changes), and F-revive combat lock. Do not pause for Augment or make invulnerability.
