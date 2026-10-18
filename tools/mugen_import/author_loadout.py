"""Author explicit provisional Atyu rank data, without altering existing heroes."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]

def build():
    stats=(ROOT/'content/characters/boros_stats.tres').read_text().replace('260.0','190.0').replace('205.0','225.0').replace('18.0','10.0').replace('0.03','0.05')
    (ROOT/'content/characters/atyu_stats.tres').write_text(stats)
    basic=(ROOT/'content/skills/boros_basic.tres').read_text().replace('boros','atyu').replace('Boros basic','Liên kiếm').replace('0.95','0.85').replace('25.0','22.0').replace('85.0','110.0')
    (ROOT/'content/skills/atyu_basic.tres').write_text(basic,encoding='utf8')
    lines=['[gd_resource type="Resource" script_class="CombatLoadoutDefinition" format=3]']
    scripts={'loadout':'combat_loadout_definition','skill':'skill_definition','rank':'skill_rank_definition','target':'targeting_definition','executor':'source_move_executor','status':'status_effect_definition'}
    for key,name in scripts.items(): lines.append(f'[ext_resource type="Script" path="res://scripts/data/{name}.gd" id="{key}"]')
    for key,path in {'stats':'content/characters/atyu_stats.tres','basic':'content/skills/atyu_basic.tres','frames':'assets/private_atyu/frames.tres'}.items():
        lines.append(f'[ext_resource type="Resource" path="res://{path}" id="{key}"]')
    rows=[
        ('j','Kiếm trảm','cone','area',5.5,[55,68,82,98],0,[140,155,170,185],0,.15,'cursor',85),
        ('k','Chú ngôn: Trói buộc','control','status',11,[0]*4,240,[0]*4,1.4,.2,'nearest',85),
        ('l','Linh thể hộ chiến','companion','area',16,[24,30,36,44],240,[1]*4,8,.4,'self',85),
        ('i','Quang chú hợp kích','charged_beam','beam',24,[160,205,255],420,[17,20,23],0,.4,'cursor',85)]
    for slot,(key,title,move,kind,cd,damage,reach,radius,duration,windup,policy,arc) in enumerate(rows,1):
        if key=='k':
            lines += ['[sub_resource type="Resource" id="root"]','script = ExtResource("status")','kind = "root"','duration = 1.4']
        lines += [f'[sub_resource type="Resource" id="exec_{key}"]','script = ExtResource("executor")',f'executor_id = &"executor.source_{move}"',f'move = "{move}"',f'kind = "{kind}"',f'windup = {windup}','tick_interval = 1.2']
        if key=='k': lines += ['status = SubResource("root")']
        for i,dmg in enumerate(damage):
            rank_duration=1.4+i*.2 if key=="k" else 8.0+i if key=="l" else duration
            rank_reach=240.0+i*20 if key=="l" else reach
            lines += [f'[sub_resource type="Resource" id="rank_{key}{i}"]','script = ExtResource("rank")',f'rank = {i+1}',f'cooldown = {cd}',f'damage = {float(dmg)}',f'range_px = {float(rank_reach)}',f'radius_px = {float(radius[i])}',f'duration = {float(rank_duration)}',f'damage_type = "{"PHYSICAL" if key=="j" else "MAGIC"}"']
        lines += [f'[sub_resource type="Resource" id="target_{key}"]','script = ExtResource("target")',f'policy = "{policy}"',f'acquisition_radius = {float(reach or radius[0])}']
        lines += [f'[sub_resource type="Resource" id="skill_{key}"]','script = ExtResource("skill")',f'id = &"skill.atyu.{key}"',f'display_name = "{title}"',f'slot = {slot}',f'unlock_level = {[3,6,9,11][slot-1]}',f'max_rank = {len(damage)}',f'executor = SubResource("exec_{key}")',f'targeting = SubResource("target_{key}")','rank_scaling = Array[ExtResource("rank")](['+','.join(f'SubResource("rank_{key}{i}")' for i in range(len(damage)))+'])']
        caps=['apply_status','cooldown_manage'] if key=='k' else ['damage','on_hit_hook','on_kill_hook','cooldown_manage']
        tags={'j':['damage','physical','area','directional'],'k':['cc','magic'],'l':['damage','magic','summon'],'i':['damage','magic','beam','directional']}[key]
        lines += ['tags = Array[StringName](['+','.join('&"'+tag+'"' for tag in tags)+'])']
        if key in ['j','i']: caps.append('resize_area')
        lines += ['declared_capabilities = Array[StringName](['+','.join('&"'+cap+'"' for cap in caps)+'])']
    lines += ['[resource]','script = ExtResource("loadout")','id = &"loadout.atyu"','character_id = &"character.atyu"','display_name = "Atyu"','class_id = &"brute"','stats = ExtResource("stats")','basic_attack = ExtResource("basic")','art_frames = ExtResource("frames")','cast_origin_offset = Vector2(0,-24)','tint = Color(0.75,0.65,1,1)','weapon = "hammer"','active_skills = Array[ExtResource("skill")](['+','.join(f'SubResource("skill_{k}")' for k in 'jkli')+'])']
    (ROOT/'content/characters/atyu_loadout.tres').write_text('\n'.join(lines)+'\n',encoding='utf8')
    path=ROOT/'content/catalog.tres'
    text=path.read_text()
    if 'id="atyu"' not in text:
        text=text.replace('[sub_resource', '[ext_resource type="Resource" path="res://content/characters/atyu_loadout.tres" id="atyu"]\n\n[sub_resource',1)
        text=text.replace('definitions = Array[ExtResource("2")]([','definitions = Array[ExtResource("2")]([ExtResource("atyu"), ',1)
    path.write_text(text,encoding='utf8')

if __name__=='__main__': build()
