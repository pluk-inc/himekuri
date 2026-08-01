# Himekuri（日めくり）

A Japanese page-a-day tear-off calendar that lives on your Mac desktop.
When the day is done, grab the page and rip it off — real paper physics,
five print styles, no accounts, no network.

**Website:** [himekuri.app](https://himekuri.app) ·
**Download:** [latest DMG](https://api.amore.computer/v1/apps/pluk.himekuri/download)

## What it does

- One page per day, floating on the desktop (above windows, standard, or
  pinned to the desktop)
- Tear by pulling down or flipping up from the bottom edge; pages can rest
  half-torn, and the freed sheet inherits your throw before fluttering off
  the screen
- The paper is simulated: a verlet grid with inextensible + bending
  constraints (`PaperSim.swift`), rendered via `SKWarpGeometryGrid`, with
  crack-propagation tearing tuned from the mechanics literature
- Five print styles: Shōwa Print (default), Minimal Swiss, Brutalist,
  Retro Office, Koyomi
- The pad never turns its own page; Reset to Today is the only way back
- Procedurally synthesized paper sounds — no audio assets

## Building

Open `himekuri.xcodeproj` in Xcode 26+ and run the `himekuri` scheme.
Requires macOS 15 or later. Sparkle is the only dependency (SPM).

Version numbers live in `Version.xcconfig`. Sparkle feed configuration is
in `Info.plist`; sandbox entitlements in `himekuri.entitlements`.

## Releasing

Releases are published through [Amore](https://amore.computer) (sign,
notarize, DMG, appcast) via:

```sh
scripts/release.sh                  # version from Version.xcconfig
scripts/release.sh --version 0.2.0  # bump + release
```

The script requires a matching entry in `CHANGELOG.md` and an
authenticated `amore` CLI.

## License

MIT — see [LICENSE](./LICENSE).
