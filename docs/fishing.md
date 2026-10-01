# Pesca

Com a **Vara** (slot 5) de frente para a **água** — célula com água ou uma das
4 vizinhas, `world.can_fish(cell)` — `Espaço` abre um **minigame de barra**
(`scripts/fishing.gd`, CanvasLayer na camada 30). Enquanto ativo, o player fica
imóvel e o jogo para de receber movimentação. Pausar o jogo **cancela** a
pescaria sem conceder item.

## Minigame

- Um **peixe** sobe e desce pela trilha, mudando de direção a cada 0,35–1 s
  (`_fish_retarget`).
- Segurar **`Espaço`** sobe a barra de captura e gasta a barra verde de
  **resistência**; soltar faz a barra descer e recupera resistência.
- Manter o peixe dentro da barra enche o **progresso** (começa em 50%);
  deixar escapar drena.
- Progresso cheio → **pega o peixe**: o item vai para o inventário e toca
  `AudioManager.play_sfx("fish")`; progresso zerado → **escapou** (som de
  água). A UI fecha sozinha em ambos os casos.

## Peixes

Sorteio por **peso** em `GameData.FISH_LOOT` (`roll_fish()`), chamado pelo
player ao usar a vara:

| Peixe | Peso | Dificuldade |
|---|---|---|
| Dourado | 60 | 0.35 |
| Cinza | 30 | 0.55 |
| Prateado | 10 | 0.80 |

A **dificuldade** acelera o peixe (55→135 px/s) e piora o ganho/perda de
progresso — pescar o prateado é o desafio do jogo. Além do minigame, o
**pescador** (máquina) coleta peixe passivamente: [`machines.md`](machines.md).

## Referência

- `fishing.gd`: UI 100% em código (`assets/graphics/ui/fish_*.png`,
  `bar.png`, `v_bar.png`, `fisher_bar.png`); sinal `finished(win, item)`;
  `cancel()` ao pausar.
- `world.gd:can_fish()` — condição para iniciar; `player.gd:_use_selected`
  decide entre abrir o minigame e usar a ferramenta.

## Verificação

O smoke test inicia a pesca num lago, confere que o minigame ativou e que o
peixe sorteado é válido (`tools/smoke_test.gd`).