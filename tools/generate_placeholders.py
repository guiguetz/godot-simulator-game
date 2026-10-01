#!/usr/bin/env python3
"""Gera os assets placeholder do jogo (tiles + personagem).

Estes arquivos sao apenas provisorios: substitua os PNGs em assets/ pelos
seus sprites definitivos, mantendo as mesmas dimensoes/grade.

Uso:
    python3 tools/generate_placeholders.py
"""

from __future__ import annotations

import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILES_DIR = os.path.join(ROOT, "assets", "tiles")
SPRITES_DIR = os.path.join(ROOT, "assets", "sprites")

TILE = 16


# ---------------------------------------------------------------------------
# Utilitarios
# ---------------------------------------------------------------------------
def _ensure_dirs() -> None:
    os.makedirs(TILES_DIR, exist_ok=True)
    os.makedirs(SPRITES_DIR, exist_ok=True)


def _shade(color: tuple[int, int, int], factor: float) -> tuple[int, int, int, int]:
    return (
        max(0, min(255, int(color[0] * factor))),
        max(0, min(255, int(color[1] * factor))),
        max(0, min(255, int(color[2] * factor))),
        255,
    )


# ---------------------------------------------------------------------------
# Chao base (grama) - tile unico de 16x16
# ---------------------------------------------------------------------------
def make_grass_tile(seed: int = 1) -> Image.Image:
    rng = random.Random(seed)
    base = (106, 170, 90)
    img = Image.new("RGBA", (TILE, TILE), base + (255,))
    px = img.load()
    for y in range(TILE):
        for x in range(TILE):
            n = rng.randint(-10, 10)
            px[x, y] = (
                max(0, min(255, base[0] + n)),
                max(0, min(255, base[1] + n)),
                max(0, min(255, base[2] + n)),
                255,
            )
    # pequenos tufos de grama
    for _ in range(6):
        x = rng.randint(1, TILE - 2)
        y = rng.randint(2, TILE - 1)
        px[x, y] = (78, 140, 66, 255)
        px[x, y - 1] = (78, 140, 66, 255)
    return img


# ---------------------------------------------------------------------------
# Dual-grid: folha 4x4 = 16 posicoes
#
#   bit0 = canto superior-esquerdo (TL)
#   bit1 = canto superior-direito  (TR)
#   bit2 = canto inferior-esquerdo (BL)
#   bit3 = canto inferior-direito  (BR)
#
#   coluna (x) = bit0 + bit1*2
#   linha  (y) = bit2 + bit3*2
# ---------------------------------------------------------------------------
def make_dual_grid_sheet(color: tuple[int, int, int], seed: int = 0,
                         with_dots: bool = False) -> Image.Image:
    rng = random.Random(seed)
    half = TILE // 2
    img = Image.new("RGBA", (TILE * 4, TILE * 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    dark = _shade(color, 0.62)

    # quadrantes: (bit, dx, dy)
    quads = [
        (1, 0, 0),  # TL
        (2, half, 0),  # TR
        (4, 0, half),  # BL
        (8, half, half),  # BR
    ]
    # vizinhos internos de cada quadrante: (bit, bit_vizinho, lado)
    neighbors = [
        (1, 2, "right"),
        (1, 4, "bottom"),
        (2, 1, "left"),
        (2, 8, "bottom"),
        (4, 1, "top"),
        (4, 8, "right"),
        (8, 2, "top"),
        (8, 4, "left"),
    ]

    for row in range(4):
        for col in range(4):
            bits = (col & 1) + ((col >> 1) << 1) + ((row & 1) << 2) + ((row >> 1) << 3)
            ox, oy = col * TILE, row * TILE
            for bit, qx, qy in quads:
                if not (bits & bit):
                    continue
                x0, y0 = ox + qx, oy + qy
                x1, y1 = x0 + half - 1, y0 + half - 1
                draw.rectangle([x0, y0, x1, y1], fill=color + (255,))
                # textura leve
                if with_dots:
                    for _ in range(4):
                        dx = rng.randint(x0, x1)
                        dy = rng.randint(y0, y1)
                        img.putpixel((dx, dy), _shade(color, 0.85))
            # contorno interno onde o terreno encontra o vazio
            for own, other, side in neighbors:
                if (bits & own) and not (bits & other):
                    qx, qy = next((qx, qy) for bit, qx, qy in quads if bit == own)
                    x0, y0 = ox + qx, oy + qy
                    x1, y1 = x0 + half - 1, y0 + half - 1
                    if side == "left":
                        draw.line([x0, y0, x0, y1], fill=dark, width=1)
                    elif side == "right":
                        draw.line([x1, y0, x1, y1], fill=dark, width=1)
                    elif side == "top":
                        draw.line([x0, y0, x1, y0], fill=dark, width=1)
                    elif side == "bottom":
                        draw.line([x0, y1, x1, y1], fill=dark, width=1)
    return img


# ---------------------------------------------------------------------------
# Personagem placeholder: 4 direcoes x 4 frames, frame 16x24
# linhas: 0=baixo, 1=cima, 2=esquerda, 3=direita
# ---------------------------------------------------------------------------
FW, FH = 16, 24

SKIN = (240, 200, 160)
HAIR = (92, 62, 42)
SHIRT = (74, 122, 200)
PANTS = (64, 64, 96)
SHOE = (48, 36, 30)
OUTLINE = (28, 26, 34)


def _rect(d: ImageDraw.ImageDraw, x0, y0, x1, y1, color):
    d.rectangle([x0, y0, x1, y1], fill=color)


def make_player_frame(direction: int, frame: int) -> Image.Image:
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = FW // 2

    # fase da passada: -1 / 0 / +1
    phase = (-1, 0, 1, 0)[frame]
    back = direction == 1
    side = direction in (2, 3)
    flip = direction == 2  # esquerda espelha

    # pernas
    _rect(d, cx - 4, 17, cx - 2, 22, PANTS)
    _rect(d, cx + 1, 17, cx + 3, 22, PANTS)
    if phase != 0:
        # perna da frente avanca, a de tras recua
        if not side or phase > 0:
            _rect(d, cx - 4, 17, cx - 2, 22 + (1 if phase > 0 else 0), PANTS)
        else:
            _rect(d, cx - 4, 17, cx - 2, 22, PANTS)
    _rect(d, cx - 4, 22, cx - 2, 23, SHOE)
    _rect(d, cx + 1, 22, cx + 3, 23, SHOE)

    # tronco
    _rect(d, cx - 5, 10, cx + 4, 18, SHIRT)
    # bracos
    _rect(d, cx - 6, 11, cx - 5, 16, SHIRT)
    _rect(d, cx + 5, 11, cx + 6, 16, SHIRT)
    _rect(d, cx - 6, 16, cx - 5, 17, SKIN)
    _rect(d, cx + 5, 16, cx + 6, 17, SKIN)

    # cabeca
    _rect(d, cx - 5, 1, cx + 4, 10, SKIN)
    # cabelo
    _rect(d, cx - 5, 0, cx + 4, 3, HAIR)
    _rect(d, cx - 5, 3, cx - 4, 7, HAIR)
    _rect(d, cx + 3, 3, cx + 4, 7, HAIR)

    if not back:
        eye_y = 6
        if side:
            # um olho voltado para o lado
            ex = cx + 1 if not flip else cx - 1
            _rect(d, ex, eye_y, ex, eye_y + 1, OUTLINE)
        else:
            _rect(d, cx - 3, eye_y, cx - 3, eye_y + 1, OUTLINE)
            _rect(d, cx + 2, eye_y, cx + 2, eye_y + 1, OUTLINE)

    # contorno simples da silhueta (apenas nas laterais)
    d.line([cx - 6, 1, cx - 6, 17], fill=OUTLINE, width=1)
    d.line([cx + 5, 1, cx + 5, 17], fill=OUTLINE, width=1)
    return img


def make_player_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (FW * 4, FH * 4), (0, 0, 0, 0))
    for direction in range(4):
        for frame in range(4):
            sheet.paste(make_player_frame(direction, frame), (frame * FW, direction * FH))
    return sheet


# ---------------------------------------------------------------------------
def main() -> None:
    _ensure_dirs()
    make_grass_tile().save(os.path.join(TILES_DIR, "ground_grass.png"))
    make_dual_grid_sheet((170, 130, 80), seed=1).save(
        os.path.join(TILES_DIR, "terrain_dirt.png"))
    make_dual_grid_sheet((72, 124, 200), seed=2, with_dots=True).save(
        os.path.join(TILES_DIR, "terrain_water.png"))
    make_dual_grid_sheet((112, 78, 52), seed=3, with_dots=True).save(
        os.path.join(TILES_DIR, "terrain_soil.png"))
    make_player_sheet().save(os.path.join(SPRITES_DIR, "player_placeholder.png"))
    print("Placeholders gerados em assets/tiles e assets/sprites.")


if __name__ == "__main__":
    main()
