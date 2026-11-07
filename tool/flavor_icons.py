#!/usr/bin/env python3
"""Draws the dev and staging icons from the production ones, so run it after the icon changes.

Needs Pillow. Android gets src/<flavor>/res, iOS gets its own AppIcon-<Flavor> set.
"""
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FONT = "assets/fonts/SchibstedGrotesk-Variable.ttf"
FLAVORS = {"dev": ("D", (232, 121, 43)), "staging": ("S", (47, 125, 225))}
ANDROID_RES = Path("android/app/src/main/res")
IOS_ICONS = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")

# a round launcher mask keeps only the circle inside the foreground, a corner would be cut off
ANDROID_BADGE = (0.74, 0.26, 0.12)
# clears ios's rounded corner
IOS_BADGE = (0.82, 0.18, 0.12)


def badged(source, letter, color, spot, gray=False):
    """Drawn 4 times bigger and scaled down, a 40 px icon has no clean edge otherwise."""
    icon = Image.open(source)
    size = icon.width * 4
    x, y, radius = (value * size for value in spot)
    badge = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(badge)
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(*color, 255))
    font = ImageFont.truetype(FONT, int(radius * 1.4))
    font.set_variation_by_axes([700])
    draw.text((x, y), letter, font=font, fill=(255, 255, 255, 255), anchor="mm")
    badge = badge.resize(icon.size, Image.LANCZOS)
    if gray:
        badge = Image.merge("RGBA", (*[badge.convert("L")] * 3, badge.getchannel("A")))
    result = icon.convert("RGBA")
    result.alpha_composite(badge)
    return result.convert(icon.mode)


def android(flavor, letter, color):
    for source in ANDROID_RES.glob("drawable-*/ic_launcher_foreground.png"):
        target = Path(f"android/app/src/{flavor}/res") / source.parent.name / source.name
        target.parent.mkdir(parents=True, exist_ok=True)
        badged(source, letter, color, ANDROID_BADGE).save(target)


def ios(flavor, letter, color):
    target = IOS_ICONS.with_name(f"AppIcon-{flavor.capitalize()}.appiconset")
    target.mkdir(exist_ok=True)
    shutil.copy(IOS_ICONS / "Contents.json", target)
    names = {item["filename"] for item in json.load(open(IOS_ICONS / "Contents.json"))["images"]}
    for name in names:
        badged(IOS_ICONS / name, letter, color, IOS_BADGE, gray="Tinted" in name).save(target / name)


for flavor, (letter, color) in FLAVORS.items():
    android(flavor, letter, color)
    ios(flavor, letter, color)
