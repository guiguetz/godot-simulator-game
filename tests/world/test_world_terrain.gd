#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestWorldTerrain
extends SimTestSuite

## Cobertura de `scripts/world.gd`: terreno, andabilidade, pesca e arável.

func test_terrain_at_agua() -> void:
	var w: Node2D = boot_game()
	# (10,7) é água no mapa demo (lago circular).
	assert_that(int(w.call("terrain_at", Vector2i(10, 7)))).is_not_equal(0)


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
	w.call("set_terrain", cell, 0)  # NONE -> grama
	assert_that(int(w.call("terrain_at", cell))).is_equal(0)


func test_tilemapdual_tem_regra_para_cada_combinacao_de_cantos() -> void:
	var tileset := load("res://assets/tiles/display_water.tres") as TileSet
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