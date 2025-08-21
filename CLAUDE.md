# CLAUDE.md - AI Assistant Guide for Nonprofit Analytics Tools

## Project Mission
This project provides free, open-source analytics tools specifically designed for nonprofits to replace expensive software subscriptions with purpose-built, accessible solutions. Our goal is to democratize data analytics for resource-constrained organizations doing important work.

## Project Structure
```
nonprofit-analytics-tools/
├── index.html                        # Main landing page with tool showcase
├── donor-retention-calculator/       # Live tool for donor analysis
│   ├── app.R                         # Shiny application
│   └── shinylive/                    # Deployment files
├── grant-deadline-tracker/           # Planned tool (coming soon)
└── fundraising-goal-planner/         # Planned tool (coming soon)
```

## Technical Architecture

### Core Stack
- **Framework**: R/Shiny for interactive web applications
- **Deployment**: Shinylive (serverless R/Shiny in browser via WebAssembly)
- **Hosting**: GitHub Pages (free, reliable, no server costs)
- **Visualizations**: Plotly (interactive charts)
- **Data Tables**: DT package (sortable, filterable tables)
- **CI/CD**: GitHub Actions for automated deployment

### Key Features
- **No Server Required**: All tools run entirely in the browser
- **Zero Cost**: Free hosting, no infrastructure expenses
- **Data Privacy**: User data never leaves their browser
- **Mobile Responsive**: Works on all devices

## Development Guidelines

### Creating New Tools
1. **Directory Structure**: Create a new subdirectory for each tool
2. **Shiny App**: Build the tool as a standard R/Shiny application
3. **Shinylive Conversion**: Use shinylive package to convert for browser deployment
4. **Landing Page**: Add tool card to index.html with consistent styling

### Design Standards
- **Color Palette**: 
  - Primary gradient: `#F9B397`, `#D68A93`, `#AD92B1`, `#B07891`
  - Background: White with subtle transparency effects
  - Text: Dark gray (`#333`) for readability
- **UI Components**:
  - Card-based layouts with hover effects
  - Clear status indicators (Live/Coming Soon)
  - Actionable buttons with gradient backgrounds
  - Icon usage for visual hierarchy

### Tool Requirements
- **Dual Data Support**: Include sample datasets AND user upload capability
- **Insights Focus**: Provide interpretations, not just visualizations
- **Benchmarking**: Include industry standards where applicable
- **Export Options**: Allow users to download results/reports
- **Help Documentation**: In-app guidance for non-technical users

## Testing & Development

### Local Development
```bash
# Install required R packages
R -e "install.packages(c('shiny', 'shinylive', 'plotly', 'DT', 'tidyverse'))"

# Test Shiny app locally
cd donor-retention-calculator/
R -e "shiny::runApp('app.R')"

# Convert to Shinylive
R -e "shinylive::export('donor-retention-calculator', 'donor-retention-calculator/shinylive')"
```

### Deployment Verification
```bash
# Build and test locally
python -m http.server 8000
# Navigate to http://localhost:8000

# Check GitHub Actions workflow
git push origin main
# Monitor: Actions tab in GitHub repository
```

### Package Management
```r
# Check package versions
packageVersion("shiny")
packageVersion("shinylive")

# Update packages
update.packages(ask = FALSE)

# Install specific versions if needed
devtools::install_version("shiny", version = "1.7.4")
```

## Nonprofit-Specific Context

### Key Metrics to Consider
- **Donor Metrics**: Retention rate, lifetime value, acquisition cost, churn prediction
- **Grant Metrics**: Success rate, time-to-decision, funder diversity, pipeline value
- **Fundraising Metrics**: Campaign ROI, channel performance, goal attainment, donor pyramids
- **Program Metrics**: Cost per outcome, beneficiary reach, impact measurements

### Common Pain Points to Address
1. **Data Silos**: Help consolidate insights from multiple systems
2. **Manual Processes**: Automate repetitive analysis tasks
3. **Limited Budgets**: Provide enterprise-level insights at zero cost
4. **Staff Capacity**: Make tools intuitive for non-technical users
5. **Board Reporting**: Generate presentation-ready visualizations

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

### Experimental Ideas
- **AI Grant Writer Assistant**: Template generation, funder matching
- **Donation Predictor**: ML-based likelihood scoring
- **Social Impact Calculator**: SROI measurements, theory of change mapping

## Deployment Workflow

The project uses GitHub Actions for continuous deployment:

1. **Trigger**: Push to main branch or manual workflow dispatch
2. **Build Process**: 
   - Set up R environment
   - Install dependencies
   - Convert Shiny apps to Shinylive format
3. **Deploy**: Push to gh-pages branch
4. **Access**: Tools available at `https://[username].github.io/nonprofit-analytics-tools/`

## Contributing Guidelines

### For New Tools
1. Create feature branch: `git checkout -b tool/[tool-name]`
2. Develop in isolated subdirectory
3. Include README with tool-specific documentation
4. Add comprehensive sample data
5. Update index.html with tool card
6. Submit PR with screenshots

### For Improvements
- Focus on user experience over features
- Maintain backward compatibility
- Add tests for critical functions
- Document any new dependencies

## Resources & References

### Nonprofit Data Standards
- **Donor Retention**: AFP Fundraising Effectiveness Project benchmarks
- **Grant Success**: Foundation Center statistics
- **Program Evaluation**: Logic Model frameworks

### Technical Documentation
- [Shiny Documentation](https://shiny.rstudio.com/)
- [Shinylive GitHub](https://github.com/posit-dev/shinylive)
- [Plotly R Documentation](https://plotly.com/r/)
- [GitHub Pages Setup](https://pages.github.com/)

## Support & Contact

**Project Maintainer**: Daly Analytics
- **Website**: https://www.dalyanalytics.com
- **Email**: jasmine@dalyanalytics.com
- **GitHub Issues**: Report bugs or request features

## License
MIT License - Free for all nonprofit use

---

*This document helps AI assistants understand the project context, technical requirements, and nonprofit sector needs to contribute effectively to the tool suite.*