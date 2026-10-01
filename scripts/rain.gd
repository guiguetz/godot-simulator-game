extends Node2D

## Overlay de chuva, em coordenadas de mundo, seguindo a camera.
## So aparece quando Weather.is_raining().
##
## Usa assets/graphics/weather/drops.png (respingo) e floor.png (poca),
## alem das linhas desenhadas em codigo.

const DROP_COUNT := 160
const LENGTH := 7.0
const SPLASH_TEX := preload("res://assets/graphics/weather/drops.png")
const PUDDLE_TEX := preload("res://assets/graphics/weather/floor.png")

var _drops := []
var _splashes := []
var _puddles := []
var _view := Vector2(640, 360)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 100
	_view = get_viewport().get_visible_rect().size
	_rng.randomize()
	for i in range(DROP_COUNT):
		_drops.append([_rng.randf() * _view.x, _rng.randf() * _view.y, _rng.randf_range(180.0, 320.0)])
	for i in range(10):
		_puddles.append(Vector2(_rng.randf() * _view.x, _rng.randf() * _view.y))
	visible = Weather.is_raining()
	Weather.changed.connect(func(kind: int) -> void: visible = kind == Enums.Weather.RAIN)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		global_position = cam.get_screen_center_position() - _view * 0.5
	if not visible:
		return
	for d in _drops:
		d[1] += d[2] * delta
		if d[1] > _view.y + LENGTH:
			_spawn_splash(d[0], d[1] - LENGTH)
			d[1] = -LENGTH
			d[0] = _rng.randf() * _view.x
	for i in range(_splashes.size() - 1, -1, -1):
		_splashes[i][2] -= delta * 2.6
		if _splashes[i][2] <= 0.0:
			_splashes.remove_at(i)
	queue_redraw()


func _spawn_splash(x: float, y: float) -> void:
	if _splashes.size() >= 48:
		_splashes.pop_front()
	_splashes.append([x, y, 1.0])


func _draw() -> void:
	# Pocas no chao (estaticas na tela, seguem a camera).
	for p in _puddles:
		draw_texture_rect(PUDDLE_TEX, Rect2(p - PUDDLE_TEX.get_size() * 0.5, PUDDLE_TEX.get_size()), false, Color(1, 1, 1, 0.18))
	# Respingos.
	for s in _splashes:
		var a: float = s[2]
		var size := SPLASH_TEX.get_size() * (1.0 + (1.0 - a) * 0.8)
		draw_texture_rect(SPLASH_TEX, Rect2(Vector2(s[0], s[1]) - size * 0.5, size), false, Color(1, 1, 1, a * 0.6))
	# Linhas de chuva.
	var color := Color(0.72, 0.82, 1.0, 0.45)
	for d in _drops:
		draw_line(Vector2(d[0], d[1]), Vector2(d[0] - 1.0, d[1] + LENGTH), color, 1.0)
