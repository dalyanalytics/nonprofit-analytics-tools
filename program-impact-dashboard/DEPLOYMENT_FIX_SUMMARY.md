# Deployment Timeout Fix - Summary

## Problem
The Program Impact Dashboard was timing out during deployment to shinyapps.io because it was geocoding 15 Connecticut town addresses at startup using the Nominatim API, which:
- Takes 30-60 seconds due to rate limits
- Counts against shinyapps.io's deployment timeout
- Makes unnecessary API calls on every app startup

## Solution
Pre-compute the geocoded data locally and deploy it as a static `.rds` file with the app.

## Changes Made

### 1. **Modified app.R** (lines 9-25)

**Before (slow, causes timeout):**
```r
library(tidycensus)
library(tidygeocoder)

census_api_key(Sys.getenv("CENSUS_API_KEY"), overwrite = TRUE)

ct_towns_data <- tryCatch({
  acs_data <- get_acs(...) %>%
    geocode(address, method = "osm", lat = lat, long = lng) %>%  # ⚠️ 15 API calls!
    ...
}, error = function(e) { ... })
```

**After (fast, no timeout):**
```r
# Removed library(tidycensus) and library(tidygeocoder)

ct_towns_data <- tryCatch({
  rds_file <- "ct_towns_geocoded.rds"
  if (file.exists(rds_file)) {
    readRDS(rds_file)  # ✓ Instant load from disk
  } else {
    stop("Pre-computed geocoding file not found")
  }
}, error = function(e) {
  # Same fallback to sample data
  ...
})
```

### 2. **Created precompute_geocoding.R**
Standalone script to fetch Census data and geocode addresses locally:
- Fetches 15 most populous CT towns from Census API
- Geocodes each address using OpenStreetMap
- Saves results to `ct_towns_geocoded.rds`

### 3. **Created run_geocoding.sh**
Helper script with error checking to run the geocoding process.

### 4. **Created GEOCODING_SETUP.md**
Comprehensive documentation for setup and troubleshooting.

## File Structure

```
program-impact-dashboard/
├── app.R                              # ✓ Modified (no more runtime geocoding)
├── precompute_geocoding.R             # ✓ New (run locally)
├── run_geocoding.sh                   # ✓ New (helper script)
├── ct_towns_geocoded.rds              # ⚠️ To be generated (run script locally)
├── GEOCODING_SETUP.md                 # ✓ New (documentation)
├── DEPLOYMENT_FIX_SUMMARY.md          # ✓ This file
├── .Renviron                          # Already exists (gitignored)
└── .Renviron.example                  # Already exists
```

## What You Need to Do

### Step 1: Run the geocoding script locally

From your local machine (not in this environment):

```bash
cd program-impact-dashboard
./run_geocoding.sh
```

Or manually:
```bash
Rscript precompute_geocoding.R
```

This will create `ct_towns_geocoded.rds` (approximately 2-3 KB).

### Step 2: Commit and push the changes

```bash
git add app.R precompute_geocoding.R run_geocoding.sh ct_towns_geocoded.rds GEOCODING_SETUP.md DEPLOYMENT_FIX_SUMMARY.md
git commit -m "Fix deployment timeout: Pre-compute geocoding instead of runtime API calls"
git push
```

### Step 3: Deploy to shinyapps.io

The GitHub Actions workflow will automatically deploy, or you can deploy manually.

## Expected Results

### Before:
- ❌ Deployment timeout after 30-60 seconds
- ❌ Unnecessary API calls on every startup
- ❌ Dependency on external Nominatim API availability

### After:
- ✅ Deployment completes in seconds
- ✅ No API calls during app startup
- ✅ Faster app initialization
- ✅ More reliable (no external dependencies at runtime)

## How the App Will Work

1. **On shinyapps.io:**
   - App loads `ct_towns_geocoded.rds` from disk (instant)
   - No external API calls
   - Fast startup

2. **If RDS file is missing:**
   - App falls back to hardcoded sample data
   - App still works, just with static demo data

3. **To update data:**
   - Re-run `precompute_geocoding.R` locally
   - Commit new `ct_towns_geocoded.rds`
   - Redeploy

## Benefits

1. **No deployment timeouts** - Geocoding happens locally, not during deployment
2. **Faster app startup** - Loading RDS file is instant vs 30-60 seconds of API calls
3. **No rate limiting issues** - Nominatim API is only called during pre-computation
4. **More reliable** - App doesn't depend on external API availability at runtime
5. **Lower costs** - No API calls during app usage

## Dependencies Removed from Runtime

The app no longer needs these packages at runtime:
- ~~`tidycensus`~~ (only needed for pre-computation)
- ~~`tidygeocoder`~~ (only needed for pre-computation)

This also reduces deployment package size and installation time.

## When to Regenerate the RDS File

Re-run the geocoding script when:
- Census data updates (typically annually)
- You want to include different towns
- Geocoding coordinates need updating
- Census API variables change

## Troubleshooting

See `GEOCODING_SETUP.md` for detailed troubleshooting steps.

Common issues:
- **"Census API key not found"** → Check `.Renviron` file exists with valid key
- **"Geocoding failed"** → Nominatim rate limits, wait a few minutes and retry
- **"File not found on shinyapps.io"** → Ensure `ct_towns_geocoded.rds` is committed to git

## Testing Locally

Before deploying, test that the app works with the new RDS file:

```bash
cd program-impact-dashboard
Rscript -e "shiny::runApp('app.R')"
```

The app should:
1. Load successfully without errors
2. Display Connecticut town data in the map
3. Allow you to select service areas
4. Show community statistics

---

**Status:** ✅ Code changes complete. Ready for local geocoding generation and deployment.
