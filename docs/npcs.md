# NPCs e criaturas ambientais

Criaturas que dão vida ao mundo, em `scripts/critter.gd` (`Critter`). São
**ambientais**: não têm colisão, não interagem e **não entram no save**
(renascem a cada sessão na mesma posição). Spawn no mapa demo em
`world.gd:_setup_demo_entities`.

## Tipos

| Tipo | Comportamento |
|---|---|
| **Gato** (`CAT`) | Segue o player num raio de 120 px; senão, vaga perto de casa |
| **Rato** (`MOUSE`) | Foge do player num raio de 72 px |
| **Moradora** (`WOMAN`) | Vaga devagar perto de casa |
| **Slime** (`BLOB`) | Vaga bem devagar (speed 16 px/s) |

Os três primeiros usam folhas de 48×48 com 4 direções
(`assets/graphics/characters/`); o slime usa o esquema de linhas próprio.
Todos têm animações `idle`/`walk` por direção.

## Comportamento comum

- Vagueiam escolhendo alvos aleatórios num raio (`wander_radius`) em volta de
  um ponto `home`; ficam parados 1–2,6 s entre alvos.
- Se se afastarem demais (> raio + 80 px), voltam para casa na hora (nunca
  atravessam o mapa).
- Spawns atuais: gato (6,7), moradora (3,8), ratos (17,4) e (30,20), slime
  (10,13).

## Estender

Para um novo tipo: adicione em `Kind`, defina `speed`/`wander_radius` no
`setup()` e mapeie as folhas em `_frames_for()`/`_build_frames()`.