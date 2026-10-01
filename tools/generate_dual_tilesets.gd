extends SceneTree
## Gera TileSets de display tiles para TileMapDual com 15 tiles configurados.
## Execute com: godot --headless --path . --script tools/generate_dual_tilesets.gd

const TILE_SIZE := Vector2i(16, 16)

# Atlas dual-grid 4x4: cada tile representa uma combinação dos quadrantes
# TL/TR (colunas) e BL/BR (linhas) da textura.
const TILE_LAYOUT := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
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
	
	# TileMapDual representa células vazias como terreno 0 e células ocupadas
	# como terreno 1. Os bits do atlas também precisam ser sempre 0 ou 1:
	# peering bits -1 fazem o addon descartar a regra daquele tile.
	ts.add_terrain_set()
	ts.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	ts.add_terrain(0)
	ts.set_terrain_name(0, 0, "empty")
	ts.set_terrain_color(0, 0, Color(0.25, 0.25, 0.25, 1.0))
	ts.add_terrain(0)
	ts.set_terrain_name(0, 1, terrain_name)
	ts.set_terrain_color(0, 1, Color.WHITE)
	
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
		
		# Os tiles vazios e cheio também são os sprites-base dos terrenos 0/1;
		# os 14 tiles restantes são apenas regras de transição.
		if tile_pos == Vector2i.ZERO:
			data.terrain = 0
		elif tile_pos == Vector2i(3, 3):
			data.terrain = 1
		else:
			data.terrain = -1

		# A textura está organizada com TL/TR nas colunas e BL/BR nas linhas.
		# TileMapDual consulta os bits nesta ordem: BR, BL, TL, TR.
		var bottom_right := tile_pos.y >> 1
		var bottom_left := tile_pos.y & 1
		var top_left := tile_pos.x & 1
		var top_right := tile_pos.x >> 1
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, bottom_right)
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, bottom_left)
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, top_left)
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, top_right)
	
	# Add source to tileset
	ts.add_source(source, 0)
	
	return ts