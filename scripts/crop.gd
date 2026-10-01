class_name Crop
extends Node2D

## Plantacao. Fica no fundo da celula; cresce um estagio por dia se estiver
## molhada (ou chovendo). Textura 64x32 = 4 estagios de 16x32.

var seed_type: int = Enums.Seed.TOMATO
var stage := 0
var days_grown := 0
var watered := false
var cell := Vector2i.ZERO
var is_ready := false

var _sprite: Sprite2D


func setup(seed: int, p_cell: Vector2i) -> void:
	seed_type = seed
	cell = p_cell
	_sprite = Sprite2D.new()
	_sprite.texture = GameData.CROP_TEXTURES[seed]
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, 16, 32)
	_sprite.offset = Vector2(0, -16)
	add_child(_sprite)
	_update_frame()


func water() -> void:
	watered = true


## Avanca um dia. `auto_water` = true quando chove.
func grow_day(auto_water: bool = false) -> void:
	if is_ready:
		return
	if watered or auto_water:
		days_grown += 1
	var grow_days: int = GameData.crops[seed_type]["grow_days"]
	stage = mini(3, days_grown)
	is_ready = days_grown >= grow_days
	watered = false
	_update_frame()


func harvest() -> int:
	if not is_ready:
		return -1
	return int(GameData.crops[seed_type]["reward"])


func restore(data: Dictionary) -> void:
	stage = int(data.get("stage", 0))
	days_grown = int(data.get("days_grown", 0))
	watered = bool(data.get("watered", false))
	is_ready = bool(data.get("is_ready", false))
	_update_frame()


func _update_frame() -> void:
	if _sprite != null:
		_sprite.region_rect = Rect2(stage * 16, 0, 16, 32)


func to_dict() -> Dictionary:
	return {
		"cell": [cell.x, cell.y],
		"seed": seed_type,
		"stage": stage,
		"days_grown": days_grown,
		"watered": watered,
		"is_ready": is_ready,
	}
