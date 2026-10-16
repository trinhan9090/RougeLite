# Questions and defaults pending owner review

Latest instruction (2026-10-15): continue M3-M5 autonomously, record unanswered questions and self-test/fix. No LOCKED rule may change.

| Question | Implemented provisional behavior | Can change later |
|---|---|---|
| Final pixel character packs and visual identity? | Original locally authored jointed geometric rigs with shoulders/elbows, hips/knees, torso/head and staff/pistols/hammer. Idle/walk/attack/dash/transform feedback. No paid or third-party character assets. | Replace visual component without combat/augment changes. Polished sprite animation is not claimed. |
| Source distribution license? | Rights reserved pending owner selection. Godot and third-party notices extracted from the exact running engine. | Owner can choose MIT or another license before public publication. |
| UI language and final audio/music style? | English UI, quiet locally synthesized short hit/kill tones; no downloaded music. | Localization and final audio pass. |
| Recasting an existing temporary buff? | Refresh same skill's buff; do not stack the same transform. Preserve HP ratio on max-HP changes. | Data/lifecycle policy can be reviewed without changing permanent upgrades. |
| Shield expiry behavior if broken early? | Native expiry blast/heal happens at the authored duration end, using total absorbed damage; no repeat or early re-cast heal exploit. | Final balance/animation timing needs owner review. |
| Native transformation and permanent HP upgrades overlap? | Permanent stats remain baseline; temporary max-HP multiplier applies above it, retaining current HP ratio at entry/refresh/expiry. | Test-backed policy retained unless owner chooses otherwise. |
| Boss-summoned enemies and OnKillBurst? | Summons are auxiliary: normal XP, enemy cap and safe spawn apply, but they cannot trigger OnKillBurst. | Explicit catalog exclusion respected. |
| Web delivery? | Secondary export attempted. Missing matching Web export templates currently block it; Windows does not depend on Web. | Install matching templates, then browser QA. |
| GitHub publication? | Earlier Git metadata/authentication restrictions remain. No push claimed. | Requires usable authenticated Git context. |
| Final difficulty/TTK and 60FPS target? | Authored DEMO DEFAULT combat values retained; accelerated regression is not a natural-play balance claim. Hardware-specific performance measurements are recorded. | Tune only after measured play feedback. |

No unresolved item authorizes a change to WASD, J/K/L/I, free3/6/9/11 unlocks,4/4/4/3 caps,3 choices, universal augment binding,10-level bosses or post-victory map changes.
