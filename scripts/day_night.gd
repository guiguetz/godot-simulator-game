extends CanvasModulate

## Tinge a cena conforme a hora (TimeManager.daylight): noite azulada,
## dia claro. Usa interpolacao suave.

const NIGHT := Color(0.30, 0.34, 0.56)
const DAY := Color(1.0, 1.0, 1.0)


func _process(_delta: float) -> void:
	var t := TimeManager.daylight()
	color = NIGHT.lerp(DAY, t)
