# CLAUDE.md - AI Assistant Guide for Nonprofit Analytics Tools

## Project Mission
This project provides free, open-source analytics tools specifically designed for nonprofits to replace expensive software subscriptions with purpose-built, accessible solutions. Our goal is to democratize data analytics for resource-constrained organizations doing important work.

## Project Structure
```
nonprofit-analytics-tools/
├── index.html                        # Minimal static landing page (NO JavaScript)
├── donor-retention-calculator/       # Live tool for donor analysis
│   └── app.R                         # Shiny application
├── board-packet-generator/           # Live tool for board materials
│   └── app.R                         # Shiny application
├── grant-research-assistant/         # Live tool for foundation research
│   └── app.R                         # Shiny application
└── capital-campaign-forecaster/      # Live tool for campaign planning
    └── app.R                         # Shiny application (with Monte Carlo simulation)
```

## Technical Architecture

### Core Stack
- **Framework**: R/Shiny for interactive web applications
- **Deployment**: Shinyapps.io (cloud hosting, NOT shinylive)
- **Landing Page**: GitHub Pages with minimal static HTML (zero JavaScript)
- **Visualizations**: Plotly (interactive charts)
- **Data Tables**: DT package (sortable, filterable tables)
- **Mapping**: Leaflet (NOT MapLibre due to shinyapps.io compatibility)
- **CI/CD**: GitHub Actions for automated deployment

### Key Features
- **Cloud Hosted**: All tools run on shinyapps.io infrastructure
- **Zero Cost**: Free hosting, no infrastructure expenses for users
- **Data Privacy**: Stateless apps, no data persistence
- **Mobile Responsive**: Works on all devices
- **Public Access**: No Auth0, all tools publicly accessible

### CRITICAL: Landing Page Stability
- **NEVER use shinylive** - causes browser crashes (100+ MB WebAssembly files)
- **Landing page MUST be minimal** - inline CSS, zero JavaScript, no external dependencies
- **GitHub Pages serves ONLY index.html** - no app files, no large assets
- If landing page becomes unstable, revert to ultra-minimal HTML immediately

## Development Guidelines

### Creating New Tools
1. **Directory Structure**: Create a new subdirectory for each tool
2. **Shiny App**: Build the tool as a standard R/Shiny application
3. **Deploy to Shinyapps.io**: Use GitHub Actions workflow, NOT shinylive
4. **Landing Page**: Add tool card to index.html with link to shinyapps.io URL
5. **Update Workflows**: Add app name to deploy-shinyapps.yml options and paths

### Design Standards
- **Color Palette**:
  - Primary gradient: `#F9B397`, `#D68A93`, `#AD92B1`, `#B07891`
  - Background: White with subtle transparency effects
  - Text: Dark gray (`#333`) for readability
- **UI Components**:
  - Card-based layouts with rounded corners
  - Inset footers with 16px border-radius
  - Gradient backgrounds for CTAs
  - Inter font family (via Google Fonts CDN in apps only)
  - Consistent spacing and padding

### Tool Requirements
- **Dual Data Support**: Include sample datasets AND user upload capability
- **Insights Focus**: Provide interpretations, not just visualizations
- **Benchmarking**: Include industry standards where applicable
- **Export Options**: Allow users to download results/reports
- **Help Documentation**: In-app guidance for non-technical users
- **Professional Footer**: Include CTA linking back to dalyanalytics.com/contact

## Testing & Development

### Local Development
```bash
# Install required R packages
R -e "install.packages(c('shiny', 'plotly', 'DT', 'tidyverse', 'leaflet', 'rsconnect'))"

# Test Shiny app locally
cd donor-retention-calculator/
R -e "shiny::runApp('app.R')"
```

### Deployment to Shinyapps.io
```bash
# Manual deployment via GitHub Actions
gh workflow run deploy-shinyapps.yml -f app_name=donor-retention-calculator

# Automatic deployment on push to main (if app files changed)
git add capital-campaign-forecaster/app.R
git commit -m "Update Capital Campaign Forecaster"
git push origin main
```

### Package Management
```r
# Check package versions
packageVersion("shiny")
packageVersion("plotly")
packageVersion("leaflet")

# Update packages
update.packages(ask = FALSE)
```

## Nonprofit-Specific Context

### Key Metrics to Consider
- **Donor Metrics**: Retention rate, lifetime value, acquisition cost, churn prediction
- **Grant Metrics**: Success rate, time-to-decision, funder diversity, pipeline value
- **Fundraising Metrics**: Campaign ROI, channel performance, goal attainment, donor pyramids
- **Program Metrics**: Cost per outcome, beneficiary reach, impact measurements
- **Capital Campaign Metrics**: Multi-year projections, retention vs acquisition ROI, confidence intervals

### Common Pain Points to Address
1. **Data Silos**: Help consolidate insights from multiple systems
2. **Manual Processes**: Automate repetitive analysis tasks
3. **Limited Budgets**: Provide enterprise-level insights at zero cost
4. **Staff Capacity**: Make tools intuitive for non-technical users
5. **Board Reporting**: Generate presentation-ready visualizations
6. **Campaign Planning**: Modernize forecasting with Monte Carlo simulation

## Current Tools (4 Live)

### 1. Donor Retention Calculator
- Multi-year retention tracking
- Cohort analysis
- Industry benchmarks
- Donor segmentation
- URL: https://dalyanalytics.shinyapps.io/donor-retention-calculator/

### 2. Board Packet Generator
- Automated report generation
- Financial summaries and visualizations
- Impact metrics
- Executive dashboards
- URL: https://dalyanalytics.shinyapps.io/board-packet-generator/

### 3. Grant Research Assistant
- Interactive map of 70+ New England foundations
- Filterable by state, asset size, grantmaking
- IRS 990 data integration
- ProPublica links for recipient research
- Uses tidygeocoder for address geocoding
- URL: https://dalyanalytics.shinyapps.io/grant-research-assistant/

### 4. Capital Campaign Forecaster (NEW)
- Monte Carlo simulation with 1,000 scenarios (base R only, no special packages)
- Multi-year capital campaign projections (3-5 years)
- ROI probability analysis with risk classification
- Confidence intervals (10th/50th/90th percentiles)
- 4 scenario tabs: Baseline, Retention Improvement, Acquisition Focus, Combined Strategy
- Animated sliders for what-if analysis
- Strategic recommendations based on simulation outcomes
- URL: https://dalyanalytics.shinyapps.io/capital-campaign-forecaster/

## Future Tool Ideas

### High Priority
- **Volunteer Analytics**: Hours tracking, retention, skill mapping, impact measurement
- **Program Impact Dashboard**: Outcome tracking, beneficiary demographics, cost-effectiveness
- **Event ROI Calculator**: Ticket sales, sponsorships, expenses, multi-year trends
- **Email Campaign Analyzer**: Open rates, conversion, segmentation effectiveness

### Medium Priority
- **Grant Pipeline Manager**: Application stages, probability scoring, deadline management
- **Major Donor Prospecting**: Wealth screening alternatives, engagement scoring
- **Budget vs Actual Tracker**: Variance analysis, forecasting, department breakdowns
- **Peer Benchmarking Tool**: Compare against similar organizations

### Rejected Ideas
- **Event Vendor Tracker**: Airtable Omni handles this natively - no technical differentiator

## Deployment Workflow

### GitHub Actions Workflows

#### 1. deploy-shinyapps.yml
- Deploys Shiny apps to shinyapps.io
- Triggers on: push to main (when app directories change) OR manual workflow_dispatch
- Apps: donor-retention-calculator, board-packet-generator, grant-research-assistant, capital-campaign-forecaster
- Uses secrets: SHINYAPPS_ACCOUNT, SHINYAPPS_TOKEN, SHINYAPPS_SECRET

#### 2. deploy-github-pages.yml
- Deploys ONLY index.html and assets/ to GitHub Pages
- Triggers on: push to main (when index.html or assets/ changes) OR manual workflow_dispatch
- **NEVER deploys app files** - those are on shinyapps.io

#### 3. deploy-tools.yaml.disabled
- **DO NOT USE** - old shinylive deployment that caused browser crashes
- Kept disabled as historical reference

## Contributing Guidelines

### For New Tools
1. Create feature branch: `git checkout -b tool/[tool-name]`
2. Develop in isolated subdirectory
3. Include README with tool-specific documentation
4. Add comprehensive sample data
5. Update index.html with tool card
6. Update deploy-shinyapps.yml with new app name
7. Submit PR with screenshots

### For Improvements
- Focus on user experience over features
- Maintain backward compatibility
- Add tests for critical functions
- Document any new dependencies
- Update CLAUDE.md if architecture changes

## Naming Conventions & Positioning

### Prospect Language
When building tools, align naming with nonprofit sector language:
- ✅ "Capital Campaign Forecaster" (industry standard term)
- ❌ "Donor Retention Forecaster" (too narrow)
- ✅ "Campaign planning" and "stewardship" (how prospects talk)
- ❌ "Donor churn prediction" (too technical)

### Positioning Strategy
- Emphasize **modernizing existing processes** (campaign planning, board reporting)
- Highlight **Monte Carlo simulation** as differentiator from static spreadsheets
- Focus on **multi-year strategic planning** not just tactical metrics
- Position for **major nonprofits** (capital campaigns = larger organizations)

## Resources & References

### Nonprofit Data Standards
- **Donor Retention**: AFP Fundraising Effectiveness Project benchmarks
- **Grant Success**: Foundation Center statistics
- **Program Evaluation**: Logic Model frameworks
- **Capital Campaigns**: Industry standards for feasibility studies

### Technical Documentation
- [Shiny Documentation](https://shiny.rstudio.com/)
- [Shinyapps.io Documentation](https://docs.posit.co/shinyapps.io/)
- [Plotly R Documentation](https://plotly.com/r/)
- [Leaflet for R](https://rstudio.github.io/leaflet/)
- [GitHub Pages Setup](https://pages.github.com/)

## Support & Contact

**Project Maintainer**: Daly Analytics
- **Website**: https://www.dalyanalytics.com
- **Email**: hello@dalyanalytics.com (updated from jasmine@)
- **GitHub Issues**: Report bugs or request features

## License
MIT License - Free for all nonprofit use

## Recent Updates (Oct 31, 2024)

### Landing Page Crisis & Resolution
- **Issue**: GitHub Pages landing page was crashing Chrome browsers when scrolling to tools section
- **Root Cause**: Old shinylive WebAssembly files (100+ MB) still cached by GitHub Pages CDN
- **Solution**: Complete rewrite to ultra-minimal HTML
  - Zero JavaScript
  - Inline CSS only (no external stylesheets)
  - System fonts only (no CDN dependencies)
  - Aggressive cache-busting headers
  - ~650 lines reduced to ~190 lines
- **Result**: Stable, crash-proof landing page

### Tool Rename
- Renamed "Donor Retention Forecaster" → "Capital Campaign Forecaster"
- Reason: Better alignment with prospect language around campaign planning and capital campaigns
- Updates: Directory, app title, README, index.html, GitHub Actions workflow

### Key Learnings
- **NEVER use shinylive for public deployment** - causes catastrophic browser crashes
- **Landing pages must be minimal** - any JavaScript/dependencies create risk
- **GitHub Pages CDN caching is aggressive** - can take hours to propagate changes
- **Use incognito mode for testing** - bypasses local cache
- **Monte Carlo in base R only** - no special packages needed (rnorm, quantile, apply)

---

*This document helps AI assistants understand the project context, technical requirements, nonprofit sector needs, and recent architectural decisions to contribute effectively to the tool suite.*
