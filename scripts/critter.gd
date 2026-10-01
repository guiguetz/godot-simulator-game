class_name Critter
extends Node2D

## Criaturas/NPCs ambientais: gato de estimacao, rato, moradora e slime.
## Usam as folhas de characters/ (frames de 48x48) com 4 direcoes.
##
## Comportamento por tipo:
##   CAT   - segue o player quando perto, senao vaga perto de casa.
##   MOUSE - foge do player quando perto.
##   WOMAN - vaga perto de casa.
##   BLOB  - vaga devagar.
##
## Nao tem colisao e nao e serializado (ambiente). Spawn em world.gd.

enum Kind { CAT, MOUSE, WOMAN, BLOB }

const CAT_TEX := preload("res://assets/graphics/characters/cat.png")
const MOUSE_TEX := preload("res://assets/graphics/characters/mouse.png")
const WOMAN_TEX := preload("res://assets/graphics/characters/woman.png")
const BLOB_TEX := preload("res://assets/graphics/characters/blob.png")

const CELL := 48
const FOLLOW_RADIUS := 120.0
const FLEE_RADIUS := 72.0

## Linha de cada direcao na folha (mapa por tipo).
const ROWS_STANDARD := {"down": 0, "up": 3, "left": 1, "right": 2}
const ROWS_BLOB := {"down": 0, "up": 1, "left": 2, "right": 3}

var kind: int = Kind.CAT
var home := Vector2.ZERO
var speed := 26.0
var wander_radius := 56.0

var _sprite: AnimatedSprite2D
var _target := Vector2.ZERO
var _timer := 0.0
var _facing := "down"
var _world: Node = null


func setup(critter_kind: int, pos: Vector2, world_ref: Node = null) -> void:
	kind = critter_kind
	home = pos
	global_position = pos
	_world = world_ref
	match kind:
		Kind.CAT:
			speed = 62.0
			wander_radius = 40.0
		Kind.MOUSE:
			speed = 46.0
			wander_radius = 44.0
		Kind.WOMAN:
			speed = 24.0
			wander_radius = 70.0
		_:
			speed = 16.0
			wander_radius = 30.0
	_sprite = AnimatedSprite2D.new()
	_sprite.offset = Vector2(0, -8)
	_sprite.sprite_frames = _frames_for(kind)
	add_child(_sprite)
	_target = home
	_pick_target()
	_play("idle_" + _facing)


func _is_walkable(pos: Vector2) -> bool:
	if _world == null or not _world.has_method("is_walkable"):
		return true
	return _world.is_walkable(pos)


func _pick_target() -> void:
	for _attempt in range(8):
		var angle := randf() * TAU
		var radius := randf_range(8.0, wander_radius)
		var candidate := home + Vector2(cos(angle), sin(angle)) * radius
		if _is_walkable(candidate):
			_target = candidate
			_timer = randf_range(1.0, 2.6)
			return
	# fallback: fica parado em casa
	_target = home
	_timer = randf_range(1.0, 2.6)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var moving := false

	if player != null:
		var to_player := player.global_position - global_position
		var dist := to_player.length()
		if kind == Kind.CAT and dist < FOLLOW_RADIUS:
			_target = player.global_position + Vector2(12, 6)
			_timer = 0.5
		elif kind == Kind.MOUSE and dist < FLEE_RADIUS:
			_target = global_position - to_player.normalized() * 48.0
			_timer = 0.4

	_timer -= delta
	var to_target := _target - global_position
	if to_target.length() > 3.0:
		var step := to_target.normalized() * speed * delta
		var next_pos := global_position + step
		if _is_walkable(next_pos):
			global_position = next_pos
			_facing = _face(to_target)
			moving = true
		else:
			# caminho bloqueado — escolhe novo alvo
			_pick_target()
	elif _timer <= 0.0:
		_pick_target()

	# Volta para casa se vagar demais (evita atravessar o mapa).
	if global_position.distance_to(home) > wander_radius + 80.0:
		global_position = home
		_pick_target()

	_play(("walk" if moving else "idle") + "_" + _facing)


func _face(dir: Vector2) -> String:
	if absf(dir.x) > absf(dir.y):
		return "right" if dir.x > 0.0 else "left"
	return "down" if dir.y > 0.0 else "up"


func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.play(anim)


# --- Frames ----------------------------------------------------------------

func _frames_for(critter_kind: int) -> SpriteFrames:
	match critter_kind:
		Kind.MOUSE:
			return _build_frames(MOUSE_TEX, ROWS_STANDARD, 4)
		Kind.WOMAN:
			return _build_frames(WOMAN_TEX, ROWS_STANDARD, 4)
		Kind.BLOB:
			return _build_frames(BLOB_TEX, ROWS_BLOB, 4)
		_:
			return _build_frames(CAT_TEX, ROWS_STANDARD, 4)


func _build_frames(tex: Texture2D, rows: Dictionary, cols: int) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for dir in rows:
		var row: int = rows[dir]
		var idle := "idle_%s" % dir
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 1.0)
		frames.set_animation_loop(idle, false)
		frames.add_frame(idle, _atlas(tex, 0, row))

		var walk := "walk_%s" % dir
		frames.add_animation(walk)
		frames.set_animation_speed(walk, 6.0)
		frames.set_animation_loop(walk, true)
		for c in range(cols):
			frames.add_frame(walk, _atlas(tex, c, row))
	return frames


func _atlas(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(col * CELL, row * CELL, CELL, CELL)
	return at
