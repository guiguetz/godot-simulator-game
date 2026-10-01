class_name HouseBuilder
extends RefCounted

## Monta uma casa decorativa com colisao usando os tilesets do projeto:
## paredes (walls_nofloor.png, bloco 3x3) + telhado (roof.png, bloco 3x3).
## As paredes tem colisao de celula cheia; o telhado nao colide.
##
## O tile (1,1) das paredes e a "janela/porta" sem colisao.

const WALLS_TEX := preload("res://assets/graphics/tilesets/walls_nofloor.png")
const ROOF_TEX := preload("res://assets/graphics/tilesets/roof.png")

const WALL_TILES := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
]
const DOOR_TILE := Vector2i(1, 1)


## Cria as camadas da casa em `parent`. `origin` = celula do canto sup. esq.
## Retorna a camada de paredes (com colisao).
static func build(parent: Node, origin: Vector2i) -> TileMapLayer:
	var roof := TileMapLayer.new()
	roof.name = "HouseRoof"
	roof.tile_set = _tileset(ROOF_TEX, false)
	roof.z_index = 20
	parent.add_child(roof)

	var walls := TileMapLayer.new()
	walls.name = "HouseWalls"
	walls.tile_set = _tileset(WALLS_TEX, true)
	walls.z_index = 5
	parent.add_child(walls)

	for y in range(3):
		for x in range(3):
			walls.set_cell(origin + Vector2i(x, y), 0, Vector2i(x, y))
			roof.set_cell(origin + Vector2i(x, y - 2), 0, Vector2i(x, y))
	return walls


static func _tileset(tex: Texture2D, collide: bool) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	if collide:
		ts.add_physics_layer(0)

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(16, 16)
	# O source precisa ser adicionado ANTES de mexer no TileData, senao a
	# camada de fisica nao existe para os poligonos.
	ts.add_source(source, 0)

	var coords := WALL_TILES if collide else _roof_tiles()
	for coord in coords:
		source.create_tile(coord)
		if collide and coord != DOOR_TILE:
			var data := source.get_tile_data(coord, 0)
			var poly := PackedVector2Array([
				Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
			])
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, poly)

	return ts


static func _roof_tiles() -> Array:
	var arr: Array = []
	for y in range(3):
		for x in range(3):
			arr.append(Vector2i(x, y))
	return arr
