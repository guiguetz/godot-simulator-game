extends CanvasLayer

## Loja simples: compra sementes com moedas e vende todos os itens.
## Aberta pelo menu de pausa (scripts/pause_menu.gd).

var _back: Callable = Callable()
var _list: VBoxContainer
var _coins_label: Label


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func setup(back: Callable) -> void:
	_back = back


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func _build() -> void:
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
		margin.add_theme_constant_override("margin_%s" % side, 22)
	frame.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Loja"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	_coins_label = Label.new()
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_coins_label)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	box.add_child(_list)

	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(230, 0)
	back.pressed.connect(_on_back)
	box.add_child(back)


func _on_back() -> void:
	close()
	if _back.is_valid():
		_back.call()


func _refresh() -> void:
	_coins_label.text = "Moedas: %d" % Inventory.coins
	for child in _list.get_children():
		child.queue_free()

	_add_section("Sementes")
	for seed in Inventory.SEED_ORDER:
		var price: int = GameData.seed_prices[seed]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var label := Label.new()
		label.text = "%s — %d moedas (tem %d)" % [
			GameData.seed_name(seed), price, Inventory.seed_count(seed)
		]
		label.custom_minimum_size = Vector2(190, 0)
		row.add_child(label)
		var buy := Button.new()
		buy.text = "Comprar"
		buy.disabled = Inventory.coins < price
		buy.pressed.connect(func() -> void: _buy_seed(seed, price))
		row.add_child(buy)
		_list.add_child(row)

	_add_section("Vender")
	var sell := Button.new()
	sell.text = "Vender tudo (+%d moedas)" % _sell_total()
	sell.disabled = _sell_total() <= 0
	sell.pressed.connect(_sell_all)
	_list.add_child(sell)


func _add_section(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	_list.add_child(l)


func _buy_seed(seed: int, price: int) -> void:
	if Inventory.spend_coins(price):
		Inventory.add_seed(seed, 1)
		_refresh()


func _sell_total() -> int:
	var total := 0
	for item in GameData.items:
		total += Inventory.count(item) * GameData.item_value(item)
	return total


func _sell_all() -> void:
	var total := 0
	for item in GameData.items:
		var n := Inventory.count(item)
		if n > 0:
			total += n * GameData.item_value(item)
			Inventory.remove_item(item, n)
	if total > 0:
		Inventory.add_coins(total)
	_refresh()
