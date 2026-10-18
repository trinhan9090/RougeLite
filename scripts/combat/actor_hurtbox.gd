class_name ActorHurtbox
extends Area2D
## Damage reception only. Never participates in move_and_slide or navigation.
var actor: Actor
func configure(owner_actor: Actor, offset: Vector2, size: Vector2) -> void:
	actor=owner_actor
	position=offset
	collision_layer=8 if actor.team==1 else 16
	collision_mask=0
	monitoring=false
	monitorable=true
	var collider := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius=size.x*.5
	capsule.height=size.y
	collider.shape=capsule
	add_child(collider)
