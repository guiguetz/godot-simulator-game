# Mundo: terreno, andabilidade e aração

Como o terreno lógico é pintado e como o código lê propriedades por material
(`scripts/world.gd`, TileSet `assets/tiles/terrain_paint.tres`).

## Materiais de terreno

O terreno lógico vive na camada `Game/DualGrid/Terrain`, pintada por **source**
do TileSet. `world.gd` mapeia source ⇄ tipo:

| Tipo | Source | Constante |
|---|---|---|
| Água | 0 | `WATER` |
| Terra | 1 | `DIRT` |
| Canteiro | 2 | `SOIL` |
| Grama (sem tile) | — | `NONE` |

`terrain_at(cell)` devolve o tipo da célula; `set_terrain(cell, tid)` pinta e
dispara a reconstrução do dual grid.

## Propriedades por material (custom data)

O comportamento do terreno é dirigido por **custom data** do TileSet, não por
listas fixas no código:

- `custom_data_layer_0` — `walkable`: se `false`, o tile bloqueia o player
  (lido por `is_walkable()` / `is_walkable_cell()`).
- `custom_data_layer_1` — `tillable`: se `true`, a enxada transforma o tile em
  `SOIL` (lido por `is_tillable_cell()`).

Ambas são lidas pelo helper genérico `_custom_data(tid, key, fallback)` sobre o
tile `(3, 3)` de cada source. Sem fonte/tile/data correspondente, vale o
`fallback`.

> O **índice da camada importa**: `walkable` já é a `_0`; a `tillable` é a `_1`.
> Inserir uma camada no meio quebraria os valores salvos — use sempre o próximo
> índice livre.

Para editar: abra o TileSet de pintura na aba **TileSet**, selecione o material
e marque `tillable` / `walkable`. Não é preciso tocar em código.

### Grama (`NONE`)

A grama não tem tile próprio, então não dá para marcar `tillable` nela na
TileSet. O valor padrão fica em `world.gd`:

```gdscript
const TILLABLE_FALLBACK := true
```

Ou seja, materiais sem tile (a grama) são aráveis **por padrão**. Água e
canteiro têm `tillable = false` (flag ausente).

## Aração (enxada)

`use_tool` usa a API pública em vez da lista hardcoded antiga:

```gdscript
func is_tillable_cell(cell: Vector2i) -> bool:
	return _is_tillable_terrain(terrain_at(cell))
```

```gdscript
Enums.Tool.HOE:
	if is_tillable_cell(cell) and is_walkable_cell(cell):
		set_terrain(cell, SOIL)
		AudioManager.play_sfx("hoe")
```

Regras:

- Grama e terra (`DIRT`) viram `SOIL`.
- Água ou material marcado `tillable = false` não fazem nada (sem som).
- `walkable` e `tillable` são **independentes**: um tile pode ser andável e não
  arável (ex.: trilha batida) e vice-versa.
- Células fora do mapa não são usadas pelas ferramentas (a checagem de
  andabilidade barra antes).

## Verificação

`tools/smoke_test.gd` cobre grama arável, terra arável e enxada na água sem
alteração. Rode:

```bash
godot --headless --path . --script tools/smoke_test.gd
```
