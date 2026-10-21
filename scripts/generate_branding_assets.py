#!/usr/bin/env python3
"""Generate default Merge Empire icon / splash PNGs (owner should replace)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "branding"
OUT.mkdir(parents=True, exist_ok=True)

ROAST = (92, 58, 33, 255)
CARAMEL = (184, 121, 58, 255)
CREAM = (255, 248, 239, 255)
ESPRESSO = (44, 24, 16)


def make_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pad = size // 16
    draw.rounded_rectangle(
        (pad, pad, size - pad, size - pad),
        radius=size // 5,
        fill=ROAST,
    )
    cup = [
        (size * 0.30, size * 0.38),
        (size * 0.70, size * 0.38),
        (size * 0.64, size * 0.68),
        (size * 0.36, size * 0.68),
    ]
    draw.polygon(cup, fill=CREAM)
    draw.arc(
        (size * 0.62, size * 0.42, size * 0.82, size * 0.62),
        start=270,
        end=90,
        fill=CREAM,
        width=max(2, size // 18),
    )
    for x in (0.42, 0.50, 0.58):
        draw.line(
            [
                (size * x, size * 0.28),
                (size * (x + 0.02), size * 0.22),
                (size * x, size * 0.18),
            ],
            fill=CARAMEL,
            width=max(2, size // 28),
        )
    return img


def make_splash(width: int, height: int) -> Image.Image:
    img = Image.new("RGB", (width, height), ESPRESSO)
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(1, height - 1)
        color = (
            int(44 + (92 - 44) * t),
            int(24 + (58 - 24) * t),
            int(16 + (33 - 16) * t),
        )
        draw.line([(0, y), (width, y)], fill=color)

    icon = make_icon(min(width, height) // 3)
    ix = (width - icon.size[0]) // 2
    iy = (height - icon.size[1]) // 2 - height // 12
    img.paste(icon, (ix, iy), icon)

    try:
        font = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            size=max(28, width // 18),
        )
        small = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            size=max(16, width // 40),
        )
    except OSError:
        font = ImageFont.load_default()
        small = font

    text = "Merge Empire"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(
        ((width - tw) / 2, iy + icon.size[1] + 24),
        text,
        fill=CREAM[:3],
        font=font,
    )
    note = "Default asset — replace before store release"
    bbox2 = draw.textbbox((0, 0), note, font=small)
    tw2 = bbox2[2] - bbox2[0]
    draw.text(
        ((width - tw2) / 2, height - max(64, height // 20)),
        note,
        fill=CARAMEL[:3],
        font=small,
    )
    return img


def write_android_mipmaps(icon_1024: Image.Image) -> None:
    mapping = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in mapping.items():
        path = res / folder
        path.mkdir(parents=True, exist_ok=True)
        icon_1024.resize((size, size), Image.Resampling.LANCZOS).save(
            path / "ic_launcher.png"
        )


def write_ios_appicon(icon_1024: Image.Image) -> None:
    base = (
        ROOT
        / "ios"
        / "Runner"
        / "Assets.xcassets"
        / "AppIcon.appiconset"
    )
    sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in sizes.items():
        # App Store icon must be opaque RGB (no alpha).
        resized = icon_1024.resize((size, size), Image.Resampling.LANCZOS)
        if size == 1024:
            bg = Image.new("RGB", (size, size), ESPRESSO)
            bg.paste(resized, mask=resized.split()[-1])
            bg.save(base / name)
        else:
            resized.save(base / name)


def main() -> None:
    icon = make_icon(1024)
    icon.save(OUT / "app_icon_1024.png")
    make_splash(1242, 2688).save(OUT / "splash_portrait_placeholder.png")
    make_splash(2048, 2732).save(OUT / "store_screenshot_ipad_placeholder.png")
    make_splash(1290, 2796).save(OUT / "store_screenshot_iphone_placeholder.png")
    write_android_mipmaps(icon)
    write_ios_appicon(icon)
    icons = ROOT / "assets" / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    icon.resize((192, 192), Image.Resampling.LANCZOS).save(
        icons / "app_icon_192.png"
    )
    print("Generated branding assets under", OUT)


if __name__ == "__main__":
    main()
