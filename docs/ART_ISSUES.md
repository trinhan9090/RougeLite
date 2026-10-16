# Art QA issues

| ID | State | Finding / resolution |
|---|---|---|
| ART-QA01 | Fixed | Initial generator rejected reversed rectangle coordinates in death pose. Coordinates are normalized; regenerated PNG validation passes. |
| ART-QA02 | Fixed | Windows tempfile default pointed outside writable workspace. Tests now use repository .local-data. |
| ART-QA03 | Fixed | Initial regression overlapped class additions before Godot class-cache refresh, causing transient missing-class/movement failures. Run interrupted; editor import followed by final33-suite clean regression. |
| ART-QA04 | Fixed | First renderer captures showed preview controls overlapping gameplay HUD. Preview hides game HUD; ordinary PLAY HUD unchanged. |
| ART-QA05 | Fixed | Legacy gold flashes/area placeholders overlapped new VFX, and captures retained a preceding long-lived skill. Factory-bound legacy draws are suppressed; capture resets actual transient state between actions. |
| ART-QA06 | Fixed | Death animation froze when run paused on death. Shared visual scene can finish death while living animations remain paused. Test baseline now waits for the process-frame signal to reach node processing before sampling;228 checks pass. |
| ART-QA07 | Fixed | First stress fixture lost projectiles to real enemy collisions, so it did not sustain300. Preserved invalid log; moved real projectiles to a safe lane and reran all3 loads with300 maintained. |
| ART-PERF01 | Improved, open | Cached immutable projectile draws reduced100-enemy median32.836→16.256ms and p9571.856→23.555ms. Stable60FPS remains unproven; A8 gate stays open.200/400 are diagnostic loads above production cap110. |
| ART-REVIEW01 | Pending owner | Original procedural prototype style, silhouette, animation and readability need visual approval. Automated correctness is not subjective approval. |
| ART-WEB01 | Optional, not executed | Windows is the tested deliverable. Web export requires a locally available compatible template. |
