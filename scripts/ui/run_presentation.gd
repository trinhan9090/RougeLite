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
	_add_vignette()
	hud = RunHud.new()
	add_child(hud)
	_notice = Label.new()
	_notice.name = "NoticeBanner"
	_notice.add_theme_font_size_override("font_size",26)
	_notice.add_theme_color_override("font_color",Color("fff7c4"))
	_notice.add_theme_color_override("font_outline_color",Color("0a0a14"))
	_notice.add_theme_constant_override("outline_size",3)
	_notice.modulate = Color(1,1,1,0)
	add_child(_notice)
	_cover = ColorRect.new()
	_cover.color = Color(0.015, 0.025, 0.045, 0.92)
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
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1.0))
	_title.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.04, 1.0))
	_title.add_theme_constant_override("outline_size", 3)
	column.add_child(_title)
	_description = Label.new()
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description.add_theme_font_size_override("font_size", 18)
	_description.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9, 1.0))
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
		var kind_tag := Label.new()
		kind_tag.name = "Kind"
		kind_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kind_tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		kind_tag.offset_top = 6
		kind_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kind_tag.add_theme_font_size_override("font_size", 13)
		card.add_child(kind_tag)
		var text := Label.new()
		text.name = "Text"
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text.offset_left = 12
		text.offset_right = -12
		text.offset_top = 30
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

## Subtle screen vignette: adds depth to the pixel art without touching gameplay.
func _add_vignette() -> void:
	var vignette := ColorRect.new()
	vignette.name = "Vignette"
	vignette.color = Color(0, 0, 0, 0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 uv = UV;\n\tvec2 d = uv - vec2(0.5);\n\tfloat dist = length(d * vec2(1.15, 1.0));\n\tfloat vig = smoothstep(0.78, 0.28, dist);\n\tCOLOR = vec4(0.0, 0.0, 0.02, (1.0 - vig) * 0.42);\n}"
	var material := ShaderMaterial.new()
	material.shader = shader
	vignette.material = material
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vignette)

func _button(parent: Control, text: String, command: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_stylebox_override("normal", _modal_button_style(Color(0.09, 0.12, 0.19, 0.96), Color(0.28, 0.36, 0.50, 0.9)))
	button.add_theme_stylebox_override("hover", _modal_button_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("pressed", _modal_button_style(Color(0.22, 0.30, 0.44, 1.0), Color(1.0, 0.90, 0.55, 1.0)))
	button.add_theme_stylebox_override("focus", _modal_button_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("disabled", _modal_button_style(Color(0.07, 0.08, 0.11, 0.9), Color(0.22, 0.24, 0.30, 0.8)))
	button.pressed.connect(command)
	parent.add_child(button)
	return button

## Shared flat style for the in-run modal buttons.
func _modal_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo():
		pause_requested.emit()
		get_viewport().set_input_as_handled()

func show_offers(level: int, cards: Array[String], tokens: int = 0, kinds: Array[StringName] = []) -> void:
	_reroll.show()
	_reroll.disabled = tokens <= 0
	_reroll.text = tr("Reroll (%d)") % tokens
	_settings_panel.hide()
	_cover.show()
	_title.text = tr("LEVEL %d") % level
	_title.add_theme_font_size_override("font_size", 38)
	_description.text = tr("CHOOSE AN UPGRADE")
	_description.add_theme_font_size_override("font_size", 18)
	for index in range(_cards.size()):
		_cards[index].show()
		_cards[index].custom_minimum_size = Vector2(300, 280)
		var card_label := _cards[index].get_node("Text") as Label
		card_label.text = cards[index]
		card_label.add_theme_font_size_override("font_size", 16)
		_cards[index].tooltip_text = cards[index]
		_cards[index].disabled = false
		var kind: StringName = kinds[index] if index < kinds.size() else &""
		var accent: Color = _kind_color(kind)
		var kind_tag := _cards[index].get_node_or_null("Kind") as Label
		if kind_tag != null:
			kind_tag.text = _kind_label(kind)
			kind_tag.add_theme_color_override("font_color", accent)
		_cards[index].add_theme_stylebox_override("normal", _card_style(accent))
		_cards[index].add_theme_stylebox_override("hover", _card_style(accent.lightened(0.12)))
		_cards[index].add_theme_stylebox_override("pressed", _card_style(accent.lightened(0.2)))
		_cards[index].add_theme_stylebox_override("focus", _card_style(accent.lightened(0.12)))
	_resume.hide()
	_retry.hide()
	_menu.hide()
	_cards[0].grab_focus()

func _kind_label(kind: StringName) -> String:
	match kind:
		&"rank": return tr("SKILL RANK")
		&"bound": return tr("SKILL BOUND")
		&"global": return tr("GLOBAL")
		_: return ""

## Border/accent colour per upgrade kind so the three choices are readable at a glance.
func _kind_color(kind: StringName) -> Color:
	match kind:
		&"rank": return Color(0.92, 0.72, 0.30)
		&"bound": return Color(0.40, 0.78, 0.52)
		&"global": return Color(0.42, 0.62, 0.92)
		_: return Color(0.55, 0.60, 0.70)

func _card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.15, 0.96)
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

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
	_notice.modulate = Color(1,1,1,0)
	var tween := create_tween()
	tween.tween_property(_notice,"modulate",Color(1,1,1,1),0.15)
	tween.tween_interval(2.0)
	tween.tween_property(_notice,"modulate",Color(1,1,1,0),0.6)



func _pixel_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = get_viewport_rect().size
	scale = Vector2.ONE
	if _notice != null:
		_notice.size = Vector2(size.x,40)
		_notice.position = Vector2(0,140)
		_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
