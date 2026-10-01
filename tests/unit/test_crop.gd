class_name TestCrop
extends SimTestSuite

## Cobertura de `scripts/crop.gd`: regar, crescer, colher e serializar.
##
## Nota de comportamento: uma vez `is_ready`, `grow_day` não avança mais dias
## nem estado (a colheita deve ser realizada).

func _make_crop(seed: int = Enums.Seed.TOMATO) -> Crop:
	var c: Crop = auto_free(Crop.new())
	c.setup(seed, Vector2i.ZERO)
	return c


func test_sprite_region_sigue_estado() -> void:
	var c := _make_crop(Enums.Seed.TOMATO)
	c.setup(Enums.Seed.TOMATO, Vector2i(3, 4))
	assert_that(c.seed_type).is_equal(Enums.Seed.TOMATO)
	assert_that(c.cell).is_equal(Vector2i(3, 4))
	assert_that(c.stage).is_equal(0)
	assert_that(c.is_ready).is_false()


func test_crece_solo_mojada() -> void:
	var c := _make_crop(Enums.Seed.TOMATO)
	c.grow_day()
	assert_that(c.days_grown).is_equal(0)
	c.water()
	c.grow_day()
	assert_that(c.days_grown).is_equal(1)
	assert_that(c.watered).is_false()
	assert_that(c.is_ready).is_false()


func test_auto_water_por_lluvia() -> void:
	var c := _make_crop(Enums.Seed.TOMATO)
	c.grow_day(true)
	assert_that(c.days_grown).is_equal(1)


func test_teto_de_estado_3() -> void:
	# Abóbora leva 4 dias: o estado (sprite) chega a 3 e aí fica
	# (4º dia marca is_ready).
	var c := _make_crop(Enums.Seed.PUMPKIN)
	for i in range(6):
		c.water()
		c.grow_day()
	assert_that(c.stage).is_equal(3)
	assert_that(c.days_grown).is_equal(4)
	assert_that(c.is_ready).is_true()


func test_is_ready_y_cosecha() -> void:
	var c := _make_crop(Enums.Seed.PUMPKIN)  # grow_days = 4
	assert_that(c.harvest()).is_equal(-1)
	for i in range(3):
		c.water()
		c.grow_day()
	assert_that(c.is_ready).is_false()
	assert_that(c.harvest()).is_equal(-1)
	c.water()
	c.grow_day()
	assert_that(c.is_ready).is_true()
	# Colher entrega o item de recompensa da semente.
	assert_that(c.harvest()).is_equal(int(GameData.crops[Enums.Seed.PUMPKIN]["reward"]))
	# Uma vez pronta, crescer não avança mais dias.
	var dias := c.days_grown
	c.water()
	c.grow_day()
	assert_that(c.days_grown).is_equal(dias)


func test_restore_y_to_dict() -> void:
	var c := _make_crop(Enums.Seed.WHEAT)
	c.setup(Enums.Seed.WHEAT, Vector2i(9, 8))
	c.water()
	c.grow_day()
	assert_that(c.days_grown).is_equal(1)
	var data := c.to_dict()
	assert_that(int(data["seed"])).is_equal(Enums.Seed.WHEAT)
	assert_that(int(data["stage"])).is_equal(1)
	assert_that(int(data["days_grown"])).is_equal(1)
	assert_that(bool(data["watered"])).is_false()
	assert_that(bool(data["is_ready"])).is_false()
	assert_that(data["cell"]).is_equal([9, 8])

	var d: Crop = auto_free(Crop.new())
	d.setup(Enums.Seed.TOMATO, Vector2i.ZERO)
	d.restore(data)
	# Contrato atual de restore(): recupera o estado de crescimento, mas
	# seed_type/cell vêm do spawn (world._spawn_crop) que os injeta.
	assert_that(d.stage).is_equal(1)
	assert_that(d.days_grown).is_equal(1)
	assert_that(d.watered).is_false()
	assert_that(d.is_ready).is_false()
	assert_that(d.seed_type).is_equal(Enums.Seed.TOMATO)
	assert_that(d.cell).is_equal(Vector2i.ZERO)