class_name ControlMageExecutor
extends EffectExecutorDefinition
## Bounded composition of shared damage, beam queries, shields and Echo scheduling.
@export_enum("lance", "prison", "orbit", "cataclysm") var move: String = "lance"
@export var windup: float = .16
@export var channel_duration: float = .75
@export var channel_intro: AudioStream
@export var channel_intro_db: float = -8
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
	if channel_intro!=null and (channel_intro.get_length()<=0 or not is_finite(channel_intro.get_length())):errors.append("invalid channel intro audio")
	if not is_finite(channel_intro_db) or channel_intro_db>0:errors.append("invalid intro gain")
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
	var runtime := ControlMageRuntime.new()
	runtime.intent=intent; runtime.definition=self; runtime.combat=combat
	combat.add_child(runtime)
	if move in ["lance","prison"]:
		combat.queue_echo(self,intent,func(copy: CastIntent) -> void: execute_cast(copy,combat))
	return true
