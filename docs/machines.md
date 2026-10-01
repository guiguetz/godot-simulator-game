# Máquinas: aspersor, espantalho e pescador

Entidades **colocadas no mundo** a partir dos 3 últimos slots da hotbar
(7–9). Custam **madeira** e têm efeito diário automático. Visual em
`scripts/machine.gd`, colocação e ciclo diário em `scripts/world.gd`
(`place_machine`, `_on_new_day`); preços em `GameData.machine_cost`.

## Colocação

Slot selecionado + `Espaço` na célula à frente (`player.gd` →
`world.place_machine`). Regras:

- a célula precisa ser **andável**, sem cultura e sem outra máquina;
- o custo em madeira é pago na hora (`GameData.pay`); sem recurso suficiente,
  nada acontece;

| Máquina | Custo | Efeito diário |
|---|---|---|
| **Aspersor** | 10 madeira | Rega a própria célula e as 4 vizinhas (N/S/L/O) |
| **Espantalho** | 8 madeira | Decorativo (sem efeito mecânico) |
| **Pescador** | 15 madeira | Com água numa das 4 células vizinhas, 70% de chance de +1 peixe por dia |

## Ciclo diário

A cada `new_day`, `world._on_new_day` roda nesta ordem:

1. **aspersores** molham as culturas ao redor (como um regador);
2. **pescadores** pescam (se `_near_water(cell)`), 70% de chance;
3. as culturas crescem (ver [`farming.md`](farming.md)).

Regar/colher não consomem nada além do custo inicial; a máquina fica até ser
sobrescrita pelo save/load (máquinas não são removíveis em jogo).

## Referência

- `machine.gd` monta `AnimatedSprite2D` por tipo (folhas em
  `assets/graphics/machines/`), com offset por máquina, e serializa em
  `to_dict()` (`{"cell", "kind"}`).
- `Enums.Machine`: `SPRINKLER`, `FISHER`, `SCARECROW`.

## Verificação

O smoke test coloca um aspersor e confere o pagamento de madeira
(`tools/smoke_test.gd`).