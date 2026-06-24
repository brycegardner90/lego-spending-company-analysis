import pandas as pd
import sqlite3
import os

# ── PATHS ────────────────────────────────────────────────────────────────────
BASE_DIR = r"C:\Users\bryce\Desktop\Data Projects\Side Projects\Lego Spending & Company Analysis"
CSV_DIR  = os.path.join(BASE_DIR, "csv")
DB_PATH  = os.path.join(BASE_DIR, "lego.db")

SETS_CSV       = os.path.join(CSV_DIR, "sets.csv")
THEMES_CSV     = os.path.join(CSV_DIR, "themes.csv")
COLLECTION_CSV = os.path.join(CSV_DIR, "bryce_lego_collection.csv")

# ── EXTRACT ───────────────────────────────────────────────────────────────────
print("Extracting...")

sets_raw    = pd.read_csv(SETS_CSV)
themes_raw  = pd.read_csv(THEMES_CSV)
collection  = pd.read_csv(COLLECTION_CSV)

print(f"  sets.csv:       {len(sets_raw):,} rows")
print(f"  themes.csv:     {len(themes_raw):,} rows")
print(f"  collection.csv: {len(collection):,} rows")

# ── TRANSFORM: THEMES ─────────────────────────────────────────────────────────
print("\nTransforming themes...")

# Rebrickable themes have parent_id for sub-themes — flatten to top-level name
themes = themes_raw[['id', 'name', 'parent_id']].copy()
themes.columns = ['theme_id', 'theme_name', 'parent_id']

# Build a parent name lookup
parent_lookup = themes.set_index('theme_id')['theme_name'].to_dict()
themes['parent_name'] = themes['parent_id'].map(parent_lookup)

# Use parent name if it exists, otherwise use theme name directly
themes['theme_display'] = themes['parent_name'].where(
    themes['parent_name'].notna(), themes['theme_name']
)

# ── TRANSFORM: SETS ───────────────────────────────────────────────────────────
print("Transforming sets...")

sets = sets_raw.copy()
sets.columns = [c.lower() for c in sets.columns]

# Join theme name
sets = sets.merge(
    themes[['theme_id', 'theme_name', 'theme_display']],
    on='theme_id',
    how='left'
)

# Clean up
sets['year'] = pd.to_numeric(sets['year'], errors='coerce')
sets['num_parts'] = pd.to_numeric(sets['num_parts'], errors='coerce').fillna(0).astype(int)

# Flag 18+ era — LEGO officially launched the 18+ label in 2020
# but adult-targeted sets started appearing around 2018 (UCS, etc.)
sets['adult_era'] = sets['year'] >= 2018

# Filter to sets with at least 1 piece (removes promotional/non-build entries)
sets = sets[sets['num_parts'] > 0].copy()

print(f"  Sets after cleaning: {len(sets):,}")
print(f"  Adult era (2018+):   {sets['adult_era'].sum():,}")

# ── TRANSFORM: COLLECTION ─────────────────────────────────────────────────────
print("Transforming personal collection...")

collection['set_num'] = collection['set_num'].astype(str)
collection['retail_price_usd'] = pd.to_numeric(collection['retail_price_usd'], errors='coerce')
collection['current_value_usd'] = pd.to_numeric(collection['current_value_usd'], errors='coerce')
collection['pieces'] = pd.to_numeric(collection['pieces'], errors='coerce').fillna(0).astype(int)
collection['minifigs'] = pd.to_numeric(collection['minifigs'], errors='coerce').fillna(0).astype(int)

# Calculate ROI
collection['gain_loss_usd'] = (
    collection['current_value_usd'] - collection['retail_price_usd']
)
collection['roi_pct'] = (
    collection['gain_loss_usd'] / collection['retail_price_usd'] * 100
).round(2)

# Price per piece
collection['price_per_piece'] = (
    collection['retail_price_usd'] / collection['pieces']
).round(4)

# Summary stats
total_paid    = collection['retail_price_usd'].sum()
total_current = collection['current_value_usd'].sum()
total_pieces  = collection['pieces'].sum()
overall_roi   = ((total_current - total_paid) / total_paid * 100)

print(f"  Total paid:          ${total_paid:,.2f}")
print(f"  Total current value: ${total_current:,.2f}")
print(f"  Overall ROI:         {overall_roi:.1f}%")
print(f"  Total pieces:        {total_pieces:,}")

# ── LOAD: SQLITE ──────────────────────────────────────────────────────────────
print(f"\nLoading to SQLite: {DB_PATH}")

conn = sqlite3.connect(DB_PATH)

# Table 1: all_sets — full Rebrickable catalog (cleaned)
sets.to_sql('all_sets', conn, if_exists='replace', index=False)
print(f"  all_sets:       {len(sets):,} rows")

# Table 2: themes — theme lookup
themes.to_sql('themes', conn, if_exists='replace', index=False)
print(f"  themes:         {len(themes):,} rows")

# Table 3: my_collection — Bryce's personal inventory
collection.to_sql('my_collection', conn, if_exists='replace', index=False)
print(f"  my_collection:  {len(collection):,} rows")

# Table 4: adult_sets — 18+ era sets only for focused analysis
adult_sets = sets[sets['adult_era'] == True].copy()
adult_sets.to_sql('adult_sets', conn, if_exists='replace', index=False)
print(f"  adult_sets:     {len(adult_sets):,} rows")

conn.close()

print("\nETL complete. Database ready at:")
print(f"  {DB_PATH}")
print("\nTables created:")
print("  all_sets       — full Rebrickable catalog")
print("  themes         — theme lookup")
print("  my_collection  — Bryce's 30-set personal inventory")
print("  adult_sets     — 2018+ sets for 18+ era analysis")
