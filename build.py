#!/usr/bin/env python3
"""
Сборка брендинга Hanafubuki из исходников src/*.svg в готовые картинки export/.

Установка (один раз):   pip install cairosvg pillow
Запуск:                 python3 build.py
"""
from pathlib import Path
import cairosvg
from PIL import Image, ImageDraw

ROOT = Path(__file__).parent
SRC, OUT = ROOT / "src", ROOT / "export"

BG = (0x1B, 0x15, 0x30)
# Палитра для иконки Minecraft — без сглаживания, только эти цвета (пиксель-арт)
MC_PALETTE = [
    BG,
    (0x8E, 0x2A, 0x5B),  # сердцевина
    (0xFF, 0xCF, 0x6B),  # пыльники
    (0xC9, 0x4F, 0x7C),  # швы между лепестками
    (0xE4, 0x62, 0x8F),  # лепесток у основания
    (0xEE, 0x84, 0xAA),  # переход
    (0xF7, 0xA1, 0xC0),  # лепесток середина
    (0xFF, 0xE1, 0xEC),  # кончик лепестка
]


def render(name: str, size: int, height: int | None = None) -> Image.Image:
    tmp = OUT / f".tmp-{name}-{size}.png"
    cairosvg.svg2png(url=str(SRC / f"{name}.svg"), write_to=str(tmp), output_width=size, output_height=height or size)
    img = Image.open(tmp).convert("RGBA")
    img.load()
    tmp.unlink()
    return img


def on_bg(img: Image.Image) -> Image.Image:
    bg = Image.new("RGBA", img.size, BG + (255,))
    bg.alpha_composite(img)
    return bg


def nearest(c):
    return min(MC_PALETTE, key=lambda p: sum((a - b) ** 2 for a, b in zip(p, c)))


def circle_preview(img: Image.Image, size: int) -> Image.Image:
    img = img.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def main():
    (OUT / "logo").mkdir(parents=True, exist_ok=True)
    (OUT / "discord").mkdir(parents=True, exist_ok=True)
    (OUT / "minecraft").mkdir(parents=True, exist_ok=True)

    # Основной логотип
    logo = render("logo", 2048)
    for s in (2048, 1024, 512):
        im = logo.resize((s, s), Image.LANCZOS)
        im.save(OUT / "logo" / f"hanafubuki-logo-{s}.png")                      # прозрачный фон
        on_bg(im).convert("RGB").save(OUT / "logo" / f"hanafubuki-logo-dark-{s}.png")  # на тёмном (аватарка GitHub и т.п.)

    # Discord: иконка сервера 512×512 (Discord сам обрежет в круг) + превью круга
    dc = render("discord-icon", 1024)
    dc.resize((512, 512), Image.LANCZOS).convert("RGB").save(OUT / "discord" / "hanafubuki-discord-icon-512.png")
    circle_preview(dc, 256).save(OUT / "discord" / "preview-circle-256.png")

    # Minecraft: server-icon.png строго 64×64, палитра без сглаживания
    mc = render("minecraft-icon", 64).convert("RGB")
    px = mc.load()
    for y in range(64):
        for x in range(64):
            px[x, y] = nearest(px[x, y])
    mc.save(OUT / "minecraft" / "server-icon.png")
    mc.resize((512, 512), Image.NEAREST).save(OUT / "minecraft" / "preview-x8.png")

    # Баннер профиля организации GitHub (1280×400, рендер в 2× для чёткости на ретине)
    (OUT / "github").mkdir(parents=True, exist_ok=True)
    render("github-banner", 2560, 800).convert("RGB").save(OUT / "github" / "hanafubuki-banner.png")

    print("Готово:", *sorted(str(p.relative_to(ROOT)) for p in OUT.rglob("*.png")), sep="\n  ")


if __name__ == "__main__":
    main()
