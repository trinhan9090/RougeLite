class_name SkillInputRouter
extends RefCounted

static func handle(event: InputEvent, controller: SkillController, mouse_world: Vector2) -> bool:
	if controller.mode() != &"MANUAL" or event.is_echo():
		return false
	for slot in range(1, 5):
		if event.is_action_pressed(StringName("active_%d" % slot)):
			return controller.request_cast(slot, mouse_world)
	return false
