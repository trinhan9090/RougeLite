class_name CelestialVisualEffect
extends CombatVisualEffect
## Data-selected presentation. Never applies damage or owns combat timers/RNG.
const GOLD := Color("e8be71")
const ICE := Color("c9f5ff")
const BLUE := Color("5295f3")
var bound_shield: ShieldInstance
var shield_capacity: float = 1.0

func _process(delta: float) -> void:
	if bound_shield != null:
		var owner_actor := follow.get_ref() as Actor if follow != null else null
		if not is_instance_valid(owner_actor) or not owner_actor.health.is_alive() or bound_shield.remaining <= 0 or bound_shield.duration_left <= 0 or not owner_actor.health.shields.has(bound_shield):
			_finish()
			return
	super._process(delta)

func _star(center: Vector2, size: float, tint: Color, angle: float = 0.0) -> void:
	if size<.75: return
	if size<2.5:
		draw_rect(Rect2(center.round()-Vector2.ONE,Vector2(2,2)),tint)
		return
	var points := PackedVector2Array()
	for index in range(8):
		var length: float = size if index%2==0 else size*.23
		points.append(center+Vector2.from_angle(angle+index*TAU/8)*length)
	draw_colored_polygon(points,tint)

func _polygon_ring(center: Vector2, size: float, sides: int, angle: float, tint: Color, width: float = 1.0) -> void:
	var points := PackedVector2Array()
	for index in range(sides+1): points.append((center+Vector2.from_angle(angle+index*TAU/sides)*size).round())
	draw_polyline(points,tint,width,false)

func _rune(center: Vector2, size: float, opacity: float, phase: float = 0.0) -> void:
	# All ornamental vertices stay inside the resolved area radius.
	draw_arc(center,maxf(1,size-1),0,TAU,80,Color(color,opacity*.85),2,false)
	draw_arc(center,size*.91,0,TAU,72,Color(GOLD,opacity*.75),1,false)
	draw_arc(center,size*.73,0,TAU,64,Color(BLUE,opacity*.55),1,false)
	for index in range(12):
		var angle: float = phase+index*TAU/12
		var radial := Vector2.from_angle(angle)
		var tangent := radial.orthogonal()
		var point: Vector2 = center+radial*size*.82
		draw_line(point-radial*size*.028,point+radial*size*.028,Color(GOLD,opacity),1,false)
		draw_line(point-radial*size*.02,point+tangent*size*.025,Color(GOLD,opacity*.75),1,false)
		if index%3==0: _star(center+radial*size*.96,maxf(2,size*.035),Color(ICE,opacity))
	for index in range(6):
		var a := center+Vector2.from_angle(index*TAU/6+phase*.12)*size*.64
		var b := center+Vector2.from_angle((index+2)*TAU/6+phase*.12)*size*.64
		draw_line(a,b,Color(color,opacity*.38),1,false)
	_polygon_ring(center,size*.28,8,-phase*.25,Color(GOLD,opacity*.7))
	_star(center,size*.16,Color(ICE,opacity*.7),PI/4)

func _draw() -> void:
	var life: float = clampf(remaining/maxf(duration,.001),0,1)
	var fade: float = minf(1,life*5)
	if kind == "projectile":
		var core: float = clampf(radius,2,9)
		var long_tail: float = 34 if style=="snare" else 25
		draw_colored_polygon(PackedVector2Array([Vector2(7,0),Vector2(-7,-core),Vector2(-long_tail,0),Vector2(-7,core)]),Color(BLUE,.25))
		draw_line(Vector2(-long_tail,0),Vector2(5,0),Color(color,.45),core,false)
		draw_line(Vector2(-long_tail*.7,0),Vector2(6,0),ICE,2,false)
		_star(Vector2.ZERO,core,ICE)
		if style=="snare":
			_polygon_ring(Vector2.ZERO,core+2,8,PI/8,GOLD)
			draw_line(Vector2(-18,-core*.6),Vector2(-5,-core*.6),Color(GOLD,.8),1,false)
			draw_line(Vector2(-18,core*.6),Vector2(-5,core*.6),Color(GOLD,.8),1,false)
	elif kind == "beam":
		# The full envelope is exactly 2*resolved_radius and resolved_range long.
		var forward: Vector2 = line_end.normalized()
		var side: Vector2 = forward.orthogonal()
		draw_line(Vector2.ZERO,line_end,Color(BLUE,.19*fade),radius*2,false)
		draw_line(Vector2.ZERO,line_end,Color(color,.78*fade),radius*1.2,false)
		draw_line(Vector2.ZERO,line_end,Color(ICE,.95*fade),radius*.5,false)
		draw_line(Vector2.ZERO,line_end,Color(1,1,1,fade),maxf(2,radius*.15),false)
		for index in range(12):
			var position: float = fposmod(index/12.0+elapsed*1.4,1.0)
			var point: Vector2 = line_end*position
			var offset: float = sin(index*2.4+elapsed*20)*radius*.72
			draw_line(point+side*offset,point-forward*minf(18,point.length())+side*offset,Color(GOLD,.85*fade),2,false)
		for index in range(3):
			var point: Vector2 = line_end*(index+1)/4
			draw_arc(point,radius*.78,forward.angle()-1.3,forward.angle()+1.3,20,Color(GOLD,.65*fade),1,false)
		_star(forward*minf(16,line_end.length()),minf(radius*.65,16),Color(1,1,1,fade),forward.angle())
	elif kind == "area":
		if persistent:
			var pulse: float = .82+sin(elapsed*4)*.12
			draw_circle(Vector2.ZERO,radius,Color(BLUE,.07),true,-1,false)
			_rune(Vector2.ZERO,radius,pulse,elapsed*.08)
			for index in range(7):
				var angle: float = index*TAU/7+elapsed*.12
				var point := Vector2.from_angle(angle)*radius*(.35+index%3*.17)
				_star(point,2+sin(elapsed*5+index),Color(ICE,.45),PI/4)
		else:
			draw_arc(Vector2.ZERO,radius*(.75+.25*(1-life)),0,TAU,64,Color(ICE,life*.55),2,false)
	elif kind == "shield" and bound_shield != null:
		var strength: float = clampf(bound_shield.remaining/shield_capacity,0,1)
		var center := Vector2(0,-18)
		var opacity: float = .45+strength*.45
		draw_circle(center,radius,Color(BLUE,.06),true,-1,false)
		draw_arc(center,radius,0,TAU,72,Color(color,opacity),2,false)
		draw_arc(center,radius-4,PI,TAU,40,Color(ICE,opacity*.55),1,false)
		for index in range(8):
			var angle: float = index*TAU/8+elapsed*.17
			var point := center+Vector2.from_angle(angle)*(radius-3)
			_star(point,3.5,Color(GOLD,opacity),angle)
			if index%2==0: _polygon_ring(center+Vector2.from_angle(angle)*radius*.53,8,6,angle,Color(color,.2+strength*.18))
		draw_arc(center+Vector2(0,24),radius*.76,0,TAU,48,Color(GOLD,.3),1,false)
	elif kind == "status":
		var center := Vector2(0,7)
		_rune(center,radius,.85,elapsed*.13)
		for index in range(4):
			var point := center+Vector2.from_angle(index*TAU/4)*radius*.8
			draw_line(point,point-Vector2(0,18),Color(GOLD,.75),1,false)
			_star(point-Vector2(0,18),3,ICE)
	elif kind == "cast":
		_star(Vector2(10,0),radius*life,Color(ICE,fade))
		_polygon_ring(Vector2(10,0),radius*(1.1-life*.4),8,PI/8,Color(GOLD,life))
	else:
		var tint: Color = GOLD if style=="snare" else color
		_star(Vector2.ZERO,5*life,Color(1,1,1,fade),PI/4)
		for index in range(8):
			var radial := Vector2.from_angle(index*TAU/8)
			var point: Vector2 = radial*radius*(1-life)
			draw_line(point,point+radial*(3+life*5),Color(tint,life),1,false)
			if index%2==0: _star(point,2*life,Color(ICE,life),PI/4)
