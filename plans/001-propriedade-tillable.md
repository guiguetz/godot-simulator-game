# 001 — Propriedade `tillable` no terreno

- **Status:** Proposto
- **Prioridade:** Média
- **Esforço:** P (horas)
- **Depende de:** — (relaciona-se a `../issues/004-caixa-andabilidade-maior-que-tile.md`)
- **Arquivos-alvo:**
  - `assets/tiles/terrain_paint.tres` (nova camada de custom data)
  - `scripts/world.gd` (`_is_tillable_terrain`, `is_tillable_cell`, `use_tool`)
  - `scripts/hud.gd` (feedback visual, opcional)
  - `tools/smoke_test.gd` (cobertura)

## Objetivo

Definir, **nos dados do terreno** (TileSet), quais materiais podem ser cavados
pela enxada, em vez de manter a lista de materiais fixa no código. A enxada
passa a consultar `is_tillable_cell(cell)`.

## Motivação / Contexto

Hoje a regra está **hardcoded** em `scripts/world.gd`:

```gdscript
Enums.Tool.HOE:
    if terrain_at(cell) in [NONE, DIRT] and is_walkable_cell(cell):
        set_terrain(cell, SOIL)
```

Ou seja, só grama (`NONE`) e `DIRT` viram `SOIL`. Qualquer ajuste de design
(ex.: liberar areia, bloquear terra perto de água) exige editar código.

O projeto **já usa** exatamente esse padrão para andabilidade: a camada de
custom data `walkable` em `assets/tiles/terrain_paint.tres` é lida em
`_is_walkable_terrain()` e exposta por `is_walkable()` / `is_walkable_cell()`.
Falta o equivalente para "arar".

## Comportamento esperado

- `tillable` é uma propriedade **por material de terreno** (água, terra,
  canteiro), editável na aba TileSet.
- Grama (ausência de overlay, `NONE`) permanece arável por padrão, pois não tem
  tile próprio; o valor padrão fica em uma constante de código documentada.
- Enxada em tile arável → cria `SOIL` (comportamento atual preservado).
- Enxada em tile não-arável (água, ou material marcado como `false`) → não faz
  nada (sem custo, sem som de enxada).
- Regra não muda a andabilidade: um tile pode ser andável e **não** arável
  (ex.: trilha de terra batida) e vice-versa.

## Design técnico

1. Em `assets/tiles/terrain_paint.tres`, adicionar a segunda camada:

   ```
   custom_data_layer_1/name = "tillable"
   custom_data_layer_1/type = 1
   ```

   e marcar `3:3/0/custom_data_1 = true` na fonte da **terra** (source 1).
   Água e canteiro ficam sem a flag (default `false`).

   > A camada `walkable` já é a `custom_data_layer_0`; a nova deve ser a `_1`
   > para não invalidar o índice existente.

2. Em `scripts/world.gd`, generalizar o helper atual. Hoje:

   ```gdscript
   func _is_walkable_terrain(tid: int) -> bool:
       var src = TERRAIN_TO_SRC.get(tid, -1)
       if src < 0:
           return true
       var source := _terrain.tile_set.get_source(src) as TileSetAtlasSource
       var data := source.get_tile_data(Vector2i(3, 3), 0)
       return data == null or bool(data.get_custom_data("walkable"))
   ```

   Extrair um helper reutilizável:

   ```gdscript
   const TILLABLE_FALLBACK := true  # NONE (grama) é arável por padrão.

   func _custom_data(tid: int, key: String, fallback: bool) -> bool:
       var src = TERRAIN_TO_SRC.get(tid, -1)
       if src < 0:
           return fallback
       var source := _terrain.tile_set.get_source(src) as TileSetAtlasSource
       if source == null:
           return fallback
       var data := source.get_tile_data(Vector2i(3, 3), 0)
       if data == null:
           return fallback
       return bool(data.get_custom_data(key))

   func _is_walkable_terrain(tid: int) -> bool:
       return _custom_data(tid, "walkable", true)

   func _is_tillable_terrain(tid: int) -> bool:
       return _custom_data(tid, "tillable", TILLABLE_FALLBACK)

   func is_tillable_cell(cell: Vector2i) -> bool:
       return _is_tillable_terrain(terrain_at(cell))
   ```

3. Atualizar `use_tool`:

   ```gdscript
   Enums.Tool.HOE:
       if is_tillable_cell(cell) and is_walkable_cell(cell):
           set_terrain(cell, SOIL)
           AudioManager.play_sfx("hoe")
   ```

4. (Opcional) Feedback no HUD: destacar o tile sob o cursor/player em vermelho
   quando não for arável, reaproveitando a lógica de mira atual.

## Escopo

- **Incluído:** camada de custom data `tillable`, leitura genérica, API
  `is_tillable_cell`, uso pela enxada, teste no smoke test.
- **Fora do escopo:** novos materiais de terreno; sistema de fertilidade;
  custo de energia; animação de "terra arada" diferente de `SOIL`.

## Tarefas

- [ ] Adicionar `custom_data_layer_1 = "tillable"` em `terrain_paint.tres`
- [ ] Marcar terra (`source 1`) como `tillable = true`
- [ ] Extrair `_custom_data()` e reescrever `_is_walkable_terrain()`
- [ ] Implementar `_is_tillable_terrain()` e `is_tillable_cell()`
- [ ] Trocar a checagem hardcoded em `use_tool` por `is_tillable_cell`
- [ ] Cobrir no `tools/smoke_test.gd` (terra ara, água não ara)
- [ ] Atualizar `README.md` se a API pública do mundo for citada

## Critérios de aceite

- [ ] Enxada em grama vira `SOIL` (regressão zero).
- [ ] Enxada em `DIRT` vira `SOIL`.
- [ ] Enxada em `WATER` não altera o terreno nem toca som de enxada.
- [ ] Alterar `tillable` na aba TileSet muda o comportamento sem recompilar
      lógica de jogo (só a leitura de dados).
- [ ] `walkable` continua funcionando exatamente como antes (camada 0 intacta).

## Riscos / Notas

- **Índice da camada:** se `tillable` for inserida antes de `walkable`, os
  valores salvos quebrariam. Use sempre o próximo índice livre.
- **`NONE` não tem tile:** o fallback de grama precisa ser documentado; sem
  isso, alguém pode tentar editar `tillable` da grama na TileSet e não achar.
- **Duplicação do dual grid:** o `DualGrid._build_tileset()` cria um TileSet
  próprio sem custom data; isso é intencional (só renderiza). A leitura de
  dados deve continuar vindo de `_terrain.tile_set`.
