extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else: failures += 1; printerr("FAIL ",label)
func simulation_steps(count: int) -> void:
	for i in range(count): await physics_frame
	await process_frame

func run_tests() -> void:
	var settings := root.get_node("AppSettings") as SettingsService
	var original: StringName = settings.mode()
	settings.set_mode(&"MANUAL")
	var game := (load("res://scenes/run/training_run.tscn") as PackedScene).instantiate() as TrainingRun
	game.loadout_id = &"loadout.atyu"
	root.add_child(game)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.basic_auto = false
	game.skills.set_mode(&"MANUAL")
	var sound: ActionAudio = game.player.action_audio
	check(sound != null and sound.voices.size()==12,"Atyu owns twelve bounded positional audio voices")
	for key: String in sound._streams:
		var stream := sound._streams[key] as AudioStreamWAV
		check(stream != null and stream.get_length()>0,"real imported WAV "+key)
	check(game.request_basic_attack(),"accepted basic against immortal boss")
	await process_frame
	await process_frame
	sound._flush(.04)
	check(sound.dispatched.has("basic") and sound.dispatched.has("impact"),"basic animation and actual hit dispatch source audio")
	var total: int = sound.voices_started
	check(not game.request_basic_attack() and sound.voices_started==total,"rejected basic produces no extra sound")
	game.request_pause()
	var paused_count: int = sound.dispatched.get("cast_i",0)
	sound.play_cue(&"cast_i")
	check(sound.voices_started==total and sound.dispatched.get("cast_i",0)==paused_count,"pause rejects new audio requests")
	game.request_pause()
	for slot in range(1,5):
		game.player.record_attack_direction(Vector2.RIGHT)
		check(game.skills.request_cast(slot,Vector2.RIGHT*500),"accepted active slot %d"%slot)
		if slot==1: check(not sound.dispatched.has("cone"),"cone audio waits for actual windup/VFX resolution")
		if slot==4: check(not sound.dispatched.has("charged_beam"),"beam audio waits for actual charge resolution")
		await simulation_steps(36)
	var cues: Array[String] = ["cast_j","cone","cast_k","control","cast_l","companion","companion_attack","cast_i","charged_beam"]
	for cue in cues: check(sound.dispatched.has(cue),"actual action/VFX timing cue "+cue)
	if DisplayServer.get_name() != "headless":
		check(sound.voices_started>10,"GUI started real AudioStreamPlayer2D playback")
		var active: int = 0
		for voice in sound.voices:
			if voice.playing: active += 1
		check(active>0,"GUI audio stream is playing")
	game.skills.request_cast(2,Vector2.RIGHT*500)
	game._basic.cooldown_left = 0
	check(game.request_basic_attack(),"basic accepted during long source skill animation")
	check(sound.dispatched.has("combo_1"),"accepted basic explicitly starts its next combo and sound during another pose")
	game.boss.position = Vector2(500,0)
	var control_before: int = sound.dispatched.get("control",0)
	check(not game.skills.request_cast(2,Vector2.RIGHT*500),"manual control without target is rejected before animation/audio")
	await simulation_steps(24)
	check(sound.dispatched.get("control",0)==control_before,"missing control target produces no false seal effect audio")
	for i in range(100): sound.play_cue(&"basic")
	check(sound.pending.size()<=64 and sound.voices.size()==12,"spam remains bounded without node growth")
	sound.clear()
	check(sound.pending.is_empty(),"clear cancels delayed sounds")
	for voice in sound.voices: check(not voice.playing,"clear stops a voice")
	game.reset_training()
	await process_frame
	await process_frame
	check(game.player.action_audio!=sound and game.player.action_audio.dispatched.is_empty(),"reset replaces audio adapter and removes stale cues")
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.skills.set_mode(&"AUTO")
	check(game.skills.auto_step()==4,"Auto submits all four accepted skills through same audio path")
	await simulation_steps(36)
	print("AUTO_AUDIO_CUES ",game.player.action_audio.dispatched)
	check(game.player.action_audio.dispatched.has("cone") and game.player.action_audio.dispatched.has("control") and game.player.action_audio.dispatched.has("charged_beam"),"Auto effects dispatch their real resolution audio")
	game.queue_free()
	await process_frame
	var normal := (load("res://scenes/run/combat_run.tscn") as PackedScene).instantiate() as CombatRunRoot
	normal.loadout_id = &"loadout.atyu"
	root.add_child(normal)
	check(normal.player.action_audio != null,"ordinary PLAY has same audio integration")
	normal.queue_free()
	await process_frame
	var other := (load("res://scenes/run/training_run.tscn") as PackedScene).instantiate() as TrainingRun
	other.loadout_id = &"loadout.astra"
	root.add_child(other)
	check(other.player.action_audio == null,"other hero audio unchanged")
	other.queue_free()
	await process_frame
	settings.set_mode(original)
	print("RESULT atyu audio: checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
