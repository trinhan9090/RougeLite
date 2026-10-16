class_name PixelTerrain
extends TileMapLayer
## Presentation only: no tile collisions. ArenaGeometry owns every collider.
func configure(definition: MapDefinition) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var theme: String = String(definition.id).trim_prefix("map.")
	var path: String = "res://assets/tiles/"+theme+"/terrain.png"
	var texture := load(path) as Texture2D
	if texture == null: return
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(32,32)
	for variant in range(4): atlas.create_tile(Vector2i(variant,0))
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(32,32)
	tile_set.add_source(atlas,0)
	var start := Vector2i(floori(definition.bounds.position.x/32),floori(definition.bounds.position.y/32))
	var end := Vector2i(ceili(definition.bounds.end.x/32),ceili(definition.bounds.end.y/32))
	for x in range(start.x,end.x):
		for y in range(start.y,end.y):
			var variant: int = posmod(x*73+y*131+x*y*7,4)
			set_cell(Vector2i(x,y),0,Vector2i(variant,0))
