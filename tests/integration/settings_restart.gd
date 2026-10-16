extends SceneTree
## Executed as two distinct engine processes by test_settings.gd.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings := SettingsService.new("user://restart_fixture.cfg")
	root.add_child(settings)
	var valid: bool = settings.last_load_error == OK
	if OS.get_cmdline_user_args().has("--write"):
		valid = valid and settings.rebind(&"active_1", KEY_U) == OK
		valid = valid and settings.set_mode(&"MANUAL") == OK
	elif OS.get_cmdline_user_args().has("--read"):
		var events: Array[InputEvent] = InputMap.action_get_events(&"active_1")
		valid = valid and settings.binding_for(&"active_1") == KEY_U and settings.mode() == &"MANUAL"
		valid = valid and events.size() == 1 and (events[0] as InputEventKey).physical_keycode == KEY_U
	else:
		valid = false
	settings.queue_free()
	await process_frame
	print("RESULT settings restart: checks=1 failures=%d" % (0 if valid else 1))
	quit(0 if valid else 1)
