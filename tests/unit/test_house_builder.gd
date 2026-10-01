class_name TestHouseBuilder
extends SimTestSuite

## Cobertura de `scripts/house_builder.gd`: a casa 3x3 com paredes com
## colisão e porta (1,1) sem colisão.

func test_construye_paredes_y_techo() -> void:
	var parent: Node = auto_free(Node2D.new())
	var walls := HouseBuilder.build(parent, Vector2i(2, 3))
	assert_that(walls.name).is_equal("HouseWalls")
	assert_that(walls.z_index).is_equal(5)
	var roof: Node = parent.get_node("HouseRoof")
	assert_that(roof).is_not_null()
	assert_that(roof.z_index).is_equal(20)


func test_bloque_3x3_de_paredes() -> void:
	var parent: Node = auto_free(Node2D.new())
	var walls := HouseBuilder.build(parent, Vector2i(2, 3))
	for y in range(3):
		for x in range(3):
			# Cada parede usa seu tile do atlas 3x3.
			assert_that(walls.get_cell_atlas_coords(Vector2i(2 + x, 3 + y))).is_equal(Vector2i(x, y))


func test_puerta_sin_colision_y_paredes_con_colision() -> void:
	var parent: Node = auto_free(Node2D.new())
	var walls := HouseBuilder.build(parent, Vector2i(2, 3))
	var source: TileSetAtlasSource = walls.tile_set.get_source(0)

	var esquina: TileData = source.get_tile_data(HouseBuilder.WALL_TILES[0], 0)
	assert_that(esquina.get_collision_polygons_count(0)).is_greater(0)

	var puerta: TileData = source.get_tile_data(HouseBuilder.DOOR_TILE, 0)
	assert_that(puerta.get_collision_polygons_count(0)).is_equal(0)