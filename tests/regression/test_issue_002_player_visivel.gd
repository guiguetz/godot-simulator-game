#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestRegression002PlayerVisivel
extends SimTestSuite

## Regressão #2: player não aparecia (coberto pelo chão/dual grid).
## A correção ajustou z_index para Entities > terrenos.

func test_player_existe_e_visivel() -> void:
	var w: Node2D = boot_game()
	var player: Node2D = get_tree().get_first_node_in_group("player")
	assert_that(player).is_not_null()
	assert_that(player.visible).is_true()


func test_entities_acima_do_terreno() -> void:
	var w: Node2D = boot_game()
	var entities: Node2D = w.get_node("Entities")
	# Entidades (z=10) ficam acima das camadas de terreno (z=1..3).
	assert_that(entities.z_index).is_greater(3)