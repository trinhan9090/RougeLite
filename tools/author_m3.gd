extends SceneTree
func _initialize() -> void: call_deferred("author")
func status(kind: String, duration: float, strength: float = .25) -> StatusEffectDefinition:
	var value := StatusEffectDefinition.new()
	value.kind = kind
	value.duration = duration
	value.strength = strength
	return value
func author() -> void:
	for identity in ["astra","vex","boros"]:
		var profile := load("res://content/characters/%s_loadout.tres" % identity) as CombatLoadoutDefinition
		profile.weapon = {"astra":"staff","vex":"pistols","boros":"hammer"}[identity]
		for index in range(4):
			var skill: SkillDefinition = profile.active_skills[index]
			if identity == "boros" and index == 3:
				var executor := EffectExecutorDefinition.new()
				executor.executor_id = &"executor.buff"
				executor.kind = "buff"
				skill.executor = executor
				skill.display_name = "Titan's Fury"
				skill.targeting.policy = "self"
				skill.targeting.acquisition_radius = 400
			if identity == "astra" and index == 2: skill.display_name = "Solar Field"
			if identity == "astra" and index == 3: skill.display_name = "Celestial Beam"
			if identity == "vex" and index == 2: skill.display_name = "Piercing Round"
			if identity == "boros" and index == 0: skill.display_name = "Ground Slam"
			skill.declared_capabilities = skill.executor.supported_capabilities()
			for r in range(skill.max_rank):
				var rank: SkillRankDefinition = skill.rank_scaling[r]
				var b := SkillBehaviorDefinition.new()
				rank.behavior = b
				if identity == "astra":
					match index:
						0:
							rank.damage = [36,44,54,65][r]
							rank.pierce_count = 2 if r >= 1 else 0
							b.status = status("root",1.65 if r >= 2 else 1.25)
							if r == 3: b.death_damage = 30
						1:
							rank.shield = [48,68,68,95][r]
							b.move_bonus = .15
							if r >= 2: b.blocked_pulse = 15
							if r == 3: b.expire_damage = 45
						2:
							rank.radius_px = 80 if r == 0 else 100
							rank.duration = 4 if r < 2 else 5.5
							if r == 3:
								rank.damage = 10
								b.status = status("slow",.6,.1)
						3:
							rank.cooldown = 23 if r == 0 else 20
							rank.radius_px = 37.5 if r == 0 else 50
							if r == 2:
								b.burn_duration = 3
								b.burn_damage = 12
				elif identity == "vex":
					match index:
						0:
							b.shot_interval = .12
							(skill.executor as EffectExecutorDefinition).spread_radians = deg_to_rad(6)
							if r >= 2:
								b.can_crit = true
								b.crit_bonus = .1
							if r == 3: b.crit_pierce = 1
						1:
							b.attack_bonus = .2 if r == 0 else .3
							if r >= 2: b.extra_basic = 1
							if r == 3: b.kill_refund = 1.5
						2:
							if r >= 2: b.boss_bonus = .35
							if r == 3:
								b.mark_duration = 3
								b.mark_bonus = .12
						3:
							b.shot_interval = 3.0 / (rank.projectile_count - 1)
							if r == 2: b.bounce_chance = .15
				else:
					match index:
						0:
							rank.radius_px = 140 if r == 0 else 170
							b.status = status("slow",1.5,.25)
							if r >= 2: b.max_hp_damage = .03
							if r == 3:
								b.repeat_delay = .4
								b.repeat_scale = .45
						1:
							rank.shield = 70 if r == 0 else 95
							b.shield_reduction = .25
							if r >= 2: b.reflect_fraction = .15
							if r == 3: b.expire_heal_fraction = .2
						2:
							rank.range_px = 230 if r == 0 else 300
							if r >= 2: b.status = status("stun",.7)
							if r == 3:
								b.trail_duration = 2
								b.trail_damage = 10
						3:
							rank.duration = 7 if r == 0 else 9
							b.hp_bonus = .4
							b.range_bonus = .45
							if r == 2: b.basic_pulse_scale = .35
			assert(skill.validate().is_empty(), str(skill.validate()))
			assert(ResourceSaver.save(skill,"res://content/skills/%s_%s.tres" % [identity,["j","k","l","i"][index]]) == OK)
		assert(ResourceSaver.save(profile,"res://content/characters/%s_loadout.tres" % identity) == OK)
	var catalog := load("res://content/catalog.tres") as ContentCatalog
	catalog.content_version = "endless-demo-v1"
	assert(ResourceSaver.save(catalog,"res://content/catalog.tres") == OK)
	print("FULL KITS AUTHORED")
	quit()

