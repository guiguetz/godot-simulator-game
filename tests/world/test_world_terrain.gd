#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestWorldTerrain
extends SimTestSuite

## Cobertura de `scripts/world.gd`: terreno, andabilidade, pesca e arável.

func test_terrain_at_agua() -> void:
	var w: Node2D = boot_game()
	# (10,7) é água no mapa demo (lago circular).
	assert_that(int(w.call("terrain_at", Vector2i(10, 7)))).is_equal(1)


func test_terrain_at_grama() -> void:
	var w: Node2D = boot_game()
	# (20,20) é grama no mapa demo.
	assert_that(int(w.call("terrain_at", Vector2i(20, 20)))).is_equal(0)


func test_terrain_fora_do_mapa() -> void:
	var w: Node2D = boot_game()
	assert_that(int(w.call("terrain_at", Vector2i(-1, 0)))).is_equal(-1)
	assert_that(int(w.call("terrain_at", Vector2i(99, 99)))).is_equal(-1)


func test_set_terrain_roundtrip() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	assert_that(int(w.call("terrain_at", cell))).is_equal(0)  # grama
	w.call("set_terrain", cell, 2)  # DIRT
	assert_that(int(w.call("terrain_at", cell))).is_equal(2)
	assert_that(w.get_node("TerrainDirt").get_cell_source_id(cell)).is_not_equal(-1)
	assert_that(w.get_node("TerrainWater").get_cell_source_id(cell)).is_equal(-1)
	w.call("set_terrain", cell, 1)  # trocar de camada sem sobreposição
	assert_that(int(w.call("terrain_at", cell))).is_equal(1)
	assert_that(w.get_node("TerrainDirt").get_cell_source_id(cell)).is_equal(-1)
	w.call("set_terrain", cell, 0)  # NONE -> grama
	assert_that(int(w.call("terrain_at", cell))).is_equal(0)
	assert_that(w.get_node("TerrainWater").get_cell_source_id(cell)).is_equal(-1)


func test_asset_demo_de_terra_usa_escala_compativel_com_grade16() -> void:
	var w: Node2D = boot_game()
	var dirt := w.get_node("TerrainDirt") as TileMapDual
	assert_that(dirt.tile_set.tile_size).is_equal(Vector2i(32, 32))
	assert_that(dirt.scale).is_equal(Vector2(0.5, 0.5))
	var atlas := dirt.tile_set.get_source(0) as TileSetAtlasSource
	assert_that(atlas.texture.resource_path).is_equal("res://assets/tiles/terrain_dirt.png")


func test_camadas_sobrepostas_sao_normalizadas_com_prioridade() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	(w.get_node("TerrainWater") as TileMapDual).draw_cell(cell, 1)
	(w.get_node("TerrainDirt") as TileMapDual).draw_cell(cell, 1)
	w.call("_normalize_terrain_layers")
	assert_that(int(w.call("terrain_at", cell))).is_equal(1)
	assert_that(w.get_node("TerrainWater").get_cell_source_id(cell)).is_not_equal(-1)
	assert_that(w.get_node("TerrainDirt").get_cell_source_id(cell)).is_equal(-1)


func test_custom_data_do_tileset_controla_regras_do_terreno() -> void:
	var w: Node2D = boot_game()
	var water := Vector2i(10, 7)
	var dirt := Vector2i(20, 17)
	var soil := Vector2i(5, 23)
	assert_that(bool(w.call("is_walkable_cell", water))).is_false()
	assert_that(bool(w.call("is_walkable_cell", dirt))).is_true()
	assert_that(bool(w.call("is_tillable_cell", dirt))).is_true()
	assert_that(bool(w.call("is_walkable_cell", soil))).is_true()
	assert_that(bool(w.call("is_tillable_cell", soil))).is_false()


func test_terreno_na_borda_e_rejeitado_fora_do_mapa() -> void:
	var w: Node2D = boot_game()
	w.call("set_terrain", Vector2i(0, 0), 1)
	assert_that(int(w.call("terrain_at", Vector2i(0, 0)))).is_equal(1)
	w.call("set_terrain", Vector2i(40, 0), 1)
	assert_that(int(w.call("terrain_at", Vector2i(40, 0)))).is_equal(-1)


func test_tilemapdual_tem_regra_para_cada_combinacao_de_cantos() -> void:
	var tileset := load("res://assets/tiles/terrain_water.tres") as TileSet
	var terrain_dual := TerrainDual.new(TileSetWatcher.new(tileset))
	var rules := terrain_dual.layers[0] as TerrainLayer
	var atlas_tiles := {}
	for mask in range(16):
		var neighbors: Array = [mask & 1, (mask >> 1) & 1, (mask >> 2) & 1, (mask >> 3) & 1]
		var mapping: Dictionary = rules.apply_rule(neighbors, Vector2i(mask, 0))
		assert_that(int(mapping.get("sid", -1))).is_equal(0)
		var expected := Vector2i(neighbors[0] + neighbors[1] * 2, neighbors[2] + neighbors[3] * 2)
		assert_that(mapping.get("tile", Vector2i(-1, -1))).is_equal(expected)
		atlas_tiles[mapping.get("tile", Vector2i(-1, -1))] = true
	assert_that(atlas_tiles.size()).is_equal(16)
	assert_that(terrain_dual.terrains[1].tile).is_equal(Vector2i(3, 3))


func test_atlas_demo_de_terra_corresponde_a_peering_bits_oficiais() -> void:
	var tileset := load("res://assets/tiles/terrain_dirt.tres") as TileSet
	var source := tileset.get_source(0) as TileSetAtlasSource
	var masks := [4, 10, 13, 12, 9, 14, 15, 7, 2, 3, 11, 5, 0, 8, 6, 1]
	for y in range(4):
		for x in range(4):
			var data := source.get_tile_data(Vector2i(x, y), 0)
			var mask: int = masks[y * 4 + x]
			assert_that(data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER)).is_equal(mask & 1)
			assert_that(data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER)).is_equal((mask >> 1) & 1)
			assert_that(data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER)).is_equal((mask >> 2) & 1)
			assert_that(data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER)).is_equal((mask >> 3) & 1)
	assert_that(source.get_tile_data(Vector2i(0, 3), 0).terrain).is_equal(0)
	assert_that(source.get_tile_data(Vector2i(2, 1), 0).terrain).is_equal(1)
	var terrain_dual := TerrainDual.new(TileSetWatcher.new(tileset))
	var rules := terrain_dual.layers[0] as TerrainLayer
	var coords_by_mask := {}
	for y in range(4):
		for x in range(4):
			coords_by_mask[masks[y * 4 + x]] = Vector2i(x, y)
	for mask in range(16):
		var neighbors: Array = [mask & 1, (mask >> 1) & 1, (mask >> 2) & 1, (mask >> 3) & 1]
		var result: Dictionary = rules.apply_rule(neighbors, Vector2i.ZERO)
		assert_that(result.get("tile", Vector2i(-1, -1))).is_equal(coords_by_mask[mask])
	assert_that(terrain_dual.terrains[1].tile).is_equal(Vector2i(2, 1))


func test_is_walkable_na_agua() -> void:
	var w: Node2D = boot_game()
	var pos_agua := Vector2(10 * 16 + 8, 7 * 16 + 8)
	assert_that(bool(w.call("is_walkable", pos_agua))).is_false()


func test_is_walkable_na_grama() -> void:
	var w: Node2D = boot_game()
	var pos_grama := Vector2(20 * 16 + 8, 20 * 16 + 8)
	assert_that(bool(w.call("is_walkable", pos_grama))).is_true()


func test_is_walkable_cell() -> void:
	var w: Node2D = boot_game()
	assert_that(bool(w.call("is_walkable_cell", Vector2i(10, 7)))).is_false()
	assert_that(bool(w.call("is_walkable_cell", Vector2i(20, 20)))).is_true()


func test_can_fish_na_agua() -> void:
	var w: Node2D = boot_game()
	assert_that(bool(w.call("can_fish", Vector2i(10, 7)))).is_true()


func test_can_fish_ao_lado_da_agua() -> void:
	var w: Node2D = boot_game()
	# Célula adjacente à água pode pescar.
	var vizinhos := [Vector2i(9, 7), Vector2i(11, 7), Vector2i(10, 6), Vector2i(10, 8)]
	var algum := false
	for v in vizinhos:
		if bool(w.call("can_fish", v)):
			algum = true
			break
	assert_that(algum).is_true()


func test_is_tillable_na_grama() -> void:
	var w: Node2D = boot_game()
	assert_that(bool(w.call("is_tillable_cell", Vector2i(20, 20)))).is_false()


func test_is_tillable_na_agua() -> void:
	var w: Node2D = boot_game()
	assert_that(bool(w.call("is_tillable_cell", Vector2i(10, 7)))).is_false()