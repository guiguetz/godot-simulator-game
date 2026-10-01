class_name TestHud
extends SimTestSuite

## Cobertura de `scripts/hud.gd`: hotbar, moedas, sementes, itens e relógio.

func _make_hud() -> Variant:
	var h: Node = auto_free(load("res://scripts/hud.gd").new())
	add_child(h)
	await_idle_frame()
	return h


func test_9_slots_na_hotbar() -> void:
	var h: Variant = _make_hud()
	assert_that(h._slot_panels.size()).is_equal(9)
	assert_that(h._slot_icons.size()).is_equal(9)


func test_refresh_moedas() -> void:
	var h: Variant = _make_hud()
	Inventory.coins = 42
	h.call("_refresh")
	assert_that(String(h._coins_label.text)).contains("42")


func test_refresh_semente() -> void:
	var h: Variant = _make_hud()
	Inventory.selected_seed = Enums.Seed.CORN
	Inventory.add_seed(Enums.Seed.CORN, 7)
	h.call("_refresh")
	assert_that(String(h._seed_label.text)).contains("Milho")
	assert_that(String(h._seed_label.text)).contains("x7")


func test_items_summary() -> void:
	var h: Variant = _make_hud()
	Inventory.add_item(Enums.Item.WOOD, 5)
	Inventory.add_item(Enums.Item.APPLE, 2)
	var texto: String = h.call("_items_summary")
	assert_that(texto).contains("Madeira")
	assert_that(texto).contains("Maca")


func test_items_summary_vazio() -> void:
	var h: Variant = _make_hud()
	var texto: String = h.call("_items_summary")
	assert_that(texto).contains("—")