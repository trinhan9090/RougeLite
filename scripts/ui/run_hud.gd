class_name RunHud
extends Control

var _hp: ProgressBar
var _xp: ProgressBar
var _label: Label
var _hint: Label
var _skills: Array[Button] = []
var _world: Label
signal skill_requested(slot: int)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 18)
	panel.custom_minimum_size.x = 500
	panel.add_theme_constant_override("separation", 7)
	add_child(panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(_label)
	_hp = ProgressBar.new()
	_hp.name = "HpBar"
	_hp.custom_minimum_size = Vector2(500, 22)
	panel.add_child(_hp)
	_xp = ProgressBar.new()
	_xp.name = "XpBar"
	_xp.custom_minimum_size = Vector2(500, 12)
	panel.add_child(_xp)
	_hint = Label.new()
	_hint.add_theme_color_override("font_color", Color("a1b5cc"))
	panel.add_child(_hint)
	_world = Label.new()
	panel.add_child(_world)
	var slots := HBoxContainer.new()
	panel.add_child(slots)
	for slot in range(1,5):
		var button := Button.new()
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.custom_minimum_size = Vector2(120,44)
		button.pressed.connect(func() -> void: skill_requested.emit(slot))
		slots.add_child(button)
		_skills.append(button)

func present(hp: float, maximum: float, xp: int, threshold: int, level: int, seed: int, kills: int, character: String, mode: StringName) -> void:
	_label.text = tr("%s   |   Lv %d   |   Kills %d") % [character, level, kills]
	_hp.max_value = maximum
	_hp.value = hp
	_xp.max_value = threshold
	_xp.value = xp
	_hint.text = tr("WASD move  /  Esc pause  |  %s  |  Seed %d") % [tr(String(mode)), seed]

func present_skills(controller: SkillController, settings: SettingsService) -> void:
	var parts: PackedStringArray = []
	for slot in range(1, 5):
		var runtime: SkillRuntime = controller.runtime_for(slot)
		var key: String = OS.get_keycode_string(settings.binding_for(StringName("active_%d" % slot)))
		parts.append(tr("%s: Lv%d locked") % [key, runtime.definition.unlock_level] if runtime.rank == 0 else tr("%s: R%d %.1fs") % [key, runtime.rank, runtime.cooldown_remaining])
		_skills[slot-1].text = parts[-1]
		_skills[slot-1].disabled = runtime.rank == 0 or runtime.cooldown_remaining > 0 or settings.mode() != &"MANUAL"
		var rank: SkillRankDefinition = runtime.effective_rank()
		_skills[slot-1].tooltip_text = tr("%s\nUnlock level %d | Rank %d/%d") % [tr(runtime.definition.display_name),runtime.definition.unlock_level,runtime.rank,runtime.definition.max_rank]
		if rank != null: _skills[slot-1].tooltip_text += tr("\nDamage %.0f | CD %.1fs | Shield %.0f | Radius %.0f") % [rank.damage,rank.cooldown,rank.shield,rank.radius_px]
	_hint.text += "\n" + "  |  ".join(parts)

func present_world(map: String, boss: BossActor, gate: StringName, player: Actor) -> void:
	_world.text = tr("%s | Shield %.0f") % [tr(map),player.health.shield_total()]
	if player.statuses.stunned(): _world.text += tr(" | STUNNED")
	elif player.statuses.movement_factor() < 1: _world.text += tr(" | SLOWED / ROOTED")
	if player.factor(&"max_hp") > 1: _world.text += tr(" | TITAN")
	if is_instance_valid(boss): _world.text += tr("\n%s: %.0f / %.0f HP") % [tr(boss.boss_definition.display_name),boss.health.current,boss.health.maximum]
	elif gate == &"PENDING": _world.text += tr(" | BOSS INCOMING")


