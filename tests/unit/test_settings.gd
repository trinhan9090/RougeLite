extends SceneTree

const FIXTURE_PATH: String = "user://unit_settings_fixture.cfg"
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)

func _remove_fixture(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	_remove_fixture(FIXTURE_PATH)
	var settings := SettingsService.new(FIXTURE_PATH)
	root.add_child(settings)
	_check(settings.last_load_error == OK, "missing settings uses defaults")
	for action: StringName in SettingsService.DEFAULT_BINDINGS:
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		_check(events.size() == 1 and (events[0] as InputEventKey).physical_keycode == SettingsService.DEFAULT_BINDINGS[action], "InputMap default %s" % action)
	_check(settings.rebind(&"active_1", KEY_W) == ERR_ALREADY_EXISTS, "movement collision rejected")
	_check(settings.rebind(&"active_1", KEY_K) == ERR_ALREADY_EXISTS, "active collision rejected")
	_check(settings.rebind(&"active_1", KEY_ESCAPE) == ERR_ALREADY_EXISTS, "pause collision rejected")
	_check(settings.binding_for(&"active_1") == KEY_J, "rejected remap leaves binding intact")
	_check(settings.rebind(&"missing", KEY_U) == ERR_INVALID_PARAMETER, "unknown action rejected")
	_check(settings.rebind(&"active_1", KEY_NONE) == ERR_INVALID_PARAMETER, "empty key rejected")
	_check(settings.rebind(&"active_1", KEY_CTRL) == ERR_INVALID_PARAMETER, "modifier alone rejected")
	_check(settings.rebind(&"pause", KEY_U) == ERR_INVALID_PARAMETER, "reserved pause key preserved")
	_check(settings.rebind(&"active_1", KEY_U) == OK, "valid remap saves")
	var mapped: InputEventKey = InputMap.action_get_events(&"active_1")[0] as InputEventKey
	_check(mapped.physical_keycode == KEY_U, "InputMap applies remap")
	_check(settings.set_mode(&"MANUAL") == OK, "manual setting saves")
	_check(settings.set_mode(&"OTHER") == ERR_INVALID_PARAMETER and settings.mode() == &"MANUAL", "invalid mode leaves state intact")
	var other := SettingsService.new(FIXTURE_PATH)
	root.add_child(other)
	_check(other.mode() == &"MANUAL" and other.binding_for(&"active_1") == KEY_U, "new service loads persisted settings")
	_check(other.rebind(&"active_1", KEY_U) == OK, "reselecting own binding permitted")
	var config := ConfigFile.new()
	_check(config.load(FIXTURE_PATH) == OK, "saved config readable")
	config.set_value("bindings", "active_1", KEY_W)
	config.save(FIXTURE_PATH)
	_check(other.load_settings() == ERR_INVALID_DATA and other.binding_for(&"active_1") == KEY_U, "saved duplicate rejected atomically")
	config.set_value("bindings", "active_1", "U")
	config.save(FIXTURE_PATH)
	_check(other.load_settings() == ERR_INVALID_DATA, "wrong binding type rejected")
	config.set_value("bindings", "active_1", KEY_U)
	config.set_value("settings", "version", 999)
	config.save(FIXTURE_PATH)
	_check(other.load_settings() == ERR_INVALID_DATA, "unknown settings version rejected")
	var unwritable := SettingsService.new("user://__missing_m0_directory__/settings.cfg")
	_check(unwritable.rebind(&"active_1", KEY_O) != OK and unwritable.binding_for(&"active_1") == KEY_J, "save failure rolls back binding")
	_check(unwritable.set_mode(&"MANUAL") != OK and unwritable.mode() == &"AUTO", "save failure rolls back mode")
	unwritable.free()
	settings.queue_free()
	other.queue_free()
	await process_frame
	_remove_fixture(FIXTURE_PATH)
	_remove_fixture("user://restart_fixture.cfg")
	for phase: String in ["--write", "--read"]:
		var output: Array = []
		var arguments := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/integration/settings_restart.gd", "--", phase])
		var code: int = OS.execute(OS.get_executable_path(), arguments, output, true)
		var combined: String = "\n".join(output)
		print(combined)
		_check(code == 0 and combined.contains("failures=0") and not combined.contains("ERROR:") and not combined.contains("WARNING:"), "separate process %s" % phase)
	_remove_fixture("user://restart_fixture.cfg")
	print("RESULT settings: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
