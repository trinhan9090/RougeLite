extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1;printerr("FAIL ",label)
func run() -> void:
	check(ProjectSettings.get_setting("display/window/size/viewport_width")==1920,"native1080p width (latest user requirement)")
	check(ProjectSettings.get_setting("display/window/size/viewport_height")==1080,"native1080p height (latest user requirement)")
	var menu := (load("res://scenes/bootstrap/main.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	menu.call("_start_run")
	await process_frame
	var hub := menu.find_child("CharacterHub",true,false) as CharacterHub
	check(hub!=null,"production PLAY opens the character hub")
	if hub==null:quit(1);return
	hub.select_hero("astra")
	hub.confirm()
	await process_frame
	var game := current_scene as CombatRunRoot
	check(game!=null,"production PLAY command creates actual run")
	if game==null:quit(1);return
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var sprite: ActorSprite = game.player.sprite_visual
	check(sprite.sprite_frames.resource_path=="res://assets/art_v3/characters/astra/frames.tres","PLAY selects new asset, not legacy profile")
	check(sprite.scale==Vector2.ONE,"native scale without per-frame auto fit")
	check(sprite.position==Vector2(0,-28),"feet match world actor origin")
	check(game._actors.y_sort_enabled,"actor feet sorting enabled")
	check((game.player.get_node("CollisionShape2D").shape as CircleShape2D).radius==14,"locked collider unchanged")
	for facing: Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
		game.player.facing=facing
		for state: String in ["idle","run","basic","cast_j","cast_k","cast_l","cast_i","hit","death"]:
			sprite.play_action(StringName(state))
			var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,0)
			check(tex.get_size()==Vector2(96,96),"fixed individual frame canvas")
	var enemy := game.spawn_enemy()
	check(enemy!=null,"actual spawn succeeds")
	if enemy!=null:
		var count: int = 0
		for child in enemy.get_children():
			if child is EnemyPixelVisual: count+=1
		check(count==1,"one enemy visual per actual actor")
	game.free()
	await process_frame
	print("RESULT pixel v3 checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
