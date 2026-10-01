class_name TestSettings
extends SimTestSuite

## Cobertura de `scripts/settings.gd`: tabela-verdade de `is_running`,
## clamps de modo/skin e persistência em user://settings.cfg.

func test_tabla_verdad_caminar() -> void:
	GameSettings.movement_mode = GameSettings.MovementMode.WALK
	assert_that(GameSettings.is_running(false)).is_false()
	assert_that(GameSettings.is_running(true)).is_true()


func test_tabla_verdad_correr() -> void:
	GameSettings.movement_mode = GameSettings.MovementMode.RUN
	assert_that(GameSettings.is_running(false)).is_true()
	assert_that(GameSettings.is_running(true)).is_false()


func test_set_movement_mode_clamp() -> void:
	GameSettings.movement_mode = GameSettings.MovementMode.WALK
	GameSettings.set_movement_mode(99)
	assert_that(GameSettings.movement_mode).is_equal(GameSettings.MovementMode.RUN)
	GameSettings.set_movement_mode(-10)
	assert_that(GameSettings.movement_mode).is_equal(GameSettings.MovementMode.WALK)


func test_set_skin_clamp() -> void:
	GameSettings.skin = 0
	GameSettings.set_skin(2)
	assert_that(GameSettings.skin).is_equal(2)
	GameSettings.set_skin(-1)
	assert_that(GameSettings.skin).is_equal(2)
	GameSettings.set_skin(GameSettings.SKIN_COUNT)
	assert_that(GameSettings.skin).is_equal(2)


func test_persistencia_en_disco() -> void:
	# SimTestSuite ya limpio/restaura user://settings.cfg alrededor del caso.
	GameSettings.set_movement_mode(GameSettings.MovementMode.RUN)
	GameSettings.set_skin(3)
	# Forçamos recarga do disco (como ao iniciar o jogo).
	GameSettings.movement_mode = GameSettings.MovementMode.WALK
	GameSettings.skin = 0
	GameSettings._load_config()
	assert_that(GameSettings.movement_mode).is_equal(GameSettings.MovementMode.RUN)
	assert_that(GameSettings.skin).is_equal(3)