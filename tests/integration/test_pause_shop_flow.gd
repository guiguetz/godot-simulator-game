#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestPauseShopFlow
extends SimTestSuite

## Teste de integração: pausa → loja compra semente → volta.

func test_pausa_abre_loja_e_compra() -> void:
	var w: Node2D = boot_game()
	var shop: Variant = w.get_node("Shop")
	var pause_menu: Variant = w.get_node("PauseMenu")
	# Abre menu de pausa.
	pause_menu.call("open_menu")
	assert_that(pause_menu.visible).is_true()
	assert_that(get_tree().paused).is_true()
	# Abre loja.
	pause_menu.call("_open_shop")
	assert_that(pause_menu.visible).is_false()  # pause esconde
	assert_that(shop.visible).is_true()
	# Compra semente.
	var antes_moedas := Inventory.coins
	var antes_sementes := Inventory.seed_count(Enums.Seed.TOMATO)
	shop.call("_buy_seed", Enums.Seed.TOMATO, 4)
	assert_that(Inventory.coins).is_equal(antes_moedas - 4)
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(antes_sementes + 1)
	# Volta.
	shop.call("_on_back")
	assert_that(shop.visible).is_false()
	# Retoma jogo.
	pause_menu.call("close_menu")
	assert_that(get_tree().paused).is_false()