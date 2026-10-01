class_name TestWeather
extends SimTestSuite

## Cobertura de `scripts/weather.gd`: sorteio, estado, nome e reação ao
## mudança de dia.

func test_estado_inicial() -> void:
	assert_that(Weather.kind).is_equal(Enums.Weather.CLEAR)
	assert_that(Weather.is_raining()).is_false()
	assert_that(Weather.name_string()).is_equal("Limpo")


func test_roll_solo_clear_o_rain() -> void:
	for i in range(100):
		Weather.roll()
		assert_that(Weather.kind).is_in([Enums.Weather.CLEAR, Enums.Weather.RAIN])


func test_estado_lluvia() -> void:
	Weather.kind = Enums.Weather.RAIN
	assert_that(Weather.is_raining()).is_true()
	assert_that(Weather.name_string()).is_equal("Chuvoso")


func test_signal_changed_en_roll() -> void:
	var ultimo := [-1]
	var cuenta := [0]
	Weather.changed.connect(func(k: int) -> void:
		ultimo[0] = k
		cuenta[0] += 1
	)
	Weather.roll()
	assert_that(cuenta[0]).is_equal(1)
	assert_that(ultimo[0]).is_in([Enums.Weather.CLEAR, Enums.Weather.RAIN])


func test_nuevo_dia_reroll() -> void:
	# new_day -> _on_new_day -> roll(): el clima cambia o permanece, pero
	# siempre dentro de los valores validos.
	var cuenta := [0]
	Weather.changed.connect(func(k: int) -> void: cuenta[0] += 1)
	TimeManager.new_day.emit(2)
	TimeManager.new_day.emit(3)
	assert_that(Weather.kind).is_in([Enums.Weather.CLEAR, Enums.Weather.RAIN])
	assert_that(cuenta[0]).is_equal(2)