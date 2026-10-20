class_name ControlMageRuntime
extends Node2D
var intent: CastIntent
var definition: ControlMageExecutor
var combat: CombatService
var elapsed: float = 0
var resolved: bool = false
var rays: int = 0
var orbit_hits: Dictionary[String,float] = {}
var shield: ShieldInstance
var center: Vector2
var origin: Vector2
var burnt: int = 0
var lance_hits: Dictionary[int,bool] = {}
const RAY_LIFETIME: float = .18
var active_rays: Array[Dictionary] = []
var finale_resolved: bool = false
var intro_audio: AudioStreamPlayer2D
var intro_remaining: float = 0
var intro_finished: bool = true
var channel_complete: bool = false

func _ready() -> void:
	center=intent.aim_point
	origin=combat.cast_origin(intent.source())
	if definition.move == "cataclysm":
		global_position=origin
		var previous_voice: WeakRef=intent.source().get_meta("channel_voice_runtime") as WeakRef if intent.source().has_meta("channel_voice_runtime") else null
		if previous_voice!=null and is_instance_valid(previous_voice.get_ref()):(previous_voice.get_ref() as Node).queue_free()
		intent.source().set_meta("channel_voice_runtime",weakref(self))
		intent.source().set_meta("channel_runtime",weakref(self))
		intent.source().set_meta("movement_lock_runtime",weakref(self))
		intent.source().velocity=Vector2.ZERO
		if definition.channel_intro!=null:
			intro_remaining=definition.channel_intro.get_length()
			intro_finished=false
			intro_audio=AudioStreamPlayer2D.new()
			intro_audio.stream=definition.channel_intro;intro_audio.volume_db=definition.channel_intro_db
			intro_audio.max_distance=1600;intro_audio.attenuation=.5
			add_child(intro_audio)
			intro_audio.finished.connect(func() -> void:intro_finished=true)
			if DisplayServer.get_name()!="headless":intro_audio.play()
	if definition.move == "orbit":
		var owner: Actor=intent.source()
		var old: WeakRef=owner.get_meta("orbit_runtime") as WeakRef if owner.has_meta("orbit_runtime") else null
		if old!=null and is_instance_valid(old.get_ref()): (old.get_ref() as Node).free()
		owner.set_meta("orbit_runtime",weakref(self))
		var inner := EffectExecutorDefinition.new()
		inner.kind="shield"
		combat.execute_effect(inner,intent)
		shield=owner.health.shields.back()
		_visual("orbit",owner.global_position,combat.modified_radius(intent),intent.rank.duration)
	elif definition.move in ["lance","cataclysm"]:
		combat.visual_event.emit({"kind":"cast","skill":intent.context.source_skill_id,"position":origin,"radius":combat.modified_radius(intent),"duration":definition.windup,"line_end":intent.direction*intent.rank.range_px,"runtime":weakref(self)})
	else: _visual("prison_warning",center,combat.modified_radius(intent),definition.windup)

func _physics_process(delta: float) -> void:
	var owner: Actor=intent.source()
	if not is_instance_valid(owner) or not owner.health.is_alive(): queue_free(); return
	if owner.statuses.stunned() and (definition.move=="cataclysm" or (definition.move=="lance" and not resolved)): queue_free(); return
	if definition.move=="cataclysm":
		global_position=combat.cast_origin(owner)
		# Voice and combat use independent clocks; playback never delays the rays.
		if not intro_finished and DisplayServer.get_name()=="headless":
			intro_remaining=maxf(0,intro_remaining-delta)
			intro_finished=intro_remaining<=0
		if channel_complete:
			if intro_finished:queue_free()
			return
	elapsed+=delta
	if definition.move=="orbit":
		for index in range(intent.rank.projectile_count):
			var point: Vector2=owner.global_position+Vector2.from_angle(elapsed*definition.orbit_speeds[intent.rank.rank-1]+index*TAU/intent.rank.projectile_count)*combat.modified_radius(intent)
			for target in combat.actors():
				if target.team==owner.team or not target.health.is_alive() or target.global_position.distance_to(point)>14 or not combat.unobstructed(owner.global_position,target.global_position): continue
				var key: String="%d:%d"%[index,target.actor_id]
				if elapsed<float(orbit_hits.get(key,-1)): continue
				orbit_hits[key]=elapsed+definition.orbit_interval
				if intent.context.budget.spend_proc(intent.context.generation_depth+1): combat.hit(owner,target,intent.rank,intent.context)
		if elapsed>=intent.rank.duration: queue_free()
		return
	if definition.move=="cataclysm":
		while rays<intent.rank.projectile_count and elapsed>=definition.windup+rays*definition.channel_duration/maxi(1,intent.rank.projectile_count-1):
			_fire_ray(owner,rays); rays+=1
		_advance_rays(owner)
		if elapsed>=definition.windup+definition.channel_duration and not finale_resolved:
			finale_resolved=true
			if intent.rank.rank==3 and intent.context.budget.claim("cataclysm_final"):
				combat.queue_burst(owner,origin+intent.direction*intent.rank.range_px,intent.context,&"cataclysm_burst",55,85,0,"MAGIC")
		if finale_resolved and active_rays.is_empty():
			channel_complete=true
			_release_channel(owner)
			if intro_finished:queue_free()
		return
	if not resolved and elapsed>=definition.windup:
		resolved=true
		if definition.move=="lance":
			origin=combat.cast_origin(owner)
			_lance_hit(owner)
			combat.visual_event.emit({"kind":"beam","skill":intent.context.source_skill_id,"position":origin,"line_end":intent.direction*intent.rank.range_px,"radius":combat.modified_radius(intent),"duration":.18})
		else:
			for target in combat.actors():
				if target.team==owner.team or not target.health.is_alive() or target.global_position.distance_to(center)>combat.modified_radius(intent) or not combat.unobstructed(center,target.global_position): continue
				var root := StatusEffectDefinition.new()
				root.kind="root";root.duration=intent.rank.duration
				if target is EnemyActor and definition.elite_ids.has((target as EnemyActor).definition.id): root.duration=definition.elite_durations[intent.rank.rank-1]
				combat.hit(owner,target,intent.rank,intent.context,0,root)
			_visual("prison",center,combat.modified_radius(intent),intent.rank.duration)
			_cue(&"prison")
	if definition.move=="lance":
		if resolved and elapsed<=definition.windup+.18: _lance_hit(owner)
		var behavior: SkillBehaviorDefinition=intent.rank.behavior
		if behavior.burn_duration>0 and resolved:
			while burnt<int(floor(behavior.burn_duration/.5)) and elapsed>=definition.windup+(burnt+1)*.5:
				burnt+=1
				var copy := CastIntent.new()
				copy.source_ref=intent.source_ref;copy.context=intent.context.child(&"line_burn");copy.rank=intent.rank.duplicate(true) as SkillRankDefinition
				copy.rank.damage=behavior.burn_damage;copy.rank.behavior=null;copy.direction=intent.direction;copy.aim_point=origin;copy.rank.radius_px=combat.modified_radius(intent)
				if copy.context!=null: combat.beam_tick(copy)
		if elapsed>=definition.windup+maxf(.18,behavior.burn_duration): queue_free()
	elif resolved and elapsed>=definition.windup+intent.rank.duration:
		if intent.rank.rank==4:
			combat.queue_burst(owner,center,intent.context,&"prison_exit",45,combat.modified_radius(intent),0,"MAGIC")
		queue_free()

func _lance_hit(owner: Actor) -> void:
	for target in combat.beam_receivers(owner,origin,intent.direction,intent.rank.range_px,combat.modified_radius(intent)):
		combat.deliver(intent,target,null,lance_hits)

func _fire_ray(owner: Actor,index: int) -> void:
	origin=combat.cast_origin(owner)
	if not intent.context.budget.spend_proc(intent.context.generation_depth+1): return
	var direction: Vector2=intent.direction.rotated(deg_to_rad(-definition.fan_degrees*.5+definition.fan_degrees*index/maxi(1,intent.rank.projectile_count-1)))
	var radius: float=combat.modified_radius(intent)
	# Snapshot each lane: moving the caster must not move an already visible ray.
	active_rays.append({"origin":origin,"direction":direction,"radius":radius,"expires":elapsed+RAY_LIFETIME,"hits":{}})
	combat.visual_event.emit({"kind":"beam","skill":intent.context.source_skill_id,"position":origin,"line_end":direction*intent.rank.range_px,"radius":radius,"duration":RAY_LIFETIME})
	_cue(&"ray")

func _advance_rays(owner: Actor) -> void:
	for index in range(active_rays.size()-1,-1,-1):
		var ray: Dictionary=active_rays[index]
		if elapsed>=float(ray.expires):
			active_rays.remove_at(index)
			continue
		for target in combat.beam_receivers(owner,ray.origin,ray.direction,intent.rank.range_px,ray.radius):
			if ray.hits.has(target.actor_id):continue
			ray.hits[target.actor_id]=true
			for cap in range(definition.hit_cap):
				if intent.context.budget.claim("fan:%d:%d"%[target.actor_id,cap]):
					combat.hit(owner,target,intent.rank,intent.context)
					break

func _visual(kind: String,point: Vector2,radius: float,duration: float) -> void:
	# Dedicated local presentation signal leaves generic VFX factory unchanged.
	var renderer := intent.source().get_node_or_null("MappedEffects") as MappedActorEffects
	if renderer!=null: renderer.show_effect(kind,point,radius,duration,self)

func _cue(id: StringName) -> void:
	var audio := intent.source().get_node_or_null("ActionAudio") as ActionAudio
	if audio!=null: audio.play_cue(id)

func _release_channel(owner: Actor) -> void:
	var lock_ref: WeakRef=owner.get_meta("movement_lock_runtime") as WeakRef if owner.has_meta("movement_lock_runtime") else null
	if lock_ref!=null and lock_ref.get_ref()==self:owner.remove_meta("movement_lock_runtime")
	var channel_ref: WeakRef=owner.get_meta("channel_runtime") as WeakRef if owner.has_meta("channel_runtime") else null
	if channel_ref!=null and channel_ref.get_ref()==self:owner.remove_meta("channel_runtime")

func _exit_tree() -> void:
	var owner: Actor=intent.source() if intent!=null else null
	if not is_instance_valid(owner): return
	if definition.move=="orbit":
		if shield!=null:shield.duration_left=0
		var ref: WeakRef=owner.get_meta("orbit_runtime") as WeakRef if owner.has_meta("orbit_runtime") else null
		if ref!=null and ref.get_ref()==self:owner.remove_meta("orbit_runtime")
	if definition.move=="cataclysm":
		if intro_audio!=null:intro_audio.stop()
		_release_channel(owner)
		var voice_ref: WeakRef=owner.get_meta("channel_voice_runtime") as WeakRef if owner.has_meta("channel_voice_runtime") else null
		if voice_ref!=null and voice_ref.get_ref()==self:owner.remove_meta("channel_voice_runtime")
