class_name TestMachine
extends SimTestSuite

## Cobertura de `scripts/machine.gd`: setup por tipo, offsets e frames.

func _make_machine() -> Machine:
	return auto_free(Machine.new())

func test_setup_aspersor() -> void:
	var m := _make_machine()
	m.setup(Enums.Machine.SPRINKLER, Vector2i(1, 1))
	assert_that(m.kind).is_equal(Enums.Machine.SPRINKLER)
	assert_that(m.cell).is_equal(Vector2i(1, 1))
	assert_that(m._offset_for(Enums.Machine.SPRINKLER)).is_equal(Vector2(0, -8))


func test_setup_espantalho() -> void:
	var m := _make_machine()
	m.setup(Enums.Machine.SCARECROW, Vector2i(2, 2))
	assert_that(m.kind).is_equal(Enums.Machine.SCARECROW)
	assert_that(m._offset_for(Enums.Machine.SCARECROW)).is_equal(Vector2(0, -16))


func test_setup_pescador() -> void:
	var m := _make_machine()
	m.setup(Enums.Machine.FISHER, Vector2i(3, 3))
	assert_that(m.kind).is_equal(Enums.Machine.FISHER)
	assert_that(m._offset_for(Enums.Machine.FISHER)).is_equal(Vector2(0, -24))


func test_frames_por_tipo() -> void:
	var m := _make_machine()
	# Cada tipo crea una animacion "idle" con frames.
	assert_that(m._frames_for(Enums.Machine.SPRINKLER).has_animation("idle")).is_true()
	assert_that(m._frames_for(Enums.Machine.SCARECROW).has_animation("idle")).is_true()
	assert_that(m._frames_for(Enums.Machine.FISHER).has_animation("idle")).is_true()


func test_to_dict() -> void:
	var m := _make_machine()
	m.setup(Enums.Machine.SPRINKLER, Vector2i(4, 5))
	var d := m.to_dict()
	assert_that(d["cell"]).is_equal([4, 5])
	assert_that(int(d["kind"])).is_equal(Enums.Machine.SPRINKLER)