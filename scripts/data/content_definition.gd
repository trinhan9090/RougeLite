class_name ContentDefinition
extends Resource
## Definitions are authoring data, never runtime state. Registry isolates copies.

@export var id: StringName
@export var display_name: String
@export var dependencies: Array[Resource] = [] # Registry verifies ContentDefinition type.

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty() or not String(id).contains("."):
		errors.append("Content ID must be nonempty and namespaced: '%s'" % id)
	if display_name.strip_edges().is_empty():
		errors.append("%s: display_name is required" % id)
	return errors

func references() -> Array[Resource]:
	return dependencies.duplicate()
