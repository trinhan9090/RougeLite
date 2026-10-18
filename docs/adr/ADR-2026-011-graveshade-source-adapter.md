# ADR-2026-011: Graveshade source-backed content adapter
Date:2026-10-17
Status:implementation mapping within existing contracts

User explicitly authorizes sixth ADC Graveshade and supplied Punisher reuse, no QA media. Existing DamageResolver, projectile sweep/factory, universal eligibility/modifier/budget order, progression, controls, boss schedule and save schema are unchanged. No new autoload, CombatSystem fork, global capability semantics or public-interface changes.

TacticalExecutor is a data-selected bounded component for burst/grenade/mine/rocket composition. Burst reuses CombatService.spawn_pattern, including Split/Pierce/Multishot/Homing; a peractivation observer excludes already capped target RIDs on existing projectiles. Echo activations have separate burst counters. PayloadFlight observes real shared CombatProjectile lifetime to trigger area damage at impact/range expiry; flight direct damage iszero and its proc flags are disabled. All final damage/status goes through existing CombatService.hit. Mine actors own perrun timers/dedupe, have cap6 and are cleared with combat children. No source code executed.

Visual/audio adapters are opt-in SpriteFrames metadata, use actual decoded local source, and react to authoritative events. Runtime root only binds/clears optional presentation; roster/training gains sixth slot. Five existing kits untouched. Latest Doom request reduces only optional presentation profile sizes22x11 and16impact.

Tradeoffs: source only has horizontal artwork; no fake rear view. No archive bytes supplied locally. Sound semantic listening and art approval remain pending. Original community IP rights unverified; private local assets excluded fromGit. Base source projectile is invisible; source FN P90 tracer is explicitly adapted for Basic. Native source ammo, fighting inputs, cinematic helper state machine and logo rights are not claimed as own implementation.

Required verification: focused actualGodotskills, source/hash/PCM checks, full regression, currentLaunchGUI, real600second30/60/120mobsoak. No locked architectural or gameplay redesign requested.

Optional data-defined SocketProjectileBasic delegates to existing basic executor after setting runtime-owned actor muzzle offset. Tactical actions choose their own source-art socket and recompute Auto firing direction. Shared ActorSprite accepts opt-in source start-frame/sustained-action metadata; default existing heroes unchanged. No skeleton is invented for SFF sprites.
