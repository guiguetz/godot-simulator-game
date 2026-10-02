@tool
extends Node2D

## Mundo: chao + terreno (agua, trilha, canteiro) + entidades (props,
## plantacoes, maquinas) + casa. Expoe `use_tool()` para o Player e
## `to_dict()/from_dict()` para o SaveGame.
##
## Cada TileMapDual e uma camada de terreno independente e tambem a fonte de
## verdade para pintura, consultas e save/load. O addon gera apenas a apresentacao.

const TILE := 16
const MAP_W := 40
const MAP_H := 30

const NONE := 0
const WATER := 1
const DIRT := 2
const SOIL := 3

const TILLABLE_FALLBACK := false

const TEX_GRASS := "res://assets/tiles/ground_grass.png"
const TEX_DECORATION := preload("res://assets/graphics/tilesets/decoration.png")

## Folha decoration.png = 4x2 tiles de 16x16 (tufos, pedras, arbustos, flores).
const DECOR_TILES := [0, 1, 2, 3, 4, 5, 6, 7]

@onready var _terrain_water: TileMapDual = $TerrainWater
@onready var _terrain_dirt: TileMapDual = $TerrainDirt
@onready var _terrain_soil: TileMapDual = $TerrainSoil
@onready var _terrain_layers: Array[TileMapDual] = [_terrain_water, _terrain_dirt, _terrain_soil]
@onready var _entities: Node2D = $Entities
@onready var _player: Player = $Entities/Player
@onready var _camera: Camera2D = $Entities/Player/Camera2D

var _walkable := PackedByteArray()

var _props: Dictionary = {}
var _crops: Dictionary = {}
var _machines: Dictionary = {}
var _decor: Dictionary = {}

@export_tool_button("Gerar mapa de exemplo") var _seed_demo_action: Callable = _seed_demo


func _ready() -> void:
	add_to_group("world")
	_rebuild_world()
	if not Engine.is_editor_hint():
		_build_house()
		_setup_demo_entities()
		_scatter_decorations()
		_setup_player()
		_setup_camera()
		TimeManager.new_day.connect(_on_new_day)


# --- Construcao do mundo ---------------------------------------------------

func _rebuild_world() -> void:
	_clear_ground()
	_build_ground()
	if _all_terrain_layers_empty():
		_seed_demo()
	_normalize_terrain_layers()
	_rebuild_walkable()


func _all_terrain_layers_empty() -> bool:
	for layer in _terrain_layers:
		if not layer.get_used_cells().is_empty():
			return false
	return true


## Resolve sobreposicoes deixadas por pintura manual em mais de uma camada.
## A prioridade fixa (agua, terra, canteiro) tambem e a ordem de consulta.
func _normalize_terrain_layers() -> void:
	var occupied: Dictionary = {}
	for tid in [WATER, DIRT, SOIL]:
		var layer := _layer_for_terrain(tid)
		for cell in layer.get_used_cells():
			# Reaplica o terreno cheio pela API do addon. Isso migra células
			# salvas com coordenadas antigas do atlas (ex.: areia oficial).
			var tile_data := layer.get_cell_tile_data(cell)
			if tile_data == null or tile_data.terrain != 1:
				layer.draw_cell(cell, 1)
			if occupied.has(cell):
				layer.erase_cell(cell)
			else:
				occupied[cell] = tid


func _rebuild_walkable() -> void:
	_walkable.resize(MAP_W * MAP_H)
	_walkable.fill(1)
	for y in range(MAP_H):
		for x in range(MAP_W):
			var cell := Vector2i(x, y)
			var tid := terrain_at(cell)
			if tid != NONE and not _is_walkable_terrain(cell, tid):
				_walkable[y * MAP_W + x] = 0


func _clear_ground() -> void:
	for child in get_children():
		if child is TileMapLayer and child.name == "Ground":
			remove_child(child)
			child.queue_free()


# --- Walkable ---------------------------------------------------------------

## Le os metadados do tile logico ocupando a celula. O tile preenchido (3,3)
## de cada TileSet carrega os dados de jogo; tiles de display nao sao consultados.
func _custom_data(cell: Vector2i, key: String, fallback: bool) -> bool:
	var tid := terrain_at(cell)
	var layer := _layer_for_terrain(tid)
	if layer == null:
		return fallback
	var tile_data := layer.get_cell_tile_data(cell)
	if tile_data == null:
		return fallback
	var value: Variant = tile_data.get_custom_data(key)
	return bool(value) if value != null else fallback


func _is_walkable_terrain(cell: Vector2i, _tid: int) -> bool:
	return _custom_data(cell, "walkable", true)


func _is_tillable_terrain(cell: Vector2i, _tid: int) -> bool:
	return _custom_data(cell, "tillable", TILLABLE_FALLBACK)


## Indica se a enxada pode transformar a celula em `SOIL` (custom data do tile).
func is_tillable_cell(cell: Vector2i) -> bool:
	return _is_tillable_terrain(cell, terrain_at(cell))


func is_walkable(world_pos: Vector2) -> bool:
	var cx := int(floor(world_pos.x / TILE))
	var cy := int(floor(world_pos.y / TILE))
	if cx < 0 or cy < 0 or cx >= MAP_W or cy >= MAP_H:
		return false
	return _walkable[cy * MAP_W + cx] != 0


func is_walkable_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= MAP_W or cell.y >= MAP_H:
		return false
	return _walkable[cell.y * MAP_W + cell.x] != 0


## Celula do mundo sob o mouse (usado pelo modo decoracao).
func mouse_cell() -> Vector2i:
	var p := get_global_mouse_position()
	return Vector2i(int(floor(p.x / TILE)), int(floor(p.y / TILE)))


# --- Chao base -------------------------------------------------------------

func _build_ground() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = load(TEX_GRASS)
	source.texture_region_size = Vector2i(TILE, TILE)
	source.create_tile(Vector2i(0, 0))
	ts.add_source(source, 0)

	var layer := TileMapLayer.new()
	layer.name = "Ground"
	layer.tile_set = ts
	# Fica abaixo de tudo: os terrenos do dual grid usam z 1..3 e as entidades
	# (Entities) usam z 10. Sem isso o chao e desenhado por cima do player.
	layer.z_index = -10
	add_child(layer)
	move_child(layer, 0)

	for y in range(MAP_H):
		for x in range(MAP_W):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))


# --- Terreno publico -------------------------------------------------------

func terrain_at(cell: Vector2i) -> int:
	if not _is_inside_map(cell):
		return -1
	for tid in [WATER, DIRT, SOIL]:
		var layer := _layer_for_terrain(tid)
		if layer.get_cell_source_id(cell) != -1:
			return tid
	return NONE


func set_terrain(cell: Vector2i, tid: int, refresh: bool = true) -> void:
	if not _is_inside_map(cell) or tid < NONE or tid > SOIL:
		return
	for layer in _terrain_layers:
		layer.erase_cell(cell)
	if tid != NONE:
		_layer_for_terrain(tid).draw_cell(cell, 1)
	if refresh:
		_rebuild_walkable()


func _is_inside_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < MAP_W and cell.y < MAP_H


func _layer_for_terrain(tid: int) -> TileMapDual:
	match tid:
		WATER: return _terrain_water
		DIRT: return _terrain_dirt
		SOIL: return _terrain_soil
		_: return null


func has_crop(cell: Vector2i) -> bool:
	return _crops.has(cell)


# --- Entidades -------------------------------------------------------------

func _cell_anchor(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE)


func _spawn_tree(cell: Vector2i) -> Prop:
	var p := Prop.new()
	p.setup_tree(cell)
	p.position = _cell_anchor(cell)
	_entities.add_child(p)
	_props[cell] = p
	return p


func _spawn_crop(seed: int, cell: Vector2i) -> Crop:
	var c := Crop.new()
	c.setup(seed, cell)
	c.position = _cell_anchor(cell)
	_entities.add_child(c)
	_crops[cell] = c
	return c


func _spawn_machine(kind: int, cell: Vector2i) -> Machine:
	var m := Machine.new()
	m.setup(kind, cell)
	m.position = _cell_anchor(cell)
	_entities.add_child(m)
	_machines[cell] = m
	return m


func _clear_entities() -> void:
	for dict in [_props, _crops, _machines]:
		for node in dict.values():
			if is_instance_valid(node):
				node.queue_free()
		dict.clear()


func _spawn_critter(kind: int, cell: Vector2i) -> Critter:
	var c := Critter.new()
	c.setup(kind, _cell_anchor(cell), self)
	_entities.add_child(c)
	return c


# --- Decoracoes (modo decoracao) -------------------------------------------

## Coloca uma decoracao de GameData.DECOR na celula. Retorna false se ocupada
## ou fora de area andavel.
func decor_place(kind: int, cell: Vector2i) -> bool:
	if kind < 0 or kind >= GameData.DECOR.size():
		return false
	if _decor.has(cell) or not is_walkable_cell(cell):
		return false
	var entry: Dictionary = GameData.DECOR[kind]
	var node := _make_decor_node(entry)
	node.position = _cell_anchor(cell)
	_entities.add_child(node)
	_decor[cell] = node
	return true


func decor_remove(cell: Vector2i) -> bool:
	if not _decor.has(cell):
		return false
	var node: Node = _decor[cell]
	_decor.erase(cell)
	if is_instance_valid(node):
		node.queue_free()
	return true


func _make_decor_node(entry: Dictionary) -> Node2D:
	if entry.has("frames"):
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = _strip_frames(entry["tex"], entry["fw"], entry["fh"], entry["frames"], 5.0)
		anim.offset = Vector2(0, -entry["fh"] / 2.0)
		anim.play("idle")
		return anim
	var sprite := Sprite2D.new()
	sprite.texture = entry["tex"]
	sprite.offset = Vector2(0, -entry["tex"].get_height() / 2.0)
	return sprite


func _strip_frames(tex: Texture2D, w: int, h: int, count: int, speed: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", speed)
	for i in range(count):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * w, 0, w, h)
		frames.add_frame("idle", at)
	return frames


func _clear_decor() -> void:
	for node in _decor.values():
		if is_instance_valid(node):
			node.queue_free()
	_decor.clear()


## Espalha pequenas decoracoes (tufos/pedras/flores) sobre a grama.
func _scatter_decorations() -> void:
	var scatter := Node2D.new()
	scatter.name = "Scatter"
	scatter.z_index = 0
	add_child(scatter)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20240607
	for i in range(70):
		var cell := Vector2i(rng.randi_range(0, MAP_W - 1), rng.randi_range(0, MAP_H - 1))
		if terrain_at(cell) != NONE or not is_walkable_cell(cell):
			continue
		if _machines.has(cell) or _crops.has(cell) or _props.has(cell):
			continue
		var idx: int = DECOR_TILES[rng.randi_range(0, DECOR_TILES.size() - 1)]
		var s := Sprite2D.new()
		s.texture = TEX_DECORATION
		s.region_enabled = true
		s.region_rect = Rect2((idx % 4) * 16, (idx / 4) * 16, 16, 16)
		s.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE)
		s.offset = Vector2(0, -8)
		scatter.add_child(s)


# --- Ferramentas -----------------------------------------------------------

func use_tool(tool: int, seed: int, cell: Vector2i) -> void:
	# Colher cultura pronta com a enxada.
	if tool == Enums.Tool.HOE and _crops.has(cell) and _crops[cell].is_ready:
		var reward: int = _crops[cell].harvest()
		if reward >= 0:
			Inventory.add_item(reward, 1)
			_crops[cell].queue_free()
			_crops.erase(cell)
		AudioManager.play_sfx("hoe")
		return

	match tool:
		Enums.Tool.HOE:
			if is_tillable_cell(cell) and is_walkable_cell(cell):
				set_terrain(cell, SOIL)
				AudioManager.play_sfx("hoe")
		Enums.Tool.WATER:
			AudioManager.play_sfx("water")
			if _crops.has(cell):
				_crops[cell].water()
			elif _machines.has(cell) and _machines[cell].kind == Enums.Machine.FISHER:
				pass
		Enums.Tool.AXE:
			if _props.has(cell):
				var result: Dictionary = _props[cell].chop()
				Inventory.add_item(Enums.Item.WOOD, int(result["wood"]))
				if bool(result["removed"]):
					_props.erase(cell)
				AudioManager.play_sfx("axe")
		Enums.Tool.SWORD:
			AudioManager.play_sfx("slime")
		Enums.Tool.FISH:
			if terrain_at(cell) == WATER or _near_water(cell):
				if randf() < 0.65:
					Inventory.add_item(Enums.Item.FISH, 1)
					AudioManager.play_sfx("fish")
		Enums.Tool.SEED:
			if terrain_at(cell) == SOIL and not _crops.has(cell) and not _machines.has(cell):
				if Inventory.seed_count(seed) > 0:
					Inventory.remove_seed(seed)
					_spawn_crop(seed, cell)


func place_machine(kind: int, cell: Vector2i) -> bool:
	if not is_walkable_cell(cell) or _machines.has(cell) or _crops.has(cell):
		return false
	if not GameData.pay(GameData.machine_cost[kind]["cost"]):
		return false
	_spawn_machine(kind, cell)
	return true


func _near_water(cell: Vector2i) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if terrain_at(cell + offset) == WATER:
			return true
	return false


## O jogador pode pescar nesta celula? (agua na celula ou ao lado)
func can_fish(cell: Vector2i) -> bool:
	return terrain_at(cell) == WATER or _near_water(cell)


# --- Ciclo diario ----------------------------------------------------------

func _on_new_day(_day: int) -> void:
	# 1) aspersores molham as plantacoes ao redor
	for cell in _machines:
		var m: Machine = _machines[cell]
		if m.kind == Enums.Machine.SPRINKLER:
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.ZERO]:
				if _crops.has(cell + offset):
					_crops[cell + offset].water()
	# 2) pescador produz peixe se estiver perto da agua
	for cell in _machines:
		var m: Machine = _machines[cell]
		if m.kind == Enums.Machine.FISHER and _near_water(cell):
			if randf() < 0.7:
				Inventory.add_item(Enums.Item.FISH, 1)
	# 3) plantacoes crescem (chuva rega automaticamente)
	var raining := Weather.is_raining()
	for cell in _crops:
		_crops[cell].grow_day(raining)


# --- Serializacao ----------------------------------------------------------

func to_dict() -> Dictionary:
	var terrain: Array = []
	# Cada TileMapDual e fonte logica e visual da propria camada; serializamos
	# apenas a ocupacao/tipo, nunca os tiles derivados escolhidos pelo addon.
	for tid in [WATER, DIRT, SOIL]:
		for cell in _layer_for_terrain(tid).get_used_cells():
			terrain.append([cell.x, cell.y, tid])
	var props: Array = []
	for node in _props.values():
		props.append(node.to_dict())
	var crops: Array = []
	for node in _crops.values():
		crops.append(node.to_dict())
	var machines: Array = []
	for node in _machines.values():
		machines.append(node.to_dict())
	var decor: Array = []
	for cell in _decor:
		decor.append([cell.x, cell.y, _decor_kind(cell)])
	return {"terrain": terrain, "props": props, "crops": crops, "machines": machines, "decor": decor}


## Indice em GameData.DECOR correspondente a textura do node (para o save).
func _decor_kind(cell: Vector2i) -> int:
	var node: Node = _decor.get(cell)
	if node == null:
		return -1
	var tex: Texture2D = null
	if node is Sprite2D:
		tex = (node as Sprite2D).texture
	elif node is AnimatedSprite2D:
		var first := (node as AnimatedSprite2D).sprite_frames.get_frame_texture("idle", 0)
		if first is AtlasTexture:
			tex = (first as AtlasTexture).atlas
	for i in range(GameData.DECOR.size()):
		if GameData.DECOR[i]["tex"] == tex:
			return i
	return -1


func from_dict(data: Dictionary) -> void:
	_clear_entities()
	_clear_decor()
	
	# Restaura as celulas logicas; TileMapDual recalcula a apresentacao.
	for layer in _terrain_layers:
		layer.clear()
	for t in data.get("terrain", []):
		if t.size() < 3:
			continue
		var cell := Vector2i(int(t[0]), int(t[1]))
		var tid := int(t[2])
		set_terrain(cell, tid, false)
	_rebuild_walkable()

	for p in data.get("props", []):
		var cell := Vector2i(int(p["cell"][0]), int(p["cell"][1]))
		var prop := _spawn_tree(cell)
		if int(p.get("kind", 0)) == Prop.Kind.STUMP:
			prop.chop()
	for c in data.get("crops", []):
		var cell := Vector2i(int(c["cell"][0]), int(c["cell"][1]))
		var crop := _spawn_crop(int(c["seed"]), cell)
		crop.restore(c)
	for m in data.get("machines", []):
		var cell := Vector2i(int(m["cell"][0]), int(m["cell"][1]))
		_spawn_machine(int(m["kind"]), cell)
	for d in data.get("decor", []):
		decor_place(int(d[2]), Vector2i(int(d[0]), int(d[1])))


# --- Montagem inicial ------------------------------------------------------

func _build_house() -> void:
	var structures := get_node_or_null("Structures")
	HouseBuilder.build(structures if structures != null else self, Vector2i(2, 3))


func _setup_demo_entities() -> void:
	# arvores espalhadas
	for cell in [Vector2i(15, 3), Vector2i(18, 4), Vector2i(33, 5), Vector2i(30, 27), Vector2i(5, 28), Vector2i(12, 2)]:
		if is_walkable_cell(cell):
			_spawn_tree(cell)
	# plantacoes iniciais no canteiro (4..11, 22..26)
	var demo_crops := {
		Vector2i(5, 23): Enums.Seed.TOMATO,
		Vector2i(6, 23): Enums.Seed.TOMATO,
		Vector2i(7, 23): Enums.Seed.CORN,
		Vector2i(9, 24): Enums.Seed.PUMPKIN,
		Vector2i(10, 24): Enums.Seed.WHEAT,
	}
	for cell in demo_crops:
		_spawn_crop(demo_crops[cell], cell)
	# maquinas
	if is_walkable_cell(Vector2i(8, 24)):
		_spawn_machine(Enums.Machine.SPRINKLER, Vector2i(8, 24))
	if is_walkable_cell(Vector2i(11, 25)):
		_spawn_machine(Enums.Machine.SCARECROW, Vector2i(11, 25))
	if is_walkable_cell(Vector2i(15, 7)):
		_spawn_machine(Enums.Machine.FISHER, Vector2i(15, 7))
	# criaturas/NPCs ambientais
	_spawn_critter(Critter.Kind.CAT, Vector2i(6, 7))
	_spawn_critter(Critter.Kind.WOMAN, Vector2i(3, 8))
	_spawn_critter(Critter.Kind.MOUSE, Vector2i(17, 4))
	_spawn_critter(Critter.Kind.MOUSE, Vector2i(30, 20))
	_spawn_critter(Critter.Kind.BLOB, Vector2i(10, 13))


func _setup_player() -> void:
	_player.global_position = Vector2(20 * TILE + TILE / 2, 17 * TILE + TILE / 2)
	_player.world_bounds = Rect2(0, 0, MAP_W * TILE, MAP_H * TILE)
	_player.walkable_check = Callable(self, "is_walkable")


func _setup_camera() -> void:
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = MAP_W * TILE
	_camera.limit_bottom = MAP_H * TILE
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0


# --- Mapa de exemplo (botao do inspetor) ------------------------------------

func _seed_demo() -> void:
	for layer in _terrain_layers:
		layer.clear()
	_paint_mask(_make_water_mask(), WATER)
	_paint_mask(_make_dirt_mask(), DIRT)
	_paint_mask(_make_soil_mask(), SOIL)
	_rebuild_walkable()


func _paint_mask(mask: PackedByteArray, tid: int) -> void:
	for y in range(MAP_H):
		for x in range(MAP_W):
			if mask[y * MAP_W + x] != 0:
				set_terrain(Vector2i(x, y), tid, false)


# --- Helpers ---------------------------------------------------------------

func _new_mask() -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(MAP_W * MAP_H)
	return mask


func _put(mask: PackedByteArray, x: int, y: int) -> void:
	if x < 0 or y < 0 or x >= MAP_W or y >= MAP_H:
		return
	mask[y * MAP_W + x] = 1


func _make_water_mask() -> PackedByteArray:
	var mask := _new_mask()
	var center := Vector2(10.5, 7.5)
	var radius := 4.3
	for y in range(MAP_H):
		for x in range(MAP_W):
			if Vector2(x, y).distance_to(center) <= radius:
				_put(mask, x, y)
	return mask


func _make_dirt_mask() -> PackedByteArray:
	var mask := _new_mask()
	for x in range(0, MAP_W):
		_put(mask, x, 17)
		_put(mask, x, 18)
	for y in range(6, 17):
		_put(mask, 26, y)
		_put(mask, 27, y)
	for y in range(18, 22):
		_put(mask, 6, y)
		_put(mask, 7, y)
	return mask


func _make_soil_mask() -> PackedByteArray:
	var mask := _new_mask()
	for y in range(22, 27):
		for x in range(4, 12):
			_put(mask, x, y)
	return mask
