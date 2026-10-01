class_name GameSettings
extends RefCounted

## Configuracoes do jogador.
##
## Classe estatica (nao depende de autoload): acesse diretamente
## GameSettings.is_running(...), GameSettings.movement_mode, etc.
##
## O modo padrao e escolhido no menu de pausa (Esc > Opcoes > Jogabilidade).
## Sempre que o jogador segura Shift, o modo e invertido.

enum MovementMode { WALK, RUN }

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "gameplay"

## Modo padrao quando o jogador NAO segura Shift.
static var movement_mode: int = MovementMode.WALK
## Skin do personagem (indice em GameData.SKIN_FRAMES).
static var skin: int = 0
## Numero de skins disponiveis (espelha GameData.SKIN_FRAMES.size()).
const SKIN_COUNT := 6


static func _static_init() -> void:
	_load_config()


## Retorna true se o jogador esta correndo neste frame.
## Se o modo padrao e WALK, segurar Shift corre; se o modo padrao e RUN,
## segurar Shift anda. Assim o toggle do menu apenas troca o padrao.
static func is_running(shift_held: bool) -> bool:
	var default_is_run := movement_mode == MovementMode.RUN
	return default_is_run != shift_held


static func set_movement_mode(mode: int) -> void:
	mode = clampi(mode, MovementMode.WALK, MovementMode.RUN)
	if mode == movement_mode:
		return
	movement_mode = mode
	_save_config()


static func set_skin(index: int) -> void:
	if index < 0 or index >= SKIN_COUNT or index == skin:
		return
	skin = index
	_save_config()


static func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	movement_mode = clampi(
		int(cfg.get_value(SECTION, "movement_mode", MovementMode.WALK)),
		MovementMode.WALK,
		MovementMode.RUN
	)
	skin = clampi(int(cfg.get_value(SECTION, "skin", 0)), 0, SKIN_COUNT - 1)


static func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "movement_mode", movement_mode)
	cfg.set_value(SECTION, "skin", skin)
	cfg.save(CONFIG_PATH)
