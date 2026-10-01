@tool
class_name DualGrid
extends Node2D

## Renderiza uma grade logica usando a tecnica "dual grid" com uma folha
## de 16 posicoes (4x4).
##
## Convencao da folha:
##     bit0 = canto superior-esquerdo (TL)
##     bit1 = canto superior-direito  (TR)
##     bit2 = canto inferior-esquerdo (BL)
##     bit3 = canto inferior-direito  (BR)
##     coluna (x) = bit0 + bit1 * 2
##     linha  (y) = bit2 + bit3 * 2
##
## Cada tile do dual grid fica centrado no canto entre 4 celulas logicas,
## por isso a camada e deslocada meia celula para cima/esquerda.
##
## No editor 2D (@tool), desenha sobre o mapa:
##     - a grade logica (celulas)
##     - a grade dual e suas subdivisoes (tiles deslocados de meio tile)
##     - um rotulo por tile dual com o bitmask e a posicao no atlas
##     - a legenda 4x4 mostrando o que cada tile e

const BIT_TL := 1
const BIT_TR := 2
const BIT_BL := 4
const BIT_BR := 8

const COLOR_LOGICAL := Color(0.30, 0.65, 1.0, 0.55)
const COLOR_DUAL := Color(1.0, 0.55, 0.10, 0.85)
const COLOR_TEXT := Color(1, 1, 1, 0.95)
const COLOR_OUTLINE := Color(0, 0, 0, 0.95)
const COLOR_LEGEND_BG := Color(0.06, 0.06, 0.08, 0.88)
const COLOR_LEGEND_CELL := Color(1, 1, 1, 0.25)


# --- Configuracoes de editor -------------------------------------------------

@export_group("Editor")
## Desenha as linhas da grade logica (as celulas do jogo).
@export var editor_show_grid: bool = true:
	set(value):
		editor_show_grid = value
		_refresh_overlay()
## Desenha a grade dual (tiles centrados nos cantos) e o offset de meio tile.
@export var editor_show_dual: bool = true:
	set(value):
		editor_show_dual = value
		_refresh_overlay()
## Mostra em cada tile o bitmask e a posicao (coluna, linha) no atlas.
@export var editor_show_labels: bool = true:
	set(value):
		editor_show_labels = value
		_refresh_overlay()
## Mostra a legenda 4x4 com os 16 tiles possiveis.
@export var editor_show_legend: bool = true:
	set(value):
		editor_show_legend = value
		_refresh_overlay()
## Escala dos textos do overlay.
@export_range(0.5, 3.0, 0.1) var editor_label_scale: float = 1.0:
	set(value):
		editor_label_scale = value
		_refresh_overlay()
## Textura usada na legenda. Se vazio, usa a primeira camada registrada.
@export var editor_preview_texture: Texture2D:
	set(value):
		editor_preview_texture = value
		_refresh_overlay()


var tile_size: int = 16
var grid_width: int = 0
var grid_height: int = 0

var _layers: Dictionary = {}
var _masks: Dictionary = {}
var _textures: Dictionary = {}
var _overlay: Node2D


# --- API publica -------------------------------------------------------------

## Define o tamanho da grade logica. Chame antes de add_terrain().
func setup(p_width: int, p_height: int, p_tile_size: int = 16) -> void:
	grid_width = p_width
	grid_height = p_height
	tile_size = p_tile_size
	_ensure_overlay()
	_refresh_overlay()


## Cria uma camada de terreno. `texture` deve ser a folha 4x4 (16 tiles).
func add_terrain(id: int, texture: Texture2D, p_z_index: int = 0) -> TileMapLayer:
	_remove_layer(id)
	var layer := TileMapLayer.new()
	layer.name = "Terrain%d" % id
	layer.tile_set = _build_tileset(texture)
	layer.position = Vector2(-tile_size * 0.5, -tile_size * 0.5)
	layer.z_index = p_z_index
	add_child(layer)
	_layers[id] = layer
	_textures[id] = texture
	_refresh_overlay()
	return layer


## Repinta uma camada a partir de uma mascara booleana de tamanho WxH.
func refresh(id: int, mask: PackedByteArray) -> void:
	var layer: TileMapLayer = _layers.get(id)
	if layer == null:
		push_warning("DualGrid: camada %d nao registrada." % id)
		return
	_masks[id] = mask
	layer.clear()
	for y in range(0, grid_height + 1):
		for x in range(0, grid_width + 1):
			var bits := _bits_of(mask, x, y)
			if bits == 0:
				continue
			layer.set_cell(Vector2i(x, y), 0, Vector2i(bits % 4, bits >> 2))
	_refresh_overlay()


## Repinta varias camadas de uma vez: { id: PackedByteArray }.
func refresh_all(masks: Dictionary) -> void:
	for id in masks:
		refresh(id, masks[id])


## Apaga as celulas de todas as camadas (mantendo os TileMapLayers).
func clear_all() -> void:
	for layer in _layers.values():
		(layer as TileMapLayer).clear()
	_refresh_overlay()


# --- Editor ------------------------------------------------------------------

class _EditorOverlay extends Node2D:
	var host: Node

	func _draw() -> void:
		if host != null:
			host.paint_overlay(self)


func _ready() -> void:
	if Engine.is_editor_hint():
		_ensure_overlay()


func _ensure_overlay() -> void:
	if not Engine.is_editor_hint():
		return
	if _overlay != null and is_instance_valid(_overlay):
		return
	var overlay := _EditorOverlay.new()
	overlay.name = "DualGridOverlay"
	overlay.host = self
	# Fica acima das camadas de terreno (que usam z_index 1..N).
	overlay.z_as_relative = false
	overlay.z_index = 4096
	add_child(overlay)
	_overlay = overlay


func _refresh_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_redraw()


## Desenha o overlay no CanvasItem informado (chamado pelo filho _EditorOverlay).
func paint_overlay(ci: CanvasItem) -> void:
	if grid_width <= 0 or grid_height <= 0:
		return
	var t := float(tile_size)
	if editor_show_grid:
		_paint_logical(ci, t)
	if editor_show_dual:
		_paint_dual(ci, t)
	if editor_show_labels:
		_paint_labels(ci, t)
	if editor_show_legend:
		_paint_legend(ci, t)


func _paint_logical(ci: CanvasItem, t: float) -> void:
	var w := grid_width * t
	var h := grid_height * t
	for i in range(grid_width + 1):
		ci.draw_line(Vector2(i * t, 0.0), Vector2(i * t, h), COLOR_LOGICAL, 1.0)
	for j in range(grid_height + 1):
		ci.draw_line(Vector2(0.0, j * t), Vector2(w, j * t), COLOR_LOGICAL, 1.0)


func _paint_dual(ci: CanvasItem, t: float) -> void:
	var half := t * 0.5
	for gy in range(grid_height + 1):
		for gx in range(grid_width + 1):
			var center := Vector2(gx * t, gy * t)
			var rect := Rect2(center - Vector2(half, half), Vector2(t, t))
			ci.draw_rect(rect, COLOR_DUAL, false, 1.0)
			# Subdivisao: marca o centro do tile (= canto da grade logica).
			ci.draw_line(center - Vector2(3, 0), center + Vector2(3, 0), COLOR_DUAL, 1.0)
			ci.draw_line(center - Vector2(0, 3), center + Vector2(0, 3), COLOR_DUAL, 1.0)


func _paint_labels(ci: CanvasItem, t: float) -> void:
	var fs := int(max(6, round(7.0 * editor_label_scale)))
	for gy in range(grid_height + 1):
		for gx in range(grid_width + 1):
			var bits := _bits_at(gx, gy)
			if bits == 0:
				continue
			var center := Vector2(gx * t, gy * t)
			_draw_text_centered(ci, str(bits), center + Vector2(0, -1), fs)
			_draw_text_centered(ci, "%d,%d" % [bits % 4, bits >> 2], center + Vector2(0, fs + 1), fs)


func _paint_legend(ci: CanvasItem, t: float) -> void:
	var size := t * 4.0
	var fs := int(max(7, round(8.0 * editor_label_scale)))
	var font := ThemeDB.fallback_font
	var captions := [
		"Dual grid 4x4 = 16 tiles",
		"col = TL + TR*2",
		"row = BL + BR*2",
		"bit0 TL  bit1 TR  bit2 BL  bit3 BR",
	]
	var text_w := 0.0
	for caption in captions:
		text_w = maxf(text_w, font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var pad := 8.0
	var origin := Vector2(grid_width * t + t, t * 2.0)
	var box_w := maxf(size, text_w) + pad * 2.0
	var box_h := size + pad * 2.0 + float(fs + 2) * captions.size()
	ci.draw_rect(Rect2(origin - Vector2(pad, pad), Vector2(box_w, box_h)), COLOR_LEGEND_BG, true)

	var tex := _legend_texture()
	if tex != null:
		ci.draw_texture_rect(tex, Rect2(origin, Vector2(size, size)), false)

	for row in range(4):
		for col in range(4):
			var cell := Rect2(origin + Vector2(col, row) * t, Vector2(t, t))
			ci.draw_rect(cell, COLOR_LEGEND_CELL, false, 1.0)
			var bits := col + row * 4
			_draw_text_centered(ci, str(bits), cell.position + cell.size * 0.5, fs, Color(1, 1, 1, 0.85))

	var y := origin.y + size + float(fs + 2)
	for caption in captions:
		_draw_text(ci, caption, Vector2(origin.x, y), fs)
		y += fs + 2


func _legend_texture() -> Texture2D:
	if editor_preview_texture != null:
		return editor_preview_texture
	for tex in _textures.values():
		if tex != null:
			return tex
	return null


func _draw_text(ci: CanvasItem, p_text: String, p_pos: Vector2, p_size: int) -> void:
	var font := ThemeDB.fallback_font
	ci.draw_string_outline(font, p_pos, p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, p_size, 3, COLOR_OUTLINE)
	ci.draw_string(font, p_pos, p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, p_size, COLOR_TEXT)


func _draw_text_centered(ci: CanvasItem, p_text: String, p_center: Vector2, p_size: int, p_color: Color = COLOR_TEXT) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, p_size).x
	var pos := Vector2(p_center.x - width * 0.5, p_center.y + p_size * 0.35)
	ci.draw_string_outline(font, pos, p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, p_size, 3, COLOR_OUTLINE)
	ci.draw_string(font, pos, p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, p_size, p_color)


# --- Internos ----------------------------------------------------------------

func _remove_layer(id: int) -> void:
	if not _layers.has(id):
		return
	var old: Node = _layers[id]
	_layers.erase(id)
	if is_instance_valid(old):
		remove_child(old)
		old.queue_free()


func _bits_at(gx: int, gy: int) -> int:
	var bits := 0
	if _occupied(gx - 1, gy - 1):
		bits |= BIT_TL
	if _occupied(gx, gy - 1):
		bits |= BIT_TR
	if _occupied(gx - 1, gy):
		bits |= BIT_BL
	if _occupied(gx, gy):
		bits |= BIT_BR
	return bits


func _occupied(x: int, y: int) -> bool:
	for mask in _masks.values():
		if _at(mask, x, y):
			return true
	return false


func _bits_of(mask: PackedByteArray, x: int, y: int) -> int:
	var bits := 0
	if _at(mask, x - 1, y - 1):
		bits |= BIT_TL
	if _at(mask, x, y - 1):
		bits |= BIT_TR
	if _at(mask, x - 1, y):
		bits |= BIT_BL
	if _at(mask, x, y):
		bits |= BIT_BR
	return bits


func _at(mask: PackedByteArray, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= grid_width or y >= grid_height:
		return false
	return mask[y * grid_width + x] != 0


func _build_tileset(texture: Texture2D) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	for y in range(4):
		for x in range(4):
			source.create_tile(Vector2i(x, y))
	ts.add_source(source, 0)
	return ts
