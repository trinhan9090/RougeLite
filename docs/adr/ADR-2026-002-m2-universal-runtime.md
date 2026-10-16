# ADR: M2 universal runtime adapters and event ownership

Date: 2026-10-15

Status: Implemented within the approved architecture; no LOCKED requirement changed.

Context: M2-02 through M2-08 require executable capabilities, common casts, targeted ranks and bounded secondary effects. M1 provided basic combat and global stats.

Decision:

- SkillController accepts Auto and Manual requests through CastIntent and the same executor/cooldown transaction. SkillInputRouter translates InputMap events. AttackController stays automatic in both modes.
- EffectExecutorDefinition implements projectile patterns, areas, beams, shields, dashes and statuses. Capabilities derive from actual adapters; validation rejects unsupported claims and invalid geometry. Bound basic projectile strategies reuse the same pattern adapter.
- AugmentManager owns detached mechanic definitions and ranks per `(augment_id, skill_id)`. UpgradeOption identifies target, slot, current rank and kind. OfferGenerator samples valid bound options without replacement; eight infinite stats provide fallback.
- CombatContext freezes modifier values at cast time using full GDScript float precision. Descendant and collision envelopes share CastBudget, but have distinct event IDs and stable parent/projectile identities. Later hits do not mutate published envelopes.
- CombatService drains a deterministic queue snapshot each physics frame. Primary-only, once-per-root and allowed-secondary policies are evaluated explicitly; descendants share depth/proc limits. Projectile emission consumes a root counter and truncates final generated shots first.
- Pattern order is base lanes, Multishot, Split on each primary lane, damage scale, pierce and steering. Split shots are secondary. Echo repeats once after 0.6s without another cooldown; secondary casts cannot split again. DamageResolver remains the shared damage/status formula.
- Safety limits live in `content/progression/combat_limits.tres`: depth 3, procs 32, projectiles 64 (editable DEMO DEFAULTS). User explicitly selected Reflect's boss cap at 1% maximum HP per hit.

Implementation mapping: ModifierRegistry responsibility is implemented by AugmentManager's stable-ID accumulation and CombatContext's frozen snapshot. TimedCombatEffect owns area ticks/dash movement; CombatFlash provides geometric feedback. No new autoloads.

Consequences: shared mechanics never branch on characters. M2 loadouts contain baseline adapters for real scene testing; complete character-specific rank effects, timed barrages, buffs and transformation remain M3. The level-10 pending-boss preview boundary remains until M4.

Tests: lifecycle, cast modes, capabilities/geometry negatives, bound offers, event envelopes, two-compatible/one-incompatible effect matrix, three real loadout scenes and four-way combinations. Commands/evidence are in WORK_LOG.md.

User references: request to complete M2; explicit selections of Split rank 5 (6 extra shots at 65%) and Reflect boss cap (1% maximum HP per hit). No broader architecture or LOCKED gameplay change introduced.
