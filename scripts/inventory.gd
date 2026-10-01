extends Node

## Inventario do jogador. Autoload `Inventory`.
## Itens (Enums.Item) e sementes (Enums.Seed) ficam em mapas separados porque
## os enums tem valores sobrepostos. Sinal `changed` para a HUD/loja.

signal changed

var items: Dictionary = {}
var seeds: Dictionary = {}
var selected_seed: int = Enums.Seed.TOMATO
var selected_slot: int = 0
var coins: int = 100

const SEED_ORDER := [Enums.Seed.TOMATO, Enums.Seed.CORN, Enums.Seed.PUMPKIN, Enums.Seed.WHEAT]


func _ready() -> void:
	add_item(Enums.Item.WOOD, 20, false)
	add_item(Enums.Item.APPLE, 3, false)
	for seed in SEED_ORDER:
		seeds[seed] = 5
	emit_signal("changed")


# --- Itens -----------------------------------------------------------------

func count(item: int) -> int:
	return int(items.get(item, 0))


func add_item(item: int, amount: int = 1, notify: bool = true) -> void:
	items[item] = count(item) + amount
	if notify:
		emit_signal("changed")


func remove_item(item: int, amount: int = 1) -> bool:
	if count(item) < amount:
		return false
	items[item] = count(item) - amount
	emit_signal("changed")
	return true


func has_item(item: int, amount: int = 1) -> bool:
	return count(item) >= amount


# --- Moedas ----------------------------------------------------------------

func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("changed")


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	emit_signal("changed")
	return true


# --- Sementes --------------------------------------------------------------

func seed_count(seed: int) -> int:
	return int(seeds.get(seed, 0))


func add_seed(seed: int, amount: int = 1, notify: bool = true) -> void:
	seeds[seed] = seed_count(seed) + amount
	if notify:
		emit_signal("changed")


func remove_seed(seed: int, amount: int = 1) -> bool:
	if seed_count(seed) < amount:
		return false
	seeds[seed] = seed_count(seed) - amount
	emit_signal("changed")
	return true


func seed_next() -> void:
	var i := SEED_ORDER.find(selected_seed)
	selected_seed = SEED_ORDER[(i + 1) % SEED_ORDER.size()]
	emit_signal("changed")


func set_slot(slot: int) -> void:
	selected_slot = clampi(slot, 0, GameData.hotbar.size() - 1)
	emit_signal("changed")


func current_entry() -> Dictionary:
	if GameData.hotbar.is_empty():
		return {}
	return GameData.hotbar[clampi(selected_slot, 0, GameData.hotbar.size() - 1)]


# --- Serializacao ----------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"items": items.duplicate(),
		"seeds": seeds.duplicate(),
		"selected_seed": selected_seed,
		"selected_slot": selected_slot,
		"coins": coins,
	}


func from_dict(data: Dictionary) -> void:
	items.clear()
	seeds.clear()
	for key in data.get("items", {}):
		items[int(key)] = int(data["items"][key])
	for key in data.get("seeds", {}):
		seeds[int(key)] = int(data["seeds"][key])
	selected_seed = int(data.get("selected_seed", Enums.Seed.TOMATO))
	selected_slot = int(data.get("selected_slot", 0))
	coins = int(data.get("coins", 100))
	emit_signal("changed")
