# Mundo: terreno, autotiling e aração

O terreno usa uma camada lógica para pintura e save/load, mais três camadas
`TileMapDual` para exibir água, terra e canteiros. A lógica está em
`scripts/world.gd`; os tiles de exibição ficam em `assets/tiles/display_*.tres`.

## Pintura e sincronização

`Game/TerrainPaint` é a fonte da verdade: cada célula usa o source ID do
`assets/tiles/terrain_paint.tres`.

| Tipo | Source | Constante |
|---|---:|---|
| Água | 0 | `WATER` |
| Terra | 1 | `DIRT` |
| Canteiro | 2 | `SOIL` |
| Grama (sem tile) | — | `NONE` |

No editor, selecione `TerrainPaint` e pinte com a ferramenta de TileMap. O
nó usa `scripts/terrain_layer.gd`: fica visível e semitransparente enquanto
selecionado, e some ao selecionar outro nó para revelar o autotiling. Em
runtime, `TerrainPaint` também fica invisível; isso não afeta `get_used_cells()`
nem a sincronização. O `world.gd` detecta alterações na camada no editor e
sincroniza as células com `TerrainWater`, `TerrainDirt` e `TerrainSoil`. Essas
camadas usam o addon TileMapDual para recalcular o atlas automaticamente. Em
runtime, `set_terrain(cell, tid)` altera `TerrainPaint` e atualiza a exibição
pelo mesmo caminho.

O gerador `tools/generate_dual_tilesets.gd` cria os três TileSets de display a
partir das texturas `terrain_water.png`, `terrain_dirt.png` e
`terrain_soil.png`. O atlas 4×4 contém as 16 combinações dos quatro cantos;
terreno 0 representa vazio e terreno 1 representa o material preenchido. Os
peering bits precisam estar definidos como 0 ou 1 em todos os cantos para que
o TileMapDual registre cada regra. Para regenerar:

```bash
godot --headless --path . --script tools/generate_dual_tilesets.gd
```

O save serializa `TerrainPaint`, não os tiles calculados do atlas. Na carga, as
camadas TileMapDual são reconstruídas a partir dos source IDs salvos.

## Andabilidade e aração

`terrain_at(cell)` devolve o tipo presente nas camadas de exibição;
`is_walkable_cell()` e `is_tillable_cell()` consultam as regras de material em
`world.gd::_custom_data()`: água bloqueia o movimento e não pode ser arada;
terra e canteiro são andáveis e aráveis. O fallback para materiais sem tile
(grama) é controlado por `TILLABLE_FALLBACK`.

A enxada usa a API `set_terrain()` para trocar o terreno da célula por `SOIL`.
Água e células fora da área caminhável não são alteradas. `walkable` e
`tillable` são propriedades independentes no fluxo de ferramentas.

## Verificação

O smoke test cobre sincronização, aração, save/load e sistemas dependentes do
terreno. Os testes de `tests/world/test_world_terrain.gd` também verificam que
o TileMapDual usa mais de uma forma do atlas:

```bash
godot --headless --path . --script tools/smoke_test.gd
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/world/test_world_terrain.gd --ignoreHeadlessMode -c
```
