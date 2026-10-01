extends SceneTree
## Gera TileSets de display tiles para TileMapDual com terrains configurados.
## Execute com: godot --headless --path . --script tools/generate_display_tilesets_runtime.gd

const TILE_SIZE := Vector2i(16, 16)

const TERRAINS := {
	"water": "res://assets/tiles/terrain_water.png",
	"dirt": "res://assets/tiles/terrain_dirt.png",
	"soil": "res://assets/tiles/terrain_soil.png",
}

func _init() -> void:
	for terrain_name in TERRAINS:
		var texture_path: String = TERRAINS[terrain_name]
		var ts := _generate_tileset(terrain_name, texture_path)
		if ts == null:
			continue
		
		var output_path: String = "res://assets/tiles/display_" + terrain_name + ".tres"
		var err := ResourceSaver.save(ts, output_path)
		if err == OK:
			print("Generated: " + output_path)
		else:
			push_error("Failed to save: " + output_path + " (error: " + str(err) + ")")
	
	print("All display tilesets generated!")
	quit()


func _generate_tileset(terrain_name: String, texture_path: String) -> TileSet:
	var tex := load(texture_path) as Texture2D
	if tex == null:
		push_error("Texture not found: " + texture_path)
		return null
	
	var ts := TileSet.new()
	ts.tile_size = TILE_SIZE
	
	# Add terrain set
	ts.add_terrain_set()
	ts.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	
	# Add terrain (foreground)
	ts.add_terrain(0)
	ts.set_terrain_name(0, 0, terrain_name)
	ts.set_terrain_color(0, 0, Color.WHITE)
	
	# Create atlas source
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = TILE_SIZE
	
	# Create tile at (0,0) with terrain
	source.create_tile(Vector2i(0, 0))
	var data := source.get_tile_data(Vector2i(0, 0), 0)
	data.terrain_set = 0
	data.terrain = 0
	
	# Add source to tileset
	ts.add_source(source, 0)
	
	return ts