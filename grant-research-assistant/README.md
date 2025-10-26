# Grant Research Assistant

A free tool to help nonprofits discover foundations in New England that fund organizations like yours.

## Features

- **Search Foundations**: Browse foundations across CT, MA, ME, NH, RI, VT
- **Filter by Criteria**:
  - State location
  - Asset size (under $1M to over $100M)
  - Foundation name
- **View Key Data**:
  - Total assets
  - Grants paid
  - Filing year
  - Contact information (EIN)
- **Export Results**: Download filtered results as CSV for follow-up

## How It Works

This tool uses data from the [ProPublica Nonprofit Explorer API](https://projects.propublica.org/nonprofits/api), which aggregates IRS Form 990 data for all tax-exempt organizations.

### Data Collection

- **GitHub Action**: Runs weekly to fetch foundation data from ProPublica API
- **Focus**: Private foundations (990-PF filers) in New England states
- **Storage**: Pre-processed data stored as JSON files in this repository
- **No API Key Needed**: Users don't need their own API access

### Privacy

All data displayed is public information from IRS filings. No user data is collected or stored.

## Development

### Local Testing

```r
# Install required packages
install.packages(c("shiny", "jsonlite", "dplyr", "DT", "plotly"))

# Run the app
shiny::runApp("app.R")
```

### Updating Foundation Data

The data automatically updates weekly via GitHub Actions. To manually trigger an update:

1. Go to Actions tab in GitHub
2. Select "Fetch Foundation Data" workflow
3. Click "Run workflow"

### Data Fetch Script

The `fetch_foundation_data.R` script:
- Searches for foundations in each New England state
- Retrieves detailed 990-PF data
- Extracts grants paid, assets, and contact info
- Saves processed data to `data/foundations.json`

## Future Enhancements

- **Grant Recipients**: Show which organizations received grants from each foundation
- **Geographic Mapping**: Visual map of foundation locations
- **Mission Matching**: NLP-based matching of foundation priorities to your mission
- **Multi-year Trends**: Track foundation giving patterns over time
- **Expanded Coverage**: Add more states beyond New England

## Contributing

This tool is open source! Contributions welcome:

- Add features (see Future Enhancements above)
- Improve data processing
- Enhance UI/UX
- Report bugs or suggest improvements

## License

MIT License - Free for all nonprofit use

## Credits

Built by [Daly Analytics](https://www.dalyanalytics.com) as part of the [Nonprofit Analytics Tools](https://github.com/dalyanalytics/nonprofit-analytics-tools) suite.

Data provided by [ProPublica Nonprofit Explorer](https://projects.propublica.org/nonprofits/).
