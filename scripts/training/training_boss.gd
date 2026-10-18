class_name TrainingBoss
extends BossActor
func _ready() -> void:
	super._ready()
	health = TrainingHealth.new(health.maximum)
	health.changed.connect(func(_hp: float,_max: float) -> void: queue_redraw())
func _physics_process(delta: float) -> void:
	advance_effects(delta)
	velocity = Vector2.ZERO
func _draw() -> void:
	super._draw()
	draw_string(ThemeDB.fallback_font,Vector2(-58,-62),"BOSS TEST / ∞",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("73e8ff"))
