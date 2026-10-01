# Decoração, construções e a casa

Dois sistemas de construção visual: o **modo decoração** (móveis com a tecla
`B` — `scripts/decor.gd`) e a **casa** fixa montada no início do jogo
(`scripts/house_builder.gd`). Ambos fazem parte do save.

## Modo decoração

Tecla **`B`** abre a paleta na parte inferior da tela — enquanto ativa, o
player fica imóvel e as ferramentas desativadas:

- **Clique esquerdo** coloca o item selecionado na célula sob o mouse;
- **Clique direito** remove;
- Seleção pelos botões da paleta (o botão ✕ desseleciona);
- Só coloca em célula **andável e desocupada** (`world.decor_place`).

Paleta (`GameData.DECOR`): cama, mesa, estante, tapete, planta, **TV**
(animada, 5 frames) e **comida** (animada, 4 frames). O save guarda célula +
índice da paleta (`world.to_dict` → `decor`).

## Casa (`house_builder.gd`)

No início do jogo, `world._build_house()` monta a casa no canto (2,3): duas
`TileMapLayer` geradas em código — paredes (`walls_nofloor.png`) e telhado
(`roof.png`), tiles de 16×16:

| Camada | Bloco | Colisão |
|---|---|---|
| `HouseWalls` | 3×3 (z 5) | célula cheia, **exceto** a porta no tile (1,1) |
| `HouseRoof` | 3×3 deslocado 2 acima (z 20) | nenhuma |

As paredes ganham polígono de física por tile (`add_collision_polygon`); o
telhado é puramente visual. A casa é decorativa — não há porta funcional.

## Vegetação espalhada

`world._scatter_decorations()` põe 70 tufos/pedras/arbustos/flores
(`decoration.png`, folha 4×2 tiles) sobre a grama, com **semente fixa**
(20240607) — o cenário é estável entre execuções e fica fora do save.

## Verificação

O smoke test coloca/remove uma decoração e valida a regra de célula ocupada
(`tools/smoke_test.gd`).