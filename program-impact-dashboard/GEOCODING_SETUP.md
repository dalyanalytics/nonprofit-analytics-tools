# Geocoding Setup Instructions

## Problem
The app was timing out on shinyapps.io during deployment because geocoding 15 Connecticut towns using the Nominatim API at startup takes too long.

## Solution
Pre-compute the geocoded data locally and deploy the RDS file with your app.

## Steps to Generate Geocoded Data

### 1. Ensure you have your Census API key set up

Make sure your `.Renviron` file exists in this directory with your Census API key:

```bash
# Check if .Renviron exists
cat .Renviron
```

It should contain:
```
CENSUS_API_KEY=your_key_here
```

### 2. Run the geocoding script locally

From the `program-impact-dashboard` directory, run:

```bash
Rscript precompute_geocoding.R
```

This script will:
- Fetch the 15 most populous Connecticut towns from Census API
- Geocode each town's address using OpenStreetMap/Nominatim
- Save the results to `ct_towns_geocoded.rds`

**Expected runtime:** 30-60 seconds (due to Nominatim rate limiting)

### 3. Verify the RDS file was created

```bash
ls -lh ct_towns_geocoded.rds
```

You should see a file of approximately 2-3 KB.

### 4. Deploy to shinyapps.io

The modified `app.R` now loads the pre-computed data from `ct_towns_geocoded.rds` instead of geocoding at runtime. Deploy as normal:

```bash
# Via GitHub Actions workflow
git add ct_towns_geocoded.rds precompute_geocoding.R
git commit -m "Add pre-computed geocoding to fix deployment timeout"
git push
```

## How It Works

### Before (causing timeout):
```r
ct_towns_data <- get_acs(...) %>%
  geocode(address, method = "osm", ...) # 15 API calls during startup
```

### After (fast):
```r
ct_towns_data <- readRDS("ct_towns_geocoded.rds") # Instant load from disk
```

## Fallback Behavior

If the RDS file is missing, the app will fall back to hardcoded sample data with 15 Connecticut towns, so the app will still run.

## When to Regenerate

Re-run `precompute_geocoding.R` when:
- Census data updates (annually)
- You want to change which towns to include
- Geocoding coordinates need updating

## Troubleshooting

### "Census API key not found"
- Ensure `.Renviron` file exists in `program-impact-dashboard/` directory
- Verify the API key is correct (test at https://api.census.gov/data/2022/acs/acs5)

### "Geocoding failed for some towns"
- Nominatim has rate limits (1 request/second)
- The script includes automatic delays between requests
- If geocoding fails, try running again in a few minutes

### "File not found" error on shinyapps.io
- Ensure `ct_towns_geocoded.rds` is committed to git
- Verify it's being deployed with your app files
- Check the file isn't in `.gitignore`

## File Structure

```
program-impact-dashboard/
├── app.R                        # Modified to load RDS file
├── precompute_geocoding.R       # Script to generate geocoded data
├── ct_towns_geocoded.rds        # Generated file (commit to git!)
├── .Renviron                    # Census API key (DO NOT commit)
├── .Renviron.example            # Template for API key
└── GEOCODING_SETUP.md           # This file
```
