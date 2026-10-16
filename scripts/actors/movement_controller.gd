class_name MovementController
extends RefCounted

static func velocity_for(intent: Vector2, speed: float) -> Vector2:
	return intent.limit_length(1.0) * maxf(0.0, speed)

static func move(body: CharacterBody2D, intent: Vector2, speed: float) -> void:
	body.velocity = velocity_for(intent, speed)
	body.move_and_slide()
