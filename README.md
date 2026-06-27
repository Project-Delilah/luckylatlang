<p align="center">
  <img src="assets/icons/flutter-icon.png" width="120" alt="Lucky Lat·Lang" />
</p>

<h1 align="center">Lucky Lat·Lang</h1>
<p align="center">Personal astrocartography — discover the places on Earth that resonate with your birth chart.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Android-API%2021+-3DDC84?style=flat&logo=android" alt="Android" />
  <img src="https://img.shields.io/badge/State-Riverpod-0175C2?style=flat" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Map-OpenStreetMap-7EBC6F?style=flat" alt="OpenStreetMap" />
</p>

---

## What it does

Lucky Lat·Lang takes your birth date, time, and place — and draws your **astrocartography map**: the planetary lines that trace where specific energies from your birth chart are strongest on Earth.

Enter your details once. The app computes nine planetary lines (Sun through Pluto), overlays them on a live world map, and scores every major city as **lucky**, **neutral**, or **challenging** for you personally. Tap any city to get a detailed breakdown of which planets are near, what they mean, and why that location might resonate.

## Features

- **Astrocartography lines** — Rising, setting, MC, and IC lines for Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, and Neptune
- **170,000+ cities** — Scored and color-coded from a local SQLite database (GeoNames `cities1000`, population ≥ 1,000)
- **City detail panel** — Google Maps–style draggable bottom sheet with per-planet explanations
- **Multiple profiles** — Save every birth chart; switch between them instantly from the drawer
- **Dark / Light / System theme** — Full dark mode with a separate design token layer; toggle persists across sessions
- **Country filter** — Focus the map on any of 252 countries
- **Planet line toggles** — Show or hide individual planets directly from the side drawer
- **PDF export** — Share your astrocartography report as a formatted PDF
- **Offline-first** — No backend, no account. All computation and city lookup runs on-device

## Screenshots

> _Coming soon._

## How it works

1. **Enter birth details** — date, time (optional, improves accuracy), and birth city
2. **Orbital mechanics** — planetary positions are computed using Meeus algorithms (pure Dart, runs in an `Isolate`)
3. **Line projection** — four lines per planet (rising/setting/MC/IC) are traced as great-circle arcs across the globe
4. **City scoring** — each city is scored by proximity to lines: < 200 km = strong influence, 200–500 km = moderate
5. **Explore** — tap any marker or blank spot on the map for a full breakdown

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.x |
| State management | Riverpod (`NotifierProvider`, manual — no codegen) |
| Navigation | go_router |
| Map | flutter_map (OpenStreetMap tiles) |
| Astro computation | Pure Dart Meeus orbital mechanics (isolated) |
| City database | SQLite via sqflite — 19 MB, 170,050 cities |
| Local storage | shared_preferences (profiles + theme mode) |
| PDF | `pdf` + `printing` + `share_plus` |
| Fonts | Cormorant Garamond (display) + Inter (body) via google_fonts |

## Getting started

### Prerequisites

- Flutter SDK ≥ 3.12
- Android SDK (API 21+)
- A connected Android device or emulator

### Run

```bash
# Install dependencies
flutter pub get

# Run on a connected device
flutter run
```

### Build

```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release
```

### Lint & test

```bash
flutter analyze
flutter test
```

### Regenerate app icons

```bash
dart run flutter_launcher_icons
```

## Architecture

```
lib/
  main.dart                   # ProviderScope + SharedPreferences init
  core/
    theme/                    # AppTheme, AppColors, AppTextStyles, ThemeModeNotifier
    router/                   # go_router route definitions
    storage/                  # ProfileStorage (multi-profile list + active id)
  features/
    intro/                    # Splash / intro screen
    profile/                  # Birth details form
    map/                      # World map + astrocartography overlays + side drawer
    detail/                   # City detail bottom sheet
    about/                    # About the app + developer
    report/                   # PDF generation + share
  models/                     # BirthProfile, PlanetLine, CitySpot
  providers/                  # profileProvider, profileListProvider, astroProvider, cityProvider
  services/
    astro/                    # Meeus orbital mechanics
    geocoding/                # City lookup from local SQLite
```

**State flow:** `BirthProfile` → `astroProvider` (computes planet lines in isolate) → `cityProvider` (scores cities) → map layer renders lines + markers.

**Multi-profile:** Each saved profile gets a timestamp-based `id`. All profiles are stored as a JSON list in SharedPreferences. The active profile id is tracked separately. The side drawer shows a profile switcher when two or more profiles are saved.

**Theme:** `ThemeModeNotifier` persists the selected mode (`light` / `dark` / `system`) to SharedPreferences. A `_DynamicColors` helper resolves design tokens based on the current `Brightness` via a `BuildContext` extension (`context.colors.canvas`, etc.).

## Design

The app follows a warm editorial design system — cream canvas (`#faf9f5`), coral primary (`#cc785c`), dark surface (`#181715`). Full token reference is in [`design.md`](design.md).

## Developer

Made by [Sapan Gajjar](https://github.com/isg32) — Fullstack Developer, Ahmedabad, India.

> "When we lose our principles, we invite chaos."

115+ open-source projects spanning Android, web, and IoT. Lucky Lat·Lang brings together orbital mechanics, cartography, and personal astrology into one cohesive experience.

---

<p align="center">
  <sub>Built with Flutter · Powered by OpenStreetMap · Orbital mechanics via Meeus algorithms · City data from GeoNames</sub>
</p>
