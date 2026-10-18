# Implementation issues and resolutions

- Original west-facing death staff crossed the96px canvas. PNG clipping validation failed; staff rotation was corrected. Final1036 asset checks pass.
- One-time migration initially read Vietnamese source with Windows cp1252. Re-executed with Python UTF-8 mode and explicit UTF-8 reads. Final Godot import and runtime pass.
- First concurrent canonical test invocation stalled at the attacks suite. It was interrupted after a clean subsequent native35-suite run and a second sequential35-suite run with per-suite timeouts. Both completed with zero failures; regression_final.log and regression_bounded.log are authoritative. Initial incomplete tests.log remains diagnostic only.
- Blender emits an optional extension-cache write warning for its protected profile folder. Encoding exits0 and creates the delivered H264 movies; no profile permissions were changed.
- Windows PowerShell5 refused the archive helper under its execution policy during final evidence assembly. The finalizer now uses Python's standard ZIP writer, explicit release-file selection and testzip integrity validation. No execution policy was changed.
- Mirroring the active initial tests.log raised a sharing violation. The finalizer excludes that diagnostic log; evidence mirroring and final integrity verification subsequently exited0.
- Generated art is a simplified original benchmark. Silhouette/animation/map polish remain human review items; technical tests do not establish concept fidelity.
