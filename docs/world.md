# Mundo: terreno, autotiling e aração

O terreno é composto por três camadas `TileMapDual` independentes — água,
terra e canteiros — que são a fonte de verdade para pintura, gameplay e
save/load. A lógica pública fica em `scripts/world.gd`; os TileSets usam três
atlas 4×4. Água e canteiro usam as imagens próprias 16×16 do jogo; terra usa o
asset oficial `tileset_sand.png` do TileMapDual, copiado para
`assets/tiles/terrain_dirt.png`.

## Pintura e autotiling

| Nó | TileSet | Tipo | Custom data (`walkable`, `tillable`) |
|---|---|---|---|
| `Game/TerrainWater` | `terrain_water.tres` | Água (`WATER`) | `false`, `false` |
| `Game/TerrainDirt` | `terrain_dirt.tres` | Terra (`DIRT`) | `true`, `true` |
| `Game/TerrainSoil` | `terrain_soil.tres` | Canteiro (`SOIL`) | `true`, `false` |
| sem célula | — | Grama (`NONE`) | `true`, fallback de aração configurável |

No editor, pinte diretamente no `TileMapDual` do material desejado, usando o
tile marcado como terreno preenchido (`(3, 3)` nos atlas locais; `(2, 1)` no
atlas oficial de areia). Apagar uma célula remove o material daquela camada. Ao trocar manualmente um material
por outro no editor, apague também a célula da camada anterior para não deixar
camadas sobrepostas. Em runtime, `world.gd::set_terrain(cell, tid)` faz essa
substituição de forma exclusiva; o addon atualiza as transições vizinhas
automaticamente.

A configuração segue o padrão de múltiplas camadas dos exemplos oficiais
[`MultipleLayers.tscn`](https://github.com/pablogila/TileMapDual/blob/main/examples/MultipleLayers.tscn)
e [`MultipleAtlases.tscn`](https://github.com/pablogila/TileMapDual/blob/main/examples/MultipleAtlases.tscn).
O atlas `assets/tiles/terrain_dirt.png` é uma cópia de
[`assets/tileset_sand.png`](https://github.com/pablogila/TileMapDual/blob/main/assets/tileset_sand.png)
do repositório oficial (snapshot consultado `b4dc775`): seus tiles têm 32×32 px e
o nó `TerrainDirt` usa escala 0,5 para ocupar as células lógicas de 16×16 do
jogo. A licença MIT e a origem estão registradas em
`assets/tiles/TILEMAPDUAL-ASSETS-LICENSE.txt`.
Água e canteiro continuam usando a arte própria do jogo.

O script `tools/generate_dual_tilesets.gd` gera os TileSets para as três
texturas e configura o tamanho de atlas de cada uma (16 px nas texturas próprias,
32 px no asset oficial usado por terra). Cada atlas 4×4 representa as combinações
dos quatro cantos: terreno 0 é o tile vazio, terreno 1 o material preenchido, e
os 14 tiles restantes codificam as transições. O atlas de água/canteiro segue a
ordem canônica; para areia, o gerador reproduz a tabela explícita do exemplo
official `MultipleLayers.tscn`: vazio em `(0, 3)` e tile cheio em `(2, 1)`. Não
calcule as máscaras da areia a partir da coordenada do atlas. Na inicialização,
células já salvas são reaplicadas via `draw_cell()` para adotar o tile cheio
correto. Todos os quatro peering bits são definidos com 0 ou 1. O tile lógico
preenchido também carrega os custom data `walkable` e `tillable`,
consultados pelo gameplay — não há um mapa lógico oculto nem uma cópia paralela
do terreno.

Para regenerar os recursos no editor Godot (importação inicial necessária após
clonar o projeto):

```bash
godot --headless --editor --path . --import
godot --headless --path . --script tools/generate_dual_tilesets.gd
```

## API, andabilidade e aração

- `terrain_at(cell)` devolve `WATER`, `DIRT`, `SOIL`, `NONE` (grama) ou `-1`
  para coordenadas fora do mapa.
- `set_terrain(cell, tid)` apaga a célula em todas as camadas e, se o tipo não
  for `NONE`, pinta o tile preenchido na camada correta. A apresentação dual
  fica a cargo do TileMapDual.
- `is_walkable_cell()` e `is_tillable_cell()` consultam os custom data do tile
  lógico correspondente. Água bloqueia o movimento; terra e canteiro são
  andáveis; somente terra pode ser arada para canteiro. Células sem tile usam
  o fallback de grama.
- Ferramentas, pesca, máquinas e NPCs consultam a mesma API do mundo, nunca os
  tiles visuais derivados do atlas.

## Save/load

O save guarda registros `[x, y, tipo]` das células ocupadas nas camadas
TileMapDual. Não persiste os tiles de apresentação escolhidos pelo addon; na
carga, cada tipo é repintado pela API e o TileMapDual recalcula as bordas.
O formato mantém os IDs de terreno já usados pelo save: 1 água, 2 terra e
3 canteiro.

## Verificação

Os testes cobrem as 16 regras do atlas, uso do asset oficial de areia na escala
correta, camadas exclusivas, custom data, andabilidade/aração, bordas do mapa e
round-trip do save. Execute:

```bash
godot --headless --path . --script tools/smoke_test.gd
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/world/test_world_terrain.gd --ignoreHeadlessMode -c
```
