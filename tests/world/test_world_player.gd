#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestWorldPlayer
extends SimTestSuite

## Cobertura de `scripts/world.gd` + `scripts/player.gd`: player, facing,
## andabilidade e skins.

func test_player_existe_no_grupo() -> void:
	var w: Node2D = boot_game()
	var player := get_tree().get_first_node_in_group("player")
	assert_that(player).is_not_null()


func test_player_posicao_inicial() -> void:
	var w: Node2D = boot_game()
	var player: Node2D = get_tree().get_first_node_in_group("player")
	# world._setup_player posiciona em (20*16+8, 17*16+8) = (328, 280).
	assert_that(player.global_position.x).is_equal_approx(328.0, 1.0)
	assert_that(player.global_position.y).is_equal_approx(280.0, 1.0)


func test_facing_vector_todas_direcoes() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	player.call("_facing_vector")  # só garante que não quebra


func test_direction_name() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	assert_that(String(player.call("_direction_name", Vector2(1, 0)))).is_equal("right")
	assert_that(String(player.call("_direction_name", Vector2(-1, 0)))).is_equal("left")
	assert_that(String(player.call("_direction_name", Vector2(0, 1)))).is_equal("down")
	assert_that(String(player.call("_direction_name", Vector2(0, -1)))).is_equal("up")


func test_tool_anim() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	assert_that(String(player.call("_tool_anim", Enums.Tool.HOE))).is_equal("hoe")
	assert_that(String(player.call("_tool_anim", Enums.Tool.WATER))).is_equal("water")
	assert_that(String(player.call("_tool_anim", Enums.Tool.AXE))).is_equal("axe")
	assert_that(String(player.call("_tool_anim", Enums.Tool.SWORD))).is_equal("sword")
	assert_that(String(player.call("_tool_anim", Enums.Tool.FISH))).is_equal("fish")
	assert_that(String(player.call("_tool_anim", Enums.Tool.SEED))).is_equal("seed")


func test_area_walkable_na_grama() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	var pos_grama := Vector2(20 * 16 + 8, 20 * 16 + 8)
	assert_that(bool(player.call("_area_walkable", pos_grama))).is_true()


func test_area_walkable_na_agua() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	var pos_agua := Vector2(10 * 16 + 8, 7 * 16 + 8)
	assert_that(bool(player.call("_area_walkable", pos_agua))).is_false()


func test_max_feet_half_limite() -> void:
	# Regressão #4: a caixa de andabilidade não deve ultrapassar meio tile.
	assert_that(Player.MAX_FEET_HALF).is_less_equal(8.0)


func test_apply_skin() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	player.call("apply_skin", 2)
	assert_that(GameSettings.skin).is_equal(2)
	# Restaura.
	player.call("apply_skin", 0)
	assert_that(GameSettings.skin).is_equal(0)