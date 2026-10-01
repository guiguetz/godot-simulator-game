#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestRegression003MovimentoHorizontal
extends SimTestSuite

## Regressão #3: movimento parecia só vertical.
## O movimento horizontal estava correto; a percepção era visual (player
## invisível + spawn em trilha horizontal).

func test_direcoes_horizontais_funcionam() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	# _direction_name cobre as 4 direções.
	assert_that(String(player.call("_direction_name", Vector2(1, 0)))).is_equal("right")
	assert_that(String(player.call("_direction_name", Vector2(-1, 0)))).is_equal("left")


func test_facing_cell_move_para_lados() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	# Posiciona em grama andável.
	player.global_position = Vector2(20 * 16 + 8, 20 * 16 + 8)
	# facing_cell depende de _facing, que é atualizado por _update_animation.
	# Forçamos facing para testar a lógica.
	player._facing = "right"
	var cell: Vector2i = player.call("facing_cell")
	assert_that(cell.x).is_greater(20)  # uma célula à direita