# 001 — Chão renderizado por cima de tudo

- **Status:** Corrigido
- **Severidade:** Alta
- **Sintoma:** o chão (grama) aparece desenhado por cima do cenário: do dual
  grid (água/trilha/canteiro) e das entidades (player, árvores, plantações).

## Reprodução

1. Rodar `scenes/game.tscn`.
2. Observar que a grama cobre tudo; não dá para ver o dual grid nem o player.

## Causa raiz

Duas coisas somadas:

1. **Ordem na árvore.** `scripts/world.gd:_build_ground()` criava a camada
   `Ground` com `add_child(layer)`, o que a **anexa no fim** da lista de filhos
   de `Game`:

   ```
   Game children: [DualGrid, Structures, Entities, DayNight, Rain, HUD, Shop, PauseMenu, Ground]
   ```

2. **z_index igual.** `Ground` tinha `z_index = 0`, o mesmo de `DualGrid` e de
   `Entities`. Com z igual, o Godot desenha pela ordem da árvore — e `Ground`
   era o último, então ficava por cima.

Além disso, as camadas de terreno do dual grid (`Terrain1..3`) usam
`z_index = 1..3`, ou seja, mesmo removendo o `Ground`, o terreno continuaria
acima de `Entities` (z 0), cobrindo o player.

## Correção aplicada

- `scripts/world.gd` — `Ground` passou a ficar realmente no fundo:
  ```gdscript
  layer.z_index = -10
  add_child(layer)
  move_child(layer, 0)
  ```
- `scenes/game.tscn` — `Entities` subiu para `z_index = 10`, acima dos terrenos
  (`Terrain1..3` = 1..3) e abaixo do telhado (z 20) e da chuva (z 100).

Ordem final de z-index:

| Nó | z | Observação |
|---|---|---|
| `Ground` | -10 | chão base |
| `DualGrid/Terrain1..3` | 1..3 | água, trilha, canteiro |
| `Structures/HouseWalls` | 5 | paredes com colisão |
| `Entities` | 10 | player, props, crops, máquinas (y-sort) |
| `Structures/HouseRoof` | 20 | telhado |
| `Rain` | 100 | chuva |
| `HUD` / `Shop` / `PauseMenu` | CanvasLayer 20/110/100 | UI |

## Verificação

```bash
Godot --headless --path . --script /tmp/diag3.gd
# Game children: [Ground(z=-10), DualGrid(z=0), Structures(z=0), Entities(z=10), ...]
```
