# 015 — Contorno do grid com ferramenta selecionada

- **Status:** Proposto
- **Prioridade:** Baixa
- **Esforço:** P (horas)
- **Depende de:** —
- **Arquivos-alvo:** scripts do jogador, HUD, configurações

## Objetivo

Exibir o contorno do tile onde a ferramenta será aplicada quando o jogador estiver com uma ferramenta selecionada na hotbar.

## Motivação / Contexto

Atualmente o jogador não tem indicação visual de qual tile será afetado pela ação, o que dificulta a precisão ao plantar, colher, arar, etc.

## Comportamento esperado

- Quando uma ferramenta está selecionada na hotbar, um contorno (outline) aparece no tile que será afetado.
- O contorno acompanha o tile sob o cursor/jogador.
- Quando nenhuma ferramenta está selecionada, o contorno desaparece.
- Opção habilitável/desabilitável nas configurações do jogo.

## Design técnico

- Usar um `TileMapLayer` separado ou um `Sprite2D` com textura de contorno para desenhar o highlight.
- Sinal de mudança de item selecionado na hotbar para ativar/desativar o contorno.
- Configuração persistida no sistema de save/load (bool `show_grid_outline`).

## Escopo

- **Incluído:** contorno visual, opção nas configurações, persistência
- **Fora do escopo:** contorno para múltiplos tiles (ex.: área de ataque)

## Tarefas

- [ ] Criar textura/sprite de contorno do tile
- [ ] Implementar lógica de posicionamento do contorno
- [ ] Adicionar opção nas configurações
- [ ] Persistir configuração no save/load
- [ ] Testar com todas as ferramentas

## Critérios de aceite

- [ ] Contorno visível apenas com ferramenta selecionada
- [ ] Contorno desaparece ao soltar a ferramenta
- [ ] Configuração persiste entre sessões

## Riscos / Notas

- Pode conflitar com o dual grid existente — verificar compatibilidade de coordenadas.