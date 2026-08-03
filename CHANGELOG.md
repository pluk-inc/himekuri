# Changelog

All notable changes to Himekuri are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The release script reads the section matching the version being released, so
keep the `## [X.Y.Z] – YYYY-MM-DD` heading format.

## [Unreleased]

### Changed

- A fresh install now starts pinned to the desktop instead of floating above
  every window, so the pad behaves like the paper one it's modelled on.
  Existing installs keep whatever mode they were set to.

## [0.1.3] – 2026-08-02

### Added

- Launch at Login, from the menu bar item (macOS 13+)

### Changed

- Himekuri now runs on macOS 12 (Monterey) and later, down from macOS 15.
  Everything works there; two touches need newer systems and are skipped
  quietly otherwise — the falling page's ripple wants the Metal shader
  support in macOS 14, and Launch at Login wants macOS 13.

## [0.1.2] – 2026-08-01

### Added

- Huangli (黄历) theme: a Chinese almanac page with the sexagenary year
  (干支), zodiac animal, and the lunar date in 初/廿 numerals
- Leap lunar months (閏/闰) now shown correctly on the Koyomi and
  Huangli pages

### Changed

- The Japanese era (令和…) now comes from the system's Japanese
  calendar, so a future era change needs no app update

## [0.1.1] – 2026-08-01

### Added

- Japanese and Simplified Chinese localization for the menu-bar menu

### Removed

- Auto-Tear at Midnight — the pad never turns its own page; tearing is yours to do
- Reset to Today is no longer in release builds (development builds keep it)

### Fixed

- The menu-bar menu no longer indents all items to make room for an
  automatic icon on Quit

## [0.1.0] – 2026-08-01

Initial release.
