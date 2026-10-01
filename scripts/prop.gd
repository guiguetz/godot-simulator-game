class_name Prop
extends Node2D

## Prop do mundo (arvore). Y-sorted pelo no pai. Machado derruba: 1o golpe
## vira toco, 2o remove. Textura tree.png = 2 frames de 32x32.

enum Kind { TREE, STUMP }

const TREE_TEX := preload("res://assets/graphics/plants/tree.png")
const STUMP_TEX := preload("res://assets/graphics/plants/stump.png")

var kind: int = Kind.TREE
var cell := Vector2i.ZERO

var _sprite: Sprite2D


func setup_tree(p_cell: Vector2i) -> void:
	cell = p_cell
	kind = Kind.TREE
	_sprite = Sprite2D.new()
	_sprite.texture = TREE_TEX
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, 32, 32)
	_sprite.offset = Vector2(0, -16)
	add_child(_sprite)


## Retorna a madeira obtida e se o prop foi removido.
func chop() -> Dictionary:
	if kind == Kind.TREE:
		kind = Kind.STUMP
		_sprite.texture = STUMP_TEX
		_sprite.region_enabled = false
		_sprite.offset = Vector2(0, -5)
		return {"wood": 2, "removed": false}
	queue_free()
	return {"wood": 1, "removed": true}


func to_dict() -> Dictionary:
	return {"cell": [cell.x, cell.y], "kind": kind, "tree": true}
