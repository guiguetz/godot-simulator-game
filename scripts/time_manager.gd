extends Node

## Relogio do jogo. Autoload `TimeManager`.
## Um dia vai de 00:00 a 24:00; ao virar, emite `new_day` (crops crescem,
## clima muda). O tint de dia/noite e aplicado por scripts/day_night.gd.

signal time_changed(hour: int, minute: int)
signal new_day(day: int)

const MINUTES_PER_DAY := 24 * 60

var day := 1
var minutes := 6.0 * 60.0
## Minutos de jogo por segundo real (2 => dia completo ~12 min reais).
var minutes_per_second := 2.0
var paused := false


func _process(delta: float) -> void:
	if paused or Engine.is_editor_hint():
		return
	minutes += minutes_per_second * delta
	if minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		day += 1
		emit_signal("new_day", day)
	var h := get_hour()
	var m := get_minute()
	if m != _last_minute:
		_last_minute = m
		emit_signal("time_changed", h, m)


var _last_minute := -1


func get_hour() -> int:
	return int(minutes) / 60


func get_minute() -> int:
	return int(minutes) % 60


func time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]


## 0.0 = noite fechada, 1.0 = dia claro. Usado pelo CanvasModulate.
func daylight() -> float:
	var h := float(get_hour()) + get_minute() / 60.0
	if h < 5.0:
		return 0.0
	if h < 8.0:
		return (h - 5.0) / 3.0
	if h < 18.0:
		return 1.0
	if h < 21.0:
		return 1.0 - (h - 18.0) / 3.0
	return 0.0


func to_dict() -> Dictionary:
	return {"day": day, "minutes": minutes}


func from_dict(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	minutes = float(data.get("minutes", 6.0 * 60.0))
