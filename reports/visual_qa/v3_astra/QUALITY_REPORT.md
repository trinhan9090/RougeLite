# Astra original pixel v3 review

Status: TECH_PASSED; ART_REVIEW PENDING.

1036 pixel/alpha/clipping/state checks;46 production PLAY/profile/collider checks;35 actual shield/status/area/beam checks. Canonical suites: 35/35 completed, failures=0. 100 deterministic layout seeds per biome (3300checks) in canonical suite. All commands/logs accompany this report.

Images: comparison.png, astra_contact.png, astra_native.png, normal_play.png, crowd_30.png, skill_*.png, augments_*.png. Video: astra_review.mp4 (movement, J/K/L/I, actual live AI crowd, Split/Echo/AreaExpand); normal_play.mp4 (normal run). Screenshots native640x360 and2x1280x720, PNG crisp sampling.

Performance (separate live render run; no movie writer):
```json
{
  "cpu": "AMD Ryzen 5 6600H with Radeon Graphics",
  "enemies": 33,
  "fixture": "real live AI/combat; QA-only invulnerability, high enemy HP and forced cooldowns; no movie writer",
  "gpu": "NVIDIA GeForce RTX 3050 Laptop GPU",
  "max_nodes": 254,
  "max_temporary_vfx": 52,
  "mean_fps": 145.467240777377,
  "mean_ms": 6.8744,
  "median_ms": 6.804,
  "one_percent_low_fps": 65.3893938403191,
  "p95_ms": 11.676,
  "renderer": "gl_compatibility",
  "samples": 600,
  "skill_cycles": 12
}
```

Visual scores are deliberately unassigned until owner review. See known_issues.md, STYLE_GUIDE.md, provenance.json and license_ledger.csv.

Final live-project and packaged verification: PLAY46 checks, VFX35 checks, actual Launch.cmd boot and3-profile/3-boss release smoke all exit0. 82 gameplay files match pre-v3 SHA256 baseline. Build SHA256: c1039da76f669a8cec7f0a3dfc76650ca306c6349bb8f8b6dd12390320b662c5.
