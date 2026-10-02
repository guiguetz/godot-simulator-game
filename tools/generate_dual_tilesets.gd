extends SceneTree
## Gera os TileSets usados diretamente pelos TileMapDual do mundo.
## Execute com: godot --headless --path . --script tools/generate_dual_tilesets.gd

const DEFAULT_TILE_SIZE := 16
const TERRAIN_CONFIG := {
	"water": {
		"texture": "res://assets/tiles/terrain_water.png",
		"walkable": false,
		"tillable": false,
	},
	"dirt": {
		"texture": "res://assets/tiles/terrain_dirt.png",
		"tile_size": 32,
		"empty_tile": Vector2i(0, 3),
		"filled_tile": Vector2i(2, 1),
		# Masks TL=bit0, TR=bit1, BL=bit2, BR=bit3 copied from the official
		# MultipleLayers.tscn configuration for assets/tileset_sand.png.
		"peering_masks": [4, 10, 13, 12, 9, 14, 15, 7, 2, 3, 11, 5, 0, 8, 6, 1],
		"walkable": true,
		"tillable": true,
	},
	"soil": {
		"texture": "res://assets/tiles/terrain_soil.png",
		"walkable": true,
		"tillable": false,
	},
}


func _init() -> void:
	for terrain_name in TERRAIN_CONFIG:
		var config: Dictionary = TERRAIN_CONFIG[terrain_name]
		var tileset := _generate_tileset(terrain_name, config)
		if tileset == null:
			continue
		var output_path := "res://assets/tiles/terrain_%s.tres" % terrain_name
		var error := ResourceSaver.save(tileset, output_path)
		if error != OK:
			push_error("Falha ao salvar %s: %s" % [output_path, error_string(error)])
			quit(1)
			return
		print("Gerado: ", output_path)
	quit()


func _generate_tileset(terrain_name: String, config: Dictionary) -> TileSet:
	var texture := load(config["texture"]) as Texture2D
	if texture == null:
		push_error("Textura nao encontrada: %s" % config["texture"])
		return null

	var tile_size := int(config.get("tile_size", DEFAULT_TILE_SIZE))
	var tile_size_pixels := Vector2i.ONE * tile_size
	var tileset := TileSet.new()
	tileset.tile_size = tile_size_pixels
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "walkable")
	tileset.set_custom_data_layer_type(0, TYPE_BOOL)
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(1, "tillable")
	tileset.set_custom_data_layer_type(1, TYPE_BOOL)
	tileset.add_terrain_set()
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	tileset.add_terrain(0)
	tileset.set_terrain_name(0, 0, "empty")
	tileset.set_terrain_color(0, 0, Color(0.25, 0.25, 0.25, 1.0))
	tileset.add_terrain(0)
	tileset.set_terrain_name(0, 1, terrain_name)
	tileset.set_terrain_color(0, 1, Color.WHITE)

	var empty_tile: Vector2i = config.get("empty_tile", Vector2i.ZERO)
	var filled_tile: Vector2i = config.get("filled_tile", Vector2i(3, 3))
	var peering_masks: Array = config.get("peering_masks", [])
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = tile_size_pixels
	for y in range(4):
		for x in range(4):
			source.create_tile(Vector2i(x, y))
	tileset.add_source(source, 0)

	for y in range(4):
		for x in range(4):
			var atlas_coord := Vector2i(x, y)
			var data := source.get_tile_data(atlas_coord, 0)
			data.terrain_set = 0
			data.terrain = 0 if atlas_coord == empty_tile else (1 if atlas_coord == filled_tile else -1)
			var mask_index := y * 4 + x
			var mask := int(peering_masks[mask_index]) if peering_masks.size() == 16 else _canonical_mask(x, y)
			data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, mask & 1)
			data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, (mask >> 1) & 1)
			data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, (mask >> 2) & 1)
			data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, (mask >> 3) & 1)
			data.set_custom_data("walkable", config["walkable"])
			data.set_custom_data("tillable", config["tillable"])
	return tileset


func _canonical_mask(x: int, y: int) -> int:
	return (x & 1) | (((x >> 1) & 1) << 1) | ((y & 1) << 2) | (((y >> 1) & 1) << 3)
