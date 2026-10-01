class_name TestFishing
extends SimTestSuite

## Cobertura de `scripts/fishing.gd`: início, progresso, vitória/derrota e
## cancelamento do minigame de pesca.

func _make_fishing() -> Variant:
	var f: Node = auto_free(load("res://scripts/fishing.gd").new())
	add_child(f)
	await_idle_frame()
	return f


func test_start_ativa() -> void:
	var f: Variant = _make_fishing()
	f.call("start", Enums.Item.FISH)
	assert_that(f.active).is_true()
	assert_that(f.visible).is_true()
	assert_that(f.target).is_equal(Enums.Item.FISH)


func test_finish_true_concede_item() -> void:
	var f: Variant = _make_fishing()
	var antes := Inventory.count(Enums.Item.FISH)
	f.call("start", Enums.Item.FISH)
	f.call("_finish", true)
	assert_that(Inventory.count(Enums.Item.FISH)).is_equal(antes + 1)
	assert_that(f.active).is_false()
	assert_that(f.visible).is_false()


func test_finish_false_nao_concede() -> void:
	var f: Variant = _make_fishing()
	var antes := Inventory.count(Enums.Item.FISH)
	f.call("start", Enums.Item.FISH)
	f.call("_finish", false)
	assert_that(Inventory.count(Enums.Item.FISH)).is_equal(antes)
	assert_that(f.active).is_false()


func test_cancel_nao_concede() -> void:
	var f: Variant = _make_fishing()
	var antes := Inventory.count(Enums.Item.FISH)
	f.call("start", Enums.Item.FISH)
	f.call("cancel")
	assert_that(Inventory.count(Enums.Item.FISH)).is_equal(antes)
	assert_that(f.active).is_false()


func test_finished_signal() -> void:
	var f: Variant = _make_fishing()
	var recebido := [false]
	f.finished.connect(func(win: bool, item: int) -> void: recebido[0] = true)
	f.call("start", Enums.Item.FISH)
	f.call("_finish", true)
	assert_that(recebido[0]).is_true()