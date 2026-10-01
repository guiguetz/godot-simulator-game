@tool
extends SceneTree

## Gera res://assets/tiles/terrain_paint.tres:
## um TileSet logico com 1 fonte por terreno (0=agua, 1=terra, 2=canteiro),
## cada fonte com o tile cheio (3,3) da folha dual grid, e a camada de
## custom data "walkable" (bool) para marcar o que o player pode pisar.

const OUT := "res://assets/tiles/terrain_paint.tres"

const SOURCES := [
	{"id": 0, "tex": "res://assets/tiles/terrain_water.png", "walkable": false},
	{"id": 1, "tex": "res://assets/tiles/terrain_dirt.png", "walkable": true},
	{"id": 2, "tex": "res://assets/tiles/terrain_soil.png", "walkable": true},
]


func _init() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "walkable")
	ts.set_custom_data_layer_type(0, TYPE_BOOL)

	for entry in SOURCES:
		_add_source(ts, entry)

	var err := ResourceSaver.save(ts, OUT)
	print("terrain_paint.tres saved: ", err)
	quit()


func _add_source(ts: TileSet, entry: Dictionary) -> void:
	var source := TileSetAtlasSource.new()
	source.texture = load(entry["tex"])
	source.texture_region_size = Vector2i(16, 16)
	# Apenas o tile cheio (bits = 15 -> coluna 3, linha 3) e usado na pintura.
	source.create_tile(Vector2i(3, 3))
	ts.add_source(source, entry["id"])
	var data := source.get_tile_data(Vector2i(3, 3), 0)
	data.set_custom_data("walkable", entry["walkable"])
