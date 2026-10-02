# Save / Load

Persistência do jogo em **dois arquivos**:

| Arquivo | Conteúdo | Formato |
|---|---|---|
| `user://savegame.json` | estado do jogo (mundo + player) | JSON versionado |
| `user://settings.cfg` | preferências (andar/correr, skin) | `ConfigFile` |

## Estado do jogo (`SaveGame`)

Autoload `scripts/save_game.gd`; acionado no menu de pausa (**Esc > Salvar /
Carregar**). `savegame.json` tem `version: 1` e guarda:

- `inventory` — itens, sementes, seleções e moedas (`Inventory.to_dict()`);
- `time` — dia e minuto (`TimeManager.to_dict()`);
- `weather` — clima atual (`Weather.kind`);
- `player_position` — posição global do player;
- `world` — terreno, árvores/tocos, plantações (com estágio e rega), máquinas
  e decorações (`world.to_dict()`).

API: `has_save()`, `save_game()`, `load_game()`, `delete_save()`.

> O campo `version` existe para migrações (ver
> [`docs/adr/005-versionamento-de-save.md`](adr/005-versionamento-de-save.md)):
> ao mudar o formato, incremente a versão e migre no `load_game()`.

## Mundo (`world.gd`)

`to_dict()/from_dict()` serializa:

- `terrain`: lista `[x, y, tipo]` (água/terra/canteiro);
- `props`: `Prop.to_dict()` (célula, árvore **ou** toco);
- `crops`: `Crop.to_dict()` (semente, estágio, dias crescidos, regada, pronta);
- `machines`: `Machine.to_dict()` (célula, tipo);
- `decor`: células + índice em `GameData.DECOR`.

No load, `from_dict` limpa as entidades e as três camadas `TileMapDual`, repinta
cada tipo pela API do mundo e reconstrói a andabilidade. O addon recalcula as
transições a partir das células lógicas; NPCs são ambientais e **não** são
serializados (renascem).

## Preferências (`GameSettings`)

`user://settings.cfg`, seção `gameplay`, guarda `movement_mode`
(Andar/Correr) e `skin`. Classe estática — acessada via
`GameSettings.movement_mode/skin`, sem autoload. Configurado em
**Esc > Opções > Jogabilidade / Aparência**.

## Verificação

O smoke test salva, carrega e confere **moedas** e **terreno** preservados
(`tools/smoke_test.gd`).