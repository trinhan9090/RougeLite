class_name ControlMageExecutor
extends EffectExecutorDefinition
## Bounded composition of shared damage, beam queries, shields and Echo scheduling.
@export_enum("lance", "prison", "orbit", "cataclysm") var move: String = "lance"
@export var windup: float = .16
@export var channel_duration: float = .75
@export var fan_degrees: float = 70
@export var hit_cap: int = 2
@export var orbit_interval: float = .7
@export var orbit_speeds: Array[float] = [2.5,2.5,3.25,3.25]
@export var elite_durations: Array[float] = [.7,.7,.85,.85]
@export var elite_ids: Array[StringName] = [&"enemy.elite_brute"]

func supported_capabilities() -> Array[StringName]:
	var caps: Array[StringName] = [&"damage",&"on_hit_hook",&"on_kill_hook",&"cooldown_manage",&"resize_area"]
	if move in ["lance","prison"]: caps.append(&"repeat_cast")
	if move == "prison": caps.append(&"apply_status")
	if move == "orbit": caps.append_array([&"modify_shield",&"damage_taken_hook"])
	return caps

func validate() -> PackedStringArray:
	var errors := super.validate()
	if move not in ["lance","prison","orbit","cataclysm"] or windup < 0 or channel_duration<=0 or hit_cap<1 or orbit_interval<=0 or orbit_speeds.size()!=4 or elite_durations.size()!=4: errors.append("invalid Control Mage executor")
	for number in [windup,channel_duration,fan_degrees,orbit_interval]:
		if not is_finite(number): errors.append("nonfinite Control Mage timing/geometry")
	if hit_cap>2 or fan_degrees<0 or fan_degrees>180: errors.append("invalid multibeam cap/spread")
	for speed in orbit_speeds:
		if not is_finite(speed) or speed<=0: errors.append("invalid orbit speed")
	for duration in elite_durations:
		if not is_finite(duration) or duration<=0: errors.append("invalid elite CC duration")
	return errors

func execute_cast(intent: CastIntent, combat: CombatService) -> bool:
	var source: Actor = intent.source()
	if not is_instance_valid(source) or not source.health.is_alive(): return false
	if move == "cataclysm" and source.has_meta("channel_runtime"):
		var old := source.get_meta("channel_runtime") as WeakRef
		if old != null and is_instance_valid(old.get_ref()): return false
	intent.context.freeze_modifiers()
	if move == "prison" and not intent.manual and not intent.context.is_echo:
		var best: int = -1
		var best_distance: float = INF
		var best_id: int = 2147483647
		for candidate in combat.actors():
			if candidate.team==source.team or not candidate.health.is_alive() or source.global_position.distance_to(candidate.global_position)>intent.rank.range_px or not combat.unobstructed(source.global_position,candidate.global_position): continue
			var count: int = 0
			for neighbor in combat.actors():
				if neighbor.team!=source.team and neighbor.health.is_alive() and candidate.global_position.distance_to(neighbor.global_position)<=combat.modified_radius(intent) and combat.unobstructed(candidate.global_position,neighbor.global_position): count+=1
			var distance: float = source.global_position.distance_squared_to(candidate.global_position)
			if count>best or (count==best and (distance<best_distance or (distance==best_distance and candidate.actor_id<best_id))):
				best=count; best_distance=distance; best_id=candidate.actor_id; intent.aim_point=candidate.global_position
		if best>=0: intent.direction=source.global_position.direction_to(intent.aim_point)
	var runtime := ControlMageRuntime.new()
	runtime.intent=intent; runtime.definition=self; runtime.combat=combat
	combat.add_child(runtime)
	if move in ["lance","prison"]:
		combat.queue_echo(self,intent,func(copy: CastIntent) -> void: execute_cast(copy,combat))
	return true
