class_name TestPauseMenu
extends SimTestSuite

## Cobertura de `scripts/pause_menu.gd`: abrir/fechar menu, painéis e
## operações de salvar/carregar.

var _pause_menu: CanvasLayer
var _shop: CanvasLayer


func _setup_scene() -> void:
	var pai: Node = auto_free(Node2D.new())
	add_child(pai)
	_shop = load("res://scripts/shop.gd").new()
	_shop.name = "Shop"
	pai.add_child(_shop)
	_pause_menu = load("res://scripts/pause_menu.gd").new()
	_pause_menu.name = "PauseMenu"
	pai.add_child(_pause_menu)
	await_idle_frame()


func test_open_close_pausa_arvore() -> void:
	_setup_scene()
	_pause_menu.call("open_menu")
	assert_that(_pause_menu.visible).is_true()
	assert_that(get_tree().paused).is_true()
	_pause_menu.call("close_menu")
	assert_that(_pause_menu.visible).is_false()
	assert_that(get_tree().paused).is_false()


func test_save_game() -> void:
	_setup_scene()
	SimTestSuite.reset_savegame()
	_pause_menu.call("_save_game")
	assert_that(SaveGame.has_save()).is_true()


func test_load_game() -> void:
	_setup_scene()
	SimTestSuite.reset_savegame()
	_pause_menu.call("_save_game")
	Inventory.coins = 999
	_pause_menu.call("_load_game")
	# load_game restaura inventário do save (coins=100 padrão).
	assert_that(Inventory.coins).is_equal(100)