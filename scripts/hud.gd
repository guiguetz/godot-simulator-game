extends CanvasLayer

## HUD: hotbar de ferramentas/maquinas, moedas, semente selecionada,
## relogio/dia/clima e lista de itens. Montado em codigo.

var _slot_panels: Array = []
var _slot_icons: Array = []
var _slot_counts: Array = []
var _seed_label: Label
var _clock_label: Label
var _coins_label: Label
var _items_label: Label


func _ready() -> void:
	layer = 20
	_build()
	Inventory.changed.connect(_refresh)
	TimeManager.time_changed.connect(func(_h: int, _m: int) -> void: _refresh_clock())
	TimeManager.new_day.connect(func(_d: int) -> void: _refresh_clock())
	Weather.changed.connect(func(_k: int) -> void: _refresh_clock())
	_refresh()
	_refresh_clock()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Hotbar (rodape, centro) ---
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	center.offset_top = -58
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	center.add_child(bar)

	for i in range(GameData.hotbar.size()):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(34, 34)
		bar.add_child(panel)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(26, 26)
		panel.add_child(icon)
		var count := Label.new()
		count.add_theme_font_size_override("font_size", 9)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		icon.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_slot_panels.append(panel)
		_slot_icons.append(icon)
		_slot_counts.append(count)

	# --- Info (canto sup. esq.) ---
	var info := VBoxContainer.new()
	info.position = Vector2(8, 6)
	info.add_theme_constant_override("separation", 2)
	root.add_child(info)

	_coins_label = _make_label(11)
	_seed_label = _make_label(10)
	_items_label = _make_label(10)
	info.add_child(_coins_label)
	info.add_child(_seed_label)
	info.add_child(_items_label)

	# --- Relogio (canto sup. dir.) ---
	_clock_label = _make_label(11)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_clock_label.offset_left = -190
	_clock_label.offset_right = -8
	_clock_label.offset_top = 6
	root.add_child(_clock_label)


func _make_label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 3)
	return l


func _refresh() -> void:
	for i in range(_slot_panels.size()):
		var entry: Dictionary = GameData.hotbar[i]
		_slot_icons[i].texture = entry.get("icon")
		var count_text := ""
		if entry.get("kind") == "tool" and int(entry.get("id", -1)) == Enums.Tool.SEED:
			count_text = "x%d" % Inventory.seed_count(Inventory.selected_seed)
		_slot_counts[i].text = count_text
		var selected := i == Inventory.selected_slot
		_slot_panels[i].add_theme_stylebox_override("panel", _slot_style(selected))

	_coins_label.text = "Moedas: %d" % Inventory.coins
	_seed_label.text = "Semente: %s x%d" % [
		GameData.seed_name(Inventory.selected_seed),
		Inventory.seed_count(Inventory.selected_seed),
	]
	_items_label.text = _items_summary()


func _items_summary() -> String:
	var parts: Array = []
	for item in GameData.items:
		var n := Inventory.count(item)
		if n > 0:
			parts.append("%s %d" % [GameData.item_name(item), n])
	return "Itens: " + (", ".join(parts) if not parts.is_empty() else "—")


func _refresh_clock() -> void:
	_clock_label.text = "Dia %d  %s  %s" % [
		TimeManager.day, TimeManager.time_string(), Weather.name_string()
	]


func _slot_style(selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.14, 0.85)
	sb.border_color = Color(1.0, 0.85, 0.25) if selected else Color(0.25, 0.25, 0.3)
	sb.set_border_width_all(2 if selected else 1)
	sb.set_corner_radius_all(3)
	return sb


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9:
			Inventory.set_slot(k - KEY_1)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			Inventory.set_slot(Inventory.selected_slot - 1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			Inventory.set_slot(Inventory.selected_slot + 1)
	elif event.is_action_pressed("tool_next"):
		Inventory.set_slot(Inventory.selected_slot + 1)
	elif event.is_action_pressed("tool_prev"):
		Inventory.set_slot(Inventory.selected_slot - 1)
	elif event.is_action_pressed("seed_next"):
		Inventory.seed_next()
