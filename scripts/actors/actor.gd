class_name Actor
extends CharacterBody2D

signal died(actor: Actor)
@export var stats_definition: ActorStatDefinition
@export var team: int = 1
var actor_id: int = 0
var stats: ActorStats
var health: Health
var statuses: StatusController = StatusController.new()
var is_boss: bool = false
var is_auxiliary: bool = false
var invulnerability_left: float = 0.0
var motion_active: bool = false
var buffs: Dictionary[StringName, Dictionary] = {}
var marked_by: int = 0
var mark_bonus: float = 0.0
var mark_left: float = 0.0
var extra_basic: int = 0
var native_pulse_scale: float = 0.0
var native_pulse_radius: float = 85.0
var kill_refund_runtime: SkillRuntime
var kill_refund_left: float = 0.0
var kill_refund_seconds: float = 0.0

func factor(key: StringName) -> float:
	var value: float = 1.0
	for buff: Dictionary in buffs.values(): value += float(buff["values"].get(key, 0.0))
	return maxf(0.0, value)

func add_buff(key: StringName, duration: float, values: Dictionary) -> void:
	buffs[key] = {"left": duration, "values": values.duplicate()}
	refresh_max_hp()

func refresh_max_hp() -> void:
	var ratio: float = health.current / health.maximum
	health.maximum = stats.max_hp * factor(&"max_hp")
	health.commit_resolved_hp(health.maximum * ratio)

func clear_temporary() -> void:
	motion_active = false
	buffs.clear()
	refresh_max_hp()
	health.shields.clear()
	statuses = StatusController.new()
	mark_left = 0
	extra_basic = 0
	native_pulse_scale = 0
	kill_refund_left = 0

func _ready() -> void:
	stats = ActorStats.new(stats_definition)
	health = Health.new(stats.max_hp)
	health.depleted.connect(_on_depleted)
	health.changed.connect(func(_current: float, _maximum: float) -> void: queue_redraw())

func advance_effects(delta: float) -> void:
	health.advance(delta)
	statuses.advance(delta)
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	mark_left = maxf(0, mark_left - delta)
	kill_refund_left = maxf(0, kill_refund_left - delta)
	var expired: bool = false
	for key: StringName in buffs.keys():
		buffs[key].left -= delta
		if buffs[key].left <= 0:
			buffs.erase(key)
			expired = true
	if expired:
		refresh_max_hp()
		if factor(&"max_hp") == 1.0: native_pulse_scale = 0

func _on_depleted() -> void:
	velocity = Vector2.ZERO
	collision_layer = 0
	set_physics_process(false)
	died.emit(self)
