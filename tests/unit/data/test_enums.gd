class_name TestEnums
extends SimTestSuite

## Cobertura de `scripts/data/enums.gd`: valores e ordem usados pelo save,
## a hotbar e os itens. Se esses números mudam, quebra a compatibilidade
## das partidas salvas.

func test_estilos_svgs() -> void:
	assert_that(int(Enums.Style.BASIC)).is_equal(0)
	assert_that(int(Enums.Style.STRAW)).is_equal(5)
	assert_that(int(Enums.Style.size())).is_equal(6)


func test_herramientas() -> void:
	assert_that(int(Enums.Tool.HOE)).is_equal(0)
	assert_that(int(Enums.Tool.WATER)).is_equal(1)
	assert_that(int(Enums.Tool.AXE)).is_equal(2)
	assert_that(int(Enums.Tool.SWORD)).is_equal(3)
	assert_that(int(Enums.Tool.FISH)).is_equal(4)
	assert_that(int(Enums.Tool.SEED)).is_equal(5)
	assert_that(int(Enums.Tool.size())).is_equal(6)


func test_semillas() -> void:
	assert_that(Enums.Seed.TOMATO).is_equal(0)
	assert_that(Enums.Seed.CORN).is_equal(1)
	assert_that(Enums.Seed.PUMPKIN).is_equal(2)
	assert_that(Enums.Seed.WHEAT).is_equal(3)
	assert_that(int(Enums.Seed.size())).is_equal(4)


func test_items_orden_estable() -> void:
	# Ordem documentada: os dois primeiros e os peixes não mudam.
	assert_that(Enums.Item.WOOD).is_equal(0)
	assert_that(Enums.Item.APPLE).is_equal(1)
	assert_that(Enums.Item.FISH).is_equal(6)
	assert_that(Enums.Item.GRAYFISH).is_equal(7)
	assert_that(Enums.Item.SILVERFISH).is_equal(8)
	assert_that(int(Enums.Item.size())).is_equal(9)


func test_maquinas() -> void:
	assert_that(Enums.Machine.SPRINKLER).is_equal(0)
	assert_that(Enums.Machine.FISHER).is_equal(1)
	assert_that(Enums.Machine.SCARECROW).is_equal(2)
	assert_that(int(Enums.Machine.size())).is_equal(3)


func test_clima() -> void:
	assert_that(Enums.Weather.CLEAR).is_equal(0)
	assert_that(Enums.Weather.RAIN).is_equal(1)
	assert_that(int(Enums.Weather.size())).is_equal(2)