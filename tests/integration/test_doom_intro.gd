extends SceneTree
var checks: int=0
var failures: int=0
var beams: int=0
var early_beams: int=0
var active: ControlMageRuntime
var definition_windup: float=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if value:print("PASS ",label)
	else:failures+=1;printerr("FAIL ",label)
func frames(count: int) -> void:
	for i in range(count):await physics_frame
	await process_frame
func run() -> void:
	var settings:=root.get_node("AppSettings") as SettingsService
	var old: StringName=settings.mode();settings.set_mode(&"MANUAL")
	var game: TrainingRun=(load("res://scenes/run/training_run.tscn") as PackedScene).instantiate()
	game.loadout_id=&"loadout.viridian";game.basic_auto=false;root.add_child(game)
	game.combat.visual_event.connect(func(event: Dictionary) -> void:
		if event.kind=="beam" and event.get("skill")==&"skill.viridian.i":
			beams+=1
			if is_instance_valid(active) and active.elapsed<definition_windup:early_beams+=1)
	var definition:=game.skills.runtime_for(4).definition.executor as ControlMageExecutor
	definition_windup=definition.windup
	print("INTRO_LENGTH_SECONDS ",definition.channel_intro.get_length())
	check(definition.channel_intro!=null and definition.channel_intro.get_length()>0,"supplied MP3 imports with real duration")
	check(game.player.action_audio.profile.cast_i.is_empty(),"old cast sound disabled; intro plays once via runtime")
	check(game.skills.request_cast(4,Vector2.RIGHT),"actual training accepts ultimate")
	active=game.player.get_meta("channel_runtime").get_ref() as ControlMageRuntime
	if DisplayServer.get_name()!="headless":check(active.intro_audio.playing,"real AudioStreamPlayer2D starts supplied intro")
	game.player.add_buff(&"test_haste",20,{&"move_speed":1.0})
	var anchor: Vector2=game.player.position
	Input.action_press(&"move_right")
	await frames(12)
	check(game.player.position.is_equal_approx(anchor) and game.player.velocity==Vector2.ZERO,"WASD blocked even with positive speed buff")
	check(beams==0 and not active.intro_finished,"no ray during short initial windup")
	check(not game.skills.request_cast(4,Vector2.RIGHT),"zero-cooldown training cannot overlap same channel")
	var elapsed_before: float=active.elapsed
	var audio_before: float=active.intro_audio.get_playback_position()
	paused=true
	await create_timer(.2,true).timeout
	check(active.elapsed==elapsed_before and absf(active.intro_audio.get_playback_position()-audio_before)<.08,"pause freezes intro and ray timing")
	paused=false
	var drift: float=0
	for i in range(ceili(definition.channel_intro.get_length()*60)+180):
		if not is_instance_valid(active) or active.channel_complete:break
		drift=maxf(drift,game.player.position.distance_to(anchor))
		await physics_frame
	await process_frame
	check(beams==5 and early_beams==0,"five actual rays after short windup, independent of voice length")
	check(drift<.01,"caster stays anchored through complete ultimate")
	check(not game.player.has_meta("movement_lock_runtime") and not game.player.has_meta("channel_runtime"),"ray completion releases movement while voice continues")
	check(is_instance_valid(active) and not active.intro_finished,"voice tail remains alive after ray release")
	if DisplayServer.get_name()!="headless":check(active.intro_audio.playing,"voice is still playing when movement unlocks")
	await frames(5)
	check(game.player.position.x>anchor.x,"movement resumes after ultimate")
	Input.action_release(&"move_right")
	# Audio uses real playback time; fixed-step frames can catch up under GPU load.
	var deadline: int=Time.get_ticks_msec()+int((definition.channel_intro.get_length()+2)*1000)
	while is_instance_valid(active) and Time.get_ticks_msec()<deadline:await process_frame
	if is_instance_valid(active):print("VOICE_DIAGNOSTIC playing=",active.intro_audio.playing," position=",active.intro_audio.get_playback_position()," finished=",active.intro_finished)
	check(not is_instance_valid(active) and not game.player.has_meta("channel_voice_runtime"),"voice naturally finishes and frees its runtime")
	Input.action_release(&"move_right")
	await frames(2)
	check(game.skills.request_cast(4,Vector2.RIGHT),"next ultimate accepted")
	active=game.player.get_meta("channel_runtime").get_ref() as ControlMageRuntime
	var stun:=StatusEffectDefinition.new();stun.kind="stun";stun.duration=.2
	game.player.statuses.apply(stun);await frames(3)
	check(not is_instance_valid(active) and not game.player.has_meta("movement_lock_runtime"),"stun cancels intro and releases lock without rays")
	await frames(20)
	game.skills.request_cast(4,Vector2.RIGHT)
	active=game.player.get_meta("channel_runtime").get_ref() as ControlMageRuntime
	await frames(100)
	var previous_tail:=active
	check(previous_tail.channel_complete and not previous_tail.intro_finished,"completed cast can have one remaining voice tail")
	check(game.skills.request_cast(4,Vector2.RIGHT),"training accepts another ultimate while old voice tail exists")
	active=game.player.get_meta("channel_runtime").get_ref() as ControlMageRuntime
	await frames(2)
	check(not is_instance_valid(previous_tail) and game.player.has_meta("movement_lock_runtime"),"recast replaces old voice without clearing the new movement lock")
	game.reset_training();await frames(3)
	check(not is_instance_valid(active) and not game.player.has_meta("movement_lock_runtime"),"training reset stops old intro and releases movement")
	game.skills.request_cast(4,Vector2.RIGHT)
	active=game.player.get_meta("channel_runtime").get_ref() as ControlMageRuntime
	game.combat.clear_transients();await frames(2)
	check(not is_instance_valid(active) and not game.player.has_meta("movement_lock_runtime"),"map-style clear cancels voice without ghost rays")
	game.skills.request_cast(4,Vector2.RIGHT)
	active=game.player.get_meta("channel_runtime").get_ref() as ControlMageRuntime
	game.set_physics_process(false) # prevent training healing, then exercise runtime death guard
	game.player.health.current=0
	await frames(3)
	check(not is_instance_valid(active) and not game.player.has_meta("movement_lock_runtime"),"dead caster stops intro and releases lock without rays")
	game.queue_free();await process_frame;settings.set_mode(old)
	print("RESULT doom intro: checks=%d failures=%d"%[checks,failures]);quit(0 if failures==0 else 1)
