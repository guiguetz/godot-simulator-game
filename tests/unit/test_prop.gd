class_name TestProp
extends SimTestSuite

## Cobertura de `scripts/prop.gd`: a árvore em dois golpes (tronco depois corte).

func _make_tree() -> Prop:
	return auto_free(Prop.new())

func test_setup_arbol() -> void:
	var p := _make_tree()
	p.setup_tree(Vector2i(5, 6))
	assert_that(p.kind).is_equal(Prop.Kind.TREE)
	assert_that(p.cell).is_equal(Vector2i(5, 6))


func test_primer_golpe_vira_tronco() -> void:
	var p := _make_tree()
	p.setup_tree(Vector2i(5, 6))
	var r: Dictionary = p.chop()
	assert_that(int(r["wood"])).is_equal(2)
	assert_that(bool(r["removed"])).is_false()
	assert_that(p.kind).is_equal(Prop.Kind.STUMP)


func test_segundo_golpe_quita() -> void:
	var p := _make_tree()
	p.setup_tree(Vector2i(5, 6))
	p.chop()
	var r: Dictionary = p.chop()
	assert_that(int(r["wood"])).is_equal(1)
	assert_that(bool(r["removed"])).is_true()


func test_to_dict() -> void:
	var p := _make_tree()
	p.setup_tree(Vector2i(5, 6))
	var d := p.to_dict()
	assert_that(d["cell"]).is_equal([5, 6])
	assert_that(int(d["kind"])).is_equal(int(Prop.Kind.TREE))
	assert_that(bool(d["tree"])).is_true()