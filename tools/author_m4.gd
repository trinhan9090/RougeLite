extends SceneTree
func _initialize() -> void: call_deferred("author")
func author() -> void:
	var catalog := load("res://content/catalog.tres") as ContentCatalog
	for row: Array in [["enchanted_forest","Enchanted Forest",14,Color("102a22"),Color("24543c")],["volcanic_arena","Volcanic Arena",5,Color("291820"),Color("613b37")]]:
		var map := MapDefinition.new()
		map.id = StringName("map." + row[0])
		map.display_name = row[1]
		map.obstacle_count = row[2]
		map.ground_color = row[3]
		map.obstacle_color = row[4]
		if row[0] == "volcanic_arena": map.hazards = [Rect2(-800,300,400,45),Rect2(350,-430,450,45)]
		assert(ResourceSaver.save(map,"res://content/maps/%s.tres" % row[0]) == OK)
		if not catalog.definitions.any(func(value: ContentDefinition) -> bool: return value.id == map.id): catalog.definitions.append(map)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://content/bosses"))
	for row: Array in [["stone_warden","Stone Warden",1600,100,20,1.0],["ember_sentinel","Ember Sentinel",2700,120,30,1.2]]:
		var boss := BossDefinition.new()
		boss.id = StringName("boss."+row[0])
		boss.display_name = row[1]
		boss.actor = EnemyDefinition.new()
		boss.actor.id = StringName("enemy."+row[0])
		boss.actor.display_name = row[1]
		boss.actor.stats = ActorStatDefinition.new()
		boss.actor.stats.max_hp = row[2]
		boss.actor.stats.move_speed = row[3]
		boss.actor.damage = row[4]
		boss.actor.xp_reward = 100
		boss.telegraph_seconds = row[5]
		boss.archetype = "stone" if row[0] == "stone_warden" else "ember"
		assert(ResourceSaver.save(boss,"res://content/bosses/%s.tres" % row[0]) == OK)
		if not catalog.definitions.any(func(value: ContentDefinition) -> bool: return value.id == boss.id): catalog.definitions.append(boss)
	catalog.content_version = "endless-demo-v1"
	assert(ResourceSaver.save(catalog,"res://content/catalog.tres") == OK)
	print("THREE MAPS AND TWO BOSSES AUTHORED")
	quit()
