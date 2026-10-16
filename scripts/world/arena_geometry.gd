class_name ArenaGeometry
extends Node2D
## Authored open test arena; random obstacle/navigation generation belongs to M4.

var definition: MapDefinition
var obstacles: Array[Rect2] = [Rect2(300, -70, 80, 140), Rect2(-480, -240, 100, 160), Rect2(-180, 360, 180, 70)]
var _grid: AStarGrid2D
var _flow_goal: Vector2i = Vector2i(-999,-999)
var _flow: Dictionary[Vector2i,Vector2i] = {}
var _hazard_clock: float = 0
var _hazard_tick: float = .5

func _ready() -> void:
	if definition == null:
		definition = load("res://content/maps/ruined_temple.tres") as MapDefinition
	_rebuild()

func apply_layout(map: MapDefinition, layout: Array[Rect2]) -> void:
	_hazard_clock = 0
	_hazard_tick = map.hazard_interval
	definition = map
	obstacles = layout.duplicate()
	for child in get_children(): child.free()
	_rebuild()

func _rebuild() -> void:
	var terrain := PixelTerrain.new()
	terrain.name = "PixelTerrain"
	terrain.z_index = -2
	add_child(terrain)
	terrain.configure(definition)
	_flow_goal = Vector2i(-999,-999)
	_flow.clear()
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(0,0,40,27)
	_grid.cell_size = Vector2(55,55)
	_grid.offset = definition.bounds.position + Vector2(27.5,27.5)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for x in range(40):
		for y in range(27): _grid.set_point_solid(Vector2i(x,y),not MapLayoutGenerator.clear(_grid.get_point_position(Vector2i(x,y)),obstacles,28))
	var bounds: Rect2 = definition.bounds
	_add_wall(Rect2(bounds.position - Vector2(40, 40), Vector2(bounds.size.x + 80, 40)))
	_add_wall(Rect2(Vector2(bounds.position.x - 40, bounds.end.y), Vector2(bounds.size.x + 80, 40)))
	_add_wall(Rect2(bounds.position - Vector2(40, 0), Vector2(40, bounds.size.y)))
	_add_wall(Rect2(Vector2(bounds.end.x, bounds.position.y), Vector2(40, bounds.size.y)))
	for obstacle in obstacles:
		_add_wall(obstacle)
	queue_redraw()

func navigation_direction(from: Vector2, to: Vector2) -> Vector2:
	# Cell positions are centers, not cell origins. Truncating relative to the
	# center switched cells early and steered bodies through obstacle corners.
	if _segment_clear(from, to, 13): return from.direction_to(to)
	var start := _cell_at(from)
	var end := _cell_at(to)
	start = start.clamp(Vector2i.ZERO,Vector2i(39,26))
	end = end.clamp(Vector2i.ZERO,Vector2i(39,26))
	if _grid.is_point_solid(start):
		var exit_cell: Vector2i = _nearest_open_cell(from)
		return from.direction_to(_grid.get_point_position(exit_cell))
	if _grid.is_point_solid(end): end = _nearest_open_cell(to)
	if end != _flow_goal:
		_flow_goal = end
		_flow.clear()
		_flow[end] = end
		var queue: Array[Vector2i] = [end]
		var i: int = 0
		while i < queue.size():
			var current: Vector2i = queue[i]
			i += 1
			for step: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var next: Vector2i = current+step
				if _grid.is_in_boundsv(next) and not _grid.is_point_solid(next) and not _flow.has(next):
					_flow[next] = current
					queue.append(next)
	if _flow.has(start) and _flow[start] != start:
		var waypoint: Vector2 = _grid.get_point_position(_flow[start])
		# Off-center bodies must align before rounding a blocked corner.
		if not _segment_clear(from, waypoint): waypoint = _grid.get_point_position(start)
		return from.direction_to(waypoint)
	return from.direction_to(to)

func _cell_at(point: Vector2) -> Vector2i:
	var relative: Vector2 = (point - definition.bounds.position) / 55.0
	return Vector2i(floori(relative.x), floori(relative.y))

func _nearest_open_cell(point: Vector2) -> Vector2i:
	var best := Vector2i.ZERO
	var distance: float = INF
	for x in range(40):
		for y in range(27):
			var cell := Vector2i(x,y)
			if _grid.is_point_solid(cell): continue
			var candidate: float = point.distance_squared_to(_grid.get_point_position(cell))
			if candidate < distance:
				distance = candidate
				best = cell
	return best

func _segment_clear(from: Vector2, to: Vector2, radius: float = 28) -> bool:
	for obstacle in obstacles:
		var expanded: Rect2 = obstacle.grow(radius)
		if expanded.has_point(from) or expanded.has_point(to): return false
		var a: Vector2 = expanded.position
		var b := Vector2(expanded.end.x, expanded.position.y)
		var c: Vector2 = expanded.end
		var d := Vector2(expanded.position.x, expanded.end.y)
		for edge: Array in [[a,b],[b,c],[c,d],[d,a]]:
			if Geometry2D.segment_intersects_segment(from,to,edge[0],edge[1]) != null: return false
	return true

func navigable(point: Vector2) -> bool:
	var cell := _cell_at(point)
	return _grid.is_in_boundsv(cell) and not _grid.is_point_solid(cell)

func spawn_clear(point: Vector2, radius: float) -> bool:
	if not point_clear(point,radius): return false
	for hazard in definition.hazards:
		if hazard.grow(radius).has_point(point): return false
	return true

func hazard_step(delta: float, point: Vector2) -> bool:
	if definition.hazards.is_empty(): return false
	var previous: int = floori(fmod(_hazard_clock,6))
	_hazard_clock += delta
	var phase: float = fmod(_hazard_clock,6)
	if floori(phase) != previous: queue_redraw()
	if phase < 1 or phase >= 4:
		_hazard_tick = definition.hazard_interval
		return false
	_hazard_tick -= delta
	if _hazard_tick > 0: return false
	_hazard_tick += definition.hazard_interval
	for hazard in definition.hazards:
		if hazard.has_point(point): return true
	return false

func _add_wall(rectangle: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 4
	wall.collision_mask = 0
	wall.position = rectangle.get_center()
	var shape := RectangleShape2D.new()
	shape.size = rectangle.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	wall.add_child(collider)
	add_child(wall)

func point_clear(point: Vector2, radius: float) -> bool:
	if not definition.bounds.grow(-radius).has_point(point):
		return false
	for obstacle in obstacles:
		if obstacle.grow(radius).has_point(point):
			return false
	return true

func _draw() -> void:
	draw_rect(definition.bounds, Color("536175"), false, 3)
	for obstacle in obstacles:
		draw_rect(obstacle, definition.obstacle_color)
		draw_rect(Rect2(obstacle.position,Vector2(obstacle.size.x,8)),definition.obstacle_color.lightened(.2))
		for x in range(int(obstacle.position.x)+12,int(obstacle.end.x),24):
			draw_line(Vector2(x,obstacle.position.y+10),Vector2(x,obstacle.end.y-2),definition.obstacle_color.darkened(.2),2)
		draw_rect(obstacle, Color("65798d"), false, 2)
	for hazard in definition.hazards:
		var phase: float = fmod(_hazard_clock,6)
		draw_rect(hazard,Color(1,.25,.05,.65) if phase >= 1 and phase < 4 else Color(.7,.25,.05,.2))
		draw_rect(hazard,Color.ORANGE,false,2)
