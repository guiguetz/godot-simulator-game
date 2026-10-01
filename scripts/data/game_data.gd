extends Node

## Dados do jogo (itens, plantacoes, ferramentas, maquinas, precos).
## Autoload `GameData`: dados do jogo (itens, culturas, ferramentas, maquinas,
## precos e icones).

const TILE := 16

# Icones (preload em const: caminhos fixos). Separados por dominio porque os
# enums tem valores sobrepostos (Item.WOOD == Seed.TOMATO == Machine.SPRINKLER).
const TOOL_ICON := {
	"hoe": preload("res://assets/graphics/icons/hoe.png"),
	"water": preload("res://assets/graphics/icons/water.png"),
	"axe": preload("res://assets/graphics/icons/axe.png"),
	"sword": preload("res://assets/graphics/icons/sword.png"),
	"fish_tool": preload("res://assets/graphics/icons/fish.png"),
	"seed": preload("res://assets/graphics/icons/wheat.png"),
}
const ITEM_ICON := {
	Enums.Item.WOOD: preload("res://assets/graphics/icons/wood.png"),
	Enums.Item.APPLE: preload("res://assets/graphics/icons/apple.png"),
	Enums.Item.TOMATO: preload("res://assets/graphics/icons/tomato.png"),
	Enums.Item.CORN: preload("res://assets/graphics/icons/corn.png"),
	Enums.Item.WHEAT: preload("res://assets/graphics/icons/wheat.png"),
	Enums.Item.PUMPKIN: preload("res://assets/graphics/icons/pumpkin.png"),
	Enums.Item.FISH: preload("res://assets/graphics/icons/goldfish.png"),
	Enums.Item.GRAYFISH: preload("res://assets/graphics/icons/grayfish.png"),
	Enums.Item.SILVERFISH: preload("res://assets/graphics/icons/silverfish.png"),
}

## Pescaria: item -> {peso (sorteio), dificuldade 0..1}.
const FISH_LOOT := {
	Enums.Item.FISH: {"weight": 60, "difficulty": 0.35},
	Enums.Item.GRAYFISH: {"weight": 30, "difficulty": 0.55},
	Enums.Item.SILVERFISH: {"weight": 10, "difficulty": 0.8},
}
const SEED_ICON := {
	Enums.Seed.TOMATO: preload("res://assets/graphics/icons/tomato.png"),
	Enums.Seed.CORN: preload("res://assets/graphics/icons/corn.png"),
	Enums.Seed.PUMPKIN: preload("res://assets/graphics/icons/pumpkin.png"),
	Enums.Seed.WHEAT: preload("res://assets/graphics/icons/wheat.png"),
}
const MACHINE_ICON := {
	Enums.Machine.SPRINKLER: preload("res://assets/graphics/icons/sprinkler.png"),
	Enums.Machine.FISHER: preload("res://assets/graphics/icons/fisher.png"),
	Enums.Machine.SCARECROW: preload("res://assets/graphics/icons/scarecrow.png"),
}

const CROP_TEXTURES := {
	Enums.Seed.TOMATO: preload("res://assets/graphics/plants/tomato.png"),
	Enums.Seed.CORN: preload("res://assets/graphics/plants/corn.png"),
	Enums.Seed.PUMPKIN: preload("res://assets/graphics/plants/pumpkin.png"),
	Enums.Seed.WHEAT: preload("res://assets/graphics/plants/wheat.png"),
}

## Moveis/decoracoes colocaveis no modo decoracao (scripts/decor.gd).
## `frames` > 1 usa a folha horizontal como animacao; `fw`/`fh` = frame.
const DECOR := [
	{"name": "Cama", "tex": preload("res://assets/graphics/objects/bed.png")},
	{"name": "Mesa", "tex": preload("res://assets/graphics/objects/table.png")},
	{"name": "Estante", "tex": preload("res://assets/graphics/objects/bookshelf.png")},
	{"name": "Tapete", "tex": preload("res://assets/graphics/objects/carpet.png")},
	{"name": "Planta", "tex": preload("res://assets/graphics/objects/plant.png")},
	{"name": "TV", "tex": preload("res://assets/graphics/machines/tv.png"), "fw": 16, "fh": 32, "frames": 5},
	{"name": "Comida", "tex": preload("res://assets/graphics/machines/food.png"), "fw": 16, "fh": 16, "frames": 4},
]

## Skins do personagem (mesma ordem de Enums.Style onde possivel).
const SKIN_FRAMES := [
	preload("res://assets/sprites/player_basic_frames.tres"),
	preload("res://assets/sprites/player_blue_frames.tres"),
	preload("res://assets/sprites/player_cowboy_frames.tres"),
	preload("res://assets/sprites/player_grey_frames.tres"),
	preload("res://assets/sprites/player_red_frames.tres"),
	preload("res://assets/sprites/player_straw_frames.tres"),
]
const SKIN_NAMES := ["Basico", "Azul", "Cowboy", "Cinza", "Vermelho", "Palha"]
## Icone de chapeu quando existir (assets/graphics/icons).
const SKIN_ICONS := [
	null,
	preload("res://assets/graphics/icons/blue.png"),
	preload("res://assets/graphics/icons/cowboy.png"),
	null,
	null,
	preload("res://assets/graphics/icons/straw.png"),
]

# Seed -> dados da cultura. Texturas 64x32 = 4 estagios de 16x32.
var crops := {}
# Enums.Item -> {name, value}
var items := {}
# Enums.Seed -> preco de compra
var seed_prices := {}
# Enums.Machine -> {name, cost: {Item: qtd}}
var machine_cost := {}
# Ordem da hotbar (6 ferramentas + 3 maquinas)
var hotbar: Array = []


func _ready() -> void:
	_build()


func _build() -> void:
	crops = {
		Enums.Seed.TOMATO: {"name": "Tomate", "grow_days": 2, "reward": Enums.Item.TOMATO},
		Enums.Seed.CORN: {"name": "Milho", "grow_days": 3, "reward": Enums.Item.CORN},
		Enums.Seed.PUMPKIN: {"name": "Abobora", "grow_days": 4, "reward": Enums.Item.PUMPKIN},
		Enums.Seed.WHEAT: {"name": "Trigo", "grow_days": 2, "reward": Enums.Item.WHEAT},
	}
	items = {
		Enums.Item.WOOD: {"name": "Madeira", "value": 2},
		Enums.Item.APPLE: {"name": "Maca", "value": 5},
		Enums.Item.TOMATO: {"name": "Tomate", "value": 8},
		Enums.Item.CORN: {"name": "Milho", "value": 6},
		Enums.Item.WHEAT: {"name": "Trigo", "value": 4},
		Enums.Item.PUMPKIN: {"name": "Abobora", "value": 12},
		Enums.Item.FISH: {"name": "Peixe Dourado", "value": 10},
		Enums.Item.GRAYFISH: {"name": "Peixe Cinza", "value": 16},
		Enums.Item.SILVERFISH: {"name": "Peixe Prateado", "value": 24},
	}
	seed_prices = {
		Enums.Seed.TOMATO: 4,
		Enums.Seed.CORN: 4,
		Enums.Seed.PUMPKIN: 6,
		Enums.Seed.WHEAT: 3,
	}
	machine_cost = {
		Enums.Machine.SPRINKLER: {"name": "Aspersor", "cost": {Enums.Item.WOOD: 10}},
		Enums.Machine.SCARECROW: {"name": "Espantalho", "cost": {Enums.Item.WOOD: 8}},
		Enums.Machine.FISHER: {"name": "Pescador", "cost": {Enums.Item.WOOD: 15}},
	}
	hotbar = [
		{"kind": "tool", "id": Enums.Tool.HOE, "name": "Enxada", "icon": TOOL_ICON["hoe"]},
		{"kind": "tool", "id": Enums.Tool.WATER, "name": "Regador", "icon": TOOL_ICON["water"]},
		{"kind": "tool", "id": Enums.Tool.AXE, "name": "Machado", "icon": TOOL_ICON["axe"]},
		{"kind": "tool", "id": Enums.Tool.SWORD, "name": "Espada", "icon": TOOL_ICON["sword"]},
		{"kind": "tool", "id": Enums.Tool.FISH, "name": "Vara", "icon": TOOL_ICON["fish_tool"]},
		{"kind": "tool", "id": Enums.Tool.SEED, "name": "Semente", "icon": TOOL_ICON["seed"]},
		{"kind": "machine", "id": Enums.Machine.SPRINKLER, "name": "Aspersor", "icon": MACHINE_ICON[Enums.Machine.SPRINKLER]},
		{"kind": "machine", "id": Enums.Machine.SCARECROW, "name": "Espantalho", "icon": MACHINE_ICON[Enums.Machine.SCARECROW]},
		{"kind": "machine", "id": Enums.Machine.FISHER, "name": "Pescador", "icon": MACHINE_ICON[Enums.Machine.FISHER]},
	]


func seed_name(seed: int) -> String:
	return crops.get(seed, {}).get("name", "Semente")


func item_name(item: int) -> String:
	return items.get(item, {}).get("name", "?")


func fish_difficulty(item: int) -> float:
	return float(FISH_LOOT.get(item, {}).get("difficulty", 0.4))


func item_value(item: int) -> int:
	return items.get(item, {}).get("value", 0)


## Sorteia um peixe conforme os pesos de FISH_LOOT.
func roll_fish() -> int:
	var total := 0
	for item in FISH_LOOT:
		total += int(FISH_LOOT[item]["weight"])
	var pick := randi_range(1, total)
	for item in FISH_LOOT:
		pick -= int(FISH_LOOT[item]["weight"])
		if pick <= 0:
			return item
	return Enums.Item.FISH


func can_afford(cost: Dictionary) -> bool:
	for item in cost:
		if Inventory.count(item) < cost[item]:
			return false
	return true


func pay(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for item in cost:
		Inventory.remove_item(item, cost[item])
	return true
