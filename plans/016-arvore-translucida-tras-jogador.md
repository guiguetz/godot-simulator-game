# 016 — Árvore translúcida quando jogador está atrás

- **Status:** Proposto
- **Prioridade:** Média
- **Esforço:** M (dias)
- **Depende de:** —
- **Arquivos-alvo:** sprites das árvores, sistema de y-sort/obstáculos

## Objetivo

Quando o jogador passa por trás de uma árvore, o sprite dela fica translúcido para manter o jogador visível.

## Motivação / Contexto

Com o y-sort ativo, objetos como árvores ficam na frente do jogador quando ele está atrás, ocultando-o completamente. Isso prejudica a jogabilidade e a percepção espacial.

## Comportamento esperado

- Quando o jogador está atrás de uma árvore (y-sort a coloca na frente), o alpha do sprite da árvore é reduzido.
- A transição deve ser suave (tween/fade), não abrupta.
- Quando o jogador sai da área, a árvore volta à opacidade normal.
- A colisão da árvore não é afetada.

## Design técnico

- Detectar sobreposição usando `Area2D` nas árvores (camada de detecção, não colisão).
- Quando o jogador entra na área e está com Y menor (atrás), aplicar `modulate.a = 0.4` com tween.
- Quando sai, restaurar `modulate.a = 1.0` com tween.
- Considerar usar shader com dissolve ou fade para efeito mais polido.

## Escopo

- **Incluído:** fade de árvores, transição suave, detecção por área
- **Fora do escopo:** outros objetos (máquinas, cercas) — pode ser generalizado depois

## Tarefas

- [ ] Adicionar `Area2D` de detecção nas árvores
- [ ] Implementar detecção de jogador atrás (Y < árvore)
- [ ] Aplicar tween de alpha
- [ ] Restaurar alpha ao sair da área
- [ ] Testar com diferentes tipos de árvores

## Critérios de aceite

- [ ] Árvore fica translúcida quando jogador está atrás
- [ ] Transição suave (não abrupta)
- [ ] Árvore volta ao normal quando jogador sai
- [ ] Colisão não é afetada

## Riscos / Notas

- Múltiplas árvores sobrepostas podem gerar flickering — limitar a 1 árvore translúcida por vez ou aplicar em todas da área.