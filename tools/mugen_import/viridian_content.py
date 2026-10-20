"""Data-only authoring of provisional Control Mage ranks; existing kits untouched."""
from pathlib import Path
from viridian_audit import ROOT

def build():
    stats=(ROOT/'content/characters/astra_stats.tres').read_text().replace('130.0','95.0').replace('240.0','215.0')
    (ROOT/'content/characters/viridian_stats.tres').write_text(stats)
    basic=(ROOT/'content/skills/astra_basic.tres').read_text().replace('astra','viridian').replace('basic_attack_executor_definition.gd','limited_projectile_basic.gd').replace('Astra basic','Emerald Bolt').replace('0.82','0.70').replace('14.0','17.0').replace('420.0','310.0').replace('650.0','590.0').replace('projectile_speed = 590.0','projectile_speed = 590.0\nradius_px = 7.0')
    (ROOT/'content/skills/viridian_basic.tres').write_text(basic)
    lines=['[gd_resource type="Resource" script_class="CombatLoadoutDefinition" format=3]']
    scripts={'loadout':'combat_loadout_definition','skill':'skill_definition','rank':'skill_rank_definition','target':'targeting_definition','executor':'control_mage_executor','behavior':'skill_behavior_definition'}
    for key,value in scripts.items():lines.append(f'[ext_resource type="Script" path="res://scripts/data/{value}.gd" id="{key}"]')
    for key,path in {'stats':'content/characters/viridian_stats.tres','basic':'content/skills/viridian_basic.tres','frames':'assets/viridian/frames.tres'}.items():lines.append(f'[ext_resource type="Resource" path="res://{path}" id="{key}"]')
    lines.append('[ext_resource type="AudioStream" path="res://assets/private_viridian/audio/doom_ultimate_intro.mp3" id="intro"]')
    config=[('j','Plasma Lance','lance','beam',.16,5.5,48,420,[12,16,16,16],0,'cursor'),('k','Arcane Prison','prison','area',.24,12,15,330,[86,110,110,110],1.6,'cursor'),('l','Molecular Orbit','orbit','shield',0,18,12,0,[52]*4,7,'self'),('i','Photon Cataclysm','cataclysm','beam',.65,32,68,460,[9]*3,1.4,'cursor')]
    for slot,(key,title,move,kind,windup,cd,damage,reach,radii,duration,policy) in enumerate(config,1):
        lines += [f'[sub_resource type="Resource" id="exec_{key}"]','script = ExtResource("executor")',f'executor_id = &"executor.control_mage.{move}"',f'move = "{move}"',f'kind = "{kind}"',f'windup = {float(windup)}']
        if key=='i':lines.append('channel_intro = ExtResource("intro")')
        for i,radius in enumerate(radii):
            lines += [f'[sub_resource type="Resource" id="behavior_{key}{i}"]','script = ExtResource("behavior")']
            if key=='j':lines += [f'boss_bonus = {0.3 if i>=2 else 0.0}',f'burn_duration = {1.4 if i==3 else 0.0}','burn_damage = 7.0']
            lines += [f'[sub_resource type="Resource" id="rank_{key}{i}"]','script = ExtResource("rank")',f'rank = {i+1}',f'cooldown = {float(cd)}',f'damage = {float(damage)}','damage_type = "MAGIC"',f'range_px = {float(reach)}',f'radius_px = {float(radius)}',f'duration = {2.0 if key=="k" and i>=2 else float(duration)}',f'behavior = SubResource("behavior_{key}{i}")']
            if key=='l':lines += [f'shield = {80.0 if i==3 else 55.0}',f'projectile_count = {[2,3,3,4][i]}']
            if key=='i':lines += [f'projectile_count = {[5,7,9][i]}']
        lines += [f'[sub_resource type="Resource" id="target_{key}"]','script = ExtResource("target")',f'policy = "{policy}"',f'acquisition_radius = {float(reach or 310)}']
        if key=="k":lines.append('prefer_nearest_with_facing_fallback = true')
        caps=['damage','on_hit_hook','on_kill_hook','cooldown_manage','resize_area']
        if key in 'jk':caps+=['repeat_cast']
        if key=='k':caps+=['apply_status']
        if key=='l':caps+=['modify_shield','damage_taken_hook']
        tags=['damage','magic',kind]
        if key=='k':tags+=['cc']
        if key=='l':tags+=['buff']
        lines += [f'[sub_resource type="Resource" id="skill_{key}"]','script = ExtResource("skill")',f'id = &"skill.viridian.{key}"',f'display_name = "{title}"',f'slot = {slot}',f'unlock_level = {[3,6,9,11][slot-1]}',f'max_rank = {len(radii)}',f'executor = SubResource("exec_{key}")',f'targeting = SubResource("target_{key}")','rank_scaling = Array[ExtResource("rank")](['+','.join(f'SubResource("rank_{key}{i}")' for i in range(len(radii)))+'])','tags = Array[StringName](['+','.join('&"'+v+'"' for v in tags)+'])','declared_capabilities = Array[StringName](['+','.join('&"'+v+'"' for v in caps)+'])']
    lines+=['[resource]','script = ExtResource("loadout")','id = &"loadout.viridian"','character_id = &"character.viridian"','display_name = "Viridian — Control Mage"','class_id = &"mage"','stats = ExtResource("stats")','basic_attack = ExtResource("basic")','art_frames = ExtResource("frames")','cast_origin_offset = Vector2(0,-24)','tint = Color(0.196,0.788,0.404,1)','active_skills = Array[ExtResource("skill")](['+','.join(f'SubResource("skill_{k}")' for k in 'jkli')+'])']
    (ROOT/'content/characters/viridian_loadout.tres').write_text('\n'.join(lines)+'\n',encoding='utf8')
    p=ROOT/'content/catalog.tres';s=p.read_text()
    if 'id="viridian"' not in s:
        s=s.replace('[sub_resource','[ext_resource type="Resource" path="res://content/characters/viridian_loadout.tres" id="viridian"]\n\n[sub_resource',1)
        s=s.replace('definitions = Array[ExtResource("2")]([','definitions = Array[ExtResource("2")]([ExtResource("viridian"), ',1)
    p.write_text(s)

if __name__=='__main__':build()
