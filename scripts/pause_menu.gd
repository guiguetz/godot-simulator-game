extends CanvasLayer

## Menu de pausa (Esc). A UI e montada em codigo para manter o placeholder
## simples. Estrutura: Pausado > Opcoes > Jogabilidade (Andar/Correr).

var _menu_panel: VBoxContainer
var _options_panel: VBoxContainer
var _gameplay_panel: VBoxContainer
var _appearance_panel: VBoxContainer
var _mode_option: OptionButton
var _skin_buttons: Array = []


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false
	var shop := get_parent().get_node_or_null("Shop")
	if shop != null and shop.has_method("setup"):
		shop.setup(func() -> void:
			visible = true
			_show_panel(_menu_panel))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if visible:
			close_menu()
		else:
			open_menu()


func open_menu() -> void:
	_close_overlays()
	visible = true
	get_tree().paused = true
	_show_panel(_menu_panel)


## Fecha minigames/overlays que poderiam continuar rodando ao pausar.
func _close_overlays() -> void:
	var fishing := get_tree().get_first_node_in_group("fishing")
	if fishing != null and fishing.active:
		fishing.cancel()
	var decor := get_tree().get_first_node_in_group("decor")
	if decor != null and decor.active:
		decor.close()


func close_menu() -> void:
	visible = false
	get_tree().paused = false


func _show_panel(panel: Control) -> void:
	_menu_panel.visible = panel == _menu_panel
	_options_panel.visible = panel == _options_panel
	_gameplay_panel.visible = panel == _gameplay_panel
	_appearance_panel.visible = panel == _appearance_panel
	if _gameplay_panel.visible and _mode_option != null:
		_mode_option.selected = GameSettings.movement_mode
	if _appearance_panel.visible:
		_refresh_skin_buttons()


# --- Construcao da UI ------------------------------------------------------

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.04, 0.07, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var frame := PanelContainer.new()
	center.add_child(frame)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 28)
	frame.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	_menu_panel = _make_menu_panel()
	_options_panel = _make_options_panel()
	_gameplay_panel = _make_gameplay_panel()
	_appearance_panel = _make_appearance_panel()
	box.add_child(_menu_panel)
	box.add_child(_options_panel)
	box.add_child(_gameplay_panel)
	box.add_child(_appearance_panel)


func _make_menu_panel() -> VBoxContainer:
	var v := _make_panel()
	v.add_child(_make_title("Pausado"))
	v.add_child(_make_button("Retomar", close_menu))
	v.add_child(_make_button("Loja", _open_shop))
	v.add_child(_make_button("Salvar", _save_game))
	var load_btn := _make_button("Carregar", _load_game)
	load_btn.disabled = not SaveGame.has_save()
	v.add_child(load_btn)
	v.add_child(_make_button("Opcoes", func() -> void: _show_panel(_options_panel)))
	v.add_child(_make_button("Sair do jogo", func() -> void: get_tree().quit()))
	v.visible = true
	return v


func _open_shop() -> void:
	var shop := get_parent().get_node_or_null("Shop")
	if shop == null:
		return
	visible = false
	shop.open()


func _save_game() -> void:
	SaveGame.save_game()


func _load_game() -> void:
	SaveGame.load_game()
	close_menu()


func _make_options_panel() -> VBoxContainer:
	var v := _make_panel()
	v.add_child(_make_title("Opcoes"))
	v.add_child(_make_button("Jogabilidade", func() -> void: _show_panel(_gameplay_panel)))
	v.add_child(_make_button("Aparencia", func() -> void: _show_panel(_appearance_panel)))
	v.add_child(_make_button("Voltar", func() -> void: _show_panel(_menu_panel)))
	v.visible = false
	return v


func _make_gameplay_panel() -> VBoxContainer:
	var v := _make_panel()
	v.add_child(_make_title("Jogabilidade"))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = "Modo padrao:"
	row.add_child(label)

	_mode_option = OptionButton.new()
	_mode_option.add_item("Andar (Shift corre)", GameSettings.MovementMode.WALK)
	_mode_option.add_item("Correr (Shift anda)", GameSettings.MovementMode.RUN)
	_mode_option.selected = GameSettings.movement_mode
	_mode_option.item_selected.connect(func(index: int) -> void: GameSettings.set_movement_mode(index))
	row.add_child(_mode_option)
	v.add_child(row)

	var hint := Label.new()
	hint.text = "Segure Shift para alternar o modo."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	v.add_child(hint)

	v.add_child(_make_button("Voltar", func() -> void: _show_panel(_options_panel)))
	v.visible = false
	return v


func _make_appearance_panel() -> VBoxContainer:
	var v := _make_panel()
	v.add_child(_make_title("Aparencia"))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)

	for i in range(GameData.SKIN_FRAMES.size()):
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 40)
		b.icon = _skin_icon(i)
		b.expand_icon = true
		b.tooltip_text = GameData.SKIN_NAMES[i]
		b.pressed.connect(func() -> void: _choose_skin(i))
		row.add_child(b)
		_skin_buttons.append(b)

	var hint := Label.new()
	hint.text = "Escolha o visual do personagem."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	v.add_child(hint)

	v.add_child(_make_button("Voltar", func() -> void: _show_panel(_options_panel)))
	v.visible = false
	return v


func _choose_skin(index: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("apply_skin"):
		player.call("apply_skin", index)
	_refresh_skin_buttons()


func _refresh_skin_buttons() -> void:
	for i in range(_skin_buttons.size()):
		(_skin_buttons[i] as Button).disabled = i == GameSettings.skin


func _skin_icon(index: int) -> Texture2D:
	var ico = GameData.SKIN_ICONS[index]
	if ico != null:
		return ico
	return GameData.SKIN_FRAMES[index].get_frame_texture("idle_down", 0)


func _make_panel() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	return v


func _make_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 22)
	return l


func _make_button(text: String, target: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(230, 0)
	b.pressed.connect(target)
	return b
