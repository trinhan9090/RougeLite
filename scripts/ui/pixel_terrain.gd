class_name PixelTerrain
extends TileMapLayer
## Presentation only: no tile collisions. ArenaGeometry owns every collider.
func configure(definition: MapDefinition) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var theme: String = String(definition.id).trim_prefix("map.")
	var path: String = "res://assets/tiles/"+theme+"/terrain.png"
	if theme == "ruined_temple": path = "res://assets/art_v3/world/courtyard.png"
	var cell: int = 16 if theme == "ruined_temple" else 32
	var texture := load(path) as Texture2D
	if texture == null: return
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(cell,cell)
	for variant in range(4): atlas.create_tile(Vector2i(variant,0))
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(cell,cell)
	tile_set.add_source(atlas,0)
	var start := Vector2i(floori(definition.bounds.position.x/float(cell)),floori(definition.bounds.position.y/float(cell)))
	var end := Vector2i(ceili(definition.bounds.end.x/float(cell)),ceili(definition.bounds.end.y/float(cell)))
	for x in range(start.x,end.x):
		for y in range(start.y,end.y):
			var variant: int = posmod(x*73+y*131+x*y*7,4)
			set_cell(Vector2i(x,y),0,Vector2i(variant,0))
