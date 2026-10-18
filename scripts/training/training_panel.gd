class_name TrainingPanel
extends VBoxContainer
signal hero_selected(id: StringName)
signal rank_selected(value: int)
signal reset_requested
signal basic_auto_changed(value: bool)
var metrics: Label
var hero_id: StringName = &"loadout.astra"
var skill_rank: int = 1
var basic_auto: bool=true
func _ready() -> void:
	custom_minimum_size.x=350
	add_theme_constant_override("separation",10)
	var title := Label.new()
	title.text="TRAINING / LUYỆN TẬP"
	title.add_theme_font_size_override("font_size",24)
	add_child(title)
	var info := Label.new()
	info.text="Đầy máu • Chiêu hồi 0s\nBoss bất động, bất tử • Không có quái/EXP\nEsc: tạm dừng, đổi Auto/Manual, về menu"
	add_child(info)
	var basic := CheckBox.new()
	basic.name="TrainingBasicAuto"
	basic.text="Tự đánh thường (tắt để thử bằng Space)"
	basic.button_pressed=basic_auto
	basic.toggled.connect(func(value: bool) -> void: basic_auto_changed.emit(value))
	add_child(basic)
	var hero := OptionButton.new()
	hero.name="TrainingHero"
	var ids: Array[StringName]=[&"loadout.astra",&"loadout.vex",&"loadout.boros",&"loadout.atyu",&"loadout.viridian",&"loadout.graveshade"]
	for text: String in ["Astra","Vex","Boros","Atyu","Viridian","Graveshade"]: hero.add_item(text)
	hero.select(ids.find(hero_id))
	hero.item_selected.connect(func(index: int) -> void: hero_selected.emit(ids[index]))
	add_child(hero)
	var rank := OptionButton.new()
	rank.name="TrainingRank"
	for i in range(1,5): rank.add_item("Hạng kỹ năng %d (I tối đa 3)"%i)
	rank.select(skill_rank-1)
	rank.item_selected.connect(func(index: int) -> void: rank_selected.emit(index+1))
	add_child(rank)
	var reset := Button.new()
	reset.name="TrainingReset"
	reset.text="Đặt lại vị trí / VFX / số đo"
	reset.pressed.connect(func() -> void: reset_requested.emit())
	add_child(reset)
	metrics=Label.new()
	add_child(metrics)
	get_viewport().size_changed.connect(_layout)
	_layout()
func _layout() -> void:
	position=Vector2(maxf(24,get_viewport_rect().size.x-390),24)
func present(hits: int,damage: float,last: float,dps: float) -> void:
	metrics.text="Đòn trúng: %d\nĐòn gần nhất: %.1f\nTổng sát thương sau giáp: %.1f\nDPS: %.1f\nAuto thử chiêu mỗi 0.25s; Manual không chờ hồi."%[hits,last,damage,dps]
