# Changelog

All notable changes to Himekuri are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The release script reads the section matching the version being released, so
keep the `## [X.Y.Z] – YYYY-MM-DD` heading format.

## [0.2.0] – 2026-08-05

### Added

- Lunisolar calendar support, as its own layer under the traditional pages:
  lunar months with their 大/小 length, leap months, the moon's phase, the 24
  solar terms computed from the sun's ecliptic longitude, and the festivals
  that follow from either — 春節, 元宵, 端午, 七夕, 中秋, 重陽, 臘八, and 除夕
  on the last day of the twelfth month whether that is the 29th or the 30th
- An almanac layer on top of that calendar (`Almanac`): the day's stem and branch,
  its 納音 element, the 28 mansions, the twelve officers (建除) and the 宜/忌
  that follow from them, the zodiac clash (沖), the wealth and joy directions,
  and which of the twelve double-hours fall on the yellow road (吉時)
- Tong Sheng (通勝) theme: the red-ink tear-off almanac, one colour on cheap
  white stock, with the Gregorian, lunisolar, and Hijri dates in the masthead
  and the almanac table underneath
- Two pages in front of a fresh pad, printed in the selected style rather than
  laid over it as a dialog: the first teaches the pull, the second points up at
  the menu bar where the other prints are and says outright that tearing it
  brings up today. Both are free — they leave their stubs under the staples but
  cost no day, so the first real page is still today's, whenever it is uncovered.
  A pad that has already been torn from, or had its style changed, doesn't get
  them

### Changed

- The Huangli page is now the green almanac it is named after: green ink on
  white stock inside a double rule, the weekday standing in a filled column,
  the 八卦 wheel between the day's 宜 and 忌, and the full day pillar
  (庚辰金鬼定日) set as one bar. It reads the same calendar and almanac layers
  as the Tong Sheng page but shares no layout with it
- Both almanac pages are now printed on translucent stock: the paper, the pad
  beneath it, the torn stubs, and the shadow all fade so the desktop reads
  through, while the ink stays fully opaque. The other five styles are
  unchanged
- Print-style names are localized along with the rest of the menu bar, so a
  Chinese system reads 黄历 / 通胜 / 和历 and a Japanese one 黄暦 / 通勝 / 暦
  instead of romanizations. The menu had been translated everywhere except
  the one list where the name is what makes the page recognizable
- Each almanac page is now set in the register its own name belongs to. 通勝
  is the Cantonese book of Hong Kong and Southeast Asia, so that page keeps
  traditional characters and the Hijri date those pads print; 黄历 is the
  Mandarin name used on the mainland, so that page is simplified throughout
  (公历, 农历, 冲, 财神, 黄历) and carries no Hijri line. The shared almanac
  model is named after neither and is now `Almanac`

## [0.1.4] – 2026-08-03

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
