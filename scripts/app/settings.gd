class_name SettingsService
extends Node
## Settings commands own validation/InputMap/persistence, never run simulation.

signal settings_changed
const SCHEMA_VERSION: int = 1
const DEFAULT_BINDINGS: Dictionary[StringName, int] = {
	&"move_up": KEY_W, &"move_left": KEY_A, &"move_down": KEY_S, &"move_right": KEY_D,
	&"active_1": KEY_J, &"active_2": KEY_K, &"active_3": KEY_L, &"active_4": KEY_I,
	&"pause": KEY_ESCAPE,
	&"basic_attack": KEY_SPACE,
}
var last_load_error: Error = OK
var _path: String
var _mode: StringName = &"AUTO"
var _bindings: Dictionary[StringName, int] = {}

func _init(settings_path: String = "user://settings.cfg") -> void:
	_path = settings_path
	_bindings.assign(DEFAULT_BINDINGS)

func _ready() -> void:
	_apply_input_map()
	last_load_error = load_settings()

func mode() -> StringName:
	return _mode

func binding_for(action: StringName) -> int:
	return _bindings.get(action, KEY_NONE)

func set_mode(value: StringName) -> Error:
	if value not in [&"AUTO", &"MANUAL"]:
		return ERR_INVALID_PARAMETER
	var previous: StringName = _mode
	_mode = value
	var error: Error = save_settings()
	if error != OK:
		_mode = previous
		return error
	settings_changed.emit()
	return OK

func rebind(action: StringName, physical_key: int) -> Error:
	if not DEFAULT_BINDINGS.has(action) or action == &"pause" or not _valid_key(physical_key):
		return ERR_INVALID_PARAMETER
	for other: StringName in _bindings:
		if other != action and _bindings[other] == physical_key:
			return ERR_ALREADY_EXISTS
	var previous: int = _bindings[action]
	_bindings[action] = physical_key
	var error: Error = save_settings()
	if error != OK:
		_bindings[action] = previous
		return error
	_apply_input_map()
	settings_changed.emit()
	return OK

func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("settings", "version", SCHEMA_VERSION)
	config.set_value("settings", "mode", String(_mode))
	for action: StringName in _bindings:
		config.set_value("bindings", String(action), _bindings[action])
	return config.save(_path)

func load_settings() -> Error:
	var config := ConfigFile.new()
	var error: Error = config.load(_path)
	if error == ERR_FILE_NOT_FOUND:
		_apply_input_map()
		return OK
	if error != OK:
		return error
	var version: Variant = config.get_value("settings", "version", null)
	var saved_mode: Variant = config.get_value("settings", "mode", null)
	if not version is int or version != SCHEMA_VERSION or not saved_mode is String or saved_mode not in ["AUTO", "MANUAL"]:
		return ERR_INVALID_DATA
	var candidate: Dictionary[StringName, int] = {}
	var seen: Dictionary[int, bool] = {}
	for action: StringName in DEFAULT_BINDINGS:
		var key: Variant = config.get_value("bindings", String(action), DEFAULT_BINDINGS[action])
		if not key is int or not _valid_key(key) or seen.has(key) or (action == &"pause" and key != KEY_ESCAPE):
			return ERR_INVALID_DATA
		candidate[action] = key
		seen[key] = true
	_bindings.assign(candidate)
	_mode = StringName(saved_mode)
	_apply_input_map()
	settings_changed.emit()
	return OK

func _apply_input_map() -> void:
	for action: StringName in _bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = _bindings[action]
		InputMap.action_add_event(action, event)

static func _valid_key(key: int) -> bool:
	return key > KEY_NONE and key not in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META] and OS.find_keycode_from_string(OS.get_keycode_string(key)) == key
