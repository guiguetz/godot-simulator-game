extends Node

## Audio. Autoload `AudioManager`. Toca SFX, musica e ambiente de chuva
## usando os sons importados de assets/audio/.

const SFX := {
	"hoe": preload("res://assets/audio/hoe.wav"),
	"axe": preload("res://assets/audio/axe.wav"),
	"water": preload("res://assets/audio/water.ogg"),
	"fish": preload("res://assets/audio/fish.wav"),
	"step": preload("res://assets/audio/step.mp3"),
	"slime": preload("res://assets/audio/slime.ogg"),
}
const MUSIC := preload("res://assets/audio/music.mp3")
const RAIN := preload("res://assets/audio/rain.mp3")

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _rain_player: AudioStreamPlayer


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -12.0
	add_child(_music_player)

	_rain_player = AudioStreamPlayer.new()
	_rain_player.bus = "Master"
	_rain_player.volume_db = -8.0
	add_child(_rain_player)

	Weather.changed.connect(_on_weather_changed)
	play_music()
	_on_weather_changed(Weather.kind)


func play_sfx(name: StringName, volume_db: float = 0.0) -> void:
	var stream: AudioStream = SFX.get(name)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = volume_db
	_sfx_player.play()


func play_music() -> void:
	if _music_player.playing:
		return
	_music_player.stream = MUSIC
	_music_player.play()


func _on_weather_changed(kind: int) -> void:
	if kind == Enums.Weather.RAIN:
		if not _rain_player.playing:
			_rain_player.stream = RAIN
			_rain_player.play()
	elif _rain_player.playing:
		_rain_player.stop()
