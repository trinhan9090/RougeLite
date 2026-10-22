class_name PlayerActor
extends Actor
const VISUAL_HEIGHT: float = 72.0

var facing: Vector2 = Vector2.RIGHT
var attack_direction: Vector2 = Vector2.RIGHT
var hitbox_indicator: HitboxIndicator
var tint: Color = Color("71d8f3")
var attack_flash: float = 0.0
var rig: JointedCharacter
var weapon: String = "staff"
var manual_aim: bool = false
var visual_frames: SpriteFrames
var sprite_visual: ActorSprite
var action_audio: ActionAudio

func face_toward(point: Vector2) -> void:
	var offset: Vector2 = point - global_position
	if offset.length_squared() > .0001: facing = offset.normalized()

func record_attack_direction(direction: Vector2) -> void:
	if direction.is_finite() and direction.length_squared() > .0001:
		attack_direction = direction.normalized()

func _ready() -> void:
	super._ready()
	hitbox_indicator = HitboxIndicator.new()
	hitbox_indicator.actor = self
	add_child(hitbox_indicator)
	if visual_frames != null:
		sprite_visual = (preload("res://scenes/characters/character_visual.tscn").instantiate() as ActorSprite) if visual_frames.get_meta("cardinal",false) else ActorSprite.new()
		sprite_visual.actor = self
		sprite_visual.sprite_frames = visual_frames
		add_child(sprite_visual)
		if visual_frames.has_meta("audio_profile"):
			action_audio = ActionAudio.new()
			action_audio.name = "ActionAudio"
			action_audio.actor = self
			add_child(action_audio)
	else:
		rig = JointedCharacter.new()
		rig.actor = self
		rig.weapon = weapon
		add_child(rig)

func _physics_process(delta: float) -> void:
	advance_effects(delta)
	# Optional per-action lock; an expired runtime cannot leave controls stuck.
	var lock_ref: WeakRef=get_meta("movement_lock_runtime") as WeakRef if has_meta("movement_lock_runtime") else null
	if lock_ref!=null and is_instance_valid(lock_ref.get_ref()) and not (lock_ref.get_ref() as Node).is_queued_for_deletion():
		velocity=Vector2.ZERO
		return
	if motion_active: return
	attack_flash = maxf(0.0, attack_flash - delta)
	var intent := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if intent.length_squared() > 0.0:
		facing = intent.normalized()
	MovementController.move(self, intent, minf(550, stats.move_speed * factor(&"move_speed")) * statuses.movement_factor())
	queue_redraw()

func _draw() -> void:
	var shell: WeakRef = get_meta("shield_visual") as WeakRef if has_meta("shield_visual") else null
	var custom_shell: bool = shell!=null and is_instance_valid(shell.get_ref()) and (shell.get_ref() as Node).is_inside_tree()
	if health != null and health.shield_total() > 0 and not custom_shell: draw_arc(Vector2.ZERO, 21, 0, TAU, 32, Color("92aaff"), 3)
	if attack_flash > 0.0 and (visual_frames == null or not visual_frames.get_meta("cardinal",false)):
		draw_arc(Vector2.ZERO, 38, attack_direction.angle() - 0.7, attack_direction.angle() + 0.7, 12, Color("ffe7a0"), 4)
