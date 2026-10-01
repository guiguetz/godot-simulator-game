class_name TestAudioManager
extends SimTestSuite

## Cobertura de `scripts/audio_manager.gd`: play_sfx e reação ao clima.

func test_play_sfx_nome_inexistente_nao_quebra() -> void:
	AudioManager.play_sfx("nome_que_nao_existe")
	# Sem crash = sucesso.


func test_on_weather_changed_liga_chuva() -> void:
	AudioManager.call("_on_weather_changed", Enums.Weather.RAIN)
	# Sem crash = sucesso (áudio dummy em headless).


func test_on_weather_changed_para_chuva() -> void:
	AudioManager.call("_on_weather_changed", Enums.Weather.RAIN)
	AudioManager.call("_on_weather_changed", Enums.Weather.CLEAR)
	# Sem crash = sucesso.