extends SceneTree

const RegistryScript = preload("res://scripts/app/content_registry.gd")
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		printerr("FAIL ", label)

func _run() -> void:
	var registry := RegistryScript.new()
	var actor := FoundationFactory.character()
	var augment := FoundationFactory.augment()
	var boss := FoundationFactory.boss()
	var definitions: Array[ContentDefinition] = [actor, augment, boss]
	_check(registry.index_definitions(definitions).is_empty(), "valid typed definition graph")
	_check(registry.content_ids().size() == 9, "nested skill/enemy definitions indexed")
	var copy := registry.definition_copy(actor.id) as CharacterDefinition
	copy.base_stats.max_hp = 999.0
	copy.active_skills[0].rank_scaling[0].damage = 999.0
	var fresh := registry.definition_copy(actor.id) as CharacterDefinition
	_check(fresh.base_stats.max_hp == 130.0 and fresh.active_skills[0].rank_scaling[0].damage == 36.0, "returned deep copy cannot mutate registry")
	actor.base_stats.max_hp = 777.0
	_check((registry.definition_copy(actor.id) as CharacterDefinition).base_stats.max_hp == 130.0, "source cannot mutate registry snapshot")
	var duplicate := FoundationFactory.character()
	_check(not registry.index_definitions([actor, duplicate]).is_empty(), "duplicate IDs rejected")
	_check(registry.content_ids().is_empty(), "failed validation leaves no partial index")
	_check(not registry.index_definitions([null]).is_empty(), "empty reference rejected")
	var bad := FoundationFactory.skill(1)
	bad.rank_scaling.pop_back()
	_check(not registry.index_definitions([bad]).is_empty(), "missing rank rejected")
	bad = FoundationFactory.skill(1)
	bad.rank_scaling[0].cooldown = -1.0
	_check(not registry.index_definitions([bad]).is_empty(), "negative cooldown rejected")
	bad.rank_scaling[0].cooldown = NAN
	_check(not registry.index_definitions([bad]).is_empty(), "nonfinite cooldown rejected")
	bad = FoundationFactory.skill(4)
	bad.max_rank = 4
	_check(not registry.index_definitions([bad]).is_empty(), "ultimate max rank enforced")
	bad = FoundationFactory.skill(2)
	bad.unlock_level = 3
	_check(not registry.index_definitions([bad]).is_empty(), "unlock slot mapping enforced")
	bad = FoundationFactory.skill(1)
	bad.executor = null
	_check(not registry.index_definitions([bad]).is_empty(), "missing executor rejected")
	bad = FoundationFactory.skill(1)
	bad.tags = [&"directional"]
	bad.declared_capabilities = [&"spawn_projectile_pattern"]
	_check(not registry.index_definitions([bad]).is_empty(), "tags cannot fabricate executor capabilities")
	var cycle_a := FoundationFactory.skill(0)
	var cycle_b := FoundationFactory.skill(1)
	cycle_a.dependencies.append(cycle_b)
	cycle_b.dependencies.append(cycle_a)
	_check(not registry.index_definitions([cycle_a]).is_empty(), "dependency cycle rejected")
	cycle_a.dependencies.clear()
	cycle_b.dependencies.clear()
	augment = FoundationFactory.augment()
	augment.max_rank = 6
	_check(not registry.index_definitions([augment]).is_empty(), "passive rank 6 rejected")
	augment = FoundationFactory.augment()
	augment.effects[0].rank_values.pop_back()
	_check(not registry.index_definitions([augment]).is_empty(), "missing effect rank rejected")
	augment = FoundationFactory.augment()
	augment.requirements.prerequisite_ids = [&"augment.missing"]
	_check(not registry.index_definitions([augment]).is_empty(), "missing requirement ID rejected")
	var prerequisite_a := FoundationFactory.augment()
	var prerequisite_b := FoundationFactory.augment()
	prerequisite_b.id = &"augment.fixture_b"
	prerequisite_a.requirements.prerequisite_ids = [prerequisite_b.id]
	prerequisite_b.requirements.prerequisite_ids = [prerequisite_a.id]
	_check(not registry.index_definitions([prerequisite_a, prerequisite_b]).is_empty(), "augment prerequisite cycle rejected")
	var wrong_reference := ContentDefinition.new()
	wrong_reference.id = &"content.wrong_reference"
	wrong_reference.display_name = "Wrong reference type"
	wrong_reference.dependencies.append(Resource.new())
	_check(not registry.index_definitions([wrong_reference]).is_empty(), "untyped content edge rejected")
	var map := MapDefinition.new()
	map.id = &"map.fixture"
	map.display_name = "Map fixture"
	map.enemy_exclusion_radius = 100.0
	_check(not registry.index_definitions([map]).is_empty(), "unsafe spawn radius rejected")
	boss = FoundationFactory.boss()
	boss.phase_thresholds = [0.4, 0.8]
	_check(not registry.index_definitions([boss]).is_empty(), "invalid boss phase order rejected")
	actor = FoundationFactory.character()
	actor.base_stats.crit_chance = 1.1
	_check(not registry.index_definitions([actor]).is_empty(), "out of range actor stats rejected")
	var path: String = "user://fixture_character.tres"
	_check(ResourceSaver.save(FoundationFactory.character(), path) == OK, "typed resource saves")
	var loaded := load(path) as CharacterDefinition
	_check(loaded != null and registry.index_definitions([loaded]).is_empty(), "typed resource reload validates")
	_check(loaded.active_skills[3].rank_scaling.size() == 3, "nested rank type retained after serialization")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check(registry.load_catalog("res://content/catalog.tres").is_empty(), "disk catalog loads")
	_check(registry.definition_copy(&"map.ruined_temple") is MapDefinition, "disk map is typed")
	_check(not registry.load_catalog("res://content/missing.tres").is_empty(), "missing catalog fails closed")
	var spawn := load("res://content/progression/spawn.tres") as SpawnDefinition
	spawn = spawn.duplicate(true) as SpawnDefinition
	spawn.exclusion_radius = 10
	_check(not spawn.validate().is_empty(), "spawn config validates exclusion radius")
	var curve := load("res://content/progression/default.tres") as ProgressionDefinition
	curve = curve.duplicate(true) as ProgressionDefinition
	curve.orb_lifetime = 5
	_check(not curve.validate().is_empty(), "progression validates orb minimum lifetime")
	registry.free()
	print("RESULT content: checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
