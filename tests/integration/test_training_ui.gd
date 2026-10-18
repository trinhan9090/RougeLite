extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks+=1
	if value: print("PASS ",label)
	else: failures+=1;printerr("FAIL ",label)
func run_tests() -> void:
	var settings := root.get_node("AppSettings") as SettingsService
	check(settings.binding_for(&"basic_attack")==KEY_SPACE,"Space registered as basic attack default")
	var game := (load("res://scenes/run/training_run.tscn") as PackedScene).instantiate() as TrainingRun
	game.loadout_id=&"loadout.boros"
	root.add_child(game)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.stats.crit_chance=0
	var auto := game.panel.find_child("TrainingBasicAuto",true,false) as CheckBox
	auto.button_pressed=false
	check(not game.basic_auto,"training checkbox disables auto basics")
	game.presentation.hud.present(123.45,260,17,42,11,1,0,"Boros",&"MANUAL")
	check(not game.presentation.hud._hp.show_percentage and game.presentation.hud._hp_value.text=="123.5 / 260.0","HP shows actual decimal values rather than percent")
	check(not game.presentation.hud._xp.show_percentage and game.presentation.hud._xp_value.text=="17 / 42","XP shows exact current and threshold")
	await process_frame
	await process_frame
	var key := InputEventKey.new()
	key.physical_keycode=KEY_SPACE
	key.pressed=true
	Input.parse_input_event(key)
	await process_frame
	check(game.hit_count==1 and game.last_damage>0,"real Space input resolves basic damage on boss")
	check(game.damage_numbers.displayed==1 and game.damage_numbers.get_child_count()==1,"one floating number for one accepted hit")
	var number := game.damage_numbers.get_child(0) as FloatingDamageNumber
	check(number.caption.text=="%.1f"%game.last_damage and number.position.y<game.boss.position.y,"actual damage caption above target")
	var before: int=game.hit_count
	key.echo=true
	Input.parse_input_event(key)
	await process_frame
	check(game.hit_count==before,"Space keyboard echo cannot bypass attack interval")
	check(not game.request_basic_attack(),"Space path respects basic attack cooldown")
	game._physics_process(1)
	# Auto actives may run in this direct step; isolate basic cooldown assertion.
	game.combat.clear_transients()
	game.skills.set_mode(&"MANUAL")
	check(game._basic.cooldown_left==0,"basic cooldown advances when automatic basic disabled")
	game.request_pause()
	check(not game.request_basic_attack(),"paused Space cannot attack")
	game.request_pause()
	game.player.clear_temporary()
	game.player.position=Vector2.ZERO
	game.player.stats.crit_chance=1
	game._basic.cooldown_left=0
	check(game.request_basic_attack(),"next ready Space command can crit")
	var crit := game.damage_numbers.get_child(game.damage_numbers.get_child_count()-1) as FloatingDamageNumber
	check(crit.critical and crit.caption.text.ends_with("!"),"critical damage has distinct visible number")
	for i in range(140):
		game.combat.visual_event.emit({"kind":"damage_number","position":Vector2.ZERO,"height":48,"amount":1.0,"critical":false,"follow":weakref(game.boss)})
	check(game.damage_numbers.get_child_count()==DamageNumberLayer.LIMIT,"floating numbers have separate bounded presentation budget")
	game.damage_numbers.clear()
	check(game.damage_numbers.get_child_count()==0,"damage-number cleanup leaves no stale labels")
	game.queue_free()
	await process_frame
	print("RESULT training UI: checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
