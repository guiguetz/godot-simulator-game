extends Node

## Clima. Autoload `Weather`. Sorteia a cada novo dia.
## Quando chove, scripts/rain.gd mostra a chuva e as plantacoes ficam molhadas.

signal changed(kind: int)

var kind: int = Enums.Weather.CLEAR


func _ready() -> void:
	TimeManager.new_day.connect(_on_new_day)


func _on_new_day(_day: int) -> void:
	roll()


func roll() -> void:
	kind = Enums.Weather.RAIN if randf() < 0.25 else Enums.Weather.CLEAR
	emit_signal("changed", kind)


func is_raining() -> bool:
	return kind == Enums.Weather.RAIN


func name_string() -> String:
	return "Chuvoso" if is_raining() else "Limpo"
