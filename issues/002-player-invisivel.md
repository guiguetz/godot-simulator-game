# 002 — Player não aparece

- **Status:** Corrigido
- **Severidade:** Alta
- **Sintoma:** o personagem não é visível na tela.

## Reprodução

1. Rodar `scenes/game.tscn`.
2. O sprite do player não aparece em lugar nenhum.

## Causa raiz

Mesma causa da [issue 001](001-chao-acima-de-tudo.md): o `Ground` (z 0, último
filho) e as camadas de terreno do dual grid (`Terrain1..3`, z 1..3) eram
desenhados **acima** de `Entities` (z 0), que contém o Player. O player estava
lá e se movendo, apenas encoberto.

Verificação de que o player existia e se movia (mesmo invisível), via teste
headless injetando eventos de teclado:

```
start=(328.0, 280.0)
D down -> axis=1.0 vel=(130.0, 0.0)
after D=(360.4998, 280.0)
A down -> axis=-1.0 vel=(-130.0, 0.0)
after A=(323.6667, 280.0)
```

## Correção aplicada

- `scenes/game.tscn` — `Entities` com `z_index = 10` (acima dos terrenos).
- `scripts/world.gd` — `Ground` com `z_index = -10` e movido para o início.

Nenhuma mudança no sprite em si foi necessária: os `SpriteFrames`
(`assets/sprites/player_basic_frames.tres`, frames 48x48, offset `(0,-8)`) já
estavam corretos.

## Verificação

- Smoke test: `PASS` em todas as checagens.
- Execução headless de 300+ frames sem erros.
- `diag3.gd` confirma `Entities z=10` e `Ground z=-10`.
