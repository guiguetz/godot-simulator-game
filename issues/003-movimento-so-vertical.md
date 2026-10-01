# 003 — Movimento percebido apenas na vertical

- **Status:** Corrigido (era efeito colateral das issues 001/002)
- **Severidade:** Média
- **Sintoma:** parecia só dar para andar para cima/baixo; esquerda/direita
  "não funcionava".

## Reprodução

1. Rodar o jogo (com o player invisível — issues 001/002).
2. Tentar andar para os lados: parece não acontecer nada.

## Causa raiz

**O movimento estava correto nas 4 direções.** Testes headless injetando
eventos de teclado confirmaram `move_left`/`move_right` com `axis = ±1.0` e
deslocamento real do player.

O que acontecia era uma combinação de percepção:

1. O player estava **invisível** (issue 002), então não havia referência visual
   de movimento.
2. O spawn é em `(20*16+8, 17*16+8)` = célula `(20,17)`, **em cima da trilha de
   terra**, que é uma faixa horizontal de 2 tiles (`y = 17 e 18`) atravessando
   o mapa inteiro.
   - Andar para **esquerda/direita** permanece na trilha: como a câmera segue o
     player, a textura sob a câmera continua igual → parece que nada se move.
   - Andar para **cima/baixo** cruza grama ↔ trilha → a mudança visual é óbvia.

Ou seja, o "só vertical" era o único eixo em que a mudança de terreno sob a
câmera ficava visível.

## Correção aplicada

Corrigido ao resolver as issues 001/002 (z-order). Com o player visível, o
movimento horizontal passa a ser perceptível. Nenhuma alteração na lógica de
input/movimento foi necessária.

Evidência (antes/depois da correção, o movimento já funcionava):

```
D down -> axis=1.0  vel=(130.0, 0.0)   after D=(360.50, 280.0)
A down -> axis=-1.0 vel=(-130.0, 0.0)  after A=(323.67, 280.0)
```

## Verificação

- `tools/smoke_test.gd`: tudo `PASS`.
- Eventos de teclado reais (`InputEventKey`) movem o player em X e Y.

## Observação

O spawn sobre a trilha (uniforme) ainda é um ponto ruim de UX para orientação.
Um follow-up possível é reposicionar o spawn inicial para uma área com mais
referência visual (ex.: perto da casa/canteiro).
