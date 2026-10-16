extends SceneTree

var _checks: int = 0
var _failures: int = 0
var _kills: int = 0
var _hits: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)

func _actor(team: int) -> Actor:
	var actor := Actor.new()
	actor.team = team
	actor.stats_definition = ActorStatDefinition.new()
	root.add_child(actor)
	return actor

func _run() -> void:
	var source := _actor(1)
	var target := _actor(2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var resolver := DamageResolver.new()
	resolver.events.actor_killed.connect(func(_ctx: CombatContext, _result: DamageResult) -> void: _kills += 1)
	resolver.events.hit_resolved.connect(func(_ctx: CombatContext, _result: DamageResult) -> void: _hits += 1)
	var packet := DamagePacket.new()
	packet.base_damage = 30
	target.stats.armor = 50
	var result := resolver.resolve(packet, source, target, rng)
	_check(is_equal_approx(result.hp_damage, 20.0), "physical armor exact mitigation")
	target.stats.magic_resistance = 100
	packet.damage_type = &"MAGIC"
	_check(is_equal_approx(resolver.resolve(packet, source, target, rng).hp_damage, 15.0), "magic resistance exact mitigation")
	packet.damage_type = &"TRUE"
	_check(is_equal_approx(resolver.resolve(packet, source, target, rng).hp_damage, 30.0), "true damage ignores resistance")
	packet.damage_type = &"PHYSICAL"
	target.stats.armor = -50
	packet.base_damage = 3
	_check(is_equal_approx(resolver.resolve(packet, source, target, rng).hp_damage, 4.0), "negative armor formula")
	target.stats.armor = 0
	var first := ShieldInstance.new(5, 4)
	var second := ShieldInstance.new(10, 4)
	target.health.shields = [first, second]
	packet.base_damage = 12
	result = resolver.resolve(packet, source, target, rng)
	_check(result.hp_damage == 0 and result.shield_damage == 12 and first.remaining == 0 and second.remaining == 3, "FIFO shield absorbs before HP")
	target.health.advance(5)
	_check(target.health.shield_total() == 0, "shields expire on simulation clock")
	packet.base_damage = 4
	packet.can_crit = true
	source.stats.crit_chance = 1.0
	source.stats.crit_multiplier = 1.5
	_check(resolver.resolve(packet, source, target, rng).hp_damage == 6, "guaranteed critical multiplier")
	source.stats.crit_chance = 0.4
	var saved: int = rng.state
	var expected_critical: bool = rng.randf() < 0.4
	rng.state = saved
	_check(resolver.resolve(packet, source, target, rng).critical == expected_critical, "crit uses explicit seeded RNG")
	packet.can_crit = false
	packet.status = StatusEffectDefinition.new()
	resolver.resolve(packet, source, target, rng)
	_check(target.statuses.movement_factor() == 0.0 and not target.statuses.stunned(), "root blocks movement but not attack")
	target.statuses.advance(2)
	_check(target.statuses.movement_factor() == 1.0, "root expires")
	packet.status.kind = "slow"
	packet.status.strength = 0.99
	target.statuses.apply(packet.status)
	_check(is_equal_approx(target.statuses.movement_factor(), 0.35), "slow minimum movement factor")
	var boss_status := StatusController.new()
	packet.status.kind = "stun"
	boss_status.apply(packet.status, true)
	_check(boss_status.stunned(), "boss hard CC converts to stagger")
	boss_status.advance(0.2)
	boss_status.apply(packet.status, true)
	_check(not boss_status.stunned(), "boss stagger immunity cooldown")
	packet.base_damage = -1
	_check(not resolver.resolve(packet, source, target, rng).accepted, "negative damage rejected")
	packet.base_damage = 1000
	_check(not resolver.resolve(packet, source, source, rng).accepted, "friendly damage rejected")
	result = resolver.resolve(packet, source, target, rng)
	_check(result.killed and _kills == 1, "lethal hit emits one kill")
	resolver.resolve(packet, source, target, rng)
	_check(_kills == 1 and _hits > 0, "dead target emits no duplicate kill and hits dispatched")
	source.queue_free()
	target.queue_free()
	await process_frame
	print("RESULT damage: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
