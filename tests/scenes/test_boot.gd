extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Swap in an isolated settings service; never overwrite the user's settings.
	var actual_settings := root.get_node("AppSettings")
	root.remove_child(actual_settings)
	var fixture_settings := SettingsService.new("user://scene_settings_fixture.cfg")
	fixture_settings.name = "AppSettings"
	if FileAccess.file_exists("user://scene_settings_fixture.cfg"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://scene_settings_fixture.cfg"))
	root.add_child(fixture_settings)
	var packed := load("res://scenes/bootstrap/main.tscn") as PackedScene
	if packed == null:
		printerr("FAIL main scene missing")
		quit(1)
		return
	var menu := packed.instantiate() as Control
	root.add_child(menu)
	await process_frame
	await process_frame
	var run_root := menu.get_node("RunRoot") as RunRoot
	var overlay := menu.find_child("DebugOverlay", true, false) as Label
	var valid: bool = run_root.state.seed == 20261015 and overlay != null and overlay.text.contains("Seed: 20261015")
	valid = valid and menu.is_visible_in_tree()
	var home := menu.find_child("HomePage", true, false) as Control
	var characters := menu.find_child("CharacterPage", true, false) as Control
	var settings_page := menu.find_child("SettingPage", true, false) as Control
	valid = valid and home.visible and not characters.visible and not settings_page.visible
	(menu.find_child("CharacterButton", true, false) as Button).pressed.emit()
	valid = valid and characters.visible and not home.visible and not settings_page.visible
	(menu.find_child("SelectVex", true, false) as Button).pressed.emit()
	valid = valid and (menu.find_child("SelectedCharacter", true, false) as Label).text.contains("Vex")
	valid = valid and (menu.find_child("SelectVex", true, false) as Button).text == "SELECTED"
	(menu.find_child("BackButton", true, false) as Button).pressed.emit()
	(menu.find_child("SettingButton", true, false) as Button).pressed.emit()
	valid = valid and settings_page.visible and not characters.visible and not home.visible
	var picker := menu.find_child("ModePicker", true, false) as OptionButton
	picker.item_selected.emit(1)
	valid = valid and fixture_settings.mode() == &"MANUAL"
	var rebind := menu.find_child("Rebind1", true, false) as Button
	rebind.pressed.emit()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	valid = valid and fixture_settings.binding_for(&"active_1") == KEY_J
	key = InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	var status := menu.find_child("SettingsStatus", true, false) as Label
	valid = valid and status.text == "Rebinding cancelled."
	rebind.pressed.emit()
	key = InputEventKey.new()
	key.physical_keycode = KEY_U
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	valid = valid and fixture_settings.binding_for(&"active_1") == KEY_U
	valid = valid and rebind.text.contains("U") and status.text == "Binding saved."
	if OS.get_cmdline_user_args().has("--capture-frame") and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		for page: StringName in [&"HOME", &"CHARACTER", &"SETTING"]:
			menu._show_page(page)
			await process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			valid = valid and image.save_png("res://docs/evidence/menu-%s.png" % String(page).to_lower()) == OK
	var seed_input := menu.find_child("SeedInput", true, false) as LineEdit
	seed_input.text = "invalid"
	menu._start_run()
	valid = valid and settings_page.visible and status.text.contains("Seed must")
	seed_input.text = "20261015"
	(menu.find_child("BackButton", true, false) as Button).pressed.emit()
	(menu.find_child("PlayButton", true, false) as Button).pressed.emit()
	await process_frame
	var combat := current_scene as CombatRunRoot
	valid = valid and combat != null and combat.loadout_id == &"loadout.vex"
	if combat != null and OS.get_cmdline_user_args().has("--capture-frame") and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		valid = valid and root.get_texture().get_image().save_png("res://docs/evidence/vex-in-game.png") == OK
	if combat != null: combat.queue_free()
	await process_frame
	fixture_settings.queue_free()
	await process_frame
	root.add_child(actual_settings)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://scene_settings_fixture.cfg"))
	print("RESULT scene boot: checks=1 failures=%d" % (0 if valid else 1))
	quit(0 if valid else 1)
