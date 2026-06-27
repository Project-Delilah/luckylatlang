"""
Downloads GeoNames cities1000 + countryInfo, builds assets/data/cities.db.
Run from project root: python3 tools/generate_city_db.py
"""

import csv
import io
import sqlite3
import urllib.request
import zipfile
from pathlib import Path

OUT = Path("assets/data/cities.db")
OUT.parent.mkdir(parents=True, exist_ok=True)

CITIES_URL = "https://download.geonames.org/export/dump/cities1000.zip"
COUNTRY_URL = "https://download.geonames.org/export/dump/countryInfo.txt"

print("Downloading countryInfo.txt …")
with urllib.request.urlopen(COUNTRY_URL) as r:
    country_raw = r.read().decode("utf-8")

print("Downloading cities1000.zip …")
with urllib.request.urlopen(CITIES_URL) as r:
    zip_bytes = r.read()

print("Parsing countries …")
countries = {}
for line in country_raw.splitlines():
    if line.startswith("#") or not line.strip():
        continue
    parts = line.split("\t")
    if len(parts) < 5:
        continue
    iso = parts[0].strip()
    name = parts[4].strip()
    capital = parts[5].strip()
    continent = parts[8].strip()
    countries[iso] = (name, capital, continent)

print(f"  {len(countries)} countries loaded")

print("Extracting cities …")
with zipfile.ZipFile(io.BytesIO(zip_bytes)) as z:
    with z.open("cities1000.txt") as f:
        raw = f.read().decode("utf-8")

# GeoNames TSV columns (0-indexed):
# 0  geonameid  1  name  2  asciiname  3  alternatenames  4  latitude
# 5  longitude  6  feature_class  7  feature_code  8  country_code
# 9  cc2  10 admin1  11 admin2  12 admin3  13 admin4
# 14 population  15 elevation  16 dem  17 timezone  18 modification_date

rows = []
reader = csv.reader(io.StringIO(raw), delimiter="\t", quoting=csv.QUOTE_NONE)
for parts in reader:
    if len(parts) < 19:
        continue
    rows.append((
        int(parts[0]),          # id
        parts[1],               # name
        parts[2],               # ascii_name
        float(parts[4]),        # latitude
        float(parts[5]),        # longitude
        parts[8].upper(),       # country_code
        int(parts[14]) if parts[14] else 0,  # population
        parts[17],              # timezone
    ))

print(f"  {len(rows):,} cities parsed")

print("Building SQLite database …")
if OUT.exists():
    OUT.unlink()

con = sqlite3.connect(OUT)
cur = con.cursor()

cur.executescript("""
PRAGMA journal_mode = DELETE;
PRAGMA page_size = 4096;

CREATE TABLE countries (
    iso_code   TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    capital    TEXT,
    continent  TEXT
);

CREATE TABLE cities (
    id           INTEGER PRIMARY KEY,
    name         TEXT    NOT NULL,
    ascii_name   TEXT    NOT NULL,
    latitude     REAL    NOT NULL,
    longitude    REAL    NOT NULL,
    country_code TEXT    NOT NULL,
    population   INTEGER NOT NULL DEFAULT 0,
    timezone     TEXT
);
""")

cur.executemany(
    "INSERT OR IGNORE INTO countries VALUES (?,?,?,?)",
    [(iso, name, cap, cont) for iso, (name, cap, cont) in countries.items()]
)

cur.executemany(
    "INSERT INTO cities VALUES (?,?,?,?,?,?,?,?)",
    rows,
)

cur.executescript("""
CREATE INDEX idx_cities_country  ON cities (country_code);
CREATE INDEX idx_cities_lat_lng  ON cities (latitude, longitude);
CREATE INDEX idx_cities_pop      ON cities (population DESC);
VACUUM;
ANALYZE;
""")

con.commit()
con.close()

size_mb = OUT.stat().st_size / 1_048_576
print(f"Done → {OUT}  ({size_mb:.1f} MB)")
print(f"  countries : {len(countries):,}")
print(f"  cities    : {len(rows):,}")
