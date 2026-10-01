class_name Machine
extends Node2D

## Maquina colocada no mundo (aspersor / espantalho / pescador).
## Visual em AnimatedSprite2D montado em codigo. Os efeitos diarios sao
## aplicados por world.gd (regar ao redor / pescar).

const SPRINKLER_TEX := preload("res://assets/graphics/machines/sprinkler.png")
const SCARECROW_TEX := preload("res://assets/graphics/machines/scarecrow.png")
const FISHER_TEX := preload("res://assets/graphics/machines/fisher.png")

var kind: int = Enums.Machine.SPRINKLER
var cell := Vector2i.ZERO

var _anim: AnimatedSprite2D


func setup(machine_kind: int, p_cell: Vector2i) -> void:
	kind = machine_kind
	cell = p_cell
	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = _frames_for(machine_kind)
	_anim.offset = _offset_for(machine_kind)
	add_child(_anim)
	_anim.play("idle")


func _offset_for(machine_kind: int) -> Vector2:
	match machine_kind:
		Enums.Machine.SPRINKLER:
			return Vector2(0, -8)
		Enums.Machine.SCARECROW:
			return Vector2(0, -16)
		_:
			return Vector2(0, -24)


func _frames_for(machine_kind: int) -> SpriteFrames:
	match machine_kind:
		Enums.Machine.SPRINKLER:
			return _strip_frames(SPRINKLER_TEX, 16, 16, 4, 1.0)
		Enums.Machine.SCARECROW:
			return _strip_frames(SCARECROW_TEX, 16, 32, 4, 0.6)
		_:
			return _grid_frames(FISHER_TEX, 48, 48, 4, 0, 8.0)


## Tira horizontal: `count` frames de w x h.
func _strip_frames(tex: Texture2D, w: int, h: int, count: int, speed: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", speed)
	for i in range(count):
		frames.add_frame("idle", _atlas(tex, i * w, 0, w, h))
	return frames


## Grade: uma linha `row_index` com `count` frames de w x h.
func _grid_frames(tex: Texture2D, w: int, h: int, count: int, row_index: int, speed: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", speed)
	for i in range(count):
		frames.add_frame("idle", _atlas(tex, i * w, row_index * h, w, h))
	return frames


func _atlas(tex: Texture2D, x: int, y: int, w: int, h: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(x, y, w, h)
	return at


func to_dict() -> Dictionary:
	return {"cell": [cell.x, cell.y], "kind": kind}
