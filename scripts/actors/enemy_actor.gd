class_name EnemyActor
extends Actor

@export var definition: EnemyDefinition
var _target: WeakRef
var navigation: Callable

# --- roster runtime --------------------------------------------------------
## Behaviour module resolved from EnemyDefinition.behavior_id.
var behavior: EnemyBehavior
## Authored numbers of the archetype (timings, ranges, targeting).
var behavior_settings: EnemyBehaviorSettings
## The archetype's authored attack, used for damage and projectile ranks.
var attack_skill: SkillDefinition
## Presentation data of the archetype.
var visual_profile: EnemyVisualProfile
var audio_profile: EnemyAudioProfile
## Shared services. They are injected by the run root so the archetype never
## has to look them up itself.
var combat: CombatService
var arena: ArenaGeometry
var audio: EnemyAudioService
## Layer that hosts attack telegraphs.
var telegraph_layer: Node2D
## Supplies the living players this archetype may target.
var targets_provider: Callable
## Action block the behaviour wants to show (windup, attack, ...).
var visual_state: StringName = &""
## Direction the archetype is locked to while it telegraphs an attack.
var facing_override: Vector2 = Vector2.ZERO
## Time left of the damage reaction animation.
var hit_flash_left: float = 0.0

var _last_hp: float = -1.0

func _ready() -> void:
	stats_definition = definition.stats if definition != null else null
	team = 2
	super._ready()
	if definition != null:
		behavior_settings = definition.behavior_settings
		attack_skill = definition.attack_skill
		visual_profile = definition.visual_profile
		audio_profile = definition.audio_profile
	if not is_boss:
		var hurtbox_size := Vector2(24, 32)
		var hurtbox_offset := Vector2(0, -18)
		if visual_profile != null:
			hurtbox_size = visual_profile.hurtbox_size
			hurtbox_offset = visual_profile.hurtbox_offset
		hurtbox=ActorHurtbox.new()
		hurtbox.configure(self,hurtbox_offset,hurtbox_size)
		add_child(hurtbox)
		var visual := EnemyPixelVisual.new()
		visual.actor = self
		add_child(visual)
		_setup_behavior()
	_last_hp = health.current if health != null else 0.0

func _setup_behavior() -> void:
	if definition == null:
		return
	behavior = EnemyBehaviorRegistry.create(definition.behavior_id)
	if behavior == null:
		return
	behavior.setup(self)

func set_target(actor: Actor) -> void:
	_target = weakref(actor)

## The single target of the legacy inline steering.
func legacy_target() -> Actor:
	return _target.get_ref() as Actor if _target != null else null

## Every living player the archetype may pick as a target.
func candidate_targets() -> Array[Actor]:
	var result: Array[Actor] = []
	if targets_provider.is_valid():
		var provided: Variant = targets_provider.call()
		if provided is Array:
			for entry in (provided as Array):
				if entry is Actor:
					result.append(entry as Actor)
	if result.is_empty():
		var legacy := legacy_target()
		if legacy != null:
			result.append(legacy)
	return result

## Terminal state of the proximity archetype. The husk ends through the normal
## death lifecycle, so the kill is worth exactly one experience orb.
func self_destruct() -> void:
	if health == null or not health.is_alive():
		return
	visual_state = &"death"
	health.commit_resolved_hp(0.0)

func _physics_process(delta: float) -> void:
	advance_effects(delta)
	_update_damage_reaction(delta)
	if behavior != null:
		behavior.tick(delta)
		return
	# Fallback for enemies without a behaviour module.
	var target: Actor = _target.get_ref() as Actor if _target != null else null
	if not is_instance_valid(target) or not target.health.is_alive():
		velocity = Vector2.ZERO
		return
	var offset: Vector2 = target.global_position - global_position
	var direction: Vector2 = offset.normalized() if offset.length() > (44 if is_boss else 26) else Vector2.ZERO
	if direction != Vector2.ZERO and navigation.is_valid():
		# The arena caches the shared flow field; steering must still use the
		# current body position every physics tick to avoid overshooting turns.
		direction = navigation.call(global_position,target.global_position)
	MovementController.move(self, direction, stats.move_speed * statuses.movement_factor())

func _update_damage_reaction(delta: float) -> void:
	if health == null:
		return
	if _last_hp < 0.0:
		_last_hp = health.current
		return
	if health.current < _last_hp:
		hit_flash_left = 0.18
	_last_hp = health.current
	hit_flash_left = maxf(0.0, hit_flash_left - delta)

func _draw() -> void:
	if health != null and health.current < health.maximum:
		draw_rect(Rect2(-16, -39, 32, 3), Color("3c2533"))
		draw_rect(Rect2(-16, -39, 32 * health.current / health.maximum, 3), Color("f0b46a"))
