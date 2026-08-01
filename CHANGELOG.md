# Changelog

All notable changes to Himekuri are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The release script reads the section matching the version being released, so
keep the `## [X.Y.Z] – YYYY-MM-DD` heading format.

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
