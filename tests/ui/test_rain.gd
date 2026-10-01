class_name TestRain
extends SimTestSuite

## Cobertura de `scripts/rain.gd`: visibilidade segue clima e splash cap.

func _make_rain() -> Variant:
	var r: Node = auto_free(load("res://scripts/rain.gd").new())
	add_child(r)
	await_idle_frame()
	return r


func test_visivel_quando_chove() -> void:
	var r: Variant = _make_rain()
	Weather.kind = Enums.Weather.CLEAR
	Weather.changed.emit(Enums.Weather.CLEAR)
	assert_that(r.visible).is_false()
	Weather.kind = Enums.Weather.RAIN
	Weather.changed.emit(Enums.Weather.RAIN)
	assert_that(r.visible).is_true()


func test_splash_cap() -> void:
	var r: Variant = _make_rain()
	# _spawn_splash adiciona splash; cap em 48.
	for i in range(60):
		r.call("_spawn_splash", 10.0, 10.0)
	assert_that(r._splashes.size()).is_less_equal(48)