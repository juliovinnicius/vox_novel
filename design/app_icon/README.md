# App icon

Source of truth for the launcher icon: an open book in the app's amber
(`#E0A45C` family) with three voice arcs, over the graphite surface used by
`AppTheme.dark`.

| File | Used for |
| --- | --- |
| `icon.svg` | Android legacy launcher icon (`mipmap-*/ic_launcher.png`) |
| `icon_round.svg` | Android round icon (`mipmap-*/ic_launcher_round.png`) |
| `icon_foreground.svg` | Adaptive icon foreground, mark inside the 66% safe zone (`mipmap-*/ic_launcher_foreground.png`) |
| `icon_ios.svg` | iOS app icon set (square, no rounding — iOS masks it) |

The adaptive background is the flat colour `@color/ic_launcher_background`
(`android/app/src/main/res/values/colors.xml`), not a bitmap.

## Regenerating the PNGs

There is no SVG rasteriser in the toolchain, so headless Chrome renders the
1024px master and `sips` downscales it.

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --default-background-color=00000000 --screenshot=master.png \
  --window-size=1024,1024 "file://$PWD/design/app_icon/icon.svg"
sips -Z 192 master.png --out android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

Sizes: legacy and round at 48/72/96/144/192 (mdpi→xxxhdpi), foreground at
108/162/216/324/432. iOS sizes follow
`ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`, and each iOS
PNG must be flattened to drop its alpha channel:

```bash
sips -s format jpeg icon.png --out /tmp/i.jpg && sips -s format png /tmp/i.jpg --out icon.png
```
