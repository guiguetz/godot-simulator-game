class_name TestDecorMode
extends SimTestSuite

## Cobertura de `scripts/decor.gd`: toggle, open, close e seleção.

func _make_decor() -> Variant:
	var d: Node = auto_free(load("res://scripts/decor.gd").new())
	add_child(d)
	await_idle_frame()
	return d


func test_toggle() -> void:
	var d: Variant = _make_decor()
	assert_that(d.active).is_false()
	d.call("toggle")
	assert_that(d.active).is_true()
	assert_that(d.visible).is_true()
	d.call("toggle")
	assert_that(d.active).is_false()
	assert_that(d.visible).is_false()


func test_open_close() -> void:
	var d: Variant = _make_decor()
	d.call("open")
	assert_that(d.active).is_true()
	d.call("close")
	assert_that(d.active).is_false()


func test_select() -> void:
	var d: Variant = _make_decor()
	d.call("_select", 3)
	assert_that(d._selected).is_equal(3)
	d.call("_select", -1)
	assert_that(d._selected).is_equal(-1)