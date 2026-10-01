# Testes — gdUnit4

## Como rodar

```bash
# Suíte completa (headless)
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
  -a tests --ignoreHeadlessMode -c

# Um arquivo
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
  -a tests/unit/test_inventory.gd --ignoreHeadlessMode -c

# Um caso
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
  -a "res://tests/unit/test_inventory.gd:test_signal_changed" --ignoreHeadlessMode -c
```

> Na primeira execução (ou ao criar novos scripts), rode `godot --headless --path . --import` para atualizar a cache de classes.

## Convenções

- **Nomenclatura:** `test_<feature>.gd`, funções `test_<comportamento>()`.
- **Identificadores em inglês**, comentários em português (pt-BR).
- **Base de teste:** todas as suítes herdam de `SimTestSuite` (`tests/helpers/sim_test_suite.gd`), que isola estado global (autoloads, RNG, save, settings) antes de cada caso.
- **Lambdas:** variáveis locais inteiras são capturadas por **valor** em lambdas do GDScript. Use arrays `[0]` ou variáveis de instância para contadores dentro de lambdas.
- **Nós órfãos:** use `auto_free()` para registrar objetos Node; o gdUnit libera ao fim do caso.
- **Cenas:** suítes de mundo/UI/integração usam `boot_game()` para instanciar `game.tscn` via `scene_runner` (auto-freed).
- **Métodos privados de world.gd:** como `world.gd` não tem `class_name`, acesse via `w.call("method", args)`.
- **Input:** não simule InputEvent em headless. Chame métodos diretamente.
- **Random:** `seed(12345)` no `before_test` (via `SimTestSuite.reset_state()`). Teste invariantes, não valores exatos.

## Estrutura

```
tests/
  helpers/
    sim_test_suite.gd        # Base: reset de autoloads, RNG, save, settings
  unit/
    data/
      test_enums.gd           # Valores/ordem dos enums
      test_game_data.gd       # Nomes, preços, roll_fish, can_afford/pay
    test_inventory.gd         # Itens, moedas, sementes, serialização
    test_time_manager.gd      # Hora, dia, daylight, pausa, serialização
    test_weather.gd           # Sorteio, estado, nome, reação a new_day
    test_settings.gd          # Tabela-verdade, clamps, persistência
    test_crop.gd              # Regar, crescer, colher, serializar
    test_prop.gd              # Árvore em dois golpes
    test_machine.gd           # Setup por tipo, frames
    test_critter.gd           # Parâmetros, frames, orientação, retorno
    test_dual_grid.gd         # Setup, máscaras→tiles, 16 combinações
    test_house_builder.gd     # Casa 3x3, colisão, porta
  world/
    test_world_terrain.gd     # Terreno, andabilidade, pesca, arável
    test_world_tools.gd       # Enxada, machado, regador, semente, colheita
    test_world_machines.gd    # Colocação de máquinas
    test_world_decor.gd       # Decoração colocar/remover
    test_world_daily.gd       # Aspersor, pescador, crescimento, chuva
    test_world_serialization.gd # to_dict/from_dict roundtrip
    test_world_player.gd      # Player, facing, andabilidade, skins
  ui/
    test_fishing.gd           # Minigame de pesca
    test_decor_mode.gd        # Modo decoração
    test_hud.gd               # Hotbar, moedas, relógio
    test_shop.gd              # Compra/venda
    test_pause_menu.gd        # Pausa, salvar/carregar
    test_rain.gd              # Chuva, splash cap
    test_day_night.gd         # Cor segue daylight
    test_audio_manager.gd     # SFX, reação ao clima
  integration/
    test_boot_game.gd         # Instanciação, grupos, nós
    test_farming_loop.gd      # Arar→plantar→regar→colher
    test_machine_loop.gd      # Aspersor/pescador
    test_fishing_flow.gd      # Pesca ponta a ponta
    test_save_load_flow.gd    # Salvar/carregar/deletar
    test_pause_shop_flow.gd   # Pausa→loja→compra
  regression/
    test_issue_001_z_order.gd   # z_index Ground < Entities
    test_issue_002_player_visivel.gd  # Player visível
    test_issue_003_movimento_horizontal.gd  # Movimento horizontal
    test_issue_004_walkable_box.gd  # Caixa de andabilidade ≤ meio tile
```

## Mapa de cobertura

| Sistema | Arquivo | Casos principais |
|---|---|---|
| Enums | `unit/data/test_enums.gd` | Valores/ordem |
| GameData | `unit/data/test_game_data.gd` | Nomes, valores, roll_fish, pay |
| Inventory | `unit/test_inventory.gd` | add/remove/count, moedas, sementes, serialização |
| TimeManager | `unit/test_time_manager.gd` | Hora, daylight, pausa, new_day |
| Weather | `unit/test_weather.gd` | Sorteio, estado, reação a new_day |
| Settings | `unit/test_settings.gd` | is_running, clamps, persistência |
| Crop | `unit/test_crop.gd` | Regar, crescer, colher, restore |
| Prop | `unit/test_prop.gd` | Dois golpes, to_dict |
| Machine | `unit/test_machine.gd` | Setup, frames, to_dict |
| Critter | `unit/test_critter.gd` | Parâmetros, frames, face, retorno |
| DualGrid | `unit/test_dual_grid.gd` | Setup, máscaras, 16 combinações |
| HouseBuilder | `unit/test_house_builder.gd` | 3x3, colisão, porta |
| World terreno | `world/test_world_terrain.gd` | terrain_at, set_terrain, walkable, can_fish |
| World ferramentas | `world/test_world_tools.gd` | Enxada, machado, semente, colheita |
| World máquinas | `world/test_world_machines.gd` | place_machine, custo, validação |
| World decoração | `world/test_world_decor.gd` | decor_place/remove |
| World ciclo diário | `world/test_world_daily.gd` | Aspersor, pescador, crescimento, chuva |
| World serialização | `world/test_world_serialization.gd` | Roundtrip terreno/props/crops/máquinas |
| World player | `world/test_world_player.gd` | Facing, walkable, skins, MAX_FEET_HALF |
| Pesca | `ui/test_fishing.gd` | start, finish, cancel, signal |
| Decor | `ui/test_decor_mode.gd` | toggle, open, close, select |
| HUD | `ui/test_hud.gd` | 9 slots, moedas, sementes, itens |
| Shop | `ui/test_shop.gd` | Comprar, vender, voltar |
| PauseMenu | `ui/test_pause_menu.gd` | Pausa, salvar, carregar |
| Rain | `ui/test_rain.gd` | Visibilidade, splash cap |
| DayNight | `ui/test_day_night.gd` | Cor dia/noite |
| AudioManager | `ui/test_audio_manager.gd` | SFX, clima |
| Integração | `integration/*.gd` | Boot, fazenda, máquinas, pesca, save, pausa+loja |
| Regressão | `regression/*.gd` | Issues #1–#4 |