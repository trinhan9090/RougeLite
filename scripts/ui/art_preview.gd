class_name ArtPreview
extends Node
## Isolated visual test fixture. Executes real skills; does not alter production content.
var game: CombatRunRoot
var target: EnemyActor
var hero: String = "astra"
var rank: int = 1
var caption: Label
func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(20,110)
	layer.add_child(panel)
	caption = Label.new()
	panel.add_child(caption)
	var heroes := HBoxContainer.new()
	panel.add_child(heroes)
	for identity: String in ["astra","vex","boros"]:
		var button := Button.new()
		button.text = identity.capitalize()
		button.pressed.connect(func() -> void: select_hero(identity))
		heroes.add_child(button)
	var actions := HBoxContainer.new()
	panel.add_child(actions)
	for slot in range(5):
		var button := Button.new()
		button.text = ["Basic","J","K","L","I"][slot]
		button.pressed.connect(func() -> void: cast(slot))
		actions.add_child(button)
	var upgrade := Button.new()
	upgrade.text = "Đổi bậc / Rank 1–3"
	upgrade.pressed.connect(func() -> void:
		rank = rank%3+1
		select_hero(hero))
	panel.add_child(upgrade)
	var back := Button.new()
	back.text = "Về menu / Back"
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/bootstrap/main.tscn"))
	panel.add_child(back)
	select_hero(hero)
func select_hero(identity: String) -> void:
	if is_instance_valid(game): game.free()
	hero = identity
	game = (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	game.loadout_id = StringName("loadout."+hero)
	add_child(game)
	game.set_physics_process(false)
	game.presentation.hide()
	game.player.invulnerability_left = 999999
	game.audio.enabled = false
	game._arena.apply_layout(game._arena.definition,[])
	game.skills.sync_level(11)
	game.skills.set_mode(&"MANUAL")
	for slot in range(1,5):
		for index in range(rank-1): game.skills.upgrade_rank(slot)
	target = game.spawn_enemy()
	if target != null:
		target.position = game.player.position+Vector2(180,0)
		target.set_physics_process(false)
		target.health = Health.new(100000)
	caption.text = "%s · bậc %d · Prototype · Chiêu thật / Real executors" % [hero.capitalize(),rank]
func cast(slot: int) -> bool:
	if not is_instance_valid(target): return false
	if slot == 0:
		game._basic.cooldown_left = 0
		# Melee fixture uses actual acquisition distance.
		target.position = game.player.position+Vector2(50 if hero=="boros" else 180,0)
		return game._basic.step(0,[target],game.combat)
	game.skills.runtime_for(slot).advance_cooldown(100000)
	game.player.facing = Vector2.RIGHT
	return game.skills.request_cast(slot,game.player.position+Vector2(180,0))
