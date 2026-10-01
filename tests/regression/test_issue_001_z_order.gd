#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestRegression001ZOrder
extends SimTestSuite

## Regressão #1: chão (Ground) z_index = -10 < entidades z_index = 10.
## Antes da correção, o chão era desenhado por cima de tudo.

func test_ground_abaixo_de_entidades() -> void:
	var w: Node2D = boot_game()
	var entities: Node2D = w.get_node("Entities")
	assert_that(entities.z_index).is_equal(10)
	# Ground é uma TileMapLayer filha de Game.
	var ground: TileMapLayer = w.get_node("Ground")
	assert_that(ground).is_not_null()
	assert_that(ground.z_index).is_equal(-10)
	assert_that(ground.z_index).is_less(entities.z_index)