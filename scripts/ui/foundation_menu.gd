extends Control
## Settings and start commands only; combat simulation belongs to CombatRunRoot.

var _settings: SettingsService
var _pending_action: StringName
var _status: Label
var _binding_buttons: Dictionary[StringName, Button] = {}
var _pages: Dictionary[StringName, Control] = {}
var _seed_input: LineEdit
var _character_details: Dictionary[StringName, Control] = {}
var _avatar_buttons: Dictionary[StringName, Button] = {}
## Back button of the menu pages (the hub owns its own back button).
var _back_button: Button
## Character hub shown before a run starts; the menu itself never picks a hero.
var _hub: CharacterHub
var _hub_mode: StringName = &"RUN"

func _ready() -> void:
	call_deferred("_pixel_layout")
	get_viewport().size_changed.connect(_pixel_layout)
	var registry := get_node("/root/ContentRegistry") as ContentRegistryService
	var errors: PackedStringArray = registry.validate_all()
	if not errors.is_empty():
		for message in errors:
			push_error(message)
		get_tree().quit(1)
		return
	_settings = get_node("/root/AppSettings") as SettingsService
	_hub = get_node_or_null("CharacterHub") as CharacterHub
	if _hub != null:
		_hub.character_chosen.connect(_on_character_chosen)
		_hub.cancelled.connect(_on_hub_cancelled)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var vignette := ColorRect.new()
	vignette.color = Color(0.0, 0.0, 0.0, 0.0)
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 uv = UV;\n\tvec2 center = uv - 0.5;\n\tfloat dist = length(center);\n\tfloat vig = smoothstep(0.7, 0.25, dist);\n\tCOLOR = vec4(0.0, 0.0, 0.0, (1.0 - vig) * 0.4);\n}"
	mat.shader = shader
	vignette.material = mat
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var shell := VBoxContainer.new()
	shell.custom_minimum_size = Vector2(980, 680)
	shell.add_theme_constant_override("separation", 14)
	center.add_child(shell)
	var title := Label.new()
	title.text = "ENDLESS SURVIVAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.05, 1.0))
	title.add_theme_constant_override("outline_size", 4)
	shell.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "SURVIVE • EVOLVE • ENDLESS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85, 1.0))
	subtitle.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.12, 1.0))
	subtitle.add_theme_constant_override("outline_size", 2)
	shell.add_child(subtitle)
	var home := VBoxContainer.new()
	home.name = "HomePage"
	home.add_theme_constant_override("separation", 12)
	shell.add_child(home)
	_pages[&"HOME"] = home
	for title_btn: String in ["PLAY", "MULTIPLAYER", "TRAINING", "CHARACTER", "SETTING"]:
		var button := Button.new()
		button.text = title_btn
		button.name = title_btn.capitalize() + "Button"
		button.custom_minimum_size = Vector2(420, 56)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_stylebox_override("normal", _slot_style(Color(0.09, 0.12, 0.19, 0.95), Color(0.28, 0.36, 0.50, 0.9), 10))
		button.add_theme_stylebox_override("hover", _slot_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0), 10))
		button.add_theme_stylebox_override("pressed", _slot_style(Color(0.22, 0.30, 0.44, 1.0), Color(1.0, 0.90, 0.55, 1.0), 10))
		button.add_theme_stylebox_override("focus", _slot_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0), 10))
		home.add_child(button)
		if title_btn == "PLAY": button.pressed.connect(_start_run)
		elif title_btn == "MULTIPLAYER": button.pressed.connect(_start_multiplayer)
		elif title_btn == "TRAINING": button.pressed.connect(func() -> void: _start_run(true))
		else:
			var page := StringName(title_btn)
			button.pressed.connect(func() -> void: _show_page(page))
	var back := Button.new()
	back.name = "BackButton"
	back.text = "← BACK TO MENU"
	back.custom_minimum_size = Vector2(240, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_stylebox_override("normal", _slot_style(Color(0.09, 0.12, 0.19, 0.95), Color(0.28, 0.36, 0.50, 0.9), 8))
	back.add_theme_stylebox_override("hover", _slot_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0), 8))
	back.pressed.connect(func() -> void: _show_page(&"HOME"))
	_back_button = back
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
	_style_button(seed_button)
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
	_style_button(controls)
	controls.pressed.connect(func() -> void: key_grid.visible = not key_grid.visible)
	column.add_child(controls)
	key_grid.visible = false
	key_grid.columns = 2
	key_grid.add_theme_constant_override("h_separation", 20)
	key_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(key_grid)
	for slot in range(0, 5):
		var action := StringName("active_%d" % slot) if slot>0 else &"basic_attack"
		_add_label(key_grid, tr("Active slot %d") % slot if slot>0 else "Đánh thường (Space)", 16)
		var button := Button.new()
		button.name = "Rebind%d" % slot
		button.custom_minimum_size.x = 260
		_style_button(button)
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
	_style_button(fullscreen)
	fullscreen.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
	column.add_child(fullscreen)
	var characters := VBoxContainer.new()
	characters.name = "CharacterPage"
	characters.add_theme_constant_override("separation", 16)
	content.add_child(characters)
	_pages[&"CHARACTER"] = characters
	var character_title := _add_label(characters, "CHARACTER / NHÂN VẬT", 34)
	character_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1.0))
	character_title.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.04, 1.0))
	character_title.add_theme_constant_override("outline_size", 3)
	var character_note := _add_label(characters, tr("Thông tin nhân vật • Roster information only — nhân vật được chọn ở Character Hub khi bắt đầu"), 15)
	character_note.add_theme_color_override("font_color", Color(0.70, 0.76, 0.86, 1.0))
	var art_preview := Button.new()
	art_preview.text = "Xem đồ họa / Art preview"
	_style_button(art_preview)
	art_preview.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/art_preview.tscn"))
	characters.add_child(art_preview)
	var play_row := HBoxContainer.new()
	var avatar_grid := GridContainer.new()
	avatar_grid.name = "CharacterSlots"
	avatar_grid.columns = 10
	avatar_grid.add_theme_constant_override("h_separation", 12)
	avatar_grid.add_theme_constant_override("v_separation", 12)
	characters.add_child(avatar_grid)
	for index in range(20):
		var avatar := Button.new()
		avatar.name = "Slot%d" % index
		avatar.custom_minimum_size = Vector2(84,84)
		avatar.expand_icon = true
		avatar.add_theme_constant_override("icon_max_width",68)
		avatar_grid.add_child(avatar)
		if index >= 6:
			avatar.text = "?"
			avatar.disabled = true
			avatar.tooltip_text = "Nhân vật chưa mở"
			avatar.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55, 1.0))
			avatar.add_theme_font_size_override("font_size", 30)
			continue
		var hero: String = HeroRoster.ORDER[index]
		var profile := registry.definition_copy(StringName("loadout."+hero)) as CombatLoadoutDefinition
		var frames: SpriteFrames = profile.art_frames if profile.art_frames != null else profile.visual_frames
		var idle: StringName = &"idle_south" if frames.has_animation(&"idle_south") else &"idle"
		var texture: Texture2D = frames.get_frame_texture(idle,0)
		var cropped := AtlasTexture.new()
		cropped.atlas = texture
		cropped.region = texture.get_image().get_used_rect()
		avatar.icon = cropped
		avatar.tooltip_text = profile.display_name
		avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		avatar.add_theme_stylebox_override("normal", _slot_style(Color(0.10, 0.13, 0.20, 0.95), Color(0.32, 0.42, 0.58, 0.9)))
		avatar.add_theme_stylebox_override("hover", _slot_style(Color(0.16, 0.21, 0.32, 1.0), Color(0.85, 0.75, 0.45, 1.0)))
		avatar.add_theme_stylebox_override("pressed", _slot_style(Color(0.22, 0.28, 0.40, 1.0), Color(1.0, 0.88, 0.55, 1.0)))
		var id := StringName("loadout."+hero)
		_avatar_buttons[id] = avatar
		avatar.pressed.connect(func() -> void: _preview_character(id))
	play_row.alignment = BoxContainer.ALIGNMENT_CENTER
	play_row.add_theme_constant_override("separation", 12)
	characters.add_child(play_row)
	for character_id: String in HeroRoster.ORDER:
		var profile := registry.definition_copy(StringName("loadout." + character_id)) as CombatLoadoutDefinition
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _slot_style(Color(0.07, 0.09, 0.14, 0.96), Color(0.30, 0.38, 0.52, 0.9), 12))
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		panel.add_child(card)
		_character_details[StringName("loadout."+character_id)] = panel
		play_row.add_child(panel)
		var name_label := _add_label(card, "%s / %s" % [profile.display_name, HeroRoster.class_label(profile.class_id)], 26)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1.0))
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
			var ranks := PackedStringArray()
			for rank: SkillRankDefinition in skill.rank_scaling:
				ranks.append("Hạng %d: sát thương %.0f | tầm %.0f | bán kính %.0f | thời lượng %.1fs" % [rank.rank,rank.damage,rank.range_px,rank.radius_px,rank.duration])
			label.tooltip_text = "\n".join(ranks)
	_preview_character(HeroRoster.loadout_for(HeroRoster.ORDER[0]))
	_show_page(&"HOME")
	var quit_button := Button.new()
	quit_button.text = "Quit"
	_style_button(quit_button, Color(0.62, 0.28, 0.30, 0.95))
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	home.add_child(quit_button)
	# The hub is an overlay: keep it as the last child so it draws above the menu.
	if _hub != null:
		move_child(_hub, get_child_count() - 1)
	print("BOOT_OK milestone=M5")
	if OS.get_cmdline_user_args().has("--smoke-release"):
		hide()
		add_child(ReleaseSmoke.new())

func _show_page(page: StringName) -> void:
	_pending_action = &""
	for id: StringName in _pages: _pages[id].visible = id == page
	if _back_button != null:
		_back_button.visible = page != &"HOME"
	var target: Control = _pages[page]
	if target != null:
		target.modulate = Color(1,1,1,0)
		var tween := create_tween()
		tween.tween_property(target,"modulate",Color.WHITE,0.12)

func _preview_character(id: StringName) -> void:
	for key: StringName in _character_details:
		_character_details[key].visible = key == id
	for key: StringName in _avatar_buttons:
		_avatar_buttons[key].modulate = Color.WHITE if key == id else Color(.65,.65,.65)

## Open the character hub; the hero is always picked there, never in the menu.
func _open_hub(mode: StringName) -> void:
	if _hub == null:
		return
	_hub_mode = mode
	_hub.open(mode)

func _on_character_chosen(loadout_id: StringName) -> void:
	match _hub_mode:
		&"MULTIPLAYER":
			_launch_multiplayer(loadout_id)
		&"TRAINING":
			_launch_run(loadout_id, true)
		_:
			_launch_run(loadout_id, false)

func _on_hub_cancelled() -> void:
	_show_page(&"HOME")

func _start_multiplayer() -> void:
	_open_hub(&"MULTIPLAYER")

func _start_run(training: bool = false) -> void:
	if not _seed_input.text.is_valid_int():
		_show_page(&"SETTING")
		_status.text = "Seed must be a signed integer."
		return
	_open_hub(&"TRAINING" if training else &"RUN")

func _launch_run(loadout_id: StringName, training: bool) -> void:
	var scene: String = "res://scenes/run/training_run.tscn" if training else "res://scenes/run/combat_run.tscn"
	var run := (load(scene) as PackedScene).instantiate() as CombatRunRoot
	run.loadout_id = loadout_id
	run.run_seed = _seed_input.text.to_int()
	get_tree().root.add_child(run)
	get_tree().current_scene = run
	queue_free()

func _launch_multiplayer(loadout_id: StringName) -> void:
	var coordinator := get_node_or_null("/root/MultiplayerCoordinator")
	if coordinator != null:
		coordinator.set("local_character", StringName(HeroRoster.hero_for(loadout_id)))
	get_tree().change_scene_to_file("res://multiplayer/scenes/multiplayer_session_flow.tscn")

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

## Flat panel/button style shared by the menu, avatar slots and character cards.
func _slot_style(background: Color, border: Color, radius: int = 8, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

## Apply the shared flat look to any button built at runtime.
func _style_button(button: Button, accent: Color = Color(0.28, 0.36, 0.50, 0.9)) -> void:
	button.add_theme_stylebox_override("normal", _slot_style(Color(0.09, 0.12, 0.19, 0.95), accent))
	button.add_theme_stylebox_override("hover", _slot_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("pressed", _slot_style(Color(0.22, 0.30, 0.44, 1.0), Color(1.0, 0.90, 0.55, 1.0)))
	button.add_theme_stylebox_override("focus", _slot_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("disabled", _slot_style(Color(0.07, 0.08, 0.11, 0.9), Color(0.22, 0.24, 0.30, 0.8)))




func _pixel_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = get_viewport_rect().size
	scale = Vector2.ONE
