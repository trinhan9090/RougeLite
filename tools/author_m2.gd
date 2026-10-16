extends SceneTree
## Reproducible authoring only. Runtime loads .tres; no kit identities in mechanics.

func _initialize() -> void:
	call_deferred("author")

func author() -> void:
	var catalog := load("res://content/catalog.tres") as ContentCatalog
	# Remove previously authored mechanics to keep regeneration idempotent.
	catalog.definitions = catalog.definitions.filter(func(definition: ContentDefinition) -> bool: return not String(definition.id).begins_with("augment."))
	var rows: Array = [
		["projectile_split", "Split", "split", ["modify_projectile_angle", "spawn_projectile_pattern"], [2,2,4,4,6], [.4,.5,.5,.65,.65], "Extra angled shots; secondary shots inherit status."],
		["multishot", "Multishot", "multishot", ["modify_projectile_count"], [1,2,3,4,5], [], "Extra primary projectile lanes."],
		["pierce", "Pierce", "pierce", ["pierce_hit"], [1,2,3,4,5], [], "Additional unique targets per projectile."],
		["homing", "Homing", "homing", ["projectile_steering"], [.1,.2,.3,.4,.5], [], "Projectile turning strength."],
		["echo_cast", "Echo Cast", "echo", ["repeat_cast"], [.35,.4,.45,.5,.55], [], "One repeat after 0.6s without extra cooldown."],
		["area_expand", "Area Expand", "area", ["resize_area"], [.12,.24,.36,.48,.6], [], "Increase radius or supported beam width."],
		["explosion_on_hit", "Explosion on Hit", "explosion", ["on_hit_hook", "damage"], [15,20,25,30,35], [55,65,75,85,95], "Magic burst, once per root cast and target."],
		["on_kill_burst", "On Kill Burst", "kill_burst", ["on_kill_hook"], [20,25,30,35,40], [], "Primary kills burst in 65px radius."],
		["cooldown_refund", "Cooldown Refund", "refund", ["cooldown_manage"], [.08,.1,.12,.14,.16], [], "Chance to refund 10% base cooldown, once per root."],
		["shield_reflect", "Shield Reflect", "reflect", ["modify_shield", "damage_taken_hook"], [.08,.11,.14,.17,.2], [], "Reflect absorbed damage; boss cap 1% maximum HP per hit."],
		["dash_shockwave", "Dash Shockwave", "dash_wave", ["dash_completed_hook"], [25,35,45,55,65], [], "One 90px physical burst on dash completion."],
		["execute", "Execute", "execute", ["damage"], [.1,.15,.2,.25,.3], [], "Bonus damage against targets below 25% HP."]
	]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://content/augments/mechanics"))
	for row: Array in rows:
		var definition := AugmentDefinition.new()
		definition.id = StringName("augment." + row[0])
		definition.display_name = row[1]
		definition.description = row[6]
		definition.rarity_weight = 30
		definition.requirements = RequirementDefinition.new()
		for cap: String in row[3]: definition.requirements.required_capabilities.append(StringName(cap))
		var effect := MechanicEffectDefinition.new()
		effect.effect_id = StringName(row[2])
		for value: float in row[4]: effect.rank_values.append(value)
		for index in range(5): effect.auxiliary_values.append(float(row[5][index]) if not row[5].is_empty() else 0.0)
		definition.effects = [effect]
		assert(definition.validate().is_empty())
		assert(ResourceSaver.save(definition, "res://content/augments/mechanics/%s.tres" % row[0]) == OK)
		catalog.definitions.append(definition)
	# Baseline M2 adapter data. Full character-specific rank effects remain M3.
	var kits: Dictionary = {
		"astra": [["Radiant Snare","projectile",7,36,620,0,0,780,0],["Prism Guard","shield",13,0,400,0,4,0,48],["Luminous Field","area",9,7,350,80,4,0,0],["Solar Beam","beam",23,120,600,37.5,0,0,0]],
		"vex": [["Quick Barrage","projectile",8,15,620,0,0,930,0],["Tactical Roll","dash",12,0,190,0,0,0,0],["Deadeye Shot","projectile",10,65,680,0,0,1100,0],["Bullet Storm","projectile",25,10,620,0,0,930,0]],
		"boros": [["Seismic Slam","area",8,55,0,140,0,0,0],["Iron Resolve","shield",16,0,400,0,3.5,0,70],["Crushing Charge","dash",11,60,230,30,0,0,0],["Titan's Fury (M3)","pending",30,0,0,0,7,0,0]]
	}
	for identity: String in kits:
		var profile := load("res://content/characters/%s_loadout.tres" % identity) as CombatLoadoutDefinition
		profile.active_skills = []
		profile.basic_attack.declared_capabilities = profile.basic_attack.executor.supported_capabilities()
		assert(ResourceSaver.save(profile.basic_attack, "res://content/skills/%s_basic.tres" % identity) == OK)
		for index in range(4):
			var row: Array = kits[identity][index]
			var skill := SkillDefinition.new()
			skill.id = StringName("skill.%s.%s" % [identity, ["j","k","l","i"][index]])
			skill.display_name = row[0]
			skill.slot = index + 1
			skill.unlock_level = [3,6,9,11][index]
			skill.max_rank = 3 if index == 3 else 4
			skill.targeting = TargetingDefinition.new()
			skill.targeting.policy = "self" if row[1] == "shield" or row[4] == 0 else "cursor"
			skill.targeting.acquisition_radius = (row[5] if row[5] > 0 else 400) if row[4] == 0 else row[4]
			if row[1] == "pending":
				skill.executor = SkillExecutorDefinition.new()
				skill.executor.executor_id = &"executor.pending_m3_transform"
			else:
				var executor := EffectExecutorDefinition.new()
				executor.executor_id = StringName("executor." + row[1])
				executor.kind = row[1]
				if identity == "astra" and index == 0: executor.status = StatusEffectDefinition.new()
				skill.executor = executor
				skill.declared_capabilities = executor.supported_capabilities()
			for rank_index in range(skill.max_rank):
				var rank := SkillRankDefinition.new()
				rank.rank = rank_index + 1
				rank.cooldown = row[2]
				rank.damage = row[3]
				rank.damage_type = "MAGIC" if identity == "astra" else "PHYSICAL"
				rank.range_px = row[4]
				rank.radius_px = row[5]
				rank.duration = row[6]
				rank.projectile_speed = row[7]
				rank.shield = row[8]
				if identity == "vex" and index == 0: rank.projectile_count = [4,5,6,7][rank_index]
				if identity == "vex" and index == 2: rank.pierce_count = 3 if rank_index == 0 else 5
				if identity == "vex" and index == 3: rank.projectile_count = 18 if rank_index == 0 else 25
				skill.rank_scaling.append(rank)
			assert(skill.validate().is_empty(), str(skill.validate()))
			assert(ResourceSaver.save(skill, "res://content/skills/%s_%s.tres" % [identity, ["j","k","l","i"][index]]) == OK)
			profile.active_skills.append(skill)
		assert(ResourceSaver.save(profile, "res://content/characters/%s_loadout.tres" % identity) == OK)
	catalog.content_version = "universal-augments-m2"
	assert(ResourceSaver.save(catalog, "res://content/catalog.tres") == OK)
	print("M2 content authored: 12 mechanics, 12 baseline active definitions")
	quit()
