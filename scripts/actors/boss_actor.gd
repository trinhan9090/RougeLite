class_name BossActor
extends EnemyActor
signal summon_requested
var boss_definition: BossDefinition
var attack_clock: float = 2
var cone_clock: float = 4
var summon_clock: float = 9
var attacks_started: int = 0
func _ready() -> void:
	definition = boss_definition.actor
	is_boss = true
	super._ready()
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var target: Actor = _target.get_ref() as Actor if _target != null else null
	if target == null or not target.health.is_alive() or statuses.stunned(): return
	var fast: float = .8 if health.current/health.maximum < .4 else 1
	attack_clock -= delta
	cone_clock -= delta
	summon_clock -= delta
	if attack_clock <= 0:
		attack_clock = maxf(2,(5 if boss_definition.archetype == "stone" else 6.5)*fast)
		if boss_definition.archetype == "stone": warn("circle",24,170,0,1)
		else:
			warn("beam",24,37.5,1000,1.2)
			if fast < 1:
				warn("beam",24,37.5,1000,1.85,.18)
				warn("beam",24,37.5,1000,2.5,-.18)
	if boss_definition.archetype == "stone" and cone_clock <= 0:
		cone_clock = maxf(2,7*fast)
		warn("cone",30,0,240,1)
	if boss_definition.archetype == "ember" and summon_clock <= 0:
		summon_clock = 9
		summon_requested.emit()
func warn(shape: String, damage: float, radius: float, length: float, seconds: float, angle: float = 0) -> BossTelegraph:
	var target: Actor = _target.get_ref() as Actor
	var warning := BossTelegraph.new()
	warning.source_ref = weakref(self)
	warning.target_ref = weakref(target)
	warning.combat = combat
	warning.shape = shape
	warning.radius = radius
	warning.length = length
	warning.damage = damage
	warning.damage_type = "MAGIC" if shape == "beam" else "PHYSICAL"
	warning.remaining = seconds
	warning.direction = global_position.direction_to(target.global_position).rotated(angle)
	combat.add_child(warning)
	warning.global_position = global_position
	attacks_started += 1
	return warning
func _draw() -> void:
	draw_circle(Vector2.ZERO,30,Color("cda263") if boss_definition.archetype == "stone" else Color("f27450"))
	draw_arc(Vector2.ZERO,36,0,TAU,6,Color("ffe4a8"),5)
	draw_rect(Rect2(-35,-49,70,6),Color("251d31"))
	if health != null: draw_rect(Rect2(-35,-49,70*health.current/health.maximum,6),Color("ffc175"))
