class_name ContentRegistryService
extends Node
## Private immutable definition snapshots; callers get detached copies.

const DEFAULT_CATALOG: String = "res://content/catalog.tres"
var _index: Dictionary[StringName, ContentDefinition] = {}
var _errors := PackedStringArray()
var _content_version: String = ""

func _ready() -> void:
	load_catalog(DEFAULT_CATALOG)

func load_catalog(path: String) -> PackedStringArray:
	_index.clear()
	_errors.clear()
	_content_version = ""
	if not ResourceLoader.exists(path):
		_errors.append("Missing content catalog: %s" % path)
		return _errors.duplicate()
	var catalog := load(path) as ContentCatalog
	if catalog == null:
		_errors.append("Not a ContentCatalog: %s" % path)
		return _errors.duplicate()
	if catalog.content_version.strip_edges().is_empty():
		_errors.append("Content version is required: %s" % path)
		return _errors.duplicate()
	_errors = index_definitions(catalog.definitions)
	if _errors.is_empty():
		_content_version = catalog.content_version
	return validate_all()

func index_definitions(definitions: Array[ContentDefinition]) -> PackedStringArray:
	var candidate: Dictionary[StringName, ContentDefinition] = {}
	var visited: Dictionary[int, bool] = {}
	var active: Dictionary[int, bool] = {}
	_errors.clear()
	_index.clear()
	_content_version = ""
	if definitions.is_empty():
		_errors.append("Content catalog must not be empty")
	for definition in definitions:
		_visit(definition, candidate, visited, active)
	for definition: ContentDefinition in candidate.values():
		if definition is AugmentDefinition:
			_validate_requirements(definition as AugmentDefinition, candidate)
	var prerequisite_visited: Dictionary[StringName, bool] = {}
	var prerequisite_active: Dictionary[StringName, bool] = {}
	for content_id: StringName in candidate:
		_visit_prerequisites(content_id, candidate, prerequisite_visited, prerequisite_active)
	if _errors.is_empty():
		for key: StringName in candidate:
			_index[key] = candidate[key].duplicate(true) as ContentDefinition
	return validate_all()

func _visit(resource: Resource, candidate: Dictionary[StringName, ContentDefinition], visited: Dictionary[int, bool], active: Dictionary[int, bool]) -> void:
	if not resource is ContentDefinition:
		_errors.append("Empty or non-ContentDefinition reference")
		return
	var definition := resource as ContentDefinition
	var instance_id: int = definition.get_instance_id()
	if active.has(instance_id):
		_errors.append("Cyclic content dependency at %s" % definition.id)
		return
	if visited.has(instance_id):
		return
	if candidate.has(definition.id) and candidate[definition.id] != definition:
		_errors.append("Duplicate content ID: %s" % definition.id)
	else:
		candidate[definition.id] = definition
	_errors.append_array(definition.validate())
	active[instance_id] = true
	for reference in definition.references():
		_visit(reference, candidate, visited, active)
	active.erase(instance_id)
	visited[instance_id] = true

func _validate_requirements(definition: AugmentDefinition, candidate: Dictionary[StringName, ContentDefinition]) -> void:
	if definition.requirements == null:
		return
	var requirements := definition.requirements
	for reference_id in requirements.prerequisite_ids + requirements.excluded_ids:
		if not candidate.get(reference_id) is AugmentDefinition:
			_errors.append("%s: missing requirement ID %s" % [definition.id, reference_id])
	if requirements.required_character_id != &"" and not candidate.get(requirements.required_character_id) is CharacterDefinition:
		_errors.append("%s: signature character reference missing/invalid" % definition.id)

func _visit_prerequisites(content_id: StringName, candidate: Dictionary[StringName, ContentDefinition], visited: Dictionary[StringName, bool], active: Dictionary[StringName, bool]) -> void:
	if active.has(content_id):
		_errors.append("Cyclic augment prerequisites at %s" % content_id)
		return
	if visited.has(content_id):
		return
	var definition := candidate.get(content_id) as AugmentDefinition
	if definition == null or definition.requirements == null:
		return
	active[content_id] = true
	for prerequisite in definition.requirements.prerequisite_ids:
		_visit_prerequisites(prerequisite, candidate, visited, active)
	active.erase(content_id)
	visited[content_id] = true

func validate_all() -> PackedStringArray:
	return _errors.duplicate()

func definition_copy(id: StringName) -> ContentDefinition:
	if not _index.has(id):
		return null
	return _index[id].duplicate(true) as ContentDefinition

func content_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_index.keys())
	result.sort()
	return result

func content_version() -> String:
	return _content_version
