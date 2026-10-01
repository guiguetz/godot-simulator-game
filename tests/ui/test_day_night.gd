class_name TestDayNight
extends SimTestSuite

## Cobertura de `scripts/day_night.gd`: cor segue daylight.

const NOITE := Color(0.30, 0.34, 0.56)
const DIA := Color(1.0, 1.0, 1.0)


func test_cor_pleno_dia() -> void:
	var dn: Node = auto_free(load("res://scripts/day_night.gd").new())
	TimeManager.minutes = 12.0 * 60.0
	dn._process(0.0)
	assert_that(dn.color.r).is_equal_approx(DIA.r, 0.01)
	assert_that(dn.color.g).is_equal_approx(DIA.g, 0.01)
	assert_that(dn.color.b).is_equal_approx(DIA.b, 0.01)


func test_cor_noite_fechada() -> void:
	var dn: Node = auto_free(load("res://scripts/day_night.gd").new())
	TimeManager.minutes = 3.0 * 60.0
	dn._process(0.0)
	assert_that(dn.color.r).is_equal_approx(NOITE.r, 0.01)
	assert_that(dn.color.g).is_equal_approx(NOITE.g, 0.01)
	assert_that(dn.color.b).is_equal_approx(NOITE.b, 0.01)