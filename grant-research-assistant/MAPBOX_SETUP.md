# Mapbox Setup Instructions

The Grant Research Assistant uses Mapbox GL for interactive mapping. You'll need a free Mapbox access token.

## Get Your Mapbox Token

1. Go to https://account.mapbox.com/
2. Sign up for a free account (if you don't have one)
3. Navigate to "Access tokens"
4. Copy your default public token (starts with `pk.`)

## Set Up Token for Local Development

### Option 1: Environment Variable (Recommended)
Add to your `.Renviron` file:

```bash
MAPBOX_PUBLIC_TOKEN=your_token_here
```

Then restart R.

### Option 2: In the App
Alternatively, you can set it directly in your R session before running the app:

```r
Sys.setenv(MAPBOX_PUBLIC_TOKEN = "your_token_here")
shiny::runApp("grant-research-assistant/app.R")
```

## Set Up Token for Deployment (shinyapps.io)

When deploying to shinyapps.io, you'll need to set the environment variable there:

1. After deploying, go to https://www.shinyapps.io/admin/#/applications
2. Click on your app → Settings → Vars
3. Add: `MAPBOX_PUBLIC_TOKEN` = `your_token_here`
4. Redeploy your app

## Mapbox Free Tier

The free tier includes:
- 50,000 map loads per month
- Unlimited styles
- All Mapbox GL JS features

This is more than enough for a nonprofit tool!

## Testing

Once configured, run the app and click the "Map View" tab. You should see an interactive map of New England with foundation locations.
