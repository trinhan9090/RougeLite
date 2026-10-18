"""Use Blender's bundled video encoder; no paid codec/plugin or pip bpy."""
import argparse, sys
from pathlib import Path
import bpy
parser=argparse.ArgumentParser(); parser.add_argument('--input',required=True); parser.add_argument('--output',required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene; editor=scene.sequence_editor_create()
scene.render.fps=30; scene.render.resolution_x=1280; scene.render.resolution_y=720; scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'; scene.view_settings.look='None'
strips=editor.strips if hasattr(editor,'strips') else editor.sequences
movie=strips.new_movie('Actual Godot capture',str(Path(args.input).resolve()),channel=1,frame_start=1)
scene.frame_start=1; scene.frame_end=int(movie.frame_final_duration)
scene.render.image_settings.media_type='VIDEO'
scene.render.ffmpeg.format='MPEG4'; scene.render.ffmpeg.codec='H264'; scene.render.ffmpeg.constant_rate_factor='MEDIUM'
scene.render.filepath=str(Path(args.output).resolve()); scene.render.use_sequencer=True
bpy.ops.render.render(animation=True)
if not Path(args.output).is_file(): raise RuntimeError('Video output missing')
print('VIDEO_ENCODE_OK frames=%d fps=30' % scene.frame_end)
