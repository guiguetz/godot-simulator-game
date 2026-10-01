extends CanvasLayer

## Modo decoracao (tecla B). Abre uma paleta de moveis; clique esquerdo
## coloca o item selecionado na celula sob o mouse, clique direito remove.
## Os nodes vivem no mundo (scripts/world.gd) e entram no savegame.
##
## Enquanto ativo, o player fica imovel/sem usar ferramentas (gating em
## scripts/player.gd via grupo "decor").

const DELETE_TEX := preload("res://assets/graphics/icons/delete.png")
const FRAME_TEX := preload("res://assets/graphics/ui/frame.png")

var active := false
var _selected := 0
var _buttons: Array = []

var _panel: PanelContainer
var _hint: Label


func _ready() -> void:
	add_to_group("decor")
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false


func toggle() -> void:
	if active:
		close()
	else:
		open()


func open() -> void:
	active = true
	visible = true


func close() -> void:
	active = false
	visible = false


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_B:
			get_viewport().set_input_as_handled()
			toggle()


func _unhandled_input(event: InputEvent) -> void:
	if not active or get_tree().paused:
		return
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			world.decor_place(_selected, world.mouse_cell())
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			world.decor_remove(world.mouse_cell())
			get_viewport().set_input_as_handled()


# --- UI --------------------------------------------------------------------

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	center.offset_top = -96
	root.add_child(center)

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.13, 0.9)
	sb.border_color = Color(0.35, 0.4, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_panel.add_child(box)

	_hint = Label.new()
	_hint.text = "Modo Decoracao — esquerdo: colocar | direito: remover | B: sair"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 9)
	box.add_child(_hint)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)

	for i in range(GameData.DECOR.size()):
		var b := _make_button(_preview(GameData.DECOR[i]))
		b.pressed.connect(func() -> void: _select(i))
		row.add_child(b)
		_buttons.append(b)

	var remove := _make_button(DELETE_TEX)
	remove.pressed.connect(func() -> void: _select(-1))
	row.add_child(remove)
	_buttons.append(remove)

	_refresh()


func _select(index: int) -> void:
	_selected = index
	_refresh()


func _refresh() -> void:
	for i in range(_buttons.size()):
		var selected := i < GameData.DECOR.size() and i == _selected
		(_buttons[i] as Button).add_theme_stylebox_override("normal", _style(selected))


func _make_button(tex: Texture2D) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(42, 42)
	b.icon = tex
	b.expand_icon = true
	b.tooltip_text = ""
	b.add_theme_stylebox_override("normal", _style(false))
	return b


func _style(selected: bool) -> StyleBox:
	if selected:
		var sel := StyleBoxFlat.new()
		sel.bg_color = Color(0.12, 0.13, 0.18, 0.95)
		sel.border_color = Color(1.0, 0.85, 0.25)
		sel.set_border_width_all(2)
		sel.set_corner_radius_all(3)
		return sel
	var sb := StyleBoxTexture.new()
	sb.texture = FRAME_TEX
	sb.set_texture_margin_all(6)
	sb.modulate_color = Color(0.20, 0.22, 0.28, 1.0)
	return sb


## Preview da decoracao (primeiro frame quando o asset anima).
func _preview(entry: Dictionary) -> Texture2D:
	if entry.has("frames"):
		var at := AtlasTexture.new()
		at.atlas = entry["tex"]
		at.region = Rect2(0, 0, entry["fw"], entry["fh"])
		return at
	return entry["tex"]
