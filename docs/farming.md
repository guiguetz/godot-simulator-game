# Fazenda: aração, plantio e colheita

O ciclo da fazenda: **arar** grama/terra com a enxada, **plantar** a semente
no canteiro, **regar** todos os dias e **colher** a cultura madura. A lógica
vive em `scripts/world.gd` (`use_tool`), `scripts/crop.gd` e nos dados de
`scripts/data/game_data.gd`. Terreno e `tillable`: [`world.md`](world.md);
máquinas que regam sozinhas: [`machines.md`](machines.md).

## Ferramentas de fazenda

| Ferramenta | Ação |
|---|---|
| **Enxada** | Célula `tillable` e andável vira `SOIL`; em canteiro com cultura **pronta**, colhe |
| **Regador** | Molha a cultura da célula (sem cultura, só toca o som) |
| **Machado** | Árvore vira toco (2 madeira); toco é removido (1 madeira) |
| **Semente** | Planta a semente selecionada numa célula de `SOIL` vazia |

Regras de `use_tool` (em `world.gd`):

- **Plantar** exige `terrain_at(cell) == SOIL`, sem cultura e sem máquina na
  célula, e pelo menos 1 semente no inventário.
- A enxada **colhe primeiro**: se existe cultura `is_ready` na célula, a
  colheita acontece antes do teste de `tillable`.

## Culturas

Tabela real de `GameData.crops`:

| Semente | Custo (loja) | Dias p/ crescer | Colheita (venda) |
|---|---|---|---|
| Trigo | 3 | 2 | Trigo (4) |
| Tomate | 4 | 2 | Tomate (8) |
| Milho | 4 | 3 | Milho (6) |
| Abóbora | 6 | 4 | Abóbora (12) |

Crescimento (`crop.gd`): 4 estágios de sprite (`stage` 0–3). A cada dia novo
(`TimeManager.new_day`) `grow_day(auto_water)` sobe `days_grown` **somente se
a cultura estiver molhada** — regada na mão ou, em dia de chuva, via
`auto_water` (ver [`time-weather.md`](time-weather.md)). Quando atinge
`grow_days`, `is_ready` ativa; o campo `watered` é resetado a cada dia.

Regar de novo no mesmo dia não adianta; falta de rega **pausa o crescimento**
(não mata a planta). A enxada na cultura pronta → `harvest()` devolve o item
(uma unidade) e a cultura sai do mundo.

## Árvores e madeira

As árvores são `Prop` (`scripts/prop.gd`) com dois estados, `TREE` e `STUMP`.
O machado (`AXE`) chama `chop()`: no 1º golpe a **árvore vira toco** (+2
madeira); no 2º o **toco é removido** (+1 madeira). Madeira é o recurso de
máquinas (ver [`machines.md`](machines.md)).

## Hotbar

Slots 1–3 são enxada/regador/machado e o 6 é a semente (a variedade se troca
com `C`). Detalhes de inventário/hotbar: [`inventory-shop.md`](inventory-shop.md).

## Verificação

`tools/smoke_test.gd` cobre grama arável, terra arável, plantio, consumo de
semente e colheita. Rode:

```bash
godot --headless --path . --script tools/smoke_test.gd
```