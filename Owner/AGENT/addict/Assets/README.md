# Turf Cash Assets

This folder contains raw MidJourney prompt text, color references, and packaging guidance for all visual assets.

## Structure

* `prompts.txt` – copy-paste prompts for generating each required image or animation in MidJourney.
* `colors.json` – canonical hex values used throughout the UI.
* `Images/` – (to be filled) PNG exports for each static asset at @1×, @2×, @3×.
* `Animations/` – (to be filled) transparent-background MP4 or GIF loops.

## Naming Convention

```
hex_neutral@2x.png
hex_owned@3x.png
icon_wallet@1x.png
... etc.
```

## Import Note

All PNGs should be trimmed of extra padding so they snap to an 8-pt grid when added to the Xcode asset catalog.

---

**Font**: The app relies on the native system font *SF Pro*; no additional font files required.

**Attribution**: MidJourney images are subject to its license; ensure compliance before App Store release.
