extends Node2D
var actions:Array=[]
var sprites:Dictionary={}
var entries:Array=[]
var duplicate_keys:Dictionary={}
var raw_sprite:int=-1
var selected:int=0
var frame_index:int=0
var elapsed:float=0
var playing:bool=true
var zoom:int=4
var mirror:bool=false
var boxes:bool=false
var image:Sprite2D
var pivot:Node2D
var chooser:OptionButton
var info:Label
var scrub:HSlider
var blend:ShaderMaterial
var texture_cache:Dictionary={}
func _ready()->void:
	actions=JSON.parse_string(FileAccess.get_file_as_string("res://data/actions.json")).actions
	sprites=JSON.parse_string(FileAccess.get_file_as_string("res://data/sprites.json")).sprites
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/sprites.json"))
	entries=manifest.entries;duplicate_keys=manifest.duplicate_keys
	pivot=Node2D.new();pivot.position=Vector2(700,590);add_child(pivot)
	image=Sprite2D.new();image.centered=false;image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;pivot.add_child(image)
	blend=ShaderMaterial.new();blend.shader=load("res://blend.gdshader")
	var panel:=Panel.new();panel.size=Vector2(440,760);add_child(panel)
	var ui:=VBoxContainer.new();ui.position=Vector2(12,12);ui.size=Vector2(420,700);add_child(ui)
	var title:=Label.new();title.text="ATYU - MUGEN SOURCE BROWSER\nPrivate source preview / not PLAY / no top-down claim";ui.add_child(title)
	var search:=LineEdit.new();search.placeholder_text="Filter action ID";ui.add_child(search)
	chooser=OptionButton.new();ui.add_child(chooser);_filter("")
	search.text_changed.connect(_filter)
	chooser.item_selected.connect(func(i:int)->void:select_action(int(chooser.get_item_metadata(i))))
	var buttons:=HBoxContainer.new();ui.add_child(buttons)
	for label:String in ["Play/Pause","Prev","Next","Mirror","Boxes"]:
		var b:=Button.new();b.text=label;buttons.add_child(b);b.pressed.connect(func()->void:_button(label))
	var zs:=SpinBox.new();zs.min_value=1;zs.max_value=8;zs.value=4;zs.prefix="Zoom ";ui.add_child(zs);zs.value_changed.connect(func(v:float)->void:zoom=int(v);_show_frame())
	var speed:=SpinBox.new();speed.min_value=.1;speed.max_value=2;speed.step=.1;speed.value=1;speed.prefix="Speed ";ui.add_child(speed);speed.value_changed.connect(func(v:float)->void:set_meta("speed",v))
	var raw:=CheckBox.new();raw.text="Inspect raw sprite table (ignores AIR image ID)";ui.add_child(raw)
	var entry:=SpinBox.new();entry.min_value=0;entry.max_value=entries.size()-1;entry.prefix="SFF entry ";ui.add_child(entry)
	raw.toggled.connect(func(v:bool)->void:raw_sprite=int(entry.value) if v else -1;playing=false;_show_frame())
	entry.value_changed.connect(func(v:float)->void:if raw.button_pressed:raw_sprite=int(v);_show_frame())
	scrub=HSlider.new();scrub.step=1;ui.add_child(scrub);scrub.value_changed.connect(func(v:float)->void:playing=false;frame_index=int(v);elapsed=0;_show_frame())
	info=Label.new();info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.custom_minimum_size=Vector2(410,400);ui.add_child(info)
	select_action(0)
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--action="):
			for i:int in range(actions.size()):
				if int(actions[i].id)==int(arg.trim_prefix("--action=")):select_action(i);break
	if OS.get_cmdline_user_args().has("--smoke"):call_deferred("_smoke")
func _filter(query:String)->void:
	chooser.clear()
	for i:int in range(actions.size()):
		var a:Dictionary=actions[i]
		if query in str(a.id):chooser.add_item("Action %d / occurrence %d / %d frames"%[a.id,a.occurrence,a.frames.size()]);chooser.set_item_metadata(chooser.item_count-1,i)
func select_action(i:int)->void:
	selected=i;frame_index=0;elapsed=0
	if scrub!=null:scrub.max_value=maxi(0,actions[i].frames.size()-1)
	_show_frame()
func _button(label:String)->void:
	match label:
		"Play/Pause":playing=not playing
		"Prev":playing=false;frame_index=maxi(0,frame_index-1);elapsed=0
		"Next":playing=false;_advance();elapsed=0
		"Mirror":mirror=not mirror
		"Boxes":boxes=not boxes
	_show_frame()
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		pivot.position+=event.relative;queue_redraw()
func _advance()->void:
	var a:Dictionary=actions[selected]
	frame_index=frame_index+1 if frame_index+1<a.frames.size() else int(a.loop_start)
func _process(delta:float)->void:
	if actions.is_empty() or actions[selected].frames.is_empty():return
	var f:Dictionary=actions[selected].frames[frame_index]
	if playing and int(f.ticks)>=0:
		elapsed+=delta*60*float(get_meta("speed",1.0))
		for limit:int in range(actions[selected].frames.size()+1):
			f=actions[selected].frames[frame_index]
			if int(f.ticks)<0 or elapsed<maxf(0,float(f.ticks)):break
			elapsed-=maxf(0,float(f.ticks));_advance()
		_show_frame()
func _show_frame()->void:
	if image==null or actions.is_empty():return
	var action:Dictionary=actions[selected]
	if action.frames.is_empty():image.visible=false;return
	var f:Dictionary=action.frames[frame_index]
	if raw_sprite>=0:
		f=f.duplicate(true);f.offset=[0,0];f.scale=[1,1];f.angle=0;f.flip="";f.blend="";f["interpolate"]=[]
	var key:String="%d_%d"%[f.group,f.index]
	var data:Dictionary=sprites.get(key,{})
	if raw_sprite>=0:data=entries[raw_sprite];key=str(data.key)+" [table %d]"%raw_sprite
	image.visible=not data.is_empty() and (raw_sprite>=0 or int(f.group)>=0)
	pivot.scale=Vector2(-zoom if mirror else zoom,zoom)
	if image.visible:
		if not texture_cache.has(key):
			if texture_cache.size()>=32:texture_cache.clear()
			texture_cache[key]=ImageTexture.create_from_image(Image.load_from_file("res://data/"+str(data.path)))
		image.texture=texture_cache[key]
		var axis:=Vector2(data.axis[0],data.axis[1]);image.offset=-axis
		image.flip_h="H" in str(f.flip);image.flip_v="V" in str(f.flip)
		if image.flip_h:image.offset.x=axis.x-float(data.width)
		if image.flip_v:image.offset.y=axis.y-float(data.height)
		image.position=Vector2(f.offset[0],f.offset[1]);image.scale=Vector2(f.scale[0],f.scale[1]);image.rotation=-deg_to_rad(float(f.angle))
		var next_index:int=frame_index+1 if frame_index+1<action.frames.size() else int(action.loop_start)
		var next:Dictionary=action.frames[next_index]
		var progress:float=clampf(floorf(elapsed)/maxf(1,float(f.ticks)),0,1)
		var interpolation:Array=f.get("interpolate",[])
		if "offset" in interpolation:image.position=image.position.lerp(Vector2(next.offset[0],next.offset[1]),progress)
		if "scale" in interpolation:image.scale=image.scale.lerp(Vector2(next.scale[0],next.scale[1]),progress)
		if "angle" in interpolation:image.rotation=-deg_to_rad(lerpf(float(f.angle),float(next.angle),progress))
		image.material=null
		var mode:String=str(f.blend)
		if mode!="" or "blend" in interpolation:
			var weights:Vector2=_weights(mode)
			if "blend" in interpolation:weights=weights.lerp(_weights(str(next.blend)),progress)
			blend.set_shader_parameter("source_weight",weights.x);blend.set_shader_parameter("destination_weight",weights.y);blend.set_shader_parameter("subtractive",mode=="S");image.material=blend
	if scrub!=null:scrub.set_value_no_signal(frame_index)
	if info!=null:info.text="Action %s (#%s) / frame %d of %d\nSprite %s / ticks %s at 60Hz\nAIR offset %s / scale %s / angle %s\nFlip %s / blend %s\nSFF axis %s\nLoop start %s / source line %s\n\n%s\n%s\n\nSingle AIR action only. CNS helpers, Explod, camera, palette swaps and combat are not executed. Explicit AIR interpolation applied at60Hz; no invented frame smoothing. Right-drag pans. Raw table mode examines duplicate sprites. Select raw IDs before assigning any Atyu skill."%[action.id,action.occurrence,frame_index+1,action.frames.size(),key,f.ticks,f.offset,f.scale,f.angle,f.flip,f.blend,data.get("axis",[]),action.loop_start,f.line,"SOURCE DECODED - VISUAL REVIEW PENDING" if image.visible else "EMPTY WAIT FRAME" if int(f.group)<0 else "UNRESOLVED SPRITE",("DUPLICATE SPRITE KEY: first table entry used; alternatives "+str(duplicate_keys.get(key,[])) if duplicate_keys.has(key) else "")+ (" SOURCE SYNTAX WARNING: "+str(action.unknown) if not action.unknown.is_empty() else "")]
	queue_redraw()
func _weights(mode:String)->Vector2:
	if mode=="":return Vector2(1,0)
	if mode=="A1":return Vector2(1,.5)
	if mode.begins_with("AS"):
		var parts:PackedStringArray=mode.trim_prefix("AS").split("D")
		return Vector2(float(parts[0])/256,float(parts[1])/256)
	return Vector2.ONE
func _draw()->void:
	draw_rect(Rect2(445,0,655,760),Color("202737"))
	if pivot!=null:
		draw_line(Vector2(445,pivot.position.y),Vector2(1100,pivot.position.y),Color("516070"))
		draw_line(Vector2(pivot.position.x,120),Vector2(pivot.position.x,710),Color("516070"))
	if boxes and not actions.is_empty() and not actions[selected].frames.is_empty():
		var f:Dictionary=actions[selected].frames[frame_index]
		for kind:String in ["1","2"]:
			for b:Array in f.boxes[kind]:
				var points:=PackedVector2Array()
				for p:Vector2 in [Vector2(b[0],b[1]),Vector2(b[2],b[1]),Vector2(b[2],b[3]),Vector2(b[0],b[3]),Vector2(b[0],b[1])]:points.append(pivot.position+p*pivot.scale)
				draw_polyline(points,Color.RED if kind=="1" else Color.CYAN,1)
func _smoke()->void:
	var checks:int=0
	var idle:int=0
	for i:int in range(actions.size()):
		if int(actions[i].id)==0:idle=i;break
	select_action(idle);playing=true;_process(float(actions[idle].frames[0].ticks)/60+.000001)
	assert(frame_index==1,"source tick timing must advance once")
	mirror=true;_show_frame();assert(pivot.scale.x<0,"mirrored origin transform")
	mirror=false
	for i:int in range(actions.size()):
		if actions[i].frames.is_empty():continue
		var last:int=actions[i].frames.size()-1
		if int(actions[i].frames[last].ticks)==-1:
			select_action(i);frame_index=last;_process(10);assert(frame_index==last,"indefinite AIR hold");break
	assert(_weights("AS128D256")==Vector2(.5,1),"source alpha weights")
	for i:int in range(actions.size()):
		select_action(i)
		for f:int in range(actions[i].frames.size()):
			frame_index=f;_show_frame();checks+=1
	print("ATYU_BROWSER_SMOKE_OK actions=",actions.size()," frames=",checks)
	get_tree().quit()
