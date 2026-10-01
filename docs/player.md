# Player: movimento e andabilidade

Como o personagem (`scripts/player.gd`, cena `scenes/player.tscn`) se move e
como a colisão com tiles não-andáveis é resolvida.

## Movimento

- Top-down em 8 direções (`WASD` / setas / analógico), com modo andar/correr
  (`Shift`), configurável no menu de pausa.
- `Player` (`CharacterBody2D`) usa `move_and_slide()` com `velocity` calculada
  por frame; `_clamp_bounds()` mantém o personagem dentro de `world_bounds`.
- Ao usar uma ferramenta, `_busy` trava o movimento por `TOOL_TIME`.

## Andabilidade (caixa de pés)

O mundo expõe uma checagem de andabilidade (ver `scripts/world.gd`), injetada
em `Player.walkable_check`. A cada frame `_block_unwalkable()` testa a posição
seguinte e, se ela cair em tile bloqueado, tenta deslizar por um dos eixos
(só X ou só Y); se nenhum servir, zera a velocidade.

A checagem amostra os **4 cantos** de uma caixa em volta dos pés:

```gdscript
var half := Vector2(5.0, 3.0) + Vector2(collision_padding, collision_padding)
```

- `collision_padding` é exportado (0–16, passo 0.5) e o padrão é **2.0**.
- A meia-caixa é limitada por `MAX_FEET_HALF` (`TILE_SIZE / 2 - 0.5`, ou seja
  **7.5 px**) em cada eixo, garantindo que a caixa **nunca fique maior que um
  tile** (16 px).

### Por que esse limite existe

Com caixas maiores que um tile, um canto amostrava o tile vizinho mesmo com o
personagem parado no centro de um tile andável — o player "travava" em quinas
e bordas de água/mapa (issue #4). O limite mantém a caixa dentro do tile
atual, preservando o deslizamento suave ao passar perto de um tile bloqueado.

Para ajustar o *feel* da colisão, mexa em `collision_padding` (valores menores
deixam o player chegar mais perto de obstáculos); o teto de `MAX_FEET_HALF` é
um invariante e não deve ser aumentado sem revisar o teste de andabilidade.

## Direção e ferramentas

- `_facing` (`down`/`up`/`left`/`right`) vem da última direção de movimento e
  define a animação (`_update_animation`) e a célula alvo (`facing_cell`).
- `facing_cell()` converte a posição global para a célula de `TILE_SIZE` px à
  frente; é a célula usada por `world.use_tool()` e pelo posicionamento de
  máquinas.
