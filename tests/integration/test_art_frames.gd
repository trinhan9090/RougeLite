extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ",label)
func run_tests() -> void:
	for hero: String in ["astra","vex","boros"]:
		var profile := load("res://content/characters/"+hero+"_loadout.tres") as CombatLoadoutDefinition
		var actor := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as PlayerActor
		actor.stats_definition = profile.stats
		actor.visual_frames = profile.art_frames
		root.add_child(actor)
		actor.set_physics_process(false)
		for pair: Array in [[Vector2.RIGHT,"east"],[Vector2.DOWN,"south"],[Vector2.LEFT,"west"],[Vector2.UP,"north"]]:
			actor.facing = pair[0]
			for clip: String in ["idle","run","basic","cast_j","cast_k","cast_l","cast_i","hit","death"]:
				actor.sprite_visual.play_action(StringName(clip))
				check(actor.sprite_visual.animation == StringName(clip+"_"+pair[1]),hero+" directional clip "+clip)
				var texture: Texture2D = actor.visual_frames.get_frame_texture(actor.sprite_visual.animation,0)
				check(texture is not AtlasTexture and texture.get_width()==(96 if actor.visual_frames.get_meta("pixel_v3",false) else 128), "separate PNG prevents atlas bleeding")
		check(actor.sprite_visual.has_node("WeaponPivot/Weapon") or actor.visual_frames.get_meta("pixel_v3",false),"separate weapon node or frame-composited editable weapon layer")
		check((actor.get_node("CollisionShape2D").shape as CircleShape2D).radius==14,"collider preserved")
		actor.sprite_visual.play_action(&"run")
		paused = true
		await process_frame
		await process_frame
		var still: int = actor.sprite_visual.frame
		for index in range(10): await process_frame
		check(actor.sprite_visual.frame==still,hero+" living animation pauses")
		actor.health.commit_resolved_hp(0)
		var start: int = Time.get_ticks_msec()
		while Time.get_ticks_msec()-start < 180: await process_frame
		check(actor.sprite_visual.frame>0,"death presentation continues after gameplay freezes")
		paused = false
		actor.queue_free()
		await process_frame
	print("RESULT art frames checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
