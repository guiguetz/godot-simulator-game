extends SceneTree
## Gera TileSets de display tiles para TileMapDual com 15 tiles configurados.
## Execute com: godot --headless --path . --script tools/generate_dual_tilesets.gd

const TILE_SIZE := Vector2i(16, 16)

# Standard dual grid tileset layout (4x4 grid = 16 positions, 15 used)
# Reference: https://github.com/user-images.githubusercontent.com/47016402/87044518-ee28fa80-c1f6-11ea-86f5-de53e86fcbb6.png
const TILE_LAYOUT := [
	# Row 0 (bottom)
	Vector2i(0, 0),  # empty (background)
	Vector2i(1, 0),  # top-right corner
	Vector2i(2, 0),  # top-left corner
	Vector2i(3, 0),  # top edge
	# Row 1
	Vector2i(0, 1),  # bottom-right corner
	Vector2i(1, 1),  # all corners
	Vector2i(2, 1),  # top-left + top-right corners
	Vector2i(3, 1),  # top edge + corners
	# Row 2
	Vector2i(0, 2),  # bottom-left corner
	Vector2i(1, 2),  # bottom-left + bottom-right corners
	Vector2i(2, 2),  # all corners except bottom-left
	Vector2i(3, 2),  # top + bottom edges
	# Row 3
	Vector2i(0, 3),  # bottom edge
	Vector2i(1, 3),  # bottom edge + corners
	Vector2i(2, 3),  # full tile (foreground)
	Vector2i(3, 3),  # empty (unused)
]

# Peering bits for each tile position
# Format: [bottom_right, bottom_left, top_left, top_right]
# 0 = background, 1 = foreground
const PEERING_BITS := [
	[0, 0, 0, 0],  # (0,0) empty
	[0, 0, 0, 1],  # (1,0) top-right corner
	[0, 0, 1, 0],  # (2,0) top-left corner
	[0, 0, 1, 1],  # (3,0) top edge
	[0, 1, 0, 0],  # (0,1) bottom-right corner
	[0, 1, 0, 1],  # (1,1) all corners
	[0, 1, 1, 0],  # (2,1) top-left + top-right
	[0, 1, 1, 1],  # (3,1) top edge + corners
	[1, 0, 0, 0],  # (0,2) bottom-left corner
	[1, 0, 0, 1],  # (1,2) bottom-left + bottom-right
	[1, 0, 1, 0],  # (2,2) all except bottom-left
	[1, 0, 1, 1],  # (3,2) top + bottom edges
	[1, 1, 0, 0],  # (0,3) bottom edge
	[1, 1, 0, 1],  # (1,3) bottom edge + corners
	[1, 1, 1, 0],  # (2,3) full tile
	[1, 1, 1, 1],  # (3,3) unused (same as full)
]

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
	
	# Create tiles with peering bits
	for i in range(TILE_LAYOUT.size()):
		var tile_pos: Vector2i = TILE_LAYOUT[i]
		source.create_tile(tile_pos)
		var data := source.get_tile_data(tile_pos, 0)
		data.terrain_set = 0
		
		# Set terrain (0 for background, 0 for foreground - we use peering bits)
		if i == 14:  # Full tile (foreground)
			data.terrain = 0
		else:
			data.terrain = -1  # No terrain (will be determined by peering bits)
		
		# Set peering bits
		var bits: Array = PEERING_BITS[i]
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, bits[0])
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, bits[1])
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, bits[2])
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, bits[3])
	
	# Add source to tileset
	ts.add_source(source, 0)
	
	return ts