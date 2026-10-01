# 014 — Migração para TileMapDual

- **Status:** Proposto
- **Prioridade:** Alta
- **Esforço:** M (dias)
- **Depende de:** —
- **Arquivos-alvo:** `scripts/dual_grid.gd` (remove), `scripts/terrain_layer.gd` (remove), `scripts/world.gd`, `scenes/game.tscn`, `docs/world.md`

## Objetivo

Substituir a implementação homebrew de dual grid (342 + 46 linhas) pelo addon
[TileMapDual](https://github.com/pablogila/TileMapDual), reduzindo código
próprio e ganhando suporte nativo a dual grid no editor.

## Motivação / Contexto

O projeto tem um dual grid funcional implementado em `dual_grid.gd` (342 linhas,
@tool com overlay de editor, bitmask 4x4, legenda) e `terrain_layer.gd` (46
linhas, camada de pintura). Funciona, mas:

- **Código próprio** que precisa de manutenção.
- **Sem suporte nativo** no editor — o overlay é desenhado via `_draw()`.
- **Limitações** — não suporta isometria, hex, nem auto-tiling avançado.
- TileMapDual é um addon maduro (v5), com suporte a todos os tipos de grid,
  preview em tempo real no editor, e apenas 15 tiles necessários (vs 16 atuais).

O trade-off é depender de um addon de terceiro, mas o projeto é ativo (v5
recente) e o código é MIT.

## Design técnico

### Arquitetura atual → nova

| Atual | Novo (TileMapDual) |
|---|---|
| `terrain_layer.gd` (TileMapLayer de pintura) | Removido — TileMapDual já é a camada de pintura |
| `dual_grid.gd` (renderização dual grid) | Removido — TileMapDual renderiza automaticamente |
| `world.gd` (lógica do mundo) | Adaptado para ler/escrever no TileMapDual |

### Estrutura de nodes

**Atual:**
```
Game/DualGrid (DualGrid @tool)
  └── Terrain (TileMapLayer) ← camada de pintura
```

**Novo:**
```
Game/TerrainWater (TileMapDual)   ← tiles de água
Game/TerrainDirt (TileMapDual)    ← tiles de terra
Game/TerrainSoil (TileMapDual)    ← tiles de canteiro
Game/TerrainPaint (TileMapLayer)  ← camada lógica oculta (para save/compatibilidade)
```

TileMapDual não suporta múltiplos terrenos num mesmo node — cada tipo de
terreno é um TileMapDual separado, conforme a documentação do addon.

### Migração de terreno

O sistema atual usa source IDs num único TileMapLayer:
- Source 0 = WATER, Source 1 = DIRT, Source 2 = SOIL

Com TileMapDual, cada terreno é um node separado. `world.gd` precisa adaptar:

```gdscript
# Antes (source-based)
func terrain_at(cell: Vector2i) -> int:
    var src := _terrain.get_cell_source_id(cell)
    return SRC_TO_TERRAIN.get(src, NONE)

# Depois (layer-based)
func terrain_at(cell: Vector2i) -> int:
    if _terrain_water.get_cell_source_id(cell) != -1:
        return WATER
    if _terrain_dirt.get_cell_source_id(cell) != -1:
        return DIRT
    if _terrain_soil.get_cell_source_id(cell) != -1:
        return SOIL
    return NONE
```

### Custom data (walkable/tillable)

O sistema atual lê `custom_data` do TileSet de pintura. Com TileMapDual,
temos duas opções:

1. **Manter custom data no TileSet de pintura** — TileMapDual usa um TileSet
   de "display tiles", mas podemos manter o TileSet original como referência
   para lógica.
2. **Mover para constantes em world.gd** — mais simples, menos flexível.

**Recomendação:** manter custom data no TileSet de pintura (que vira o
"world tiles" do TileMapDual) e ler como antes via `_custom_data()`.

### Save/load

O save atual salva o estado do `_terrain` (TileMapLayer de pintura). Com
TileMapDual, precisamos salvar a camada lógica (paint) em vez da visual.
Duas opções:

1. **Manter um TileMapLayer oculto** como camada lógica — o TileMapDual lê
   dele para renderizar. Save lê/escreve nele.
2. **Salvar diretamente os cells do TileMapDual** — mais simples, mas
   acopla save ao addon.

**Recomendação:** opção 1 — manter `TerrainPaint` como camada lógica
oculta. TileMapDual lê dele. Save continua usando a mesma API.

### Editor workflow

Hoje o designer pinta no `Terrain` (TileMapLayer) e vê o dual grid em
tempo real via `@tool` no `DualGrid`. Com TileMapDual, o designer pinta
direto no `TileMapDual` e vê o resultado imediatamente — sem overlay
customizado. Melhor UX.

## Escopo

- **Incluído:** instalação do TileMapDual, remoção de dual_grid.gd e
  terrain_layer.gd, adaptação de world.gd, migração do TileSet,
  atualização da cena game.tscn, documentação.
- **Fora do escopo:** suporte a isometria/hex (futuro), tiles de decoração
  (já funcionam separadamente), refatoração de farming.

## Tarefas

### Fase 1 — Instalação e setup
- [ ] Instalar TileMapDual v5 como addon (`addons/TileMapDual/`)
- [ ] Habilitar plugin no Project Settings
- [ ] Criar TileSet de display tiles (15 tiles para cada terreno)
- [ ] Criar 3 nodes TileMapDual na cena (Water, Dirt, Soil)
- [ ] Configurar cada um com seu TileSet e shape

### Fase 2 — Migração da lógica
- [ ] Adaptar `terrain_at()` para ler de múltiplos TileMapDual
- [ ] Adaptar `set_terrain()` para escrever no TileMapDual correto
- [ ] Manter custom data (walkable/tillable) no TileSet de pintura
- [ ] Manter camada `TerrainPaint` oculta para save/load
- [ ] Adaptar `_rebuild_world()` para setup do TileMapDual
- [ ] Remover referências a `DualGrid` e `terrain_layer` em world.gd

### Fase 3 — Migração da cena
- [ ] Atualizar `game.tscn`: remover DualGrid, adicionar TileMapDual nodes
- [ ] Remover `dual_grid.gd` e `terrain_layer.gd`
- [ ] Testar pintura no editor (preview em tempo real)
- [ ] Testar farming (enxada, plantio, colheita)
- [ ] Testar save/load com a nova estrutura

### Fase 4 — Validação
- [ ] Smoke test passa com a nova estrutura
- [ ] gdUnit4 passa (testes de terreno adaptados)
- [ ] Performance: dual grid não é mais lento que antes
- [ ] Documentar em `docs/world.md` (nova estrutura de nodes)

## Critérios de aceite

- [ ] TileMapDual renderiza o dual grid corretamente no editor e em runtime.
- [ ] Pintar terreno no editor mostra preview instantâneo.
- [ ] Enxada transforma grama em canteiro (SOIL) corretamente.
- [ ] Walkable/tillable funcionam como antes.
- [ ] Save/load preserva o estado do terreno.
- [ ] Smoke test passa.
- [ ] `dual_grid.gd` e `terrain_layer.gd` foram removidos.

## Riscos / Notas

- **Breaking change:** remover `DualGrid` afeta todo mundo que referencia
  o node (world.gd, possivelmente save). Mitigar: mapear todas as
  referências antes de remover.
- **Múltiplos terrenos:** TileMapDual recomenda um node por terreno. Com
  3 terrenos + grama, são 3-4 nodes. Pode ficar verboso mas é o padrão
  do addon.
- **Compatibilidade de save:** saves antigos usam o formato do terrain
  antigo. Mitigar: manter `TerrainPaint` como camada lógica e migrar
  saves na primeira carga.
- **Dependência de terceiro:** TileMapDual é MIT e ativo, mas pode ter
  bugs. Mitigar: manter `dual_grid.gd` como backup por 1-2 semanas
  antes de deletar.
- **Tiles de decoração:** o sistema atual de decoração (arbustos, pedras)
  é independente do dual grid e deve continuar funcionando.