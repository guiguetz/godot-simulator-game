class_name TestTimeManager
extends SimTestSuite

## Cobertura de `scripts/time_manager.gd`: hora, dia, daylight, pausa e
## serialização.
##
## O relógio avança em tempo real entre frames; esta suíte congela o relógio
## (paused = true) para que as asserções de `minutes`/`time_string` sejam
## determinísticas.


func before_test() -> void:
	SimTestSuite.reset_state()
	TimeManager.paused = true


func test_estado_inicial() -> void:
	SimTestSuite.reset_time()
	assert_that(TimeManager.day).is_equal(1)
	assert_that(TimeManager.minutes).is_equal_approx(360.0, 0.01)
	assert_that(TimeManager.get_hour()).is_equal(6)
	assert_that(TimeManager.get_minute()).is_equal(0)
	assert_that(TimeManager.time_string()).is_equal("06:00")


func test_hora_y_minuto() -> void:
	TimeManager.minutes = 6.0 * 60.0 + 30.0
	assert_that(TimeManager.get_hour()).is_equal(6)
	assert_that(TimeManager.get_minute()).is_equal(30)
	assert_that(TimeManager.time_string()).is_equal("06:30")
	TimeManager.minutes = 23.0 * 60.0 + 59.0
	assert_that(TimeManager.time_string()).is_equal("23:59")


# --- Daylight ---------------------------------------------------------------

func test_daylight_nocturno() -> void:
	TimeManager.minutes = 3.0 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(0.0, 0.001)
	TimeManager.minutes = 4.99 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(0.0, 0.001)


func test_daylight_amanecer() -> void:
	TimeManager.minutes = 5.0 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(0.0, 0.001)
	TimeManager.minutes = 6.5 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(0.5, 0.002)
	TimeManager.minutes = 7.0 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(2.0 / 3.0, 0.002)


func test_daylight_pleno() -> void:
	TimeManager.minutes = 12.0 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(1.0, 0.001)
	TimeManager.minutes = 17.99 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(1.0, 0.001)


func test_daylight_atardecer() -> void:
	TimeManager.minutes = 18.0 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(1.0, 0.001)
	TimeManager.minutes = 19.5 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(0.5, 0.002)
	TimeManager.minutes = 21.0 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(0.0, 0.001)
	TimeManager.minutes = 23.0 * 60.0
	assert_that(TimeManager.daylight()).is_equal_approx(0.0, 0.001)


# --- Relógio / pausa / virada do dia ------------------------------------------

func test_pausa_congela_reloj() -> void:
	TimeManager.minutes = 12.0 * 60.0
	TimeManager.paused = true
	TimeManager._process(60.0)
	assert_that(TimeManager.minutes).is_equal_approx(12.0 * 60.0, 0.001)


func test_sin_pausa_avanza() -> void:
	TimeManager.minutes = 12.0 * 60.0
	TimeManager.paused = false
	TimeManager._process(1.0)
	assert_that(TimeManager.minutes).is_greater(12.0 * 60.0)
	TimeManager.paused = true


func test_new_day_al_virar() -> void:
	var dias := [0]
	TimeManager.new_day.connect(func(d: int) -> void: dias[0] = d)
	TimeManager.day = 1
	TimeManager.minutes = TimeManager.MINUTES_PER_DAY - 2.0
	TimeManager.paused = false
	TimeManager._process(1.0)
	assert_that(dias[0]).is_greater(1)
	assert_that(TimeManager.day).is_equal(2)
	assert_that(TimeManager.minutes).is_less(1.0)
	TimeManager.paused = true


func test_serializacion_roundtrip() -> void:
	TimeManager.day = 7
	TimeManager.minutes = 13.0 * 60.0 + 20.0
	var data := TimeManager.to_dict()
	TimeManager.day = 1
	TimeManager.minutes = 360.0
	TimeManager.from_dict(data)
	assert_that(TimeManager.day).is_equal(7)
	assert_that(TimeManager.minutes).is_equal_approx(13.0 * 60.0 + 20.0, 0.001)