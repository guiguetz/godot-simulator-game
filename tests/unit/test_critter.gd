class_name TestCritter
extends SimTestSuite

## Cobertura de `scripts/critter.gd`: parâmetros por tipo, frames, orientação
## e retorno para casa.

var _liberados: Array = []


func after_test() -> void:
	# Os critters que viveram na árvore são liberados aqui para não deixar
	# nós órfãos (a suíte retém filhos entre casos).
	for c in _liberados:
		if is_instance_valid(c):
			c.queue_free()
	_liberados.clear()


func _em_arvore(kind: int) -> Critter:
	var c := Critter.new()
	add_child(c)
	c.setup(kind, Vector2(100, 100))
	_liberados.append(c)
	return c


func test_parametros_por_tipo() -> void:
	var gato := Critter.new()
	gato.setup(Critter.Kind.CAT, Vector2.ZERO)
	assert_that(gato.speed).is_equal_approx(62.0, 0.01)
	assert_that(gato.wander_radius).is_equal_approx(40.0, 0.01)
	gato.free()

	var raton := Critter.new()
	raton.setup(Critter.Kind.MOUSE, Vector2.ZERO)
	assert_that(raton.speed).is_equal_approx(46.0, 0.01)
	assert_that(raton.wander_radius).is_equal_approx(44.0, 0.01)
	raton.free()

	var mujer := Critter.new()
	mujer.setup(Critter.Kind.WOMAN, Vector2.ZERO)
	assert_that(mujer.speed).is_equal_approx(24.0, 0.01)
	assert_that(mujer.wander_radius).is_equal_approx(70.0, 0.01)
	mujer.free()

	var slime := Critter.new()
	slime.setup(Critter.Kind.BLOB, Vector2.ZERO)
	assert_that(slime.speed).is_equal_approx(16.0, 0.01)
	assert_that(slime.wander_radius).is_equal_approx(30.0, 0.01)
	slime.free()


func test_frames_standard_vs_blob() -> void:
	var gato := Critter.new()
	gato.setup(Critter.Kind.CAT, Vector2.ZERO)
	var standard := gato._frames_for(Critter.Kind.CAT)
	assert_that(standard.has_animation("idle_down")).is_true()
	assert_that(standard.has_animation("idle_up")).is_true()
	assert_that(standard.has_animation("idle_left")).is_true()
	assert_that(standard.has_animation("idle_right")).is_true()
	assert_that(standard.has_animation("walk_left")).is_true()
	gato.free()

	var blob := Critter.new()
	blob.setup(Critter.Kind.BLOB, Vector2.ZERO)
	var bframes := blob._frames_for(Critter.Kind.BLOB)
	assert_that(bframes.has_animation("idle_down")).is_true()
	assert_that(bframes.has_animation("idle_right")).is_true()
	assert_that(bframes.has_animation("walk_up")).is_true()
	blob.free()


func test_face_direcciones() -> void:
	var c := Critter.new()
	c.setup(Critter.Kind.CAT, Vector2.ZERO)
	assert_that(c._face(Vector2(1, 0))).is_equal("right")
	assert_that(c._face(Vector2(-5, 0.5))).is_equal("left")
	assert_that(c._face(Vector2(0.2, 1))).is_equal("down")
	assert_that(c._face(Vector2(0.1, -3))).is_equal("up")
	# Vector nulo: ninguna direccion dominante -> arriba (por el else final).
	assert_that(c._face(Vector2.ZERO)).is_equal("up")
	c.free()


func test_vuelve_a_casa_cuando_se_aleja() -> void:
	var c := _em_arvore(Critter.Kind.CAT)
	c.home = Vector2(500, 500)
	c.global_position = Vector2(10000, 10000)
	c._process(0.016)
	assert_that(c.global_position).is_equal(c.home)