#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestSaveLoadFlow
extends SimTestSuite

## Teste de integração: salvar, carregar e deletar partida;
## JSON inválido não derruba o jogo.

func test_has_save_save_delete() -> void:
	SimTestSuite.reset_savegame()
	assert_that(SaveGame.has_save()).is_false()
	SaveGame.save_game()
	assert_that(SaveGame.has_save()).is_true()
	SaveGame.delete_save()
	assert_that(SaveGame.has_save()).is_false()


func test_save_load_restaura_estado() -> void:
	var w: Node2D = boot_game()
	Inventory.add_item(Enums.Item.WOOD, 42)
	Inventory.coins = 777
	TimeManager.day = 99
	SaveGame.save_game()
	# Altera estado.
	Inventory.items.clear()
	Inventory.coins = 0
	TimeManager.day = 1
	# Carrega.
	SaveGame.load_game()
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(42)
	assert_that(Inventory.coins).is_equal(777)
	assert_that(TimeManager.day).is_equal(99)


func test_load_sem_save_retorna_false() -> void:
	SimTestSuite.reset_savegame()
	assert_that(SaveGame.load_game()).is_false()


func test_json_invalido_nao_derruba() -> void:
	SimTestSuite.reset_savegame()
	var f := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	f.store_string("isso nao e json valido {{{")
	f.close()
	assert_that(SaveGame.has_save()).is_true()
	# load_game deve retornar false sem crash.
	var ok: bool = SaveGame.load_game()
	assert_that(ok).is_false()