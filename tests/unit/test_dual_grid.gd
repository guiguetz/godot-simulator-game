class_name TestDualGrid
extends SimTestSuite

## Cobertura de `scripts/dual_grid.gd`: setup, camadas, máscaras->tiles e
## operações de repintura.

const TILE_ATLAS := "res://assets/tiles/terrain_dirt.png"

func _make_grid() -> DualGrid:
	return auto_free(DualGrid.new())

func _mask(bits: Array) -> PackedByteArray:
	var m := PackedByteArray()
	m.resize(4 * 4)
	for i in range(bits.size()):
		var cell: Vector2i = bits[i]
		m[cell.y * 4 + cell.x] = 1
	return m


func test_setup_y_capas() -> void:
	var dg := _make_grid()
	dg.setup(4, 4, 16)
	assert_that(dg.grid_width).is_equal(4)
	assert_that(dg.grid_height).is_equal(4)
	assert_that(dg.tile_size).is_equal(16)


func test_add_terrain_desplaza_media_celda() -> void:
	var dg := _make_grid()
	dg.setup(4, 4, 16)
	var layer := dg.add_terrain(0, load(TILE_ATLAS))
	assert_that(layer.name).is_equal("Terrain0")
	# O dual grid fica centrado nos cantos: deslocado -tile/2.
	assert_that(layer.position).is_equal(Vector2(-8, -8))


func test_refresh_convierte_mascara_en_tiles() -> void:
	var dg := _make_grid()
	dg.setup(4, 4, 16)
	var layer := dg.add_terrain(0, load(TILE_ATLAS))
	var m := PackedByteArray()
	m.resize(4 * 4)
	m[1 * 4 + 1] = 1  # celula logica (1,1) ocupada
	dg.refresh(0, m)

	# Os 4 tiles duais ao redor do canto recebem o tile correto do atlas
	# 4x4: bits -> coluna = bit0 + bit1*2, linha = bit2 + bit3*2.
	assert_that(layer.get_cell_atlas_coords(Vector2i(1, 1))).is_equal(Vector2i(0, 2))  # BR (8)
	assert_that(layer.get_cell_atlas_coords(Vector2i(2, 1))).is_equal(Vector2i(0, 1))  # BL (4)
	assert_that(layer.get_cell_atlas_coords(Vector2i(1, 2))).is_equal(Vector2i(2, 0))  # TR (2)
	assert_that(layer.get_cell_atlas_coords(Vector2i(2, 2))).is_equal(Vector2i(1, 0))  # TL (1)


func test_bits_de_16_combinaciones() -> void:
	var dg := _make_grid()
	dg.setup(2, 2, 16)
	# As 16 combinações de bitmask 2x2 -> bits no canto central ->
	# coordenada no atlas 4x4 (col = bit0 + bit1*2, linha = bit2 + bit3*2).
	for bits in range(16):
		var m := PackedByteArray()
		m.resize(2 * 2)
		if bits & 1:
			m[0 * 2 + 0] = 1  # TL (0,0)
		if bits & 2:
			m[0 * 2 + 1] = 1  # TR (1,0)
		if bits & 4:
			m[1 * 2 + 0] = 1  # BL (0,1)
		if bits & 8:
			m[1 * 2 + 1] = 1  # BR (1,1)
		assert_that(dg._bits_of(m, 1, 1)).is_equal(bits)
		assert_that(bits % 4).is_equal(bits & 3)
		assert_that(bits >> 2).is_equal((bits & 12) >> 2)
	# E a célula vazia não pinta nada.
	var vacio := PackedByteArray()
	vacio.resize(2 * 2)
	assert_that(dg._bits_of(vacio, 1, 1)).is_equal(0)


func test_bits_fuera_de_rango() -> void:
	var dg := _make_grid()
	dg.setup(4, 4, 16)
	var m := PackedByteArray()
	m.resize(4 * 4)
	assert_that(dg._bits_of(m, -1, 0)).is_equal(0)
	assert_that(dg._bits_of(m, 0, 4)).is_equal(0)
	assert_that(dg._at(m, -1, 0)).is_false()
	assert_that(dg._at(m, 4, 3)).is_false()
	assert_that(dg._at(m, 3, 4)).is_false()


func test_refresh_all_y_clear_all() -> void:
	var dg := _make_grid()
	dg.setup(4, 4, 16)
	var l0 := dg.add_terrain(0, load(TILE_ATLAS))
	var l1 := dg.add_terrain(1, load(TILE_ATLAS))

	var m0 := PackedByteArray()
	m0.resize(4 * 4)
	m0[0 * 4 + 0] = 1
	var m1 := PackedByteArray()
	m1.resize(4 * 4)
	m1[3 * 4 + 3] = 1

	dg.refresh_all({0: m0, 1: m1})
	assert_that(l0.get_used_cells().size()).is_equal(4)
	assert_that(l1.get_used_cells().size()).is_equal(4)

	dg.clear_all()
	assert_that(l0.get_used_cells().is_empty()).is_true()
	assert_that(l1.get_used_cells().is_empty()).is_true()


func test_refresh_capa_no_registrada_avisa() -> void:
	var dg := _make_grid()
	dg.setup(4, 4, 16)
	var m := PackedByteArray()
	m.resize(4 * 4)
	dg.refresh(99, m)  # não deve estourar