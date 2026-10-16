extends Control
## Settings and start commands only; combat simulation belongs to CombatRunRoot.

var _settings: SettingsService
var _pending_action: StringName
var _status: Label
var _binding_buttons: Dictionary[StringName, Button] = {}
var _pages: Dictionary[StringName, Control] = {}
var _selected_loadout: StringName = &"loadout.astra"
var _selected_label: Label
var _seed_input: LineEdit
var _selection_buttons: Dictionary[StringName, Button] = {}

func _ready() -> void:
	var registry := get_node("/root/ContentRegistry") as ContentRegistryService
	var errors: PackedStringArray = registry.validate_all()
	if not errors.is_empty():
		for message in errors:
			push_error(message)
		get_tree().quit(1)
		return
	_settings = get_node("/root/AppSettings") as SettingsService
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var shell := VBoxContainer.new()
	shell.custom_minimum_size = Vector2(940, 640)
	shell.add_theme_constant_override("separation", 12)
	center.add_child(shell)
	_add_label(shell, "ENDLESS SURVIVAL RPG", 32)
	var home := VBoxContainer.new()
	home.name = "HomePage"
	home.add_theme_constant_override("separation", 16)
	shell.add_child(home)
	_pages[&"HOME"] = home
	_add_label(home, "Move. Survive. Evolve.", 20)
	_selected_label = _add_label(home, "Selected: Astra / MAGE", 18)
	_selected_label.name = "SelectedCharacter"
	for title: String in ["PLAY", "CHARACTER", "SETTING"]:
		var button := Button.new()
		button.text = title
		button.name = title.capitalize() + "Button"
		button.custom_minimum_size.y = 64
		home.add_child(button)
		if title == "PLAY": button.pressed.connect(_start_run)
		else:
			var page := StringName(title)
			button.pressed.connect(func() -> void: _show_page(page))
	var back := Button.new()
	back.name = "BackButton"
	back.text = "BACK TO MENU"
	back.pressed.connect(func() -> void: _show_page(&"HOME"))
	shell.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var column := VBoxContainer.new()
	column.name = "SettingPage"
	column.add_theme_constant_override("separation", 10)
	content.add_child(column)
	_pages[&"SETTING"] = column
	_add_label(column, "SETTING", 24)
	var run_root: RunRoot = $RunRoot
	var debug_label := _add_label(column, run_root.state.debug_summary(), 14)
	debug_label.name = "DebugOverlay"
	debug_label.hide()
	run_root.foundation_started.connect(func(summary: String) -> void: debug_label.text = summary)
	var seed_row := HBoxContainer.new()
	column.add_child(seed_row)
	_add_label(seed_row, "Preview seed", 16)
	var seed_input := LineEdit.new()
	seed_input.name = "SeedInput"
	_seed_input = seed_input
	seed_input.text = str(run_root.state.seed)
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(seed_input)
	var seed_button := Button.new()
	seed_button.text = "Apply seed"
	seed_button.pressed.connect(func() -> void:
		if seed_input.text.is_valid_int():
			run_root.start_foundation(seed_input.text.to_int())
			_status.text = "Run seed applied."
		else:
			_status.text = "Seed must be a signed integer."
	)
	seed_row.add_child(seed_button)
	var mode_row := HBoxContainer.new()
	column.add_child(mode_row)
	_add_label(mode_row, "Active skill mode", 16)
	var mode_picker := OptionButton.new()
	mode_picker.name = "ModePicker"
	mode_picker.add_item("Auto")
	mode_picker.add_item("Manual")
	mode_picker.select(0 if _settings.mode() == &"AUTO" else 1)
	mode_picker.item_selected.connect(func(index: int) -> void:
		var error: Error = _settings.set_mode(&"AUTO" if index == 0 else &"MANUAL")
		mode_picker.select(0 if _settings.mode() == &"AUTO" else 1)
		_status.text = tr("Mode saved: %s") % _settings.mode() if error == OK else tr("Could not save mode (error %d).") % error
	)
	mode_row.add_child(mode_picker)
	_add_label(column, "WASD movement | Basic attack always automatic | Esc cancels rebinding", 15)
	var key_grid := GridContainer.new()
	var controls := Button.new()
	controls.text = "Key bindings / Controls"
	controls.pressed.connect(func() -> void: key_grid.visible = not key_grid.visible)
	column.add_child(controls)
	key_grid.visible = false
	key_grid.columns = 2
	key_grid.add_theme_constant_override("h_separation", 20)
	key_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(key_grid)
	for slot in range(1, 5):
		var action := StringName("active_%d" % slot)
		_add_label(key_grid, tr("Active slot %d") % slot, 16)
		var button := Button.new()
		button.name = "Rebind%d" % slot
		button.custom_minimum_size.x = 260
		button.pressed.connect(func() -> void:
			_pending_action = action
			_status.text = tr("Press a key for %s; Esc cancels.") % action
		)
		key_grid.add_child(button)
		_binding_buttons[action] = button
	_status = _add_label(column, "Click a key to rebind. Changes are saved automatically.", 15)
	_status.name = "SettingsStatus"
	if _settings.last_load_error != OK:
		_status.text = tr("Settings could not load (error %d); defaults are in use.") % _settings.last_load_error
	_refresh_binding_labels()
	var fullscreen := Button.new()
	fullscreen.text = "Fullscreen / Window"
	fullscreen.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
	column.add_child(fullscreen)
	var characters := VBoxContainer.new()
	characters.name = "CharacterPage"
	content.add_child(characters)
	_pages[&"CHARACTER"] = characters
	_add_label(characters, "CHARACTER", 24)
	var art_preview := Button.new()
	art_preview.text = "Xem đồ họa / Art preview"
	art_preview.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/art_preview.tscn"))
	characters.add_child(art_preview)
	var play_row := HBoxContainer.new()
	play_row.alignment = BoxContainer.ALIGNMENT_CENTER
	play_row.add_theme_constant_override("separation", 12)
	characters.add_child(play_row)
	for character_id: String in ["astra", "vex", "boros"]:
		var profile := registry.definition_copy(StringName("loadout." + character_id)) as CombatLoadoutDefinition
		var card := VBoxContainer.new()
		card.custom_minimum_size.x = 290
		play_row.add_child(card)
		_add_label(card, "%s / %s" % [profile.display_name, tr(String(profile.class_id).to_upper())], 22)
		var portrait := Control.new()
		portrait.custom_minimum_size = Vector2(290,165)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var actor := PlayerActor.new()
		actor.stats_definition = profile.stats
		actor.tint = profile.tint
		actor.weapon = profile.weapon
		actor.visual_frames = profile.art_frames if profile.art_frames != null else profile.visual_frames
		actor.position = Vector2(145,105)
		actor.scale = Vector2.ONE * 1.8
		portrait.add_child(actor)
		actor.set_physics_process(false)
		_add_label(card, tr("HP %.0f | Armor %.0f\nSpeed %.0f | Crit %.0f%%") % [profile.stats.max_hp,profile.stats.armor,profile.stats.move_speed,profile.stats.crit_chance*100],16)
		_add_label(card, tr("Basic: %s") % tr(profile.basic_attack.display_name),16)
		for slot in range(4):
			var skill: SkillDefinition = profile.active_skills[slot]
			var label := _add_label(card, tr("%s - %s\nLv%d | Max rank %d | CD %.1fs") % [["J","K","L","I"][slot],tr(skill.display_name),skill.unlock_level,skill.max_rank,skill.rank_scaling[0].cooldown],15)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var play := Button.new()
		play.name = "Select" + character_id.capitalize()
		play.custom_minimum_size.y = 44
		var id := StringName("loadout." + character_id)
		play.pressed.connect(func() -> void: _select_character(id))
		card.add_child(play)
		_selection_buttons[id] = play
	_select_character(_selected_loadout)
	_show_page(&"HOME")
	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	home.add_child(quit_button)
	print("BOOT_OK milestone=M5")
	if OS.get_cmdline_user_args().has("--smoke-release"):
		hide()
		add_child(ReleaseSmoke.new())

func _show_page(page: StringName) -> void:
	_pending_action = &""
	for id: StringName in _pages: _pages[id].visible = id == page
	(find_child("BackButton", true, false) as Button).visible = page != &"HOME"

func _select_character(id: StringName) -> void:
	_selected_loadout = id
	for key: StringName in _selection_buttons:
		_selection_buttons[key].text = "SELECTED" if key == id else "SELECT"
	var registry := get_node("/root/ContentRegistry") as ContentRegistryService
	var profile := registry.definition_copy(id) as CombatLoadoutDefinition
	_selected_label.text = tr("Selected: %s / %s") % [profile.display_name, tr(String(profile.class_id).to_upper())]

func _start_run() -> void:
	if not _seed_input.text.is_valid_int():
		_show_page(&"SETTING")
		_status.text = "Seed must be a signed integer."
		return
	var run := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	run.loadout_id = _selected_loadout
	run.run_seed = _seed_input.text.to_int()
	get_tree().root.add_child(run)
	get_tree().current_scene = run
	queue_free()

func _input(event: InputEvent) -> void:
	if _pending_action == &"" or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	get_viewport().set_input_as_handled()
	if key_event.physical_keycode == KEY_ESCAPE:
		_pending_action = &""
		_status.text = "Rebinding cancelled."
		return
	var error: Error = _settings.rebind(_pending_action, key_event.physical_keycode)
	if error == OK:
		_pending_action = &""
		_status.text = "Binding saved."
		_refresh_binding_labels()
	elif error == ERR_ALREADY_EXISTS:
		_status.text = "Key already assigned; choose another key or Esc to cancel."
	else:
		_status.text = tr("Could not save binding (error %d).") % error

func _refresh_binding_labels() -> void:
	for action: StringName in _binding_buttons:
		_binding_buttons[action].text = OS.get_keycode_string(_settings.binding_for(action)) + tr("  /  Rebind")

func _add_label(parent: Control, value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label



