#!/usr/bin/env Rscript
# Pre-compute geocoding for Connecticut towns to avoid shinyapps.io timeout
# Run this script locally to generate ct_towns_geocoded.rds

library(tidycensus)
library(tidygeocoder)
library(dplyr)

# Load Census API key from .Renviron
census_api_key(Sys.getenv("CENSUS_API_KEY"), overwrite = TRUE)

# Fetch Connecticut place (town/city) data from Census Bureau ACS 5-year estimates
cat("Fetching Census data for Connecticut towns...\n")
acs_data <- get_acs(
  geography = "place",
  state = "CT",
  variables = c(
    population = "B01003_001",      # Total population
    median_income = "B19013_001"    # Median household income
  ),
  year = 2022,
  survey = "acs5",
  output = "wide"
) %>%
  # Clean up place names (remove ", Connecticut" suffix)
  mutate(
    town = gsub(" town, Connecticut| city, Connecticut", "", NAME),
    population = populationE,
    median_income = median_incomeE
  ) %>%
  # Keep only the most populous towns for the app
  arrange(desc(population)) %>%
  head(15) %>%
  select(GEOID, town, population, median_income)

cat("Fetched data for", nrow(acs_data), "towns\n")
cat("Towns:", paste(acs_data$town, collapse = ", "), "\n\n")

# Geocode the town addresses to get lat/lng for mapping
cat("Geocoding addresses using OpenStreetMap...\n")
cat("This may take 30-60 seconds due to Nominatim API rate limits...\n\n")

ct_towns_geocoded <- acs_data %>%
  mutate(address = paste0(town, ", Connecticut")) %>%
  geocode(address, method = "osm", lat = lat, long = lng, verbose = TRUE) %>%
  filter(!is.na(lat) & !is.na(lng)) %>%  # Remove rows with failed geocoding
  select(GEOID, town, population, median_income, lat, lng)

cat("\nSuccessfully geocoded", nrow(ct_towns_geocoded), "of", nrow(acs_data), "towns\n")

if (nrow(ct_towns_geocoded) < nrow(acs_data)) {
  failed_towns <- setdiff(acs_data$town, ct_towns_geocoded$town)
  cat("WARNING: Failed to geocode:", paste(failed_towns, collapse = ", "), "\n")
}

# Save to RDS file
output_file <- "ct_towns_geocoded.rds"
saveRDS(ct_towns_geocoded, output_file)
cat("\nSaved geocoded data to:", output_file, "\n")
cat("File size:", file.info(output_file)$size, "bytes\n")

# Display preview
cat("\nPreview of geocoded data:\n")
print(ct_towns_geocoded)

cat("\n✓ Success! You can now deploy the app with this pre-computed data.\n")
