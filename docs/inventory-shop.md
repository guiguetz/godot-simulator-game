# Inventário, HUD e loja

Economia do jogador: itens, sementes, moedas e a hotbar. Vive nos autoloads
`scripts/inventory.gd`, `scripts/hud.gd`, `scripts/shop.gd` e nos dados de
`scripts/data/game_data.gd`.

## Inventário (autoload `Inventory`)

- Itens e sementes ficam em mapas **separados** porque `Enums.Item` e
  `Enums.Seed` têm valores sobrepostos (ex.: `Item.WOOD == Seed.TOMATO`).
- Estado inicial: **20 madeira, 3 maçãs, 5 de cada semente, 100 moedas**.
- API: `count/add_item/remove_item/has_item`, `add_coins/spend_coins`,
  `seed_count/add_seed/remove_seed/seed_next`, `set_slot`,
  `current_entry()` (entrada da hotbar selecionada).
- Emite o sinal **`changed`** em toda alteração — HUD e loja escutam.

## Hotbar e seleção

`GameData.hotbar` define os 9 slots: 6 ferramentas (enxada, regador, machado,
espada, vara, semente) + 3 máquinas (aspersor, espantalho, pescador).
Seleção: `1`–`9`, roda do mouse e `Q`/`E` (`via hud.gd`). A variedade de
semente era selecionada com `C` (`seed_next`) — a conta aparece no slot 6.

## HUD (`scripts/hud.gd`)

Montado em código na camada 20: hotbar (com contador de semente no slot 6),
moedas, semente selecionada, resumo de itens ("Itens: ...") e relógio
(`Dia N hh:mm Clima`). Escuta `Inventory.changed`, `TimeManager` e
`Weather.changed`.

## Loja (`scripts/shop.gd`)

Aberta pelo menu de pausa (**Esc > Loja**), camada 110.

- **Comprar sementes:** os preços de `GameData.seed_prices` —
  tomate 4, milho 4, abóbora 6, trigo 3 moedas.
- **Vender tudo:** vende todos os **itens** do inventário pelo `value` de cada
  um (`GameData.items`); sementes não são vendidas.

## Serialização

`Inventory.to_dict()/from_dict()` guarda itens, sementes, seleções e moedas —
usado pelo save/load ([`save-load.md`](save-load.md)).