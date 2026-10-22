class_name EnemyVisualProfile
extends Resource
## Authored presentation data for one enemy archetype.
##
## Plain Resource on purpose: ContentDefinition.references() may only return
## ContentDefinition instances, and ContentRegistryService.definition_copy()
## deep-duplicates resources. The sheet is therefore referenced by path and
## loaded lazily by the visual node instead of holding a Texture2D reference.
##
## Sheet layout: one row per (action, facing) pair, ordered action-major:
##   row = action_index * facing_count + facing_index
## The row holds frames_per_action[action] cells side by side.

@export var sheet_path: String = ""
@export var frame_size: Vector2i = Vector2i(32, 40)
## Feet anchor inside one cell, measured from the cell's top-left corner.
@export var pivot: Vector2 = Vector2(16, 35)
@export var actions: Array[StringName] = [&"idle", &"walk", &"windup", &"attack", &"hit", &"death"]
@export var frames_per_action: Array[int] = [2, 4, 2, 2, 1, 3]
## Facing order used by the sheet rows (matches EnemyPixelVisual.facing).
@export var facing_order: Array[StringName] = [&"south", &"east", &"west", &"north"]
@export var tint: Color = Color.WHITE
## Signature colour of the archetype (armour cracks, unstable core, tracer).
@export var accent: Color = Color.WHITE
## 0 disables the pulsing accent overlay; higher values pulse faster.
@export var accent_pulse: float = 0.0
@export var health_bar_width: float = 32.0
## Size of the damage hurtbox, in pixels. It has to match the drawn silhouette
## so the visual hit radius and the collider never disagree.
@export var hurtbox_size: Vector2 = Vector2(24, 32)
## Hurtbox centre relative to the actor origin (feet anchor).
@export var hurtbox_offset: Vector2 = Vector2(0, -18)
## Draws one or two fading copies behind a fast archetype. Purely visual: the
## afterimages never carry a hitbox.
@export var afterimages: bool = false
## Offset of the archetype's signature core, used for the pulsing glow.
@export var core_offset: Vector2 = Vector2(0, -20)

## Lazily loaded sheet. The path is kept instead of a texture reference so the
## registry can deep-duplicate the profile without duplicating the texture.
var _sheet: Texture2D

func sheet() -> Texture2D:
	if sheet_path.strip_edges().is_empty():
		return null
	if _sheet == null:
		_sheet = load(sheet_path) as Texture2D
	return _sheet

func facing_count() -> int:
	return maxi(1, facing_order.size())

func has_action(action: StringName) -> bool:
	return actions.has(action)

## Index of an action, or -1 when the sheet does not contain it.
func action_index(action: StringName) -> int:
	return actions.find(action)

func frames_for(action: StringName) -> int:
	var index := action_index(action)
	if index < 0:
		index = 0
	if index >= frames_per_action.size():
		return 1
	return maxi(1, frames_per_action[index])

## Source cell rectangle inside the sheet for an action/facing/frame triple.
## Unknown actions fall back to the first action so a sparse sheet never
## renders out of bounds.
func source_rect(action: StringName, facing: int, frame: int) -> Rect2:
	var index := action_index(action)
	if index < 0:
		index = 0
	var frames := frames_for(actions[index] if index < actions.size() else &"idle")
	var column: int = clampi(frame, 0, frames - 1)
	var row: int = index * facing_count() + clampi(facing, 0, facing_count() - 1)
	return Rect2(column * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)

## Destination rectangle for one cell, anchored on the feet pivot.
func destination_rect() -> Rect2:
	return Rect2(-pivot.x, -pivot.y, frame_size.x, frame_size.y)

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if sheet_path.strip_edges().is_empty():
		errors.append("enemy visual profile: sheet_path is required")
	elif not ResourceLoader.exists(sheet_path):
		errors.append("enemy visual profile: missing sheet '%s'" % sheet_path)
	if frame_size.x <= 0 or frame_size.y <= 0:
		errors.append("enemy visual profile: frame_size must be positive")
	if actions.is_empty():
		errors.append("enemy visual profile: at least one action is required")
	if frames_per_action.size() != actions.size():
		errors.append("enemy visual profile: frames_per_action must match actions")
	for count in frames_per_action:
		if count < 1:
			errors.append("enemy visual profile: every action needs at least one frame")
	if facing_order.size() < 1:
		errors.append("enemy visual profile: at least one facing is required")
	return errors
