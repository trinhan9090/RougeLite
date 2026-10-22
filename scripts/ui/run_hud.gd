class_name RunHud
extends Control

var _hp: ProgressBar
var _xp: ProgressBar
var _hp_value: Label
var _xp_value: Label
var _label: Label
var _hint: Label
var _skills: Array[Button] = []
var _world: Label
var _boss_bar: ProgressBar
var _boss_name: Label
var _boss_value: Label
var _boss_panel: VBoxContainer
var _fps_label: Label
var _fps_clock: float = 0.0
var _top_panel: VBoxContainer
var _skill_bar: PanelContainer
signal skill_requested(slot: int)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_layout)
	var panel := VBoxContainer.new()
	_top_panel = panel
	panel.custom_minimum_size.x = 520
	panel.add_theme_constant_override("separation", 6)
	add_child(panel)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	panel.add_child(header)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1, 1.0))
	_label.add_theme_constant_override("outline_size", 3)
	header.add_child(_label)
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 16)
	panel.add_child(stats_row)
	_hp = ProgressBar.new()
	_hp.name = "HpBar"
	_hp.custom_minimum_size = Vector2(320, 26)
	_hp.show_percentage=false
	stats_row.add_child(_hp)
	_hp_value=_numeric_label(_hp,"HpValue")
	_xp = ProgressBar.new()
	_xp.name = "XpBar"
	_xp.custom_minimum_size = Vector2(180, 26)
	_xp.show_percentage=false
	stats_row.add_child(_xp)
	_xp_value=_numeric_label(_xp,"XpValue")
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92, 1.0))
	_hint.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.12, 1.0))
	_hint.add_theme_constant_override("outline_size", 2)
	panel.add_child(_hint)
	_world = Label.new()
	_world.add_theme_font_size_override("font_size", 14)
	_world.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98, 1.0))
	_world.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.12, 1.0))
	_world.add_theme_constant_override("outline_size", 2)
	panel.add_child(_world)
	var skills_panel := PanelContainer.new()
	_skill_bar = skills_panel
	skills_panel.custom_minimum_size.x = 520
	add_child(skills_panel)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	skills_panel.add_child(slots)
	for slot in range(1,5):
		var button := Button.new()
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.custom_minimum_size = Vector2(125,48)
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(func() -> void: skill_requested.emit(slot))
		slots.add_child(button)
		_skills.append(button)
	_build_boss_bar()
	_build_fps_label()
	_layout()

## Small performance read-out in the top-right corner.
func _build_fps_label() -> void:
	_fps_label = Label.new()
	_fps_label.name = "FpsLabel"
	_fps_label.add_theme_font_size_override("font_size", 13)
	_fps_label.add_theme_color_override("font_color", Color(0.7, 0.78, 0.88, 0.85))
	_fps_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.12, 1.0))
	_fps_label.add_theme_constant_override("outline_size", 2)
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_fps_label)

func _process(delta: float) -> void:
	if _fps_label == null:
		return
	_fps_clock -= delta
	if _fps_clock > 0.0:
		return
	_fps_clock = 0.5
	var fps: int = int(Performance.get_monitor(Performance.TIME_FPS))
	_fps_label.text = "%d FPS" % fps

## Top-centre boss bar: name, health bar and numeric HP.
func _build_boss_bar() -> void:
	var column := VBoxContainer.new()
	column.name = "BossBarPanel"
	column.add_theme_constant_override("separation", 2)
	column.visible = false
	_boss_panel = column
	add_child(column)
	_boss_name = Label.new()
	_boss_name.name = "BossName"
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.add_theme_font_size_override("font_size", 20)
	_boss_name.add_theme_color_override("font_color", Color("ff9a6a"))
	_boss_name.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04, 1.0))
	_boss_name.add_theme_constant_override("outline_size", 3)
	column.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.name = "BossBar"
	_boss_bar.custom_minimum_size = Vector2(720, 22)
	_boss_bar.show_percentage = false
	column.add_child(_boss_bar)
	_boss_value = _numeric_label(_boss_bar,"BossValue")
	_boss_value.add_theme_font_size_override("font_size", 14)

func _layout() -> void:
	var view: Vector2 = get_viewport_rect().size
	if _top_panel != null:
		_top_panel.position = Vector2(32,24)
		_top_panel.size = Vector2(520,0)
	if _skill_bar != null:
		_skill_bar.position = Vector2(32,view.y-88)
	var boss_column := get_node_or_null("BossBarPanel") as VBoxContainer
	if boss_column != null:
		boss_column.position = Vector2((view.x-720)*0.5,34)
		boss_column.size = Vector2(720,0)
	if _fps_label != null:
		_fps_label.size = Vector2(180,20)
		_fps_label.position = Vector2(view.x-200,24)

func present(hp: float, maximum: float, xp: int, threshold: int, level: int, seed: int, kills: int, character: String, mode: StringName) -> void:
	_label.text = tr("%s   |   Lv %d   |   Kills %d") % [character, level, kills]
	_hp.max_value = maximum
	_hp.value = hp
	_hp_value.text="%.1f / %.1f"%[hp,maximum]
	_xp.max_value = threshold
	_xp.value = xp
	_xp_value.text="%d / %d"%[xp,threshold]
	_hint.text = tr("WASD move  /  Esc pause  |  %s  |  Seed %d") % [tr(String(mode)), seed]
	var settings := get_node("/root/AppSettings") as SettingsService
	_hint.text += " | %s: đánh thường"%OS.get_keycode_string(settings.binding_for(&"basic_attack"))

func _numeric_label(bar: ProgressBar,id: String) -> Label:
	var label := Label.new()
	label.name=id
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.12, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	bar.add_child(label)
	return label

func present_skills(controller: SkillController, settings: SettingsService) -> void:
	var parts: PackedStringArray = []
	for slot in range(1, 5):
		var runtime: SkillRuntime = controller.runtime_for(slot)
		var key: String = OS.get_keycode_string(settings.binding_for(StringName("active_%d" % slot)))
		parts.append(tr("%s: Lv%d locked") % [key, runtime.definition.unlock_level] if runtime.rank == 0 else tr("%s: R%d %.1fs") % [key, runtime.rank, runtime.cooldown_remaining])
		_skills[slot-1].text = parts[-1]
		if runtime.rank == 0:
			_skills[slot-1].disabled = true
			_skills[slot-1].modulate = Color(0.5, 0.5, 0.5, 0.8)
		elif runtime.cooldown_remaining > 0:
			_skills[slot-1].disabled = true
			_skills[slot-1].modulate = Color(0.7, 0.7, 0.7, 0.9)
		elif settings.mode() != &"MANUAL":
			_skills[slot-1].disabled = true
			_skills[slot-1].modulate = Color(0.6, 0.7, 0.8, 0.7)
		else:
			_skills[slot-1].disabled = false
			_skills[slot-1].modulate = Color(1.0, 0.95, 0.8, 1.0)
		var rank: SkillRankDefinition = runtime.effective_rank()
		_skills[slot-1].tooltip_text = tr("%s\nUnlock level %d | Rank %d/%d") % [tr(runtime.definition.display_name),runtime.definition.unlock_level,runtime.rank,runtime.definition.max_rank]
		if rank != null: _skills[slot-1].tooltip_text += tr("\nDamage %.0f | CD %.1fs | Shield %.0f | Radius %.0f") % [rank.damage,rank.cooldown,rank.shield,rank.radius_px]
	_hint.text += "\n" + "  |  ".join(parts)

func present_world(map: String, boss: BossActor, gate: StringName, player: Actor) -> void:
	_world.text = tr("%s | Shield %.0f") % [tr(map),player.health.shield_total()]
	if player.statuses.stunned(): _world.text += tr(" | STUNNED")
	elif player.statuses.movement_factor() < 1: _world.text += tr(" | SLOWED / ROOTED")
	if player.factor(&"max_hp") > 1: _world.text += tr(" | TITAN")
	_present_boss(boss, gate)

## Dedicated boss bar so the player never has to read boss HP out of the corner text.
func _present_boss(boss: BossActor, gate: StringName) -> void:
	if is_instance_valid(boss):
		_boss_panel.visible = true
		_boss_name.text = tr(boss.boss_definition.display_name)
		_boss_bar.max_value = boss.health.maximum
		_boss_bar.value = boss.health.current
		_boss_value.text = "%.0f / %.0f" % [boss.health.current, boss.health.maximum]
	elif gate == &"PENDING":
		_boss_panel.visible = true
		_boss_name.text = tr("BOSS INCOMING")
		_boss_bar.max_value = 1.0
		_boss_bar.value = 1.0
		_boss_value.text = ""
	else:
		_boss_panel.visible = false


