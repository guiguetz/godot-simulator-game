@tool
extends Node
## Gera TileSets de display tiles para TileMapDual a partir das texturas de terreno.
## Uso: rode este script no editor ou via CLI para criar os .tres em assets/tiles/.

const TILE_SIZE := Vector2i(16, 16)

const TERRAINS := {
	"water": "res://assets/tiles/terrain_water.png",
	"dirt": "res://assets/tiles/terrain_dirt.png",
	"soil": "res://assets/tiles/terrain_soil.png",
}

static func generate_tileset(texture_path: String) -> TileSet:
	var tex := load(texture_path) as Texture2D
	if tex == null:
		push_error("Texture not found: " + texture_path)
		return null

	var ts := TileSet.new()
	ts.tile_size = TILE_SIZE

	# Create atlas source
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = TILE_SIZE

	# Create a single tile at (0,0)
	source.create_tile(Vector2i(0, 0))

	# Add source to tileset
	ts.add_source(source, 0)

	return ts


static func generate_all(output_dir: String = "res://assets/tiles/") -> void:
	for terrain_name in TERRAINS:
		var texture_path: String = TERRAINS[terrain_name]
		var ts := generate_tileset(texture_path)
		if ts == null:
			continue

		var output_path: String = output_dir + "display_" + terrain_name + ".tres"
		var err := ResourceSaver.save(ts, output_path)
		if err == OK:
			print("Generated: " + output_path)
		else:
			push_error("Failed to save: " + output_path + " (error: " + str(err) + ")")


func _ready() -> void:
	generate_all()
	print("All display tilesets generated!")
	get_tree().quit()