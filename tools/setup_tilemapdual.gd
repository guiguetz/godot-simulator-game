@tool
extends Node
## Configura os nodes TileMapDual para cada terreno.
## Uso: rode este script no editor para criar os nodes na cena.

const TILE_SIZE := Vector2i(16, 16)

const TERRAINS := {
	"water": {
		"texture": "res://assets/tiles/terrain_water.png",
		"display_texture": "res://assets/tiles/display_water.tres",
		"z_index": 1,
	},
	"dirt": {
		"texture": "res://assets/tiles/terrain_dirt.png",
		"display_texture": "res://assets/tiles/display_dirt.tres",
		"z_index": 2,
	},
	"soil": {
		"texture": "res://assets/tiles/terrain_soil.png",
		"display_texture": "res://assets/tiles/display_soil.tres",
		"z_index": 3,
	},
}

static func create_tilemap_dual(terrain_name: String, config: Dictionary) -> TileMapDual:
	var tilemap := TileMapDual.new()
	tilemap.name = "Terrain" + terrain_name.capitalize()

	# Load display texture
	var display_tex := load(config.display_texture) as Texture2D
	if display_tex == null:
		push_error("Failed to load display texture: " + config.display_texture)
		return null

	# Create TileSet for display
	var ts := TileSet.new()
	ts.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = display_tex
	source.texture_region_size = TILE_SIZE
	source.create_tile(Vector2i(0, 0))
	ts.add_source(source, 0)

	tilemap.tile_set = ts
	tilemap.z_index = config.z_index

	return tilemap


static func setup_all(parent: Node) -> void:
	for terrain_name in TERRAINS:
		var config: Dictionary = TERRAINS[terrain_name]
		var tilemap := create_tilemap_dual(terrain_name, config)
		if tilemap != null:
			parent.add_child(tilemap)
			tilemap.owner = parent.owner if parent.owner != null else parent
			print("Created TileMapDual: " + tilemap.name)