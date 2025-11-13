# Program Impact Dashboard

Measure and communicate your program's impact in Connecticut communities with data-driven insights.

## Features

- **Impact Metrics**: Track participants served, completion rates, outcome improvements, and cost efficiency
- **Live Census Data**: Real-time Connecticut demographic data via US Census Bureau ACS 5-year estimates
- **Causal Impact Analysis**: Bayesian structural time-series modeling to estimate the causal effect of your program
- **Interactive Visualizations**: Plotly charts showing outcome improvements and trends over time
- **Community Mapping**: Leaflet map displaying service areas across Connecticut towns
- **Sample Programs**: 5 pre-loaded examples (literacy, workforce training, health, arts, mindfulness)
- **Service-Focused**: Emphasizes program reach and impact, not demographic targeting
- **Statistical Rigor**: Includes counterfactual prediction, 95% credible intervals, and p-values

## Setup Instructions

### Prerequisites

Install required R packages:

```r
install.packages(c(
  "shiny",
  "bslib",
  "plotly",
  "dplyr",
  "tidyr",
  "scales",
  "leaflet",
  "DT",
  "tidycensus",
  "tidygeocoder",
  "CausalImpact",
  "zoo"
))
```

### Census API Key

This app uses the US Census Bureau API to fetch live demographic data for Connecticut towns.

**Get your free API key:**

1. Visit https://api.census.gov/data/key_signup.html
2. Fill out the form with your email
3. Check your email for the API key
4. Set up the key using one of the methods below

#### Local Development

1. Copy `.Renviron.example` to `.Renviron`:
   ```bash
   cp .Renviron.example .Renviron
   ```

2. Edit `.Renviron` and add your Census API key:
   ```
   CENSUS_API_KEY=your_actual_key_here
   ```

3. Restart your R session

#### Shinyapps.io Deployment

1. Log in to shinyapps.io
2. Go to your app settings
3. Navigate to "Vars" tab
4. Add environment variable:
   - Name: `CENSUS_API_KEY`
   - Value: Your Census API key

#### GitHub Actions Deployment

1. Go to repository Settings > Secrets and variables > Actions
2. Add a new repository secret:
   - Name: `CENSUS_API_KEY`
   - Secret: Your Census API key
3. Update `.github/workflows/deploy-shinyapps.yml` to include:
   ```yaml
   env:
     CENSUS_API_KEY: ${{ secrets.CENSUS_API_KEY }}
   ```

### Running Locally

```r
# From the project root
shiny::runApp("program-impact-dashboard")
```

The app will attempt to fetch live Census data. If the API key is missing or invalid, it will automatically fall back to sample data with a warning.

## Data Sources

- **Population & Income**: US Census Bureau American Community Survey (ACS) 5-year estimates (2022)
- **Geocoding**: OpenStreetMap Nominatim (via tidygeocoder)
- **Program Samples**: Representative data for demonstration purposes

## Usage

1. **Load a Sample Program** or enter your own program details
2. **Select Service Towns** from the dropdown to define your geographic reach
3. **Enter Program Metrics**: Budget, participants, completion rate, pre/post scores
4. **Click "Analyze Impact"** to view visualizations and insights
5. Review the **Impact Overview** value boxes showing key metrics
6. Examine the **Causal Impact Analysis** with statistical significance testing
7. Explore the **Community Context** map and demographic data for your service area

## Technical Details

- **Framework**: R Shiny with Bootstrap 5 (bslib)
- **Statistical Method**: Bayesian structural time-series (BSTS) via CausalImpact package
- **Data Fetching**: Performed once at app startup via `tryCatch()` with fallback
- **Caching**: Census data cached for the session duration
- **API Rate Limits**: Census API allows 500 requests/day without authentication, unlimited with key
- **Geocoding**: Uses OpenStreetMap (free, no key required)
- **Causal Inference**: Uses state averages as control group for counterfactual prediction

## Customization for Production

To customize this tool for a specific organization:

- Add organization-specific program types
- Integrate with internal databases for automated data loading
- Expand to additional states beyond Connecticut
- Add export functionality (PDF/HTML reports)
- Implement CausalImpact statistical analysis for before/after comparisons

Contact [Daly Analytics](https://www.dalyanalytics.com/contact) for custom implementations.

## License

MIT License - Free for all nonprofit use
