extends CanvasLayer

## Minigame de pesca. Autocontido: monta a UI em codigo com os assets de
## assets/graphics/ui/fish_*.png e usa os peixes (goldfish/grayfish/
## silverfish) como alvo movel.
##
## Mecanica: um peixe sobe/desce pela barra; o jogador segura "action"
## (Espaco) para subir a barra de captura. Manter o peixe dentro da barra
## enche a barra de progresso; deixar escapar drena. Segurar gasta a barra
## verde de resistencia.
##
## Chamado pelo player (scripts/player.gd) ao usar a Vara; termina chamando
## Inventory.add_item(). Veja scripts/world.gd:can_fish().

signal finished(win: bool, item: int)

const FRAME_TEX := preload("res://assets/graphics/ui/fish_frame.png")
const BAR_TEX := preload("res://assets/graphics/ui/fish_bar.png")
const PROGRESS_BG_TEX := preload("res://assets/graphics/ui/fish_progress_bg.png")
const PROGRESS_TEX := preload("res://assets/graphics/ui/fish_progress.png")
const STAMINA_TEX := preload("res://assets/graphics/ui/bar.png")
const GUIDE_TEX := preload("res://assets/graphics/ui/v_bar.png")
const RULE_TEX := preload("res://assets/graphics/ui/fisher_bar.png")

const TRACK_W := 26.0
const TRACK_H := 132.0
const BAR_H := 34.0
const MOVE_SPEED := 165.0
const FALL_SPEED := 120.0
const STAMINA_DRAIN := 0.85
const STAMINA_REGEN := 0.7

var active := false
var target: int = Enums.Item.FISH

var _difficulty := 0.4
var _fish_y := 0.0
var _fish_h := 16.0
var _fish_dir := 1.0
var _fish_speed := 60.0
var _fish_retarget := 0.0
var _bar_y := 0.0
var _progress := 0.5
var _stamina := 1.0

var _panel: Control
var _track: Control
var _fish_marker: TextureRect
var _bar: TextureRect
var _progress_fill: TextureRect
var _stamina_fill: TextureRect
var _title: Label


func _ready() -> void:
	add_to_group("fishing")
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false
	set_process(false)


## Inicia a pescaria para o peixe `item` (normalmente GameData.roll_fish()).
func start(item: int) -> void:
	target = item
	_difficulty = GameData.fish_difficulty(item)
	_fish_speed = lerpf(55.0, 135.0, _difficulty)
	_fish_h = 16.0
	_fish_y = randf_range(0.0, TRACK_H - _fish_h)
	_fish_dir = 1.0 if randf() < 0.5 else -1.0
	_fish_retarget = 0.0
	_bar_y = clampf(TRACK_H - BAR_H, 0.0, TRACK_H - BAR_H) * 0.5
	_progress = 0.5
	_stamina = 1.0
	_title.text = "Pescando: %s" % GameData.item_name(item)
	var icon: Texture2D = GameData.ITEM_ICON.get(item)
	_fish_marker.texture = icon
	if icon != null:
		_fish_marker.size = Vector2(icon.get_width(), icon.get_height())
	active = true
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	if not active:
		return
	_update_fish(delta)
	_update_bar(delta)
	_update_progress(delta)
	_refresh_visuals()


# --- Logica ----------------------------------------------------------------

func _update_fish(delta: float) -> void:
	_fish_retarget -= delta
	if _fish_retarget <= 0.0:
		_fish_retarget = randf_range(0.35, 1.0)
		_fish_dir = [-1.0, 1.0].pick_random()
	_fish_y += _fish_dir * _fish_speed * delta
	var limit := TRACK_H - _fish_h
	if _fish_y <= 0.0:
		_fish_y = 0.0
		_fish_dir = 1.0
	elif _fish_y >= limit:
		_fish_y = limit
		_fish_dir = -1.0


func _update_bar(delta: float) -> void:
	var held := Input.is_action_pressed("action") and _stamina > 0.0
	if held:
		_bar_y -= MOVE_SPEED * delta
		_stamina = maxf(0.0, _stamina - STAMINA_DRAIN * delta)
	else:
		_bar_y += FALL_SPEED * delta
		_stamina = minf(1.0, _stamina + STAMINA_REGEN * delta)
	_bar_y = clampf(_bar_y, 0.0, TRACK_H - BAR_H)


func _update_progress(delta: float) -> void:
	var fish_center := _fish_y + _fish_h * 0.5
	var bar_center := _bar_y + BAR_H * 0.5
	var in_zone := absf(fish_center - bar_center) <= BAR_H * 0.5
	if in_zone:
		_progress += delta * lerpf(0.55, 0.34, _difficulty)
	else:
		_progress -= delta * lerpf(0.30, 0.52, _difficulty)
	_progress = clampf(_progress, 0.0, 1.0)
	if _progress >= 1.0:
		_finish(true)
	elif _progress <= 0.0:
		_finish(false)


func _refresh_visuals() -> void:
	_bar.position.y = _bar_y
	_fish_marker.position.y = _fish_y
	var h := _progress * TRACK_H
	_progress_fill.size = Vector2(_progress_fill.size.x, h)
	_progress_fill.position.y = TRACK_H - h
	var sh := _stamina * TRACK_H
	_stamina_fill.size = Vector2(_stamina_fill.size.x, sh)
	_stamina_fill.position.y = TRACK_H - sh


func _finish(win: bool) -> void:
	active = false
	visible = false
	set_process(false)
	if win:
		Inventory.add_item(target, 1)
		AudioManager.play_sfx("fish")
		_title.text = "Pescou!"
	else:
		AudioManager.play_sfx("water", -6.0)
	emit_signal("finished", win, target)


## Cancela a pescaria sem conceder item (ex.: ao pausar o jogo).
func cancel() -> void:
	active = false
	visible = false
	set_process(false)


# --- UI --------------------------------------------------------------------

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = root

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var frame := PanelContainer.new()
	center.add_child(frame)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 0.92)
	sb.border_color = Color(0.35, 0.4, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(10)
	frame.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 12)
	box.add_child(_title)

	var rule := TextureRect.new()
	rule.texture = RULE_TEX
	rule.custom_minimum_size = Vector2(120, 2)
	rule.stretch_mode = TextureRect.STRETCH_SCALE
	box.add_child(rule)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	row.add_child(_make_stamina())
	row.add_child(_make_track())
	row.add_child(_make_progress())

	var hint := Label.new()
	hint.text = "Segure Espaco para subir"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	box.add_child(hint)


func _make_track() -> Control:
	_track = Control.new()
	_track.custom_minimum_size = Vector2(TRACK_W, TRACK_H)
	_track.clip_contents = true
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := TextureRect.new()
	bg.texture = FRAME_TEX
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(bg)

	var guide := TextureRect.new()
	guide.texture = GUIDE_TEX
	guide.modulate = Color(1, 1, 1, 0.22)
	guide.size = Vector2(8, TRACK_H)
	guide.position = Vector2((TRACK_W - 8.0) * 0.5, 0)
	guide.stretch_mode = TextureRect.STRETCH_SCALE
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(guide)

	_bar = TextureRect.new()
	_bar.texture = BAR_TEX
	_bar.size = Vector2(TRACK_W - 4.0, BAR_H)
	_bar.position = Vector2(2, 0)
	_bar.stretch_mode = TextureRect.STRETCH_SCALE
	_bar.modulate = Color(1, 1, 1, 0.85)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(_bar)

	_fish_marker = TextureRect.new()
	_fish_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_fish_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(_fish_marker)
	return _track


func _make_progress() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(16, TRACK_H)
	wrap.clip_contents = true
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := TextureRect.new()
	bg.texture = PROGRESS_BG_TEX
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(bg)

	_progress_fill = TextureRect.new()
	_progress_fill.texture = PROGRESS_TEX
	_progress_fill.size = Vector2(16, TRACK_H * 0.5)
	_progress_fill.position = Vector2(0, TRACK_H * 0.5)
	_progress_fill.stretch_mode = TextureRect.STRETCH_SCALE
	_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(_progress_fill)
	return wrap


func _make_stamina() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(14, TRACK_H)
	wrap.clip_contents = true
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.06, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(bg)

	_stamina_fill = TextureRect.new()
	_stamina_fill.texture = STAMINA_TEX
	_stamina_fill.size = Vector2(14, TRACK_H)
	_stamina_fill.stretch_mode = TextureRect.STRETCH_SCALE
	_stamina_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(_stamina_fill)
	return wrap
