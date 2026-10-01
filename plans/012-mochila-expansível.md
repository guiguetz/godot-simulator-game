# 012 — Mochila expansível com progressão

- **Status:** Proposto
- **Prioridade:** Média
- **Esforço:** M (dias)
- **Depende de:** —
- **Arquivos-alvo:** `scripts/inventory.gd`, `scripts/hud.gd`, `docs/inventory-shop.md`

## Objetivo

Inventário começa pequeno e pode ser expandido ao longo da progressão,
recompensando exploração e conquistas.

## Motivação / Contexto

O inventário atual tem 124 linhas e uma hotbar fixa de 9 slots. Stardew Valley
começa com 12 slots e pode ir a 36. Um sistema de mochila expansível adiciona
progressão e dá ao jogador motivo para gastar moedas/completar quests.
O código atual não suporta slots dinâmicos — precisa ser redesenhado.

## Comportamento esperado

- Player começa com **12 slots** (hotbar visível + estoque oculto).
- Pode expandir para 24 e depois 36 slots (2 upgrades).
- Upgrade é comprado na loja ou desbloqueado via quest.
- Hotbar mostra os primeiros 9 slots; o restante fica na "mochila" (abre com
  tecla `Tab` ou botão).
- Itens empilham (seeds, crops) até um limite por slot.
- Slot vazio mostra ícone de "vazio" no HUD.
- Inventário cheio: player não pode coletar item (som de erro + feedback).

## Design técnico

- **Refatoração de `inventory.gd`:**
  - Slots como `Array[InventorySlot]` em vez de dicionário fixo.
  - `InventorySlot`: `item_id: StringName`, `quantity: int`, `max_stack: int`.
  - `max_slots` começa em 12, expansível via `upgrade_inventory(tier)`.
- **Upgrade tiers:**
  ```gdscript
  const TIERS = {
    1: { "slots": 12, "cost": 0 },      # inicial
    2: { "slots": 24, "cost": 2000 },    # loja
    3: { "slots": 36, "cost": 5000 },    # loja ou quest
  }
  ```
- **Hotbar:** sempre mostra slots 0-8; a mochila (slots 9+) abre com `Tab`.
- **HUD:** atualizar `hud.gd` para renderizar slots dinamicamente.
  Hotbar: barra fixa na parte inferior. Mochila: painel overlay com grid.
- **Save:** salvar `max_slots` e cada slot (`item_id`, `quantity`).
  Compatibilidade com saves antigos: se `max_slots` não existir, assume 12.
- **Integração com loja:** botão "Expandir Mochila" na loja quando
  `current_tier < 3`.
- **Integração com mineração:** drop de minérios na caverna pode exigir
  mais espaço — motivação natural para upgrade.

## Escopo

- **Incluído:** refatoração do inventário para slots dinâmicos, 3 tiers
  de upgrade, UI da mochila (overlay), integração com loja, save/load
  compatível.
- **Fora do escopo:** inventário com drag-and-drop, tooltips detalhados,
  organização automática, filtro por tipo.

## Tarefas

- [ ] Refatorar `inventory.gd` para `Array[InventorySlot]` dinâmico
- [ ] Criar `InventorySlot` como Resource ou classe interna
- [ ] Implementar `upgrade_inventory(tier)` com validação de moedas
- [ ] Atualizar `hud.gd` para renderizar hotbar + painel da mochila
- [ ] Adicionar input `Tab` para abrir/fechar mochila
- [ ] Integrar upgrade com loja (botão "Expandir Mochila")
- [ ] Atualizar `SaveGame.gd` para salvar `max_slots` e slots
- [ ] Garantir compatibilidade com saves antigos
- [ ] Adicionar feedback de inventário cheio (som + mensagem)
- [ ] Documentar em `docs/inventory-shop.md` (seção de mochila)

## Critérios de aceite

- [ ] Player começa com 12 slots visíveis na hotbar.
- [ ] Comprar upgrade expande para 24 slots (12 na mochila oculta).
- [ ] Mochila abre com `Tab` e mostra grid de slots extras.
- [ ] Itens empilham corretamente (ex.: 99 sementes por slot).
- [ ] Inventário cheio impede coleta com feedback sonoro.
- [ ] Save/load preserva todos os slots e o tier atual.
- [ ] Smoke test cobre coleta e upgrade básico.

## Riscos / Notas

- **Breaking change:** refatorar `inventory.gd` afeta todo mundo que lê
  inventário (farming, loja, save, crafting). Mitigar: manter API pública
  compatível (`add_item()`, `remove_item()`, `has_item()`).
- **UI da mochila:** pode precisar de scroll se o grid for grande.
  Mitigar: usar `GridContainer` dentro de `ScrollContainer`.
- **Balanceamento de preços:** 2000/5000 são placeholders. Ajustar após
  testes de economia.