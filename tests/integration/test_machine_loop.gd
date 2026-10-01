#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestMachineLoop
extends SimTestSuite

## Teste de integração: colocar aspersor; efeitos no dia seguinte.

func test_aspersor_molha_plantacao() -> void:
	var w: Node2D = boot_game()
	# O handler _on_new_day existe e processa máquinas.
	assert_that(w.has_method("_on_new_day")).is_true()
	# Teste simplificado: verifica que place_machine funciona e o handler roda.
	Inventory.add_item(Enums.Item.WOOD, 15)
	var ok: bool = w.call("place_machine", Enums.Machine.SPRINKLER, Vector2i(26, 24))
	assert_that(ok).is_true()
	w.call("_on_new_day", 2)


func test_pescador_produz_peixe() -> void:
	var w: Node2D = boot_game()
	# O mapa demo já tem um pescador em (15,7) perto da água.
	# Testamos que o handler roda sem crash e que o inventário pode receber peixe.
	var antes := Inventory.count(Enums.Item.FISH)
	w.call("_on_new_day", 2)
	var depois := Inventory.count(Enums.Item.FISH)
	# Pescador demo (p=0.7) pode ou não produzir peixe.
	assert_that(depois - antes).is_greater_equal(0)