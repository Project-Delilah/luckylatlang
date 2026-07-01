# Lucky Lat·Lang — Developer Handbook

> Personal reference for maintaining and extending the app. Written for someone who built it but doesn't have every detail memorised.

---

## Table of Contents

1. [The Big Picture](#1-the-big-picture)
2. [User Flow — Screen by Screen](#2-user-flow--screen-by-screen)
3. [Architecture](#3-architecture)
4. [The Astrology — Plain English](#4-the-astrology--plain-english)
5. [Algorithms & Formulas](#5-algorithms--formulas)
6. [City Scoring in Detail](#6-city-scoring-in-detail)
7. [Every Package Explained](#7-every-package-explained)
8. [How to Change Things (Recipes)](#8-how-to-change-things-recipes)
9. [Build & Release](#9-build--release)
10. [Home Screen Widget](#10-home-screen-widget)

---

<div style="page-break-after: always;"></div>

## 1. The Big Picture

**Lucky Lat·Lang** is an astrocartography app. The idea: the position of the planets at the exact moment you were born traces a unique set of energy lines across the globe. Where those lines pass near a city, that city carries that planet's influence for you. Jupiter near a city → lucky, expansive. Saturn near a city → demanding, heavy. The app draws those lines, scores 170,000 cities against them, and explains what each one means.

**Three questions the app answers:**
- Where on Earth would your life expand?
- Where would it be a grind?
- Why — which planet, which angle, at what strength?

**What the app does NOT do:**
- It does not connect to the internet for astro data (all computation is on-device).
- It does not store data anywhere remotely (everything lives in SharedPreferences on your phone).
- It is not a Western astrology app — it uses **Vedic (sidereal)** positions, not tropical.

---

<div style="page-break-after: always;"></div>

## 2. User Flow — Screen by Screen

### Screen 1: Intro (`/`)
**File:** `lib/features/intro/intro_screen.dart`

The splash screen. Shows the app name, a tagline, and a randomly picked animated cutout image from `assets/animated/` on every launch. There's a "Begin" button. If a saved profile already exists in storage, a "Continue as [name]" shortcut appears so returning users skip the profile form.

**Navigation:** → Profile screen (`/profile`) or Map screen (`/map`) directly if profile exists.

---

### Screen 2: Profile (`/profile`)
**File:** `lib/features/profile/profile_screen.dart`

The birth details form. Fields:
- **Name** — free text, used in PDF filename
- **Birth date** — date picker
- **Birth time** — time picker (optional but improves MC/AC accuracy)
- **Birth city** — search box backed by the cities.db SQLite database

On submit, the profile is saved to SharedPreferences and the app navigates to the map.

**Key widget:** `BirthPlaceSearch` (`lib/features/profile/widgets/birth_place_search.dart`) — an autocomplete that queries `cities.db` as the user types.

---

### Screen 3: Map (`/map`)
**File:** `lib/features/map/map_screen.dart`

The main screen. Has three visual layers stacked on top of each other:

1. **OpenStreetMap tile layer** (via `flutter_map`) — the world map
2. **Planet lines layer** (`PlanetLinesLayer`) — coloured polylines per planet
3. **City spots layer** (`CitySpotsLayer`) — coloured circle markers for scored cities

Plus a **bottom sheet** that slides up from the bottom (Google Maps style) and a **side drawer** opened by the hamburger icon.

**Bottom sheet states:**
- Collapsed (just a drag handle visible) → shows city list
- Half-open → city list scrollable
- Full-open → still city list, or city detail if one is selected

**Drawer contents:**
- Profile switcher
- Planet line visibility toggles (toggle each planet on/off)
- Country filter dropdown
- Navigation to About screen

**Tap behaviour:**
- Tap a city marker → `selectedCityProvider` updates → city detail panel opens
- Tap blank map → `tappedPointProvider` updates → that point is scored live and detail panel opens
- Back arrow in detail → returns to city list

---

### Screen 4: City Detail (inside the Map bottom sheet)
**File:** `lib/features/map/widgets/city_detail_panel.dart`

Not a separate route — it's content inside the `MapBottomSheet`. Shows:
- City name, country, rating badge
- Per-planet cards, one per influencing line:
  - Planet image (`assets/planets/ddd_{planet}.webp`) + glyph badge
  - Planet name, line type (AC / DC / MC / IC)
  - Natal sign chip with constellation image
  - Distance from line in km
  - Strength bar (0–100%)
  - Interpretation text
  - Topographic texture background (subtle, 7% opacity)

---

### Screen 5: About (`/about`)
**File:** `lib/features/about/about_screen.dart`

Explains astrocartography, the methodology, and developer info. Features:
- A randomly selected mystic polaroid image from `assets/mystic/`
- Live app version read from the package metadata
- Collapsible "Reading your map" explainer sections

---

### PDF Export
**File:** `lib/features/report/report_service.dart`

Triggered from the map screen's action button. Generates a multi-page PDF:
- Cover: name, birth details, ascendant sign
- Natal chart table: every planet with sign, house, dignity, functional nature
- Top 10 lucky cities with planetary breakdown
- Top 5 challenging cities

File is named `luckylatlang_<name>_<yyyyMMdd_HHmm>.pdf` and shared via the OS share sheet.

---

<div style="page-break-after: always;"></div>

## 3. Architecture

### Folder map

```
lib/
  main.dart                     App entry point — boots SharedPreferences, wraps in ProviderScope
  core/
    theme/                      Colors, text styles, Material theme config
    router/                     Route paths + GoRouter setup
    storage/                    ProfileStorage — reads/writes profiles to SharedPreferences
    db/                         CityDb — SQLite wrapper for cities.db
  data/
    fortunes.dart               Seed quotes for the home screen widget fallback
  features/
    intro/                      Splash screen
    profile/                    Birth details form + city search
    map/                        Map screen + all its sub-widgets and layers
    about/                      About + explainer screen
    report/                     PDF generation + share
  models/                       Pure data classes (no Flutter, no providers)
    birth_profile.dart          BirthProfile — the user's birth data
    natal_chart.dart            NatalChart, PlanetNatal, ZodiacSign, FunctionalNature
    planet_line.dart            Planet, LineType, PlanetLine
    city_spot.dart              CitySpot, LineInfluence, SpotRating
  providers/                    Riverpod state
    profile_provider.dart       profileProvider, profileListProvider
    astro_provider.dart         astroResultProvider, natalChartProvider, planetFilterProvider
    city_provider.dart          citySpotsProvider, selectedCityProvider, countryFilterProvider…
  services/
    astro_service.dart          All orbital mechanics + line geometry
    city_service.dart           City scoring + interpretation lookup
    natal_interpretations.dart  Dignity tables, remedy text, functional nature labels
```

### State management — Riverpod

The entire app state is in providers. Nothing uses `setState` except minor local animation state. The key providers and what they hold:

| Provider | Type | What it holds |
|---|---|---|
| `sharedPreferencesProvider` | `Provider<SharedPreferences>` | Injected at startup via `overrideWithValue` |
| `profileProvider` | `NotifierProvider<BirthProfile?>` | The active birth profile |
| `profileListProvider` | `NotifierProvider<List<BirthProfile>>` | All saved profiles |
| `astroResultProvider` | `FutureProvider<AstroResult?>` | Planet lines computed from profile |
| `natalChartProvider` | `Provider<NatalChart?>` | Natal chart (synchronous) |
| `planetFilterProvider` | `NotifierProvider<Set<Planet>>` | Hidden planets (toggled in drawer) |
| `cityDbProvider` | `FutureProvider<CityDb>` | Open SQLite database |
| `cityServiceProvider` | `Provider<CityService?>` | City scoring service |
| `citySpotsProvider` | `FutureProvider<List<CitySpot>>` | All scored cities |
| `selectedCityProvider` | `StateProvider<CitySpot?>` | City currently shown in detail panel |
| `countryFilterProvider` | `StateProvider<String?>` | Active country filter code |
| `filteredSpotsProvider` | `Provider<List<CitySpot>>` | Spots filtered by country |
| `tappedPointProvider` | `StateProvider<LatLng?>` | Last tapped lat/lng on map |
| `tappedPointSpotProvider` | `Provider<CitySpot?>` | Tapped point scored synchronously |

### Data flow (simplified)

```
User enters birth details
        │
        ▼
profileProvider (saves to SharedPreferences)
        │
        ├──▶ astroResultProvider ──▶ PlanetLinesLayer (draws polylines)
        │            │
        │            ▼
        │      citySpotsProvider ──▶ CitySpotsLayer (draws markers)
        │                  │
        │                  ▼
        │          selectedCityProvider ──▶ CityDetailContent
        │
        └──▶ natalChartProvider ──▶ CityDetailContent (sign chips, dignity)
```

Every provider at the bottom automatically recomputes when `profileProvider` changes. This means switching profiles instantly redraws the entire map.

---

<div style="page-break-after: always;"></div>

## 4. The Astrology — Plain English

### What is astrocartography?

Astrocartography (also called astro*locality* mapping) asks: *if I were born at this other location, what would my chart look like?* The answer is that most planets don't move — their position in the sky is fixed relative to the stars — but the angles of the chart (Ascendant, Midheaven etc.) change depending on where on Earth you are. So there is exactly one latitude/longitude on Earth where Saturn is rising for you. There's another line where Jupiter is at the top of the sky. The app draws all of those lines.

### Tropical vs Sidereal (Western vs Vedic)

Western astrology uses the **tropical zodiac** — Aries begins at the March equinox, regardless of where the actual stars are. Over thousands of years, the Earth's axis precesses (wobbles) and the equinox has drifted about 24° away from the actual Aries constellation. Vedic astrology corrects for this drift using an **ayanamsha** — a subtraction applied to tropical positions to get back to the real sky. This app uses the **Lahiri ayanamsha**, the standard for Indian Vedic astrology (≈ 24° in 2026, growing at ~50 arcseconds per year).

**In practice:** a planet at 28° tropical Gemini becomes 28° − 24° = 4° sidereal Gemini. This matters because it changes which sign a planet is in, which house it occupies, and therefore how it's interpreted.

### The four line types

For each planet, the app draws four lines:

| Line | Abbreviation | Meaning |
|---|---|---|
| **Ascendant** | AC | This planet is rising on the eastern horizon. Strongest personal expression of that planet's energy. |
| **Descendant** | DC | This planet is setting on the western horizon. Affects relationships, partnerships, what you attract. |
| **Midheaven** | MC | This planet is at the top of the sky (culminating). Affects career, public reputation, visibility. |
| **Imum Coeli** | IC | This planet is at the bottom of the sky (anti-culminating). Affects home, roots, inner life, private self. |

AC and MC lines have weight 1.0 in scoring. DC and IC have weight 0.8 (slightly less influential).

### Why do MC/IC lines run north-south and AC/DC lines curve?

**MC/IC:** The Midheaven is defined purely by your longitude on Earth (your local sidereal time). It does not depend on latitude at all. So the MC line for a planet is a vertical north-south line at a fixed longitude. The IC line is exactly opposite (180° away).

**AC/DC:** The Ascendant is the point of the ecliptic rising on the eastern horizon, which depends on *both* latitude and local time. The rising point changes as you move north or south (the sky tilts). This creates the characteristic S-shaped curves you see on the map.

### Whole-sign house system

In Vedic astrology, houses are whole signs — the entire sign that the Ascendant falls in becomes the 1st house, the next sign (in order) is the 2nd house, and so on. If your Ascendant is at 15° Scorpio, then Scorpio is your entire 1st house, Sagittarius is the entire 2nd, etc.

### Functional benefics and malefics

A planet's nature as "good" or "bad" for you depends not just on the planet itself but on which houses it rules for your specific Ascendant. Each sign is ruled by a planet (traditional rulership). The sign's ruler becomes the "lord" of that house.

- **Trikona lords** (houses 1, 5, 9) — naturally beneficial; these are the houses of dharma and luck.
- **Kendra lords** (houses 1, 4, 7, 10) — angular houses; supportive when they don't also rule dusthanas.
- **Yoga Karaka** — a planet that rules both a kendra AND a trikona simultaneously becomes the most auspicious planet for that ascendant. For Cancer ascendant, Mars rules the 5th (trikona) and 10th (kendra) → Yoga Karaka.
- **Dusthana lords** (houses 6, 8, 12) — houses of disease, obstacles, loss → challenging functional nature.

### Planet dignity

A planet's sign also matters. In Vedic astrology, certain signs bring out a planet's best qualities:

| Status | Meaning |
|---|---|
| **Exalted** | Planet at its strongest. Sun exalted in Aries, Moon in Taurus, etc. |
| **Own sign** | Planet in the sign it rules. Natural, unobstructed. |
| **Neutral** | Functioning at a baseline level. |
| **Debilitated** | Planet at its weakest. Requires conscious effort to manifest positive results. |

---

<div style="page-break-after: always;"></div>

## 5. Algorithms & Formulas

All the maths lives in `lib/services/astro_service.dart`. The source is **Jean Meeus, *Astronomical Algorithms*, 2nd ed.** (the standard reference for this kind of computation). Accuracy is approximately 1 arcminute for dates 1900–2100 — more than enough for astrocartography, which works at the scale of cities.

### Step 1 — Julian Day Number (JD)

Converts a calendar date + time to a single continuous number (days since noon, 1 January 4713 BC). Every astronomical formula needs this as input.

```
JD = floor(365.25 × (Y + 4716))
   + floor(30.6001 × (M + 1))
   + D + hour/24 + B - 1524.5

where:
  if month ≤ 2: Y = year - 1, M = month + 12
  A = floor(Y / 100)
  B = 2 - A + floor(A / 4)   ← Gregorian calendar correction
```

### Step 2 — Julian Centuries from J2000 (T)

Nearly every Meeus formula uses T, not JD directly. J2000.0 is the standard epoch (noon, 1 Jan 2000, JD 2451545.0).

```
T = (JD - 2451545.0) / 36525
```

### Step 3 — Greenwich Mean Sidereal Time (GMST)

Sidereal time is how far the sky has rotated. GMST at Greenwich tells us where the sky is overhead in degrees. Meeus Ch. 12:

```
GMST (°) = 280.46061837
          + 360.98564736629 × (JD - 2451545.0)
          + 0.000387933 × T²
          − T³ / 38710000
          (normalised to 0–360°)
```

### Step 4 — Obliquity of the Ecliptic (ε)

The tilt of Earth's axis relative to its orbit. Changes slowly over time (Meeus Ch. 22):

```
ε = 23.439291111° − 0.013004167° × T − 0.000001639° × T² + 0.000000503° × T³
```

### Step 5 — Heliocentric Ecliptic Coordinates (planets)

Each planet's position in space is computed from its orbital elements — six numbers that describe the size, shape, and orientation of its orbit. These are from Meeus Table 33.a (J2000 epoch):

| Element | Symbol | What it is |
|---|---|---|
| Mean longitude | L₀ + L₁·T | Where the planet "would be" if orbiting in a circle at uniform speed |
| Semi-major axis | a (AU) | Average distance from Sun |
| Eccentricity | e | How elliptical the orbit is (0 = circle) |
| Inclination | i (°) | Tilt of orbit vs Earth's orbital plane |
| Longitude of ascending node | Ω (°) | Where orbit crosses the ecliptic going north |
| Longitude of perihelion | ω̃ (°) | Direction of closest approach to Sun |

**Procedure:**

```
1. Mean anomaly:    M = L₀ + L₁·T - ω̃

2. Eccentric anomaly E — solve Kepler's equation iteratively:
   E - e·sin(E) = M   (Newton-Raphson, converges in ~5 iterations)

3. True anomaly:    ν = 2 · atan2(√(1+e)·sin(E/2), √(1-e)·cos(E/2))

4. Distance from Sun:  r = a · (1 - e·cos(E))

5. Argument of latitude: u = ν + (ω̃ - Ω)

6. Cartesian (heliocentric ecliptic):
   x = r · (cos(Ω)·cos(u) - sin(Ω)·sin(u)·cos(i))
   y = r · (sin(Ω)·cos(u) + cos(Ω)·sin(u)·cos(i))
   z = r · sin(u) · sin(i)
```

### Step 6 — Geocentric Position

Subtract Earth's heliocentric position from the planet's heliocentric position. This gives the planet as seen from Earth.

```
dx = x_planet - x_earth
dy = y_planet - y_earth
dz = z_planet - z_earth

ecliptic longitude λ = atan2(dy, dx)
ecliptic latitude  β = atan2(dz, √(dx² + dy²))
```

### Step 7 — Ecliptic → Equatorial Coordinates

Convert from ecliptic (RA/Dec referenced to the plane of the solar system) to equatorial (referenced to Earth's equator). This uses the obliquity ε:

```
Right Ascension:
  α = atan2(sin(λ)·cos(ε) - tan(β)·sin(ε),  cos(λ))

Declination:
  δ = asin(sin(β)·cos(ε) + cos(β)·sin(ε)·sin(λ))
```

### Step 8 — Moon (Simplified Lunar Theory)

The Moon orbits Earth, not the Sun, so the orbital mechanics are different. The app uses a truncated version of Meeus Ch. 47 — accurate to about 1°, which is fine for astrocartography:

```
D  = JD - 2451545.0   (days from J2000)

Mean longitude:  L = 218.316° + 13.176396°·D
Mean anomaly:    M = 134.963° + 13.064993°·D
Argument of latitude: F = 93.272° + 13.229350°·D

Ecliptic longitude: λ = L + 6.289°·sin(M)
Ecliptic latitude:  β = 5.128°·sin(F)
```

Then convert to RA/Dec using the same ecliptic → equatorial formula above.

### Step 9 — Lahiri Ayanamsha

Subtract from any tropical ecliptic longitude to convert to sidereal:

```
ayanamsha = 23.85317° + 1.39552°·T
```

This is an approximation of the standard Lahiri formula, accurate to within ~0.1° for modern dates.

### Step 10 — Ascendant

The Ascendant is the ecliptic degree rising on the eastern horizon for a given place and time. It needs Local Mean Sidereal Time (LMST = GMST + observer's longitude) and the observer's latitude. Meeus formula:

```
LMST = GMST + longitude

ASC = atan2(cos(LMST), -(sin(ε)·tan(lat) + cos(ε)·sin(LMST)))
```

After computing, subtract the ayanamsha to get the sidereal Ascendant.

### Step 11 — MC/IC Lines (vertical lines)

The MC (Midheaven) is where the ecliptic intersects the local meridian. The longitude where a planet's MC line crosses is simply:

```
MC longitude = RA_planet - GMST      (normalised to −180° to +180°)
IC longitude = MC longitude + 180°
```

The app then draws a vertical line from lat −85° to +85° at that longitude.

### Step 12 — AC/DC Lines (rising/setting curves)

The planet rises where the angle between it and the local horizon is zero. For a planet with declination δ, at a location with latitude φ, the hour angle H at rising satisfies:

```
cos(H) = -tan(δ) · tan(φ)
```

The app parameterises H from 0° to 180° in 0.5° steps and computes:

```
latitude  = atan(-cos(H) / tan(δ))
longitude = RA ± H - GMST        (+ for rising, - for setting)
```

This produces the S-shaped curves. The curve is split into separate segments wherever it crosses the antimeridian (±180°) to avoid lines jumping across the map.

---

<div style="page-break-after: always;"></div>

## 6. City Scoring in Detail

**File:** `lib/services/city_service.dart`

### How cities are found

For each planet line segment, the app computes a bounding box and queries the SQLite database for cities within that box (plus a 5° latitude / 8° longitude buffer). This is a fast indexed query — the `(latitude, longitude)` index makes it O(log n).

### Distance calculation — Haversine formula

For a city at (lat1, lon1) and a point on a line at (lat2, lon2), the great-circle distance in km is:

```
a = sin²(Δlat/2) + cos(lat1)·cos(lat2)·sin²(Δlon/2)
d = 6371 · 2 · atan2(√a, √(1-a))
```

6371 km is Earth's mean radius. The app finds the minimum distance from the city to any point along the line segment.

### Influence radius

Only cities within **500 km** of a line are scored. Cities further away are ignored.

### Strength

```
strength = (500 - distance_km) / 500
```

A city 0 km from a line has strength 1.0. A city 499 km away has strength ≈ 0.002. A city 500+ km away has strength 0 (excluded).

### Score per influence

```
score = planet.benefitScore × lineType.weight × strength
```

**Planet benefit scores** (built into `Planet.benefitScore`):

| Planet | Score |
|---|---|
| Jupiter | +3.0 |
| Venus | +2.5 |
| Sun | +1.5 |
| Moon | +0.8 |
| Mercury | +0.5 |
| Uranus | +0.3 |
| Neptune | −0.3 |
| Pluto | −1.0 |
| Mars | −1.5 |
| Saturn | −2.0 |

**Line type weights:**

| Line | Weight |
|---|---|
| MC, AC | 1.0 |
| DC, IC | 0.8 |

### Total score and rating

The total city score is the sum of all individual influence scores. The rating threshold:

```
score ≥ 1.5  → Lucky    (green marker)
score ≤ −1.5 → Challenging (red marker)
otherwise    → Neutral   (amber marker)
```

### Tapped map points

When the user taps a blank spot on the map, the same scoring runs synchronously (no DB lookup needed — just iterate all planet lines and compute distances). The result is displayed immediately in the detail panel.

---

<div style="page-break-after: always;"></div>

## 7. Every Package Explained

### Production dependencies

#### `flutter_riverpod: ^2.5.1`
The state management library. Every piece of data in the app — the birth profile, the computed lines, the city list, the active filters — lives in a Riverpod provider. Widgets "watch" a provider and automatically rebuild when its value changes. No manual `setState` needed for shared state.

*In this app:* `ref.watch(citySpotsProvider)` in the map screen — whenever the profile changes, `citySpotsProvider` recomputes and the map rebuilds with new markers.

#### `riverpod_annotation: ^2.4.0`
Provides the `@riverpod` annotation for code generation. Allows you to write providers as annotated functions/classes instead of manually instantiating `Provider(...)`. Run `dart run build_runner build` after annotating a new provider.

*Note:* Not all providers in this app use annotation — some are written manually. Either style works.

#### `go_router: ^14.3.0`
URL-style navigation for Flutter. Defines routes as `/`, `/profile`, `/map`, `/about`. Instead of `Navigator.push(...)`, you call `context.go('/map')`. Routes are defined in `lib/core/router/app_router.dart`.

*In this app:* The intro screen calls `context.go(Routes.map)` when the user has a saved profile.

#### `shared_preferences: ^2.3.2`
Key-value storage that persists across app restarts. Under the hood it's Android's `SharedPreferences` (XML file in the app's private storage). Used to save and load birth profiles as JSON strings.

*In this app:* `ProfileStorage` in `lib/core/storage/profile_storage.dart` serialises a `BirthProfile` to JSON, stores it under a key like `profile_<id>`, and keeps a list of all IDs under `profile_ids`.

#### `sqflite: ^2.3.3+1`
SQLite for Flutter. Lets the app run SQL queries against a bundled `.db` file. The cities database is 19 MB and pre-built — the app opens it read-only at startup.

*In this app:* `CityDb.open()` copies `assets/data/cities.db` to the device's documents directory on first launch, then opens it. Queries like `SELECT * FROM cities WHERE latitude BETWEEN ? AND ?` run indexed in milliseconds.

#### `path_provider: ^2.1.4`
Finds the right directory to store files on the device. `getApplicationDocumentsDirectory()` returns where to put the copied SQLite file. Without this, the app wouldn't know a safe writable path.

#### `flutter_map: ^7.0.2`
The map widget. Renders OpenStreetMap tiles (free, no API key). Supports layers — the app adds `TileLayer` (map tiles), `PolylineLayer` (planet lines), and `CircleLayer` (city markers). Handles zoom, pan, and tap events.

*In this app:* `FlutterMap(children: [TileLayer(...), PlanetLinesLayer(), CitySpotsLayer()])` in `map_screen.dart`.

#### `latlong2: ^0.9.1`
Simple `LatLng` data class — a latitude/longitude pair. Used everywhere coordinates are passed between functions. Also provides a `Distance` class with haversine computation (though the app implements its own haversine for the scoring loop for performance).

#### `google_fonts: ^6.2.1`
Downloads and caches Google Fonts. The app uses **Cormorant Garamond** (display text, headlines) and **Inter** (body text). Fonts are fetched once and cached on device. In release builds, they're bundled to avoid network dependency.

#### `intl: ^0.19.0`
Internationalisation utilities. The app uses only `DateFormat` from this package — for formatting dates in the PDF filename (`DateFormat('yyyyMMdd_HHmm').format(now)`) and for displaying birth dates.

#### `path: ^1.9.0`
Path manipulation utilities. `path.join(docsDir, 'cities.db')` — combines directory and filename correctly for any OS. Rarely used directly but needed by sqflite internally.

#### `package_info_plus: ^10.2.0`
Reads the app's version metadata (`pubspec.yaml` version field) at runtime. Used in the About screen to display `Version 1.0.9+10` dynamically without hardcoding.

*In this app:* `PackageInfo.fromPlatform()` is async; called in `initState()` with a `then()` callback that calls `setState()` once the version string arrives.

#### `pdf: ^3.11.1`
Pure-Dart PDF generation library. Lets you build a PDF document programmatically — define pages, add text, images, tables, columns. The output is a `Uint8List` (byte array) that can be saved or shared.

*In this app:* `lib/features/report/report_service.dart` builds a `pw.Document`, adds pages for the cover, natal chart table, and city breakdowns, then converts to bytes.

#### `printing: ^5.13.1`
Companion to `pdf`. Provides `Printing.sharePdf(bytes, filename: ...)` which triggers the OS share sheet. Also lets you open a PDF preview.

*In this app:* Used only for `Printing.sharePdf(...)` after generating the PDF bytes.

#### `share_plus: ^13.2.0`
General-purpose sharing — can share text, files, URLs. Slightly more flexible than `printing`'s share. Used alongside `printing` so the PDF appears in any app (email, WhatsApp, Drive, etc.) rather than only print destinations.

---

### Dev dependencies

#### `flutter_lints: ^6.0.0`
Official Flutter linting rules. Catches common mistakes (unused imports, unnecessary null checks, etc.). Configuration in `analysis_options.yaml`.

#### `build_runner: ^2.4.13`
Code generation runner. Run `dart run build_runner build` to generate `.g.dart` files from annotations like `@riverpod`.

#### `riverpod_generator: ^2.4.0`
Generates Riverpod provider boilerplate from `@riverpod` annotations. Requires `build_runner`.

#### `custom_lint: ^0.7.6` and `riverpod_lint: ^2.4.0`
Riverpod-specific lint rules — catches errors like watching a provider outside a widget, or forgetting `ref.watch` vs `ref.read` distinctions.

#### `flutter_launcher_icons: ^0.14.3`
Generates all Android launcher icon sizes from one source image. Run `dart run flutter_launcher_icons` after changing `assets/icons/flutter-icon.png`. Config is in `pubspec.yaml` under `flutter_launcher_icons:`.

---

<div style="page-break-after: always;"></div>

## 8. How to Change Things (Recipes)

### Add a new planet

1. Add the planet to the `Planet` enum in `lib/models/planet_line.dart` with a `displayName`, `color`, `glyph`, and `benefitScore`.
2. Add its orbital elements to `_planetElements` in `lib/services/astro_service.dart` (look up Meeus Table 33.a for the values).
3. Add its planet image asset: `assets/planets/ddd_{planet_name}.webp`.
4. Add its sign dignity row in `planetDignity` in `lib/services/natal_interpretations.dart` (12 values, one per sign, 0=Aries).
5. Add its remedies text in `planetRemedies` in the same file.
6. Add interpretations for all 4 line types in `_interpretations` in `lib/services/city_service.dart`.

---

### Change the scoring thresholds

**Lucky/Challenging cutoff** — in `lib/models/city_spot.dart`, the `rating` getter:
```dart
if (score >= 1.5) return SpotRating.lucky;
if (score <= -1.5) return SpotRating.challenging;
```
Change `1.5` to make it more or less strict.

**Influence radius** — in `lib/services/city_service.dart`:
```dart
const _influenceRadiusKm = 500.0;
```
Increase for more cities to appear. Decrease for only very close cities.

**Planet weights** — change `benefitScore` in `Planet` enum in `planet_line.dart`.

**Line type weights** — change `weight` in `LineType` enum in `planet_line.dart`.

---

### Add a new screen

1. Create the widget file in `lib/features/your_screen/your_screen.dart`.
2. Add a route constant in `lib/core/router/app_router.dart`:
   ```dart
   static const yourScreen = '/your-screen';
   ```
3. Add a `GoRoute` entry in `routerProvider`:
   ```dart
   GoRoute(
     path: Routes.yourScreen,
     builder: (ctx, state) => const YourScreen(),
   ),
   ```
4. Navigate to it with `context.go(Routes.yourScreen)`.

---

### Change interpretation text for a planet line

Open `lib/services/city_service.dart`. Find the `_interpretations` map. Each entry is keyed by `(Planet, LineType)`. Edit the string value:

```dart
(Planet.jupiter, LineType.ac): 'Your own text here...',
```

---

### Change colours

All colour tokens are in `lib/core/theme/app_colors.dart`. The design system colours:

| Token | Hex | Use |
|---|---|---|
| `canvas` | `#faf9f5` | Default background |
| `surfaceCard` | `#efe9de` | Cards, bottom sheet |
| `surfaceDark` | `#181715` | Dark cards |
| `primary` | `#cc785c` | Coral — CTA, accents |
| `ink` | `#141413` | Headlines |
| `body` | `#3d3d3a` | Body text |
| `muted` | `#6c6a64` | Secondary labels |

Planet colours are also in `app_colors.dart` as `planetSun`, `planetMoon`, etc.

---

### Change the city database

The cities come from GeoNames `cities1000` (all cities population ≥ 1,000). To regenerate:

```bash
python3 tools/generate_city_db.py
```

This downloads fresh data from GeoNames and rebuilds `assets/data/cities.db`. The resulting file is about 19 MB. Commit it with the app.

To change the minimum population threshold, edit the Python script.

---

### Change the PDF layout

The PDF is built in `lib/features/report/report_service.dart`. The `pdf` package uses a constraint-based layout similar to Flutter but with its own widget set (prefixed `pw.`). Key things:

- `pw.Page` — a page
- `pw.Column`, `pw.Row` — layout
- `pw.Text(text, style: pw.TextStyle(...))` — text
- `pw.Image(image)` — image from `pw.MemoryImage(bytes)`
- `pw.Table` — table with rows and columns

Images must be loaded as bytes first (`rootBundle.load('assets/...')`) and wrapped in `pw.MemoryImage(data.buffer.asUint8List())`.

---

### Add a profile field

1. Add the field to `BirthProfile` in `lib/models/birth_profile.dart` (with a default value so old stored data doesn't break).
2. Update `toJson()` and `fromJson()` in the same class.
3. Add the input field to `ProfileScreen` in `lib/features/profile/profile_screen.dart`.
4. The `profileProvider` will automatically persist the new data since it serialises the whole object.

---

<div style="page-break-after: always;"></div>

## 9. Build & Release

### Version numbering

The version is in `pubspec.yaml`:
```yaml
version: 1.0.9+10
```

Format: `major.minor.patch+buildNumber`. The build number (`+10`) is what the Play Store uses to distinguish releases — it must increase with every upload. Increment both when releasing.

### Local debug build

```bash
flutter pub get
flutter run
```

This builds a debug APK and installs it directly on the connected device.

### Signing setup

The release keystore is at `android/keystore/release-key.jks`. The credentials go in `android/key.properties` (this file is gitignored — never commit it):

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=../../keystore/release-key.jks
```

### Local release build

```bash
# Split by CPU architecture — smaller files, recommended
flutter build apk --split-per-abi --release

# Single fat APK (larger, works on all devices)
flutter build apk --release
```

Output lands in `build/app/outputs/flutter-apk/`. The `applicationVariants.all` block in `android/app/build.gradle.kts` renames them to `luckylatlang_<arch>_<datetime>-signed.apk` in the Gradle output directory (not the `flutter-apk/` copy).

### CI — GitHub Actions

File: `.github/workflows/release.yml`

Triggers on every push to `master`. Steps:
1. Set up Java 17 and Flutter 3.44.4
2. Extract version from `pubspec.yaml`
3. Write `android/key.properties` from GitHub Secrets (`STORE_PASSWORD`, `KEY_PASSWORD`)
4. `flutter pub get`
5. `flutter build apk --split-per-abi --release`
6. Shell rename step: renames `app-<arch>-release.apk` → `luckylatlang_<arch>_<datetime>-signed.apk`
7. Creates a GitHub Release with the APKs attached

**Required GitHub Secrets:** `STORE_PASSWORD`, `KEY_PASSWORD`

### Secrets setup (one-time)

In the GitHub repo → Settings → Secrets and variables → Actions → New repository secret. Add `STORE_PASSWORD` and `KEY_PASSWORD`.

### APK sizes

| Build type | Size |
|---|---|
| Fat APK (all architectures) | ~116 MB |
| Split APK (arm64-v8a only) | ~75–79 MB |

The size is dominated by assets: animated cutouts (~27 MB), cities.db (~19 MB), mystic polaroids (~8 MB). The Dart code and Flutter engine account for only ~15 MB in a split APK.

---

<div style="page-break-after: always;"></div>

## 10. Home Screen Widget

The home screen widget is a native Android `AppWidget` — not Flutter. It lives entirely in the Kotlin/Java side of the project.

### Files

```
android/app/src/main/
  kotlin/.../FortuneWidgetProvider.kt     Main widget logic + 3 subclasses
  res/
    layout/
      fortune_widget_dark.xml             Dark variant layout
      fortune_widget_coral.xml            Coral variant layout
      fortune_widget_material.xml         Material You variant layout
    xml/
      fortune_widget_dark_info.xml        Widget metadata (size, update interval)
      fortune_widget_coral_info.xml
      fortune_widget_material_info.xml
```

### How it works

1. The widget uses `RemoteViews` — the only widget system Android allows for home screen widgets.
2. It displays a `ViewFlipper` on each side: one for quotes (left), one for goth images (right).
3. On first load, it fetches a list of fortune-mod quotes from GitHub (raw text), parses them, and caches them in `SharedPreferences`.
4. On each widget update or tap, it picks a random quote and a random goth image and sets them into the `ViewFlipper`, then triggers the fade animation.
5. Tap does not open the app — it just cycles to the next quote + image pair with a 400 ms crossfade.

### Three style variants

| Variant | Background | Text colour |
|---|---|---|
| Dark | `#181715` (near-black) | Warm cream |
| Coral | `#cc785c` (brand coral) | White |
| Material You | Dynamic system colours | Dynamic |

Each variant is a separate `AppWidgetProvider` subclass in `FortuneWidgetProvider.kt` — `DarkFortuneWidgetProvider`, `CoralFortuneWidgetProvider`, `MaterialFortuneWidgetProvider`. They all call the same `updateWidget()` method with different layout resource IDs.

### Layout structure

Each XML layout:
```
LinearLayout (horizontal)
  ├── ViewFlipper (quote_flipper, weight=6, LEFT side)
  │     └── TextViews for each quote
  └── ViewFlipper (image_flipper, weight=4, RIGHT side)
        └── ImageViews for each goth image
```

Quote side gets 60% of the width, image side gets 40%.

### Modifying the widget

**Change quote source:** Edit the URL in `FortuneWidgetProvider.kt` where it fetches the fortune list. It currently hits a raw GitHub URL. Swap it for any line-delimited plain text URL.

**Change images:** The goth images are loaded from `assets/goth/` at build time and referenced in the XML layouts as `@drawable/...` entries (Android copies assets declared as drawables). To add images, add them to the goth assets folder and reference them in the layout XML with a new `ImageView`.

**Change the animation speed:** The `ViewFlipper` `android:flipInterval` attribute in the XML controls the auto-flip interval. The crossfade animation duration is controlled by `android:inAnimation` and `android:outAnimation` attributes which reference animation resources in `res/anim/`.

**Change widget size:** Edit the `minWidth` and `minHeight` in the `*_info.xml` files. Android snaps to grid cells — each cell is approximately 74dp on most launchers.

---

<div style="page-break-after: always;"></div>

## Quick Reference

### Common commands

```bash
flutter pub get                          # after changing pubspec.yaml
flutter run                              # debug on connected device
flutter build apk --split-per-abi --release   # release APKs
flutter analyze                          # lint check (should show 0 issues)
flutter test                             # run tests
dart run build_runner build              # regenerate Riverpod code
dart run flutter_launcher_icons          # regenerate app icons
python3 tools/generate_city_db.py        # rebuild city database
```

### Key file locations

| What | Where |
|---|---|
| Birth profile model | `lib/models/birth_profile.dart` |
| All orbital mechanics | `lib/services/astro_service.dart` |
| City scoring + interpretations | `lib/services/city_service.dart` |
| Planet dignity + remedies | `lib/services/natal_interpretations.dart` |
| All providers | `lib/providers/` |
| All routes | `lib/core/router/app_router.dart` |
| Design colours | `lib/core/theme/app_colors.dart` |
| PDF generation | `lib/features/report/report_service.dart` |
| Home screen widget | `android/app/src/main/kotlin/.../FortuneWidgetProvider.kt` |
| App version | `pubspec.yaml` → `version:` field |
| CI workflow | `.github/workflows/release.yml` |
| Signing config | `android/key.properties` (gitignored) |

### Asset naming conventions

| Asset type | Naming pattern | Example |
|---|---|---|
| Planet images | `assets/planets/ddd_{planet}.webp` | `ddd_jupiter.webp` |
| Sign images | `assets/signs/mundane_solar_ingress_{sign}.webp` | `mundane_solar_ingress_aries.webp` |
| Mystic polaroids | `assets/mystic/module_timeline_shop_*.webp` | `module_timeline_shop_sign_edu_01.webp` |
| Goth images | `assets/goth/` | `*.webp` |
| Animated cutouts | `assets/animated/` | `*.webp` |

Planet and sign names in filenames always match the Dart enum `.name` property (lowercase, e.g. `jupiter`, `aries`).

---

*Generated 2026-07-01 · Lucky Lat·Lang v1.0.9*
