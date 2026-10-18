"""Apply visual-only v3 adapters on the isolated branch. No combat resources edited."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[2]
def replace(file,old,new):
 p=R/file;s=p.read_text(encoding='utf-8');assert old in s,(file,old);p.write_text(s.replace(old,new),encoding='utf-8')
replace('content/characters/astra_loadout.tres','res://assets/characters/astra/frames.tres','res://assets/art_v3/characters/astra/frames.tres')
replace('scripts/ui/actor_sprite.gd','\t_update_size()\n\tif sprite_frames.has_meta', '\tif sprite_frames.get_meta("pixel_v3",false):\n\t\t_base_scale = 1\n\t\t_feet_offset = float(sprite_frames.get_meta("feet_anchor").y)-reference.get_height()*.5\n\t_update_size()\n\tif sprite_frames.has_meta')
replace('scripts/ui/actor_sprite.gd','position = Vector2(0,20-_feet_offset*factor)','position = Vector2(0,(0 if sprite_frames.get_meta("pixel_v3",false) else 20)-_feet_offset*factor)')
replace('scripts/ui/visual_controller.gd','\tif sprite_frames.get_meta("baked_3d",false): shadow.position.y = profile.feet_anchor.y-96-37','\tif sprite_frames.get_meta("baked_3d",false): shadow.position.y = profile.feet_anchor.y-96-37\n\tif sprite_frames.get_meta("pixel_v3",false):\n\t\tshadow.position.y = float(sprite_frames.get_meta("feet_anchor").y)-48-37\n\t\tshadow.scale.x = .65')
f='scripts/ui/combat_visual_factory.gd'
replace(f,'var _status_targets:', 'var _pixel_mode: bool = false\nvar _status_targets:')
# Existing boolean pool selects the configured custom renderer once per run;
# all custom effects within this factory use the same renderer. Legacy remains isolated.
replace(f,'\tcombat.visual_event.connect(_on_event)','\t_pixel_mode = renderers.values().has("pixel_v3")\n\tcombat.visual_event.connect(_on_event)')
replace(f,'!= "celestial": return','not in ["celestial","pixel_v3"]: return')
replace(f,'=="celestial"','in ["celestial","pixel_v3"]')
replace(f,'var effect := CelestialVisualEffect.new()','var effect: CelestialVisualEffect = PixelVisualEffect.new() if _pixel_mode else CelestialVisualEffect.new()')
replace(f,'CelestialVisualEffect.new() if celestial else CombatVisualEffect.new()', '(PixelVisualEffect.new() if _pixel_mode else CelestialVisualEffect.new()) if celestial else CombatVisualEffect.new()')
for p in (R/'assets/vfx/generated').glob('astra_*.json'):
 m=json.loads(p.read_text());m['parameters']['renderer']='pixel_v3';m['parameters']['revision']='astra-pixel-v3';p.write_text(json.dumps(m,indent=2)+'\n')
replace('tests/integration/test_astra_celestial_vfx.gd','=="celestial"','=="pixel_v3"')
replace('tests/integration/test_art_frames.gd','texture.get_width()==128','texture.get_width()==(96 if actor.visual_frames.get_meta("pixel_v3",false) else 128)')
replace('tests/integration/test_art_frames.gd','check(actor.sprite_visual.has_node("WeaponPivot/Weapon"),"separate weapon layer")','check(actor.sprite_visual.has_node("WeaponPivot/Weapon") or actor.visual_frames.get_meta("pixel_v3",false),"separate weapon node or frame-composited editable weapon layer")')
# Keep legacy UI layout at a virtual 1280x720 while world pixels use native 640x360.
for file in ['scripts/ui/foundation_menu.gd','scripts/ui/run_presentation.gd']:
 p=R/file;s=p.read_text();needle='func _ready() -> void:\n';s=s.replace(needle,needle+'\tcall_deferred("_pixel_layout")\n',1)
 s+='\nfunc _pixel_layout() -> void:\n\tset_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)\n\tsize = Vector2(1280,720)\n\tscale = Vector2(.5,.5)\n'
 p.write_text(s)
replace('project.godot','config/name="Endless Survival RPG"','config/name="Endless Survival RPG | Astra Pixel v3"')
replace('project.godot','window/size/viewport_height=720','window/size/viewport_width=640\nwindow/size/viewport_height=360\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720\nwindow/stretch/scale_mode="integer"')
replace('project.godot','renderer/rendering_method="gl_compatibility"','textures/default_filters/use_nearest_mipmap_filter=false\ntextures/canvas_textures/default_texture_filter=0\n2d/snap/snap_2d_transforms_to_pixel=true\nrenderer/rendering_method="gl_compatibility"')
replace('scripts/ui/pixel_terrain.gd','var texture := load(path)', 'if theme == "ruined_temple": path = "res://assets/art_v3/world/courtyard.png"\n\tvar cell: int = 16 if theme == "ruined_temple" else 32\n\tvar texture := load(path)')
p=R/'scripts/ui/pixel_terrain.gd';s=p.read_text().replace('Vector2i(32,32)','Vector2i(cell,cell)').replace('/32','/float(cell)');p.write_text(s)
replace('scripts/core/combat_run_root.gd','\t_actors = Node2D.new()','\t_actors = Node2D.new()\n\t_actors.y_sort_enabled = true')
# Reference packs, authoring layers and reports are not runtime content.
p=R/'export_presets.cfg';s=p.read_text().replace('assets/vfx/generated/*.json','assets/vfx/generated/*.json,assets/art_v3/**/*.json').replace('docs/*,tests/*','art_source/*,reports/*,assets/Endless_Survival_Wizard_of_Legend_Visual_Spec_v3/*,docs/*,tests/*');p.write_text(s)
(R/'art_source/.gdignore').touch()
print('V3 runtime adapters integrated; gameplay numeric data unchanged')
