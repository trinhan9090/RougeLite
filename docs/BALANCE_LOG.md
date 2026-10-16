# Balance observations — demo defaults

2026-10-15:100 enemy/300 swept-projectile stress tests on AMD Ryzen5 6600H / NVIDIA RTX3050 Laptop GPU did not sustain the provisional60FPS goal in this environment. No gameplay budget was raised and no test assertion was weakened to claim that goal. Median/p95 frame timing and node cleanup are recorded in m5-performance.log.

M4's adaptive population cap is now explicitly authored:40 at level1,+2 per level, clamped to the existing110 hard maximum. Spawn count/period pressure continues to scale by the original level/time formula, with the same550px exclusion and bounded attempts. This is a DEMO DEFAULT resource knob, not a LOCKED rule or approved final balance. The stress fixture explicitly overrides its detached cap to100 so the full-load measurement remains honest.

Shared flow-field navigation and attack-rank snapshots reduce repeated work. Pooling was not added speculatively; the measured fixture returns live node count to baseline, and no critical hang is claimed resolved merely by lowering the fixture load. Stable60FPS at the full stress load remains a performance follow-up, clearly recorded in OPEN_QUESTIONS.md.
