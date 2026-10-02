class_name SimTestSuite
extends GdUnitTestSuite

## Base de todas as suítes de teste do projeto.
##
## Isola o estado global antes de cada caso:
##   - autoloads (Inventory, TimeManager, Weather, GameSettings)
##   - RNG global (seed(12345) -> série determinística)
##   - arquivos do usuário (user://savegame.json e user://settings.cfg)
##
## Suítes de cena não fazem nada especial: herdam daqui e qualquer
## `before_test` próprio deve começar chamando `SimTestSuite.reset_state()`.
##
## Nota de design: as suítes de teste DEVEM herdar de SimTestSuite (ou outro
## filho de GdUnitTestSuite) e o script deve se registrar no cache global
## de classes (godot --headless --path . --import) para que o scanner do
## gdUnit as descubra.

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"

var _backup_save := PackedByteArray()
var _backup_settings := PackedByteArray()


func before_test() -> void:
	reset_state()
	_backup_user_files()


func after_test() -> void:
	_restore_user_files()


# --- Estado global ------------------------------------------------------------

static func reset_state() -> void:
	reset_inventory()
	reset_time()
	reset_weather()
	reset_settings()
	reset_savegame()
	seed(12345)


static func reset_inventory() -> void:
	Inventory.items.clear()
	Inventory.seeds.clear()
	Inventory.coins = 100
	Inventory.selected_seed = Enums.Seed.TOMATO
	Inventory.selected_slot = 0


static func reset_time() -> void:
	TimeManager.day = 1
	TimeManager.minutes = 6.0 * 60.0
	TimeManager.minutes_per_second = 2.0
	TimeManager.paused = false


static func reset_weather() -> void:
	Weather.kind = Enums.Weather.CLEAR


static func reset_settings() -> void:
	GameSettings.movement_mode = GameSettings.MovementMode.WALK
	GameSettings.skin = 0


static func reset_savegame() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


# --- Arquivos do usuário ------------------------------------------------------

## Salva os arquivos reais do jogador/desenvolvedor e inicia limpo.
func _backup_user_files() -> void:
	_backup_save = SimTestSuite._read_file(SAVE_PATH)
	_backup_settings = SimTestSuite._read_file(SETTINGS_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## Restaura os arquivos reais ao encerrar o caso.
func _restore_user_files() -> void:
	SimTestSuite._write_file(SAVE_PATH, _backup_save)
	SimTestSuite._write_file(SETTINGS_PATH, _backup_settings)


static func _read_file(path: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return PackedByteArray()
	var data := f.get_buffer(f.get_length())
	f.close()
	return data


static func _write_file(path: String, data: PackedByteArray) -> void:
	if data.is_empty():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_buffer(data)
	f.close()


# --- Cenas ------------------------------------------------------------------

## Bota `res://scenes/game.tscn` y devuelve el nodo del mundo (script world.gd).
## O root de game.tscn é o próprio nó `Game` com o script world.gd.
##
## O runner criado se auto-libera ao encerrar o caso (auto_free), com o
## que cada teste inicia com uma cena fresca sem deixar nós órfãos.
func boot_game() -> Variant:
	var runner := scene_runner("res://scenes/game.tscn")
	await_idle_frame()
	var world: Node = runner.scene()
	# Tests assert against the procedural demo map. Do not depend on cells saved
	# in game.tscn by editor sessions; regenerate the fixture for every test.
	world.call("_seed_demo")
	world.call("_rebuild_walkable")
	await_idle_frame()
	return world