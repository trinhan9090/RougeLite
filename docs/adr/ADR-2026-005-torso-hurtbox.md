# Ground locomotion versus torso damage reception

Approved scope: explicit user correction2026-10-17, followed by Vex/Boros visual completion.
Enemy ground collision remains the original13px circle at grounded actor origin.
Normal enemy damage reception uses a24x32 capsule centered18px above its feet,
matching the pixel silhouette. Dedicated Area2D layers8/16 represent player/enemy
hurtboxes. Projectile sweep includes areas; ignores a body's ground collider if
that actor has a hurtbox; excludes area RID and deduplicates by actor ID for Pierce.
Bosses and simple Actor fixtures retain existing geometry until configured.
Actor.hit_position supplies torso position for prediction, homing, beam hits and
impact feedback. Nearest selection, melee range, ground AOEs, navigation, spawn
safety, damage and proc ordering remain ground-based and unchanged.
Latest instruction explicitly supersedes the Astra-first visual review gate for
continuing Vex/Boros. Simplified faces permitted; hair/hats/cloaks remain.

Presentation additions: CombatService.projectile_fired is emitted only for accepted projectile spawns; shared ActorSprite consumes it for real recoil. PixelVisualEffect reads actual buff IDs/shield references, and dash visuals are children of TimedCombatEffect. Ricochet and damaging-trail visuals are emitted at accepted native gameplay events/ticks. No extra gameplay timers, outgoing packets, proc recursion, RNG draws or skill-specific branches added to the augment engine.
