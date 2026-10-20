"""Tofu gameplay DEMO DEFAULT data; does not mutate any existing hero definition."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def ext(script,id):return f'[ext_resource type="Script" path="res://scripts/data/{script}.gd" id="{id}"]'
def build():
 (ROOT/'content/characters/tofu_stats.tres').write_text('[gd_resource type="Resource" script_class="ActorStatDefinition" format=3]\n'+ext('actor_stat_definition','stats')+'\n[resource]\nscript = ExtResource("stats")\nmax_hp = 200.0\nmove_speed = 215.0\narmor = 10.0\ncrit_chance = 0.05\ncrit_multiplier = 1.5\n')
 lines=['[gd_resource type="Resource" script_class="SkillDefinition" format=3]',ext('skill_definition','skill'),ext('melee_combo_basic','exec'),ext('skill_rank_definition','rank'),ext('targeting_definition','target'),'[sub_resource type="Resource" id="Executor"]','script = ExtResource("exec")','executor_id = &"executor.melee_combo"','strategy = "melee"','combo_damage = Array[float]([10,15,30])','[sub_resource type="Resource" id="Rank"]','script = ExtResource("rank")','cooldown = 0.55','damage = 10.0','range_px = 110.0','[sub_resource type="Resource" id="Target"]','script = ExtResource("target")','acquisition_radius = 110.0','[resource]','script = ExtResource("skill")','id = &"skill.tofu.basic"','display_name = "Cursed-Tool Slash"','executor = SubResource("Executor")','targeting = SubResource("Target")','rank_scaling = Array[ExtResource("rank")]([SubResource("Rank")])','declared_capabilities = Array[StringName]([&"damage",&"on_hit_hook",&"on_kill_hook",&"repeat_cast"])']
 (ROOT/'content/skills/tofu_basic.tres').write_text('\n'.join(lines)+'\n')
 lines=['[gd_resource type="Resource" script_class="CombatLoadoutDefinition" format=3]']
 for script,id in [('combat_loadout_definition','loadout'),('skill_definition','skill'),('skill_rank_definition','rank'),('melee_sequence_executor','exec'),('targeting_definition','target'),('skill_behavior_definition','behavior')]:lines.append(ext(script,id))
 for id,path in [('stats','content/characters/tofu_stats.tres'),('basic','content/skills/tofu_basic.tres'),('frames','assets/private_tofu/frames.tres')]:lines.append(f'[ext_resource type="Resource" path="res://{path}" id="{id}"]')
 config=[('j','Playful Cloud Rush','rush','dash',.08,.1,6,2,8,15,240,75,.6),('k','Debris Projection','debris','area',.35,.5,1,0,14,40,300,110,6),('l','Chain of a Thousand Miles','chain','dash',.10,.18,4,1,16,50,200,110,.9),('i','Inverted Spear of Heaven','nuke','area',.45,.1,1,0,30,180,110,70,.5)]
 for slot,(key,title,move,kind,windup,interval,hits,extra,cd,damage,reach,radius,duration) in enumerate(config,1):
  lines += [f'[sub_resource type="Resource" id="exec_{key}"]','script = ExtResource("exec")',f'executor_id = &"executor.melee_sequence.{move}"',f'move = "{move}"',f'kind = "{kind}"',f'windup = {windup}',f'hit_interval = {interval}',f'base_hits = {hits}',f'rank2_extra_hits = {extra}']
  count=3 if key=='i' else 4
  for i in range(count):
   lines += [f'[sub_resource type="Resource" id="behavior_{key}{i}"]','script = ExtResource("behavior")',f'can_crit = {str(key!="k").lower()}']
   if key=='i' and i>=1:lines += ['boss_bonus = 0.3']
   lines += [f'[sub_resource type="Resource" id="rank_{key}{i}"]','script = ExtResource("rank")',f'rank = {i+1}',f'cooldown = {float(cd*.8 if key=="i" and i==2 else cd)}',f'damage = {float(damage)}','damage_type = "PHYSICAL"',f'range_px = {float(reach)}',f'radius_px = {radius*1.2 if key=="k" and i>=1 else float(radius)}',f'duration = {float(duration)}',f'behavior = SubResource("behavior_{key}{i}")']
  lines += [f'[sub_resource type="Resource" id="target_{key}"]','script = ExtResource("target")',f'acquisition_radius = {float(reach)}','policy = "cursor"']
  if key=="k":lines.append('prefer_nearest_with_facing_fallback = true')
  caps=['damage','cooldown_manage','apply_status']+(['on_kill_hook'] if key=='k' else ['on_hit_hook'])
  if key!='i':caps+=['repeat_cast']
  if key=='k':caps+=['resize_area']
  if key in 'jl':caps+=['dash_completed_hook']
  lines += [f'[sub_resource type="Resource" id="skill_{key}"]','script = ExtResource("skill")',f'id = &"skill.tofu.{key}"',f'display_name = "{title}"',f'slot = {slot}',f'unlock_level = {[3,6,9,11][slot-1]}',f'max_rank = {count}',f'executor = SubResource("exec_{key}")',f'targeting = SubResource("target_{key}")','rank_scaling = Array[ExtResource("rank")](['+','.join(f'SubResource("rank_{key}{i}")' for i in range(count))+'])','declared_capabilities = Array[StringName](['+','.join('&"'+v+'"' for v in caps)+'])','tags = Array[StringName]([&"damage",&"physical",&"melee"])']
 lines+=['[resource]','script = ExtResource("loadout")','id = &"loadout.tofu"','character_id = &"character.tofu"','display_name = "Tofu"','class_id = &"brute"','weapon = "hammer"','stats = ExtResource("stats")','basic_attack = ExtResource("basic")','art_frames = ExtResource("frames")','cast_origin_offset = Vector2(0,-24)','tint = Color(0.5,0.4,0.65,1)','active_skills = Array[ExtResource("skill")](['+','.join(f'SubResource("skill_{k}")' for k in 'jkli')+'])']
 (ROOT/'content/characters/tofu_loadout.tres').write_text('\n'.join(lines)+'\n')
 p=ROOT/'content/catalog.tres';text=p.read_text()
 if 'id="tofu"' not in text:
  text=text.replace('[sub_resource','[ext_resource type="Resource" path="res://content/characters/tofu_loadout.tres" id="tofu"]\n[sub_resource',1)
  text=text.replace('definitions = Array[ExtResource("2")]([','definitions = Array[ExtResource("2")]([ExtResource("tofu"),',1)
 p.write_text(text)
 print('TOFU_CONTENT 5skills,4/4/4/3 ranks; brute class Bruiser role')
if __name__=='__main__':build()
