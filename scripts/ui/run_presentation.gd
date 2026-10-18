class_name RunPresentation
extends Control
## Presentation emits commands. It contains no simulation/progression rules.

signal upgrade_selected(index: int)
signal reroll_requested
signal resume_requested
signal retry_requested
signal menu_requested
signal pause_requested

var hud: RunHud
var _cover: ColorRect
var _title: Label
var _description: Label
var _cards: Array[Button] = []
var _resume: Button
var _retry: Button
var _menu: Button
var _notice: Label
var _settings_panel: VBoxContainer
var _pending_bind: StringName
var _reroll: Button

func _ready() -> void:
	call_deferred("_pixel_layout")
	get_viewport().size_changed.connect(_pixel_layout)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud = RunHud.new()
	add_child(hud)
	_notice = Label.new()
	_notice.position = Vector2(250,210)
	_notice.add_theme_font_size_override("font_size",22)
	_notice.add_theme_color_override("font_color",Color("ffd39a"))
	add_child(_notice)
	_cover = ColorRect.new()
	_cover.color = Color(0.025, 0.04, 0.07, 0.94)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cover)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 920
	column.add_theme_constant_override("separation", 22)
	center.add_child(column)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	column.add_child(_title)
	_description = Label.new()
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_description)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	for index in range(3):
		var card := Button.new()
		card.name = "UpgradeCard%d" % index
		card.custom_minimum_size = Vector2(288, 250)
		card.add_theme_font_size_override("font_size", 18)
		var text := Label.new()
		text.name = "Text"
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text.offset_left = 12
		text.offset_right = -12
		text.offset_top = 8
		text.offset_bottom = -8
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 17)
		card.add_child(text)
		card.pressed.connect(func() -> void: upgrade_selected.emit(index))
		row.add_child(card)
		_cards.append(card)
	_reroll = _button(column,"Reroll",func() -> void: reroll_requested.emit())
	_resume = _button(column, "Resume", func() -> void: resume_requested.emit())
	_settings_panel = VBoxContainer.new()
	column.add_child(_settings_panel)
	_button(_settings_panel,"Switch Auto / Manual",func() -> void:
		var settings := get_node("/root/AppSettings") as SettingsService
		settings.set_mode(&"MANUAL" if settings.mode() == &"AUTO" else &"AUTO")
		_description.text = tr("Mode: %s") % settings.mode())
	_button(_settings_panel,"Fullscreen / Window",func() -> void: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
	for slot in range(0,5):
		_button(_settings_panel,tr("Rebind skill %d") % slot if slot>0 else "Đổi phím đánh thường",func() -> void:
			_pending_bind = StringName("active_%d" % slot) if slot>0 else &"basic_attack"
			_description.text = "Press a new key; Esc cancels.")
	_retry = _button(column, "Retry same character / seed", func() -> void: retry_requested.emit())
	_menu = _button(column, "Back to menu", func() -> void: menu_requested.emit())
	hide_modal()

func _button(parent: Control, text: String, command: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.pressed.connect(command)
	parent.add_child(button)
	return button

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo():
		pause_requested.emit()
		get_viewport().set_input_as_handled()

func show_offers(level: int, cards: Array[String], tokens: int = 0) -> void:
	_reroll.show()
	_reroll.disabled = tokens <= 0
	_reroll.text = tr("Reroll (%d)") % tokens
	_settings_panel.hide()
	_cover.show()
	_title.text = tr("LEVEL %d  /  CHOOSE A CORE") % level
	_description.text = "Combat paused. Choose one permanent upgrade."
	for index in range(_cards.size()):
		_cards[index].show()
		(_cards[index].get_node("Text") as Label).text = cards[index]
		_cards[index].tooltip_text = cards[index]
		_cards[index].disabled = false
	_resume.hide()
	_retry.hide()
	_menu.hide()
	_cards[0].grab_focus()

func show_message(title: String, description: String, can_resume: bool) -> void:
	_reroll.hide()
	_settings_panel.visible = can_resume
	_cover.show()
	_title.text = title
	_description.text = description
	for card in _cards:
		card.hide()
	_resume.visible = can_resume
	_retry.show()
	_menu.show()

func hide_modal() -> void:
	_cover.hide()
	_settings_panel.hide()
	_pending_bind = &""

func _input(event: InputEvent) -> void:
	if _pending_bind == &"" or not event is InputEventKey or not event.pressed or event.echo: return
	get_viewport().set_input_as_handled()
	if event.physical_keycode == KEY_ESCAPE:
		_pending_bind = &""
		_description.text = "Rebinding cancelled."
		return
	var error: Error = (get_node("/root/AppSettings") as SettingsService).rebind(_pending_bind,event.physical_keycode)
	_description.text = "Binding saved." if error == OK else "Key already assigned or invalid; choose another."
	if error == OK: _pending_bind = &""

func announce(text: String) -> void:
	_notice.text = tr(text)



func _pixel_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = get_viewport_rect().size
	scale = Vector2.ONE
