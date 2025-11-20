#!/bin/bash
# Helper script to generate pre-computed geocoding data

set -e  # Exit on error

echo "========================================="
echo "Geocoding Data Pre-computation Script"
echo "========================================="
echo ""

# Check if .Renviron exists
if [ ! -f ".Renviron" ]; then
    echo "ERROR: .Renviron file not found!"
    echo ""
    echo "Please create a .Renviron file with your Census API key:"
    echo "  CENSUS_API_KEY=your_key_here"
    echo ""
    echo "You can copy .Renviron.example as a template:"
    echo "  cp .Renviron.example .Renviron"
    echo ""
    exit 1
fi

# Check if Census API key is set
if ! grep -q "CENSUS_API_KEY=" .Renviron; then
    echo "ERROR: CENSUS_API_KEY not found in .Renviron file!"
    echo ""
    echo "Please add your Census API key to .Renviron:"
    echo "  CENSUS_API_KEY=your_key_here"
    echo ""
    exit 1
fi

echo "✓ Found .Renviron with Census API key"
echo ""

# Check if R is installed
if ! command -v Rscript &> /dev/null; then
    echo "ERROR: Rscript not found!"
    echo "Please install R: https://www.r-project.org/"
    exit 1
fi

echo "✓ Found Rscript"
echo ""

# Run the geocoding script
echo "Running geocoding script..."
echo "This will take 30-60 seconds due to API rate limits..."
echo ""

Rscript precompute_geocoding.R

# Check if RDS file was created
if [ ! -f "ct_towns_geocoded.rds" ]; then
    echo ""
    echo "ERROR: ct_towns_geocoded.rds was not created!"
    exit 1
fi

echo ""
echo "========================================="
echo "✓ Success!"
echo "========================================="
echo ""
echo "Generated file: ct_towns_geocoded.rds"
echo "File size: $(du -h ct_towns_geocoded.rds | cut -f1)"
echo ""
echo "Next steps:"
echo "1. Test the app locally: Rscript -e \"shiny::runApp('app.R')\""
echo "2. Commit the file: git add ct_towns_geocoded.rds"
echo "3. Deploy to shinyapps.io"
echo ""
