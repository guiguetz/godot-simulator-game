class_name TestInventory
extends SimTestSuite

## Cobertura de `scripts/inventory.gd`: itens, moedas, sementes, hotbar e
## serialização.

func test_add_remove_count() -> void:
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(0)
	Inventory.add_item(Enums.Item.WOOD, 3)
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(3)
	assert_that(Inventory.has_item(Enums.Item.WOOD, 3)).is_true()
	assert_that(Inventory.remove_item(Enums.Item.WOOD, 2)).is_true()
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(1)
	# No se puede quitar mas de lo que hay.
	assert_that(Inventory.remove_item(Enums.Item.WOOD, 5)).is_false()
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(1)
	# Sobreposição de valores de enum: itens e sementes vão por separado.
	Inventory.add_item(Enums.Item.WOOD, 1)
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(0)


func test_signal_changed() -> void:
	var cuenta := [0]
	Inventory.changed.connect(func() -> void: cuenta[0] += 1)
	Inventory.add_item(Enums.Item.APPLE, 1)
	Inventory.remove_item(Enums.Item.APPLE, 1)
	Inventory.add_coins(5)
	Inventory.add_seed(Enums.Seed.CORN, 2)
	Inventory.set_slot(3)
	Inventory.seed_next()
	assert_that(cuenta[0]).is_equal(6)


func test_monedas() -> void:
	assert_that(Inventory.coins).is_equal(100)
	Inventory.add_coins(10)
	assert_that(Inventory.coins).is_equal(110)
	assert_that(Inventory.spend_coins(120)).is_false()
	assert_that(Inventory.coins).is_equal(110)
	assert_that(Inventory.spend_coins(20)).is_true()
	assert_that(Inventory.coins).is_equal(90)


func test_semillas() -> void:
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(0)
	Inventory.add_seed(Enums.Seed.TOMATO, 4)
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(4)
	assert_that(Inventory.remove_seed(Enums.Seed.CORN, 1)).is_false()
	assert_that(Inventory.remove_seed(Enums.Seed.TOMATO, 2)).is_true()
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(2)


func test_seed_next_circular() -> void:
	Inventory.selected_seed = Enums.Seed.TOMATO
	Inventory.seed_next()
	assert_that(Inventory.selected_seed).is_equal(Enums.Seed.CORN)
	Inventory.seed_next()
	assert_that(Inventory.selected_seed).is_equal(Enums.Seed.PUMPKIN)
	Inventory.seed_next()
	assert_that(Inventory.selected_seed).is_equal(Enums.Seed.WHEAT)
	Inventory.seed_next()
	assert_that(Inventory.selected_seed).is_equal(Enums.Seed.TOMATO)


func test_set_slot_clamp() -> void:
	Inventory.selected_slot = 0
	Inventory.set_slot(-5)
	assert_that(Inventory.selected_slot).is_equal(0)
	Inventory.set_slot(99)
	assert_that(Inventory.selected_slot).is_equal(GameData.hotbar.size() - 1)
	var entry := Inventory.current_entry()
	assert_that(entry["kind"]).is_equal("machine")
	assert_that(entry["id"]).is_equal(Enums.Machine.FISHER)


func test_current_entry_sigue_seleccion() -> void:
	Inventory.selected_slot = 0
	assert_that(Inventory.current_entry()["id"]).is_equal(Enums.Tool.HOE)
	Inventory.selected_slot = 5
	assert_that(Inventory.current_entry()["id"]).is_equal(Enums.Tool.SEED)


func test_serializacion_roundtrip() -> void:
	Inventory.add_item(Enums.Item.WOOD, 7)
	Inventory.add_item(Enums.Item.FISH, 2)
	Inventory.add_seed(Enums.Seed.WHEAT, 11)
	Inventory.coins = 250
	Inventory.selected_slot = 4
	Inventory.selected_seed = Enums.Seed.CORN
	var data := Inventory.to_dict()
	Inventory.from_dict(data)
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(7)
	assert_that(Inventory.count(Enums.Item.FISH)).is_equal(2)
	assert_that(Inventory.seed_count(Enums.Seed.WHEAT)).is_equal(11)
	assert_that(Inventory.coins).is_equal(250)
	assert_that(Inventory.selected_slot).is_equal(4)
	assert_that(Inventory.selected_seed).is_equal(Enums.Seed.CORN)