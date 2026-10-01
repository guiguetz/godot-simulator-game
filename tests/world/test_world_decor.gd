#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestWorldDecor
extends SimTestSuite

## Cobertura de `scripts/world.gd`: modo decoração (colocar/remover).

func test_decor_place_valido() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	assert_that(bool(w.call("decor_place", 0, cell))).is_true()


func test_decor_place_duplicado() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("decor_place", 0, cell)
	assert_that(bool(w.call("decor_place", 0, cell))).is_false()


func test_decor_place_indice_invalido() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	assert_that(bool(w.call("decor_place", -1, cell))).is_false()
	assert_that(bool(w.call("decor_place", 99, cell))).is_false()


func test_decor_place_na_agua() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(10, 7)  # água
	assert_that(bool(w.call("decor_place", 0, cell))).is_false()


func test_decor_remove() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("decor_place", 0, cell)
	assert_that(bool(w.call("decor_remove", cell))).is_true()
	assert_that(bool(w.call("decor_remove", cell))).is_false()