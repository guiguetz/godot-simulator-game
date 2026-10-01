extends Node

## Persistencia do jogo. Autoload `SaveGame`.
## Junta o estado de Inventory/TimeManager/Weather + o mundo (grupo "world")
## e o player (grupo "player") num JSON em user://savegame.json.

const PATH := "user://savegame.json"


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func save_game() -> bool:
	var world := get_tree().get_first_node_in_group("world")
	var player := get_tree().get_first_node_in_group("player")
	var data := {
		"version": 1,
		"inventory": Inventory.to_dict(),
		"time": TimeManager.to_dict(),
		"weather": Weather.kind,
		"player_position": [player.global_position.x, player.global_position.y] if player else [0, 0],
		"world": world.to_dict() if world and world.has_method("to_dict") else {},
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveGame: nao foi possivel abrir %s" % PATH)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveGame: arquivo invalido")
		return false
	Inventory.from_dict(parsed.get("inventory", {}))
	TimeManager.from_dict(parsed.get("time", {}))
	Weather.kind = int(parsed.get("weather", Enums.Weather.CLEAR))
	Weather.changed.emit(Weather.kind)
	var player := get_tree().get_first_node_in_group("player")
	var pos: Array = parsed.get("player_position", [0, 0])
	if player:
		player.global_position = Vector2(float(pos[0]), float(pos[1]))
	var world := get_tree().get_first_node_in_group("world")
	if world and world.has_method("from_dict"):
		world.from_dict(parsed.get("world", {}))
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)
