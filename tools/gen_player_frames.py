#!/usr/bin/env python3
"""Gera SpriteFrames (.tres) para o personagem a partir do sheet base.

O sheet tem frames de 48x48 (33 colunas x 4 linhas). Como as animacoes de
ferramenta alcancam fora do corpo, geramos TODOS os frames em 48x48 (celula
inteira). O Player usa offset (0,-8) para alinhar os pes.

Animacoes: idle_<dir>/walk_<dir> + ferramentas hoe/water/axe/sword/fish/seed.

Uso:
    python3 tools/gen_player_frames.py
"""

from __future__ import annotations

import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CELL = 48   # tamanho do frame no sheet
COLS = 33   # colunas do sheet

# direcao -> animacao -> indices de frame no sheet
ANIMS = {
    "down": {
        "idle": [0, 1],
        "walk": [2, 3, 4, 5],
        "axe": [6, 7, 8, 9],
        "water": [10, 11, 12, 13],
        "hoe": [14, 15, 16, 17],
        "fish": [18, 19, 20, 21],
        "sword": [22, 23, 24, 25],
        "seed": [26, 27, 28, 29],
    },
    "left": {
        "idle": [34, 35],
        "walk": [35, 36, 37, 38],
        "axe": [39, 40, 41, 42],
        "water": [43, 44, 45, 46],
        "hoe": [47, 48, 49, 50],
        "fish": [51, 52, 53, 54],
        "sword": [55, 56, 57, 58],
        "seed": [59, 60, 61, 62],
    },
    "right": {
        "idle": [67, 68],
        "walk": [68, 69, 70, 71],
        "axe": [72, 73, 74, 75],
        "water": [76, 77, 78, 79],
        "hoe": [80, 81, 82, 83],
        "fish": [84, 85, 86, 87],
        "sword": [88, 89, 90, 91],
        "seed": [92, 93, 94, 95],
    },
    "up": {
        "idle": [99, 100],
        "walk": [101, 102, 103, 104],
        "axe": [105, 106, 107, 108],
        "water": [109, 110, 111, 112],
        "hoe": [113, 114, 115, 116],
        "fish": [117, 118, 119, 120],
        "sword": [121, 122, 123, 124],
        "seed": [125, 126, 127, 128],
    },
}

SKINS = {
    "basic": "main_basic",
    "blue": "main_blue",
    "cowboy": "main_cowboy",
    "grey": "main_grey",
    "red": "main_red",
    "straw": "main_straw",
}

# animacoes de loop (idle/walk) vs de uso unico (ferramentas)
LOOPING = {"idle", "walk"}


def region_of(frame: int) -> tuple[int, int, int, int]:
    col = frame % COLS
    row = frame // COLS
    return (col * CELL, row * CELL, CELL, CELL)


def build_tres(texture_path: str) -> str:
    ids: dict[int, str] = {}
    sub: list[str] = []
    for order in ANIMS.values():
        for frames in order.values():
            for f in frames:
                if f not in ids:
                    ids[f] = f"atlas_{len(ids)}"

    for f, rid in ids.items():
        x, y, w, h = region_of(f)
        sub.append(
            f'[sub_resource type="AtlasTexture" id="{rid}"]\n'
            f'atlas = ExtResource("1_tex")\n'
            f"region = Rect2({x}, {y}, {w}, {h})\n"
        )

    anims: list[str] = []
    for direction, order in ANIMS.items():
        for kind, frames in order.items():
            entries = ", ".join(
                '{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % ids[f]
                for f in frames
            )
            speed = 1.0 if kind == "idle" else (8.0 if kind == "walk" else 12.0)
            loop = "true" if kind in LOOPING else "false"
            anims.append(
                '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %s\n}'
                % (entries, loop, kind, direction, speed)
            )

    load_steps = len(ids) + 2
    header = (
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{texture_path}" id="1_tex"]\n\n'
    )
    body = "\n".join(sub)
    return header + body + "\n[resource]\nanimations = [" + ", ".join(anims) + "]\n"


def main() -> None:
    out_dir = os.path.join(ROOT, "assets", "sprites")
    os.makedirs(out_dir, exist_ok=True)
    for skin, filename in SKINS.items():
        tex = f"res://assets/graphics/characters/main/{filename}.png"
        out = os.path.join(out_dir, f"player_{skin}_frames.tres")
        with open(out, "w", encoding="utf-8") as fh:
            fh.write(build_tres(tex))
        print("gerado:", os.path.relpath(out, ROOT))


if __name__ == "__main__":
    main()
