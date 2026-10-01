#warning-ignore-all:unsafe_method_access,return_value_discarded

class_name TestWorldTools
extends SimTestSuite

## Cobertura de `scripts/world.gd`: uso de ferramentas (enxada, machado,
## regador, semente, colheita).

func test_enxada_na_grama_vira_solo() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 0)  # limpa para grama
	assert_that(bool(w.call("is_tillable_cell", cell))).is_true()
	w.call("use_tool", Enums.Tool.HOE, 0, cell)
	assert_that(int(w.call("terrain_at", cell))).is_equal(3)  # SOIL


func test_enxada_na_agua_nao_altera() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(10, 7)  # água
	var antes := int(w.call("terrain_at", cell))
	w.call("use_tool", Enums.Tool.HOE, 0, cell)
	assert_that(int(w.call("terrain_at", cell))).is_equal(antes)


func test_semente_solo_e_solo() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 3)  # SOIL
	Inventory.add_seed(Enums.Seed.TOMATO, 3)
	var antes := Inventory.seed_count(Enums.Seed.TOMATO)
	w.call("use_tool", Enums.Tool.SEED, Enums.Seed.TOMATO, cell)
	assert_that(bool(w.call("has_crop", cell))).is_true()
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(antes - 1)


func test_semente_solo_nao_empilha() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 3)
	Inventory.add_seed(Enums.Seed.TOMATO, 3)
	w.call("use_tool", Enums.Tool.SEED, Enums.Seed.TOMATO, cell)
	w.call("use_tool", Enums.Tool.SEED, Enums.Seed.TOMATO, cell)
	assert_that(Inventory.seed_count(Enums.Seed.TOMATO)).is_equal(2)  # 1 consumida, 1 rejeitada


func test_semente_sem_semente_nao_planta() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 3)
	Inventory.seeds[Enums.Seed.TOMATO] = 0
	w.call("use_tool", Enums.Tool.SEED, Enums.Seed.TOMATO, cell)
	assert_that(bool(w.call("has_crop", cell))).is_false()


func test_machado_arvore_dar_madeira() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 24)
	w.call("_spawn_tree", cell)
	var antes := Inventory.count(Enums.Item.WOOD)
	w.call("use_tool", Enums.Tool.AXE, 0, cell)
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(antes + 2)


func test_machado_segundo_golpe() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 24)
	w.call("_spawn_tree", cell)
	w.call("use_tool", Enums.Tool.AXE, 0, cell)
	var antes := Inventory.count(Enums.Item.WOOD)
	w.call("use_tool", Enums.Tool.AXE, 0, cell)
	assert_that(Inventory.count(Enums.Item.WOOD)).is_equal(antes + 1)


func test_regador_molha_crop() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 3)
	Inventory.add_seed(Enums.Seed.TOMATO, 1)
	w.call("use_tool", Enums.Tool.SEED, Enums.Seed.TOMATO, cell)
	w.call("use_tool", Enums.Tool.WATER, 0, cell)
	var data: Dictionary = w.call("to_dict")
	for c in data["crops"]:
		if c["cell"] == [25, 25]:
			assert_that(bool(c["watered"])).is_true()
			return
	assert_that(false).is_true()  # crop não encontrada


func test_colheita_com_enxada() -> void:
	var w: Node2D = boot_game()
	var cell := Vector2i(25, 25)
	w.call("set_terrain", cell, 3)
	Inventory.add_seed(Enums.Seed.TOMATO, 1)
	w.call("use_tool", Enums.Tool.SEED, Enums.Seed.TOMATO, cell)
	# Rega e avança dias até ficar pronta (TOMATO grow_days=2).
	for i in range(4):
		w.call("use_tool", Enums.Tool.WATER, 0, cell)
		TimeManager.new_day.emit(TimeManager.day + i + 1)
	var antes := Inventory.count(Enums.Item.TOMATO)
	w.call("use_tool", Enums.Tool.HOE, 0, cell)
	assert_that(Inventory.count(Enums.Item.TOMATO)).is_equal(antes + 1)
	assert_that(bool(w.call("has_crop", cell))).is_false()