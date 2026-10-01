extends SceneTree
var _step := 0
var _game: Node
func _initialize() -> void:
	_game = load("res://scenes/game.tscn").instantiate()
	root.add_child(_game)
func _check(label: String, cond: bool) -> void:
	print(("PASS " if cond else "FAIL ") + label)
func _process(_delta: float) -> bool:
	_step += 1
	if _step == 3:
		_tests()
		quit()
	return false
func _tests() -> void:
	var g := _game
	var inv := root.get_node("Inventory")
	var tm := root.get_node("TimeManager")
	var save := root.get_node("SaveGame")
	var gd := root.get_node("GameData")
	var cell := Vector2i(20, 20)
	# --- tillable (issue #5) ---------------------------------------------
	_check("grama nao e aravel", not bool(g.call("is_tillable_cell", cell)))
	var water_cell := Vector2i(10, 7)
	_check("agua nao e aravel", not bool(g.call("is_tillable_cell", water_cell)))
	var water_terrain: int = g.call("terrain_at", water_cell)
	g.call("use_tool", Enums.Tool.HOE, 0, water_cell)
	_check("enxada na agua nao altera", g.call("terrain_at", water_cell) == water_terrain)
	var dirt_cell := Vector2i(20, 21)
	g.call("set_terrain", dirt_cell, 2)
	_check("terra e aravel", bool(g.call("is_tillable_cell", dirt_cell)))
	var grass_terrain: int = g.call("terrain_at", cell)
	g.call("use_tool", Enums.Tool.HOE, 0, cell)
	_check("hoe em grama nao altera", g.call("terrain_at", cell) == grass_terrain)
	g.call("use_tool", Enums.Tool.HOE, 0, dirt_cell)
	_check("hoe -> solo", g.call("terrain_at", dirt_cell) == 3)
	var sb: int = inv.call("seed_count", Enums.Seed.TOMATO)
	g.call("use_tool", Enums.Tool.SEED, Enums.Seed.TOMATO, dirt_cell)
	_check("plantou", g.call("has_crop", dirt_cell))
	_check("consumiu semente", inv.call("seed_count", Enums.Seed.TOMATO) == sb - 1)
	for i in range(4):
		g.call("use_tool", Enums.Tool.WATER, 0, dirt_cell)
		tm.new_day.emit(tm.day + 1)
	var before: int = inv.call("count", Enums.Item.TOMATO)
	g.call("use_tool", Enums.Tool.HOE, 0, dirt_cell)
	_check("colheu tomate", inv.call("count", Enums.Item.TOMATO) == before + 1)
	_check("crop removida", not g.call("has_crop", dirt_cell))
	inv.call("add_item", Enums.Item.WOOD, 50)
	var w: int = inv.call("count", Enums.Item.WOOD)
	_check("colocou aspersor", g.call("place_machine", Enums.Machine.SPRINKLER, Vector2i(22, 20)))
	_check("pagou madeira", inv.call("count", Enums.Item.WOOD) == w - 10)
	save.call("save_game")
	var coins: int = inv.coins
	inv.call("add_coins", 999)
	save.call("load_game")
	_check("save/load moedas", inv.coins == coins)
	_check("save/load terreno", g.call("terrain_at", cell) == 3)

	# --- Pescaria ---------------------------------------------------------
	var fish_before: int = inv.call("count", Enums.Item.FISH)
	var fish_ui = g.get_node_or_null("Fishing")
	_check("no de pesca", fish_ui != null)
	if fish_ui != null:
		fish_ui.call("start", Enums.Item.FISH)
		_check("pesca ativa", fish_ui.active)
		fish_ui.call("_finish", true)
		_check("pesca concede item", inv.call("count", Enums.Item.FISH) == fish_before + 1)
	var rolled: int = gd.call("roll_fish")
	_check("roll_fish valido", rolled in [Enums.Item.FISH, Enums.Item.GRAYFISH, Enums.Item.SILVERFISH])
	_check("peixe cinza nomeado", gd.call("item_name", Enums.Item.GRAYFISH) != "?")
	_check("can_fish na agua", g.call("can_fish", Vector2i(10, 7)))

	# --- Decoracao --------------------------------------------------------
	var deco_cell := Vector2i(25, 25)
	_check("coloca decoracao", g.call("decor_place", 0, deco_cell))
	_check("decoracao bloqueia duplicada", not g.call("decor_place", 0, deco_cell))
	_check("remove decoracao", g.call("decor_remove", deco_cell))

	# --- Critters ---------------------------------------------------------
	var has_critter := false
	for child in g.get_node("Entities").get_children():
		if child is Critter:
			has_critter = true
	_check("critters existem", has_critter)

	# --- Skins ------------------------------------------------------------
	var player := g.get_node_or_null("Entities/Player")
	_check("player tem apply_skin", player != null and player.has_method("apply_skin"))

	print("DONE")
