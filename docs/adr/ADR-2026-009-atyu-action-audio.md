# ADR-2026-009 — Data-configured action audio presentation

Date:2026-10-17. Status: implementation of explicitly requested audio integration.

User approval/reference: latest user requests Atyu SND extraction, CNS mapping to Basic/J/K/L/I, AudioStreamPlayer2D and animation/VFX synchronization. Scope is local private testing of the supplied mod, not redistribution permission.

Decision: add one per-actor `ActionAudio` presentation adapter selected through read-only SpriteFrames metadata. ActorSprite exposes additive `action_started(action)` after resolving combo variants. Accepted basics with slot-action visuals explicitly start their animation; actual custom runtime effect branches dispatch effect cues. Existing damage events drive impact audio. Reuse a bounded pool of twelve positional voices and64 pending delayed cues. Preserve timing, targets, damage, unlocks, ranks, augments, event/proc budgets and settings schema.

Alternatives: frame polling can miss repeated same-animation starts; independent timers can play impact sounds for cancelled/missed effects; copying sound logic into individual skills duplicates lifecycle/pooling. The selected adapter shares cue scheduling, loading and cleanup while runtime owns whether an effect actually occurred.

Affected contracts: additive presentation signal only. No locked combat/augment public interfaces or ownership changes. Basic damage still resolves immediately as before; its source swing sound remains at2/60s where specified. Source CNS timings are adapted at actual game effects, not used to delay gameplay.

Tests: lossless supplied binary parsing plus malformed/cycle rejection; actual imported streams, combo interruption, rejected commands, real delayed effect timing, missing target, Auto/Manual, pause/cleanup/reset/voice caps, ordinary PLAY and non-profile hero isolation; source headless regression and current Launch GUI playback. Evidence in ATYU_AUDIO.md and WORK_LOG.md.

Consequences: missing CNS sound IDs require explicit, documented in-package substitutions. Perceived mix needs the user's listening test. Private audio is excluded from Git; reproducible extraction remains local and offline.
