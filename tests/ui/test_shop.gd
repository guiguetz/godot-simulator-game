class_name TestShop
extends SimTestSuite

## Cobertura de `scripts/shop.gd`: compra de sementes, venda de itens e
## botão voltar.

func _make_shop() -> Variant:
	var s: Node = auto_free(load("res://scripts/shop.gd").new())
	add_child(s)
	await_idle_frame()
	return s


func test_buy_seed_debita_moeda() -> void:
	var s: Variant = _make_shop()
	var antes_moedas := Inventory.coins
	var antes_sementes := Inventory.seed_count(Enums.Seed.TOMATO)
	s.call("_buy_seed", Enums.Seed.TOMATO, 4)
	assert_that(Inventory.coins).is_equal(antes_moedas - 4)
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(antes_sementes + 1)


func test_buy_seed_sem_moeda() -> void:
	var s: Variant = _make_shop()
	Inventory.coins = 3
	var antes_sementes := Inventory.seed_count(Enums.Seed.TOMATO)
	s.call("_buy_seed", Enums.Seed.TOMATO, 4)
	# spend_coins falha, nada muda.
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(antes_sementes)


func test_sell_total() -> void:
	var s: Variant = _make_shop()
	Inventory.add_item(Enums.Item.WOOD, 10)
	var total: int = s.call("_sell_total")
	# WOOD value=2, 10*2=20.
	assert_that(total).is_equal(20)


func test_sell_all() -> void:
	var s: Variant = _make_shop()
	Inventory.add_item(Enums.Item.WOOD, 10)
	Inventory.coins = 100
	s.call("_sell_all")
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(0)
	assert_that(Inventory.coins).is_equal(120)


func test_on_back_chama_callback() -> void:
	var s: Variant = _make_shop()
	var chamado := [false]
	s.setup(func() -> void: chamado[0] = true)
	s.call("_on_back")
	assert_that(chamado[0]).is_true()