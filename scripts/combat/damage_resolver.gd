class_name DamageResolver
extends RefCounted

var events: CombatEventBus

func _init(bus: CombatEventBus = null) -> void:
	events = bus if bus != null else CombatEventBus.new()

func resolve(packet: DamagePacket, source: Actor, target: Actor, rng: RandomNumberGenerator) -> DamageResult:
	var result := DamageResult.new()
	if packet == null or not is_instance_valid(source) or not is_instance_valid(target) or target.is_queued_for_deletion() or source.team == target.team or not source.health.is_alive() or not target.health.is_alive() or target.invulnerability_left > 0.0:
		return result
	if not is_finite(packet.base_damage) or packet.base_damage < 0.0 or packet.damage_type not in [&"PHYSICAL", &"MAGIC", &"TRUE"]:
		return result
	result.accepted = true
	result.target_id = target.actor_id
	var damage: float = packet.base_damage * (source.stats.damage_multiplier if packet.scale_with_stats else 1.0)
	if packet.can_crit and rng != null:
		result.critical = rng.randf() < clampf(source.stats.crit_chance + packet.crit_bonus, 0.0, 1.0)
		if result.critical:
			damage *= maxf(1.0, source.stats.crit_multiplier)
	if packet.damage_type != &"TRUE":
		var resistance: float = target.stats.armor if packet.damage_type == &"PHYSICAL" else target.stats.magic_resistance
		var multiplier: float = 100.0 / (100.0 + resistance) if resistance >= 0.0 else 2.0 - 100.0 / (100.0 - resistance)
		damage *= clampf(multiplier, 0.5, 2.0)
	damage *= clampf(target.factor(&"damage_taken"), 0, 1)
	if packet.scale_with_stats and target.mark_left > 0 and target.marked_by == source.actor_id: damage *= 1.0 + target.mark_bonus
	result.mitigated_damage = maxf(0.0, damage)
	var remaining: float = result.mitigated_damage
	for shield in target.health.shields:
		if shield.duration_left <= 0.0:
			continue
		var absorbed: float = minf(shield.remaining, remaining)
		shield.remaining -= absorbed
		shield.absorbed += absorbed
		remaining -= absorbed
		result.shield_damage += absorbed
	result.hp_damage = minf(target.health.current, remaining)
	result.killed = remaining >= target.health.current
	target.health.commit_resolved_hp(target.health.current - remaining)
	if target.health.is_alive():
		target.statuses.apply(packet.status, target.is_boss)
	events.damage_applied.emit(packet.context, result)
	if packet.context.can_trigger_on_hit:
		events.hit_resolved.emit(packet.context, result)
	if result.critical:
		events.critical_applied.emit(packet.context, result)
	if result.killed and packet.context.can_trigger_on_kill:
		events.actor_killed.emit(packet.context, result)
	return result
