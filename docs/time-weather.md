# Tempo, dia/noite e clima

Relógio e clima do mundo, em autoloads: `scripts/time_manager.gd`,
`scripts/weather.gd`, `scripts/day_night.gd` (tint) e `scripts/rain.gd`
(overlay de chuva).

## Tempo (`TimeManager`)

- O dia vai de 00:00 a 24:00 e começa no **dia 1 às 06:00**.
- Progressão: `minutes_per_second = 2.0` → um dia completo dura
  **~12 minutos reais**.
- Sinais: `time_changed(hour, minute)` a cada minuto de jogo;
  `new_day(day)` ao virar o dia (as culturas crescem e o clima é sorteado).
- API: `get_hour()/get_minute()/time_string()`; `daylight()` devolve 0.0
  (noite fechada) a 1.0 (dia claro): nasce 05–08 e anoitece 18–21.

## Dia / noite (`day_night.gd`)

Um `CanvasModulate` interpola de `NIGHT` (azulado) para `DAY` (branco)
seguindo `TimeManager.daylight()` — o tint é suave na transição.

## Clima (`Weather`)

- A cada `new_day` há **25% de chance de chuva** (`roll()`); no resto dos
  dias, tempo limpo.
- Quando chove: as culturas **crescem sem precisar de rega**
  (`world._on_new_day` chama `grow_day(auto_water=true)`), toca o loop de
  chuva no áudio e o overlay aparece.
- API: `kind` (`Enums.Weather.CLEAR/RAIN`), `is_raining()`,
  `name_string()`, sinal `changed(kind)`.

## Chuva (`rain.gd`)

Overlay em coordenadas de mundo que segue a câmera: 160 gotas desenhadas em
código, com respingos (`drops.png`) e poças (`floor.png`) ao tocar o chão.
Só ativo quando `Weather.is_raining()`.

## Verificação

O smoke test não depende de hora; o efeito da chuva no crescimento é coberto
indiretamente pelo ciclo de culturas (ver [`farming.md`](farming.md)).