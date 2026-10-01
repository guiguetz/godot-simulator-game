#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestBootGame
extends SimTestSuite

## Teste de integração: a cena `game.tscn` instancia corretamente e todos
## os nós esperados existem.

func test_game_instancia() -> void:
	var w: Node2D = boot_game()
	assert_that(w).is_not_null()


func test_grupos_world_e_player() -> void:
	var w: Node2D = boot_game()
	assert_that(get_tree().get_first_node_in_group("world")).is_not_null()
	assert_that(get_tree().get_first_node_in_group("player")).is_not_null()


func test_dualgrid_e_terrain_existem() -> void:
	var w: Node2D = boot_game()
	var dg := w.get_node("DualGrid")
	var terrain := w.get_node("DualGrid/Terrain")
	assert_that(dg).is_not_null()
	assert_that(terrain).is_not_null()


func test_entities_e_player() -> void:
	var w: Node2D = boot_game()
	var entities := w.get_node("Entities")
	var player := w.get_node("Entities/Player")
	assert_that(entities).is_not_null()
	assert_that(player).is_not_null()


func test_ui_layers_existem() -> void:
	var w: Node2D = boot_game()
	assert_that(w.get_node("HUD")).is_not_null()
	assert_that(w.get_node("Fishing")).is_not_null()
	assert_that(w.get_node("Decor")).is_not_null()
	assert_that(w.get_node("Shop")).is_not_null()
	assert_that(w.get_node("PauseMenu")).is_not_null()
	assert_that(w.get_node("DayNight")).is_not_null()
	assert_that(w.get_node("Rain")).is_not_null()


func test_camera_no_player() -> void:
	var w: Node2D = boot_game()
	var cam := w.get_node("Entities/Player/Camera2D")
	assert_that(cam).is_not_null()