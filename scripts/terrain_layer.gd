@tool
extends TileMapLayer

## Camada de pintura do terreno logico (1 celula = 1 terreno).
##
## No editor ela fica visivel para voce pintar com a ferramenta de TileMap
## (aba TileMap no rodape). Por padrao ela so aparece quando este no esta
## selecionado: ao selecionar outro no, ela some e voce ve o dual grid real.
## Em execucao fica visivel (com opacidade 1.0) para que as camadas de
## renderização (TerrainWater, TerrainDirt, TerrainSoil) possam ler os tiles.
##
## Pinte o tile cheio de cada fonte:
##     fonte 0 = agua, fonte 1 = terra, fonte 2 = canteiro
##
## A andabilidade de cada material fica na custom data "walkable" do TileSet
## (assets/tiles/terrain_paint.tres), editavel na aba TileSet.

## Opacidade da camada enquanto voce pinta no editor.
@export_range(0.1, 1.0, 0.05) var editor_alpha: float = 0.85
## Se true, so aparece no editor quando este no esta selecionado.
@export var only_visible_when_selected: bool = true


func _ready() -> void:
	_apply_editor_mode()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_apply_editor_mode()


func _apply_editor_mode() -> void:
	if Engine.is_editor_hint():
		z_index = 100
		modulate = Color(1, 1, 1, editor_alpha)
		if only_visible_when_selected:
			visible = EditorInterface.get_selection().get_selected_nodes().has(self)
		else:
			visible = true
	else:
		# Em runtime, mantém visível para que as camadas de renderização
		# (TerrainWater, TerrainDirt, TerrainSoil) possam ler os tiles.
		# A opacidade volta ao normal para não atrapalhar o visual.
		modulate = Color(1, 1, 1, 1.0)
