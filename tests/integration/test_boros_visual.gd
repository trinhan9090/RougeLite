extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run_tests")
func check(value: bool,label: String) -> void:
	checks += 1
	if value: print("PASS ",label)
	else:
		failures += 1
		printerr("FAIL ",label)
func ticks() -> void:
	await process_frame
	await process_frame
func run_tests() -> void:
	var actors: Array[PlayerActor] = []
	for id in ["astra","vex","boros"]:
		var profile := load("res://content/characters/%s_loadout.tres" % id) as CombatLoadoutDefinition
		var actor := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as PlayerActor
		actor.visual_frames = profile.visual_frames
		if id != "astra": actor.visual_frames = load("res://content/characters/"+id+"_visual_frames.tres") as SpriteFrames
		actor.stats_definition = profile.stats
		actor.weapon = profile.weapon
		actor.tint = profile.tint
		actor.position = Vector2(300+actors.size()*250,350)
		root.add_child(actor)
		actor.set_physics_process(false)
		actors.append(actor)
	await ticks()
	for actor in actors:
		var height: float
		if actor.sprite_visual != null:
			var visual: ActorSprite = actor.sprite_visual
			var texture: Texture2D = visual.sprite_frames.get_frame_texture(visual._resolve(&"idle"),0)
			height = texture.get_image().get_used_rect().size.y * visual.scale.y
		else: height = 57*actor.rig.scale.y
		check(absf(height-72) < .1,"same72px baseline for actor%d" % actors.find(actor))
		check(actor.scale == Vector2.ONE and (actor.get_node("CollisionShape2D").shape as CircleShape2D).radius == 14,"visual sizing preserves body and14px collider")
	var boros: PlayerActor = actors[2]
	var sprite: ActorSprite = boros.sprite_visual
	var images: Dictionary = {}
	for name in sprite.sprite_frames.get_animation_names():
		var valid: bool = sprite.sprite_frames.get_frame_count(name) > 0
		for index in range(sprite.sprite_frames.get_frame_count(name)):
			var texture := sprite.sprite_frames.get_frame_texture(name,index) as AtlasTexture
			valid = valid and texture.filter_clip
			var path: String = texture.atlas.resource_path
			if not images.has(path): images[path] = texture.atlas.get_image()
			var region: Image = images[path].get_region(texture.region)
			valid = valid and region.get_size() == Vector2i(128,128) and not region.is_invisible()
		check(valid,"Boros nonempty128px frames "+String(name))
	for pair: Array in [[Vector2.RIGHT,"east"],[Vector2.DOWN,"south"],[Vector2.LEFT,"west"],[Vector2.UP,"north"],[Vector2(1,1),"south_east"],[Vector2(-1,1),"south_west"],[Vector2(-1,-1),"north_west"],[Vector2(1,-1),"north_east"]]:
		boros.facing = pair[0]
		await ticks()
		check(sprite.animation == StringName("idle_"+pair[1]) and not sprite.flip_h,"Boros actual direction "+pair[1])
	for action: StringName in [&"attack",&"ground_slam",&"iron_resolve",&"transform_start"]:
		sprite.play_action(action)
		await ticks()
		check(String(sprite.animation).begins_with(String(action)+"_"),"Boros action "+String(action))
	boros.motion_active = true
	await ticks()
	check(String(sprite.animation).begins_with("dash_"),"Boros charge visual")
	boros.motion_active = false
	boros.add_buff(&"fixture.transform",9,{&"max_hp":.4})
	await ticks()
	var transformed_scale: float = sprite.scale.y
	boros.clear_temporary()
	await ticks()
	check(is_equal_approx(transformed_scale/sprite.scale.y,1.25),"transform grows visual then restores shared baseline")
	if DisplayServer.get_name() != "headless":
		boros.velocity = Vector2(200,0)
		boros.facing = Vector2.RIGHT
		sprite._action = &""
		await ticks()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/evidence/character-sizes.png")
	boros.health.commit_resolved_hp(0)
	check(String(sprite.animation).begins_with("death_"),"Boros death visual")
	for actor in actors: actor.queue_free()
	await process_frame
	print("RESULT Boros visual checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
