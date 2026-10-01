#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestFishingFlow
extends SimTestSuite

## Teste de integração: fluxo de pesca (player perto da água → minigame →
## item no inventário).

func test_fluxo_de_pesca() -> void:
	var w: Node2D = boot_game()
	var player: Variant = get_tree().get_first_node_in_group("player")
	var fishing: Variant = w.get_node("Fishing")
	# Posiciona player perto da água.
	var cell_agua := Vector2i(9, 7)
	var cell_player := Vector2i(9, 6)  # adjacente
	player.global_position = Vector2(cell_player.x * 16 + 8, cell_player.y * 16 + 8)
	# Seleciona ferramenta de pesca (slot 4 do hotbar).
	Inventory.selected_slot = 4
	var antes := Inventory.count(Enums.Item.FISH)
	# Inicia pesca manualmente (como o player faria).
	fishing.call("start", Enums.Item.FISH)
	assert_that(fishing.active).is_true()
	# Finaliza com vitória.
	fishing.call("_finish", true)
	assert_that(Inventory.count(Enums.Item.FISH)).is_equal(antes + 1)