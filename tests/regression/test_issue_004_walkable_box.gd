#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestRegression004WalkableBox
extends SimTestSuite

## Regressão #4: caixa de andabilidade maior que o tile travava o player em
## cantos. Correção: MAX_FEET_HALF <= 8 (meio tile).

func test_max_feet_half_limite() -> void:
	# A constante não pode ultrapassar meio tile (16/2 = 8).
	assert_that(Player.MAX_FEET_HALF).is_less_equal(8.0)


func test_area_walkable_agua_bloqueia() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	# Centro de célula de água.
	var pos_agua := Vector2(10 * 16 + 8, 7 * 16 + 8)
	assert_that(bool(player.call("_area_walkable", pos_agua))).is_false()


func test_area_walkable_grama_permite() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	var pos_grama := Vector2(20 * 16 + 8, 20 * 16 + 8)
	assert_that(bool(player.call("_area_walkable", pos_grama))).is_true()