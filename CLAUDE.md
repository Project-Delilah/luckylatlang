# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This App Is

**luckylatlang** — an Android astrocartography app. User inputs birthdate/time/place → app computes planetary lines and overlays them on a world map → highlights cities that are lucky/neutral/bad for that person, with detailed explanations per planet/combination. Report is shareable as PDF.

## Commands

```bash
# Run on connected Android device
flutter run

# Build release APK
flutter build apk --release

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run single test file
flutter test test/path/to/test_file.dart

# Get dependencies after pubspec changes
flutter pub get
```

## Architecture

**State management:** Riverpod (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`). All state lives in providers. No `setState` except for purely local UI animation state.

**Folder structure under `lib/`:**
```
lib/
  main.dart                   # ProviderScope + app bootstrap
  core/
    theme/                    # AppTheme, color tokens, text styles
    router/                   # go_router route definitions
    storage/                  # SharedPreferences wrappers (user profile persistence)
  features/
    intro/                    # Splash / intro screen
    profile/                  # Birth details form + local profile store
    map/                      # World map screen (flutter_map + astrocartography overlays)
    detail/                   # Bottom sheet / full-screen city detail panel
    report/                   # PDF generation + share
  models/                     # Pure Dart data classes (BirthProfile, PlanetLine, CitySpot)
  services/
    astro/                    # Swiss Ephemeris bindings or astro computation logic
    geocoding/                # City lookup / reverse geocoding
```

**App flow:** Intro → Profile (check SharedPreferences, offer to reuse saved profile) → Map (astrocartography lines + hotspot markers) → Detail panel (Google Maps-style bottom sheet that expands to full screen) → PDF share.

**Map layer:** `flutter_map` (OpenStreetMap tiles, free). Astrocartography lines drawn as `Polyline` layers. City hotspots as `Marker` or `CircleLayer` with color-coded good/neutral/bad.

**Astro computation:** Swiss Ephemeris (C library via FFI) or `sweph` Dart package if available; otherwise `astronomy` package. All computation runs in an `Isolate` — never on the UI thread.

**Local persistence:** `shared_preferences` for birth profile. No remote backend required.

**City database:** `assets/data/cities.db` — SQLite, 19 MB, 170,050 cities across 252 countries from GeoNames `cities1000` (population ≥ 1,000). Tables: `cities` (id, name, ascii_name, latitude, longitude, country_code, population, timezone) and `countries` (iso_code, name, capital, continent). Indexes on `(latitude, longitude)` and `country_code`. Regenerate with `python3 tools/generate_city_db.py` from project root.

**PDF export:** `pdf` + `printing` packages.

## Design System (from `design.md`)

The app follows the Anthropic/Claude editorial brand. Key tokens:

| Token | Value | Use |
|---|---|---|
| Canvas | `#faf9f5` | Default background (warm cream, not white) |
| Surface Card | `#efe9de` | Cards, bottom sheet |
| Surface Dark | `#181715` | Map overlay panels, dark cards |
| Primary / Coral | `#cc785c` | Primary CTA, accents |
| Primary Active | `#a9583e` | Pressed state |
| Ink | `#141413` | Headlines, primary text |
| Body | `#3d3d3a` | Running text |
| Muted | `#6c6a64` | Secondary labels |
| Hairline | `#e6dfd8` | 1px borders |

**Typography:** Display/headline → Cormorant Garamond (open-source substitute for Copernicus) weight 400, negative letter-spacing. Body → Inter weight 400-500. Code → JetBrains Mono.

**Border radius:** buttons/inputs 8px · cards 12px · hero containers 16px · pills 9999px.

**Spacing base unit:** 4px. Key steps: 8 · 12 · 16 · 24 · 32 · 48 · 96px.

**Elevation:** color-block first, shadows rare. Depth via cream ↔ dark surface contrast, not drop shadows.

**Surface rhythm:** never two same-surface bands in a row. Alternate: cream → card → dark → cream → coral callout.

## Key Conventions

- Providers are code-generated with `@riverpod` annotation (`riverpod_generator`). Run `dart run build_runner watch` during development.
- Route definitions use `go_router`; all named routes live in `core/router/`.
- The birth profile is the single source of truth — all astro computation providers depend on it.
- Astrocartography lines are pre-computed once after profile entry and cached in a provider; the map just reads them.
- Bottom sheet detail panel mirrors Google Maps UX: draggable, collapses to peek, expands to full screen.
