class_name MapLayoutGenerator
extends RefCounted
## Conservative coarse flood fill; every generated free cell must be connected.
const CELL: int = 55
static func clear(point: Vector2, obstacles: Array[Rect2], radius: float = 24) -> bool:
	for rect in obstacles:
		if rect.grow(radius).has_point(point): return false
	return true
static func connected(definition: MapDefinition, obstacles: Array[Rect2]) -> bool:
	var grid := AStarGrid2D.new()
	var size := Vector2i(floori(definition.bounds.size.x / CELL),floori(definition.bounds.size.y / CELL))
	grid.region = Rect2i(Vector2i.ZERO,size)
	grid.cell_size = Vector2(CELL,CELL)
	grid.offset = definition.bounds.position + Vector2.ONE * CELL * .5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var available: int = 0
	for x in range(size.x):
		for y in range(size.y):
			var cell := Vector2i(x,y)
			var solid: bool = not clear(grid.get_point_position(cell),obstacles)
			grid.set_point_solid(cell,solid)
			if not solid: available += 1
	var start := Vector2i((definition.safe_spawn_anchor-definition.bounds.position)/CELL)
	if grid.is_point_solid(start): return false
	var queue: Array[Vector2i] = [start]
	var seen: Dictionary[Vector2i,bool] = {start:true}
	var index: int = 0
	while index < queue.size():
		var cell: Vector2i = queue[index]
		index += 1
		for step: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+step
			if grid.is_in_boundsv(next) and not grid.is_point_solid(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return available == seen.size()
static func generate(definition: MapDefinition, rng: RandomNumberGenerator) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for index in range(definition.obstacle_count):
		for attempt in range(definition.spawn_attempts):
			var center := Vector2(rng.randf_range(-900,900),rng.randf_range(-570,570))
			var size := Vector2(rng.randf_range(65,120),rng.randf_range(65,140))
			var rect := Rect2(center-size*.5,size)
			# Four explicit open escape corridors and a safe250px starting disk.
			if rect.grow(definition.safe_spawn_radius).has_point(definition.safe_spawn_anchor) or absf(center.x) < size.x*.5+definition.min_path_width*.5 or absf(center.y) < size.y*.5+definition.min_path_width*.5: continue
			var overlap: bool = false
			for previous in result:
				if previous.grow(definition.min_path_width).intersects(rect): overlap = true
			if overlap: continue
			result.append(rect)
			if connected(definition,result): break
			result.pop_back()
	if not connected(definition,result): result.clear() # Proven safe open fallback.
	return result
