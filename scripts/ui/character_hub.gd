class_name CharacterHub
extends Control
## Character hub shown right before a run starts.
##
## Every card shows three things only: the portrait, the hero name and the
## hero type (BRUISER / MAGE / ADC). The main menu roster page stays a
## read-only information page, so the playable character is always picked here.

signal character_chosen(loadout_id: StringName)
signal cancelled()

const COLUMNS: int = 3
const CARD_SIZE: Vector2 = Vector2(360.0, 366.0)
const PORTRAIT_HEIGHT: float = 214.0
const CLASS_COLORS: Dictionary = {
	&"mage": Color(0.55, 0.78, 1.0),
	&"adc": Color(0.98, 0.78, 0.35),
	&"brute": Color(1.0, 0.56, 0.42),
}

var _cards: Array[Dictionary] = []
var _selected_index: int = -1
var _start_button: Button
var _hint: Label
var _subtitle: Label
var _registry: ContentRegistryService
var _mode: StringName = &"RUN"

func _ready() -> void:
	_build()

## Open the hub for a menu action (RUN, TRAINING or MULTIPLAYER).
func open(mode: StringName) -> void:
	_mode = mode
	_subtitle.text = tr("%s • Chọn một nhân vật để bắt đầu") % _mode_title(mode)
	_selected_index = -1
	_refresh_cards()
	# The hub is an overlay: it must draw and take clicks above the menu UI.
	var parent := get_parent()
	if parent != null:
		parent.move_child(self, parent.get_child_count() - 1)
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)

## Hide the hub without choosing anything.
func close() -> void:
	visible = false

## Currently highlighted loadout, empty when nothing is picked yet.
func selected_loadout() -> StringName:
	if _selected_index < 0 or _selected_index >= _cards.size():
		return &""
	return StringName(_cards[_selected_index]["loadout"])

## Highlight one card by hero key (astra, vex, boros, viridian, graveshade, tofu).
func select_hero(hero: String) -> void:
	for index in _cards.size():
		if String(_cards[index]["hero"]) == hero:
			_selected_index = index
			_refresh_cards()
			return

## Confirm the highlighted card and hand it to the caller.
func confirm() -> void:
	var loadout_id := selected_loadout()
	if loadout_id == &"":
		return
	visible = false
	character_chosen.emit(loadout_id)

## Leave the hub without choosing.
func cancel() -> void:
	visible = false
	cancelled.emit()

func _build() -> void:
	_registry = get_node_or_null("/root/ContentRegistry") as ContentRegistryService
	var background := ColorRect.new()
	background.color = Color(0.02, 0.03, 0.06, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Stop so the menu underneath never receives clicks while the hub is open.
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)
	var vignette := ColorRect.new()
	vignette.color = Color(0.0, 0.0, 0.0, 0.0)
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 uv = UV;\n\tvec2 center = uv - 0.5;\n\tfloat dist = length(center);\n\tfloat vig = smoothstep(0.75, 0.22, dist);\n\tCOLOR = vec4(0.0, 0.0, 0.0, (1.0 - vig) * 0.45);\n}"
	material.shader = shader
	vignette.material = material
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "CHOOSE YOUR HERO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.04, 1.0))
	title.add_theme_constant_override("outline_size", 4)
	column.add_child(title)
	_subtitle = Label.new()
	_subtitle.name = "HubSubtitle"
	_subtitle.text = tr("START A RUN • Chọn một nhân vật để bắt đầu")
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 17)
	_subtitle.add_theme_color_override("font_color", Color(0.68, 0.75, 0.88, 1.0))
	column.add_child(_subtitle)
	var grid := GridContainer.new()
	grid.name = "CharacterGrid"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grid)
	for hero: String in HeroRoster.ORDER:
		var card := _build_card(hero)
		if card != null:
			grid.add_child(card)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 18)
	column.add_child(footer)
	var back := Button.new()
	back.name = "HubBackButton"
	back.text = "← BACK"
	back.custom_minimum_size = Vector2(220.0, 52.0)
	_style_button(back, Color(0.30, 0.38, 0.52, 0.9))
	back.pressed.connect(cancel)
	footer.add_child(back)
	_hint = Label.new()
	_hint.name = "HubHint"
	_hint.text = tr("Chọn một nhân vật / Pick a hero to begin")
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88, 1.0))
	footer.add_child(_hint)
	_start_button = Button.new()
	_start_button.name = "StartButton"
	_start_button.text = "START"
	_start_button.custom_minimum_size = Vector2(220.0, 52.0)
	_style_button(_start_button, Color(0.85, 0.66, 0.28, 0.95))
	_start_button.disabled = true
	_start_button.pressed.connect(confirm)
	footer.add_child(_start_button)
	_refresh_cards()

func _build_card(hero: String) -> Control:
	if _registry == null:
		return null
	var loadout_id := HeroRoster.loadout_for(hero)
	var profile := _registry.definition_copy(loadout_id) as CombatLoadoutDefinition
	if profile == null:
		return null
	var card := Button.new()
	card.name = "Card" + hero.capitalize()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.clip_contents = true
	var box := VBoxContainer.new()
	box.anchor_left = 0.0
	box.anchor_top = 0.0
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 12.0
	box.offset_top = 10.0
	box.offset_right = -12.0
	box.offset_bottom = -10.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var tag := Label.new()
	tag.name = "SelectedTag"
	tag.text = tr("● SELECTED")
	tag.anchor_left = 0.5
	tag.anchor_right = 0.5
	tag.anchor_top = 0.0
	tag.anchor_bottom = 0.0
	tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tag.grow_vertical = Control.GROW_DIRECTION_END
	tag.offset_top = 6.0
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 15)
	tag.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 1.0))
	tag.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02, 1.0))
	tag.add_theme_constant_override("outline_size", 3)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.visible = false
	card.add_child(tag)
	var portrait := Control.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(0.0, PORTRAIT_HEIGHT)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)
	var sprite := _build_portrait(profile, portrait)
	var name_label := Label.new()
	name_label.text = HeroRoster.short_name(profile.display_name)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 27)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1.0))
	name_label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.03, 1.0))
	name_label.add_theme_constant_override("outline_size", 2)
	box.add_child(name_label)
	var type_label := Label.new()
	type_label.text = HeroRoster.class_label(profile.class_id)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.clip_text = true
	type_label.add_theme_font_size_override("font_size", 17)
	type_label.add_theme_color_override("font_color", _class_color(profile.class_id))
	box.add_child(type_label)
	card.pressed.connect(func() -> void: select_hero(hero))
	_cards.append({
		"hero": hero,
		"loadout": loadout_id,
		"button": card,
		"tag": tag,
		"name": HeroRoster.short_name(profile.display_name),
	})
	return card

## Animated idle portrait drawn inside the card; the art frames are read only.
## Frames are cropped to their used rectangle so the hub never draws the large
## transparent padding of the source sheets.
func _build_portrait(profile: CombatLoadoutDefinition, portrait: Control) -> AnimatedSprite2D:
	var frames: SpriteFrames = profile.art_frames if profile.art_frames != null else profile.visual_frames
	var sprite := AnimatedSprite2D.new()
	sprite.name = "IdlePortrait"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.add_child(sprite)
	if frames == null:
		return sprite
	var idle: StringName = &"idle_south" if frames.has_animation(&"idle_south") else &"idle"
	if not frames.has_animation(idle):
		return sprite
	var cropped := _crop_animation(frames, idle)
	if cropped.is_empty():
		return sprite
	sprite.sprite_frames = cropped["frames"]
	sprite.animation = idle
	sprite.autoplay = idle
	sprite.play(idle)
	var used: Rect2i = cropped["used"]
	var frame_size := Vector2(used.size)
	portrait.resized.connect(func() -> void: _place_portrait(sprite, portrait, frame_size))
	call_deferred("_place_portrait", sprite, portrait, frame_size)
	return sprite

## Build a cropped SpriteFrames for one animation plus its used rectangle.
## Source frames may be single images or atlas regions; both are handled so the
## hub only ever draws the cropped hero art.
func _crop_animation(frames: SpriteFrames, animation: StringName) -> Dictionary:
	var images: Array[Image] = []
	var atlases: Dictionary = {}
	var used := Rect2i()
	for index in frames.get_frame_count(animation):
		var texture: Texture2D = frames.get_frame_texture(animation, index)
		var frame_image := _frame_image(texture, atlases)
		if frame_image == null:
			continue
		images.append(frame_image)
		var rect := frame_image.get_used_rect()
		if rect.size.x <= 0 or rect.size.y <= 0:
			rect = Rect2i(Vector2i.ZERO, frame_image.get_size())
		used = rect if images.size() == 1 else used.merge(rect)
	if images.is_empty() or used.size.x <= 0 or used.size.y <= 0:
		return {}
	var cropped := SpriteFrames.new()
	cropped.remove_animation(&"default")
	cropped.add_animation(animation)
	cropped.set_animation_speed(animation, frames.get_animation_speed(animation))
	cropped.set_animation_loop(animation, frames.get_animation_loop(animation))
	for frame_image in images:
		cropped.add_frame(animation, ImageTexture.create_from_image(frame_image.get_region(used)))
	return {"frames": cropped, "used": used}

## Pixel data of a single frame, atlas regions included.
func _frame_image(texture: Texture2D, atlases: Dictionary) -> Image:
	if texture == null:
		return null
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		if atlas.atlas == null:
			return null
		var key := atlas.atlas.get_instance_id()
		var atlas_image: Image = atlases.get(key)
		if atlas_image == null:
			atlas_image = atlas.atlas.get_image()
			atlases[key] = atlas_image
		if atlas_image == null:
			return null
		return atlas_image.get_region(Rect2i(atlas.region))
	return texture.get_image()

func _place_portrait(sprite: AnimatedSprite2D, portrait: Control, frame_size: Vector2) -> void:
	if not is_instance_valid(sprite) or not is_instance_valid(portrait):
		return
	var height_factor := maxf(1.0, portrait.size.y) * 0.94 / maxf(1.0, frame_size.y)
	var width_factor := maxf(1.0, portrait.size.x) * 0.90 / maxf(1.0, frame_size.x)
	sprite.scale = Vector2.ONE * minf(height_factor, width_factor)
	sprite.position = portrait.size * 0.5

func _refresh_cards() -> void:
	for index in _cards.size():
		var entry := _cards[index]
		var button: Button = entry["button"]
		var tag: Label = entry["tag"]
		var selected := index == _selected_index
		button.add_theme_stylebox_override("normal", _card_style(selected, false))
		button.add_theme_stylebox_override("hover", _card_style(selected, true))
		button.add_theme_stylebox_override("pressed", _card_style(selected, true))
		tag.visible = selected
	if _start_button != null:
		_start_button.disabled = _selected_index < 0
	if _hint != null:
		if _selected_index < 0:
			_hint.text = tr("Chọn một nhân vật / Pick a hero to begin")
		else:
			_hint.text = tr("Đã chọn %s • START hoặc Enter để vào trận") % String(_cards[_selected_index]["name"])

func _card_style(selected: bool, hovered: bool) -> StyleBoxFlat:
	var background := Color(0.07, 0.09, 0.14, 0.96)
	var border := Color(0.30, 0.38, 0.52, 0.9)
	if selected:
		background = Color(0.13, 0.16, 0.24, 0.98)
		border = Color(1.0, 0.84, 0.40, 1.0)
	elif hovered:
		background = Color(0.11, 0.14, 0.21, 0.98)
		border = Color(0.75, 0.68, 0.42, 0.95)
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _style_button(button: Button, accent: Color = Color(0.28, 0.36, 0.50, 0.9)) -> void:
	button.add_theme_stylebox_override("normal", _slot_style(Color(0.09, 0.12, 0.19, 0.95), accent))
	button.add_theme_stylebox_override("hover", _slot_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("pressed", _slot_style(Color(0.22, 0.30, 0.44, 1.0), Color(1.0, 0.90, 0.55, 1.0)))
	button.add_theme_stylebox_override("focus", _slot_style(Color(0.16, 0.22, 0.34, 1.0), Color(0.95, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("disabled", _slot_style(Color(0.07, 0.08, 0.11, 0.9), Color(0.22, 0.24, 0.30, 0.8)))

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

func _class_color(class_id: StringName) -> Color:
	return CLASS_COLORS.get(class_id, Color(0.85, 0.88, 0.94, 1.0))

func _mode_title(mode: StringName) -> String:
	match mode:
		&"TRAINING": return "TRAINING"
		&"MULTIPLAYER": return "MULTIPLAYER"
		_: return "START A RUN"

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.physical_keycode:
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			cancel()
		KEY_LEFT:
			get_viewport().set_input_as_handled()
			_move_selection(-1, 0)
		KEY_RIGHT:
			get_viewport().set_input_as_handled()
			_move_selection(1, 0)
		KEY_UP:
			get_viewport().set_input_as_handled()
			_move_selection(0, -1)
		KEY_DOWN:
			get_viewport().set_input_as_handled()
			_move_selection(0, 1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			get_viewport().set_input_as_handled()
			if _selected_index < 0 and not _cards.is_empty():
				select_hero(String(_cards[0]["hero"]))
			else:
				confirm()

func _move_selection(column_step: int, row_step: int) -> void:
	if _cards.is_empty():
		return
	var index := _selected_index
	if index < 0:
		index = 0
	else:
		var row := index / COLUMNS
		var column := index % COLUMNS
		column = posmod(column + column_step, COLUMNS)
		var rows := int(ceil(float(_cards.size()) / float(COLUMNS)))
		row = clampi(row + row_step, 0, rows - 1)
		index = row * COLUMNS + column
		if index >= _cards.size():
			index = _cards.size() - 1
	select_hero(String(_cards[index]["hero"]))
