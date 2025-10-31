# Grant Research Assistant
# Free tool to help nonprofits find foundations in New England

library(shiny)
library(jsonlite)
library(dplyr)
library(DT)
library(plotly)
library(leaflet)
# library(mapgl)  # Removed to avoid terra/sf dependency on shinyapps.io
# library(sf)  # Removed to avoid terra dependency on shinyapps.io

# Using Leaflet for mapping (no API tokens required)

# Load foundation data
load_foundation_data <- function() {
  data_file <- "data/foundations.json"

  if (file.exists(data_file)) {
    foundations <- fromJSON(data_file)
    return(foundations)
  } else {
    # Return sample data if file doesn't exist (for testing)
    return(data.frame(
      foundation_name = c(
        "Sample Family Foundation",
        "Community Foundation of New England",
        "Green Earth Foundation"
      ),
      foundation_ein = c("123456789", "987654321", "456789123"),
      foundation_city = c("Boston", "Hartford", "Portland"),
      foundation_state = c("MA", "CT", "ME"),
      total_assets = c(5000000, 12000000, 3500000),
      total_contributions = c(250000, 600000, 175000),
      filing_year = c(2023, 2023, 2023),
      grants_paid = c(240000, 580000, 165000)
    ))
  }
}

foundations_data <- load_foundation_data()

# Load metadata
load_metadata <- function() {
  meta_file <- "data/metadata.json"

  if (file.exists(meta_file)) {
    return(fromJSON(meta_file))
  } else {
    return(list(
      last_updated = format(Sys.Date(), "%B %Y"),
      states_included = c("CT", "MA", "ME", "NH", "RI", "VT"),
      total_foundations = nrow(foundations_data),
      data_source = "ProPublica Nonprofit Explorer API (Sample Data)"
    ))
  }
}

metadata <- load_metadata()

# UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap');

      body {
        font-family: 'Inter', sans-serif;
        background: linear-gradient(135deg, #F9B397 0%, #D68A93 25%, #AD92B1 75%, #B07891 100%);
        min-height: 100vh;
        padding: 20px;
      }

      .main-container {
        background: white;
        border-radius: 16px;
        padding: 40px;
        max-width: 1400px;
        margin: 0 auto;
        box-shadow: 0 20px 60px rgba(0,0,0,0.15);
      }

      h1 {
        color: #333;
        font-weight: 700;
        font-size: 2.5em;
        margin-bottom: 10px;
      }

      .subtitle {
        color: #666;
        font-size: 1.1em;
        margin-bottom: 30px;
        font-weight: 300;
      }


      .info-box {
        background: linear-gradient(135deg, rgba(249, 179, 151, 0.1), rgba(214, 138, 147, 0.1));
        border-left: 4px solid #D68A93;
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 25px;
      }

      .filter-section {
        background: #f8f9fa;
        padding: 20px;
        border-radius: 12px;
        margin-bottom: 25px;
      }

      .stat-card {
        background: linear-gradient(135deg, #F9B397, #D68A93);
        color: white;
        padding: 20px;
        border-radius: 12px;
        text-align: center;
        margin-bottom: 15px;
      }

      .stat-card h3 {
        margin: 0;
        font-size: 2em;
        font-weight: 700;
      }

      .stat-card p {
        margin: 5px 0 0 0;
        font-size: 0.9em;
        opacity: 0.9;
      }

      .btn-primary {
        background: linear-gradient(135deg, #D68A93, #AD92B1);
        border: none;
        border-radius: 8px;
        padding: 10px 25px;
        font-weight: 600;
        transition: transform 0.2s;
      }

      .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 5px 15px rgba(0,0,0,0.2);
      }

      .dataTables_wrapper {
        margin-top: 20px;
      }

      .selectize-input {
        border-radius: 8px;
        border: 2px solid #e0e0e0;
      }

      /* Footer styling */
      .app-footer {
        background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
        color: white;
        padding: 3rem 2rem;
        margin-top: 4rem;
        border-radius: 16px;
      }

      .app-footer a {
        color: #d68a93;
        text-decoration: none;
      }

      .app-footer a:hover {
        color: #F9B397;
        text-decoration: underline;
      }

      /* CTA Button styling */
      .app-footer .btn {
        text-decoration: none !important;
        transition: all 0.3s ease;
        cursor: pointer;
      }

      .app-footer .btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        text-decoration: none !important;
      }

      /* Tab styling - brand colors */
      .nav-pills > li > a {
        background: #f8f9fa;
        color: #666;
        border-radius: 8px;
        margin-right: 5px;
        font-weight: 600;
      }

      .nav-pills > li.active > a,
      .nav-pills > li.active > a:hover,
      .nav-pills > li.active > a:focus {
        background: #D68A93;
        color: white;
      }

      .nav-pills > li > a:hover {
        background: #B07891;
        color: white;
      }

      .summary-stats {
        background: #f8f9fa;
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 15px;
        border-left: 4px solid #D68A93;
      }

      .summary-stats h4 {
        margin-top: 0;
        color: #333;
      }

      .stat-inline {
        display: inline-block;
        margin-right: 25px;
        margin-bottom: 10px;
      }

      .stat-inline strong {
        color: #D68A93;
        font-size: 1.2em;
      }

      /* MapLibre/Mapbox popup containment styles */
      .mapboxgl-popup, .maplibregl-popup {
        max-width: 320px !important;
      }

      .mapboxgl-popup-content, .maplibregl-popup-content {
        width: 300px !important;
        max-width: 300px !important;
        padding: 10px !important;
        overflow: hidden !important;
        box-sizing: border-box !important;
        border-radius: 10px;
        box-shadow: 0 8px 24px rgba(0,0,0,.15);
      }

      .mapboxgl-popup-close-button, .maplibregl-popup-close-button {
        top: 6px;
        right: 8px;
      }

      /* Ensure all popup children respect container width */
      .mapboxgl-popup-content *, .maplibregl-popup-content * {
        max-width: 100% !important;
        box-sizing: border-box !important;
      }
    "))
  ),

  div(class = "main-container",
    # Header - full width, centered
    h1(style = "margin-bottom: 5px; text-align: center;", "Grant Research Assistant"),
    div(class = "subtitle", style = "margin-bottom: 15px; text-align: center;",
      "Discover Select New England foundations that fund organizations like yours"
    ),
    div(class = "info-box", style = "margin-bottom: 15px;",
      HTML(paste0(
        "<strong>About this tool:</strong> Search ", nrow(foundations_data),
        " foundations across ", paste(metadata$states_included, collapse = ", "),
        ". Data from ", metadata$data_source, ".",
        "<br><strong>Last Updated:</strong> ", format(as.POSIXct(metadata$last_updated), "%B %d, %Y")
      ))
    ),

    # Compact filter bar
    div(style = "background: #f8f9fa; border-radius: 8px; padding: 12px 15px; border: 1px solid #e0e0e0; margin-bottom: 15px;",
      fluidRow(
        column(2,
          textInput(
            "search_name",
            "Foundation Name:",
            placeholder = "Search...",
            width = "100%"
          )
        ),
        column(2,
          selectInput(
            "filter_state",
            "State:",
            choices = c("All States" = "all", sort(unique(foundations_data$foundation_state))),
            width = "100%"
          )
        ),
        column(2,
          selectInput(
            "filter_assets",
            "Asset Size:",
            choices = c(
              "All Sizes" = "all",
              "Under $1M" = "small",
              "$1M - $10M" = "medium",
              "$10M - $100M" = "large",
              "Over $100M" = "xlarge"
            ),
            width = "100%"
          )
        ),
        column(2,
          selectInput(
            "filter_grants",
            "Annual Grants:",
            choices = c(
              "All Amounts" = "all",
              "Under $100K" = "small",
              "$100K - $500K" = "medium",
              "$500K - $2M" = "large",
              "Over $2M" = "xlarge"
            ),
            width = "100%"
          )
        ),
        column(2,
          div(style = "padding-top: 25px;",
            actionButton(
              "search_btn",
              "Apply Filters",
              class = "btn-primary",
              icon = icon("search"),
              style = "width: 100%;"
            )
          )
        ),
        column(2,
          div(style = "padding-top: 25px;",
            actionButton(
              "reset_btn",
              "Reset",
              class = "btn btn-secondary",
              icon = icon("undo"),
              style = "width: 100%;"
            )
          )
        )
      )
    ),

    tabsetPanel(
      id = "results_tabs",
      type = "pills",
      selected = "Map View",  # Make map the default view

      tabPanel(
        "Map View",
        icon = icon("map-marked-alt"),
        value = "Map View",
        br(),

        # Map with overlay legend
        div(style = "position: relative;",
          leafletOutput("foundation_map", height = "700px"),

          # Compact legend overlay (top-left corner)
          div(style = "position: absolute; top: 10px; left: 10px; background: rgba(255, 255, 255, 0.95); border: 2px solid #e0e0e0; padding: 12px 15px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.15); max-width: 280px; font-size: 12px; z-index: 1000;",
            div(style = "font-weight: 600; margin-bottom: 8px; color: #2c3e50; font-size: 13px;", "🗺️ Legend"),

            # Colors
            div(style = "margin-bottom: 8px;",
              div(style = "font-weight: 600; color: #34495e; font-size: 11px; margin-bottom: 4px;", "Payout Rate"),
              div(style = "display: flex; flex-direction: column; gap: 3px;",
                div(HTML("<span style='display: inline-block; width: 12px; height: 12px; background: #27ae60; border-radius: 50%; margin-right: 6px; vertical-align: middle;'></span><span style='color: #27ae60; font-weight: 600;'>≥5%</span> Active")),
                div(HTML("<span style='display: inline-block; width: 12px; height: 12px; background: #f1c40f; border-radius: 50%; margin-right: 6px; vertical-align: middle;'></span><span style='color: #d68a00; font-weight: 600;'>3-5%</span> Moderate")),
                div(HTML("<span style='display: inline-block; width: 12px; height: 12px; background: #e74c3c; border-radius: 50%; margin-right: 6px; vertical-align: middle;'></span><span style='color: #c0392b; font-weight: 600;'><3%</span> Conservative")),
                div(HTML("<span style='display: inline-block; width: 12px; height: 12px; background: #95a5a6; border-radius: 50%; margin-right: 6px; vertical-align: middle;'></span><span style='color: #7f8c8d;'>No data</span>"))
              )
            ),

            # Size
            div(style = "margin-bottom: 6px;",
              div(style = "font-weight: 600; color: #34495e; font-size: 11px; margin-bottom: 4px;", "Circle Size = Assets"),
              div(HTML("<span style='display: inline-block; width: 18px; height: 18px; background: #3498db; border-radius: 50%; margin-right: 6px; vertical-align: middle;'></span>Larger<span style='margin: 0 8px;'>•</span><span style='display: inline-block; width: 10px; height: 10px; background: #3498db; border-radius: 50%; margin-right: 6px; vertical-align: middle;'></span>Smaller"))
            ),

            # Flags
            div(style = "padding-top: 6px; border-top: 1px solid #ecf0f1; font-size: 11px;",
              HTML("<strong style='color: #e74c3c;'>🚩</strong> = Low payout or high overhead")
            )
          )
        )
      ),

      tabPanel(
        "Table View",
        icon = icon("table"),
        value = "Table View",
        br(),

        # Summary statistics box
        div(class = "summary-stats",
          h4("📊 Dataset Summary"),
          div(
            div(class = "stat-inline",
              span("Organizations: "),
              strong(nrow(foundations_data))
            ),
            div(class = "stat-inline",
              span("Total Assets: "),
              strong(scales::dollar(sum(foundations_data$total_assets, na.rm = TRUE) / 1e6, suffix = "M"))
            ),
            div(class = "stat-inline",
              span("Grants Paid: "),
              strong(if("grants_paid" %in% names(foundations_data)) {
                scales::dollar(sum(foundations_data$grants_paid, na.rm = TRUE) / 1e6, suffix = "M")
              } else {
                "N/A"
              })
            ),
            div(class = "stat-inline",
              span("Avg Payout Rate: "),
              strong(if("payout_rate" %in% names(foundations_data)) {
                paste0(round(mean(foundations_data$payout_rate, na.rm = TRUE), 1), "%")
              } else {
                "N/A"
              })
            )
          )
        ),

        p(style = "color: #666;", "Sortable table of all foundations. Click column headers to sort, use the search box to filter."),
        DTOutput("foundation_table")
      ),

      tabPanel(
        "Foundation Metrics Explained",
        icon = icon("info-circle"),
        value = "Metrics Explained",
        br(),

        div(class = "info-box", style = "background: linear-gradient(135deg, rgba(39, 174, 96, 0.1), rgba(46, 204, 113, 0.1)); border-left: 4px solid #27ae60;",
          h3(style = "margin-top: 0;", "📊 Understanding Foundation Metrics"),

          h4("Key Metrics for Grant Research"),
          tags$ul(
            tags$li(HTML("<strong>Payout Rate</strong> (Grants Paid ÷ Total Assets × 100): Measures what percentage of a foundation's assets are distributed as grants each year.")),
            tags$ul(
              tags$li(HTML("<strong>IRS Minimum:</strong> Private foundations must pay out at least <strong>5% annually</strong>")),
              tags$li(HTML("<strong>7-8%+ = Generous:</strong> Foundation prioritizes grantmaking and impact")),
              tags$li(HTML("<strong>5-7% = Moderate:</strong> Meeting requirements with room for more giving")),
              tags$li(HTML("<strong><5% = Conservative:</strong> Below IRS minimum; may indicate limited grantmaking capacity or strategy"))
            ),

            tags$li(style = "margin-top: 15px;", HTML("<strong>Admin Ratio</strong> (Admin Expenses ÷ Grants Paid × 100): Shows how much it costs to run the foundation relative to grants made.")),
            tags$ul(
              tags$li(HTML("<strong>13-18% = Healthy:</strong> Industry-standard overhead for effective operations")),
              tags$li(HTML("<strong>>20% = High overhead:</strong> May indicate inefficiency or limited grantmaking"))
            ),

            tags$li(style = "margin-top: 15px;", HTML("<strong>Red Flags 🚩</strong>: Foundations flagged when payout <5% OR admin ratio >20%")),
            tags$ul(
              tags$li(HTML("These foundations may have less capacity or willingness to fund your work")),
              tags$li(HTML("Not necessarily a deal-breaker, but worth researching their giving history"))
            ),

            tags$li(style = "margin-top: 15px;", HTML("<strong>Form Types</strong>:")),
            tags$ul(
              tags$li(HTML("<strong>Form 990-PF:</strong> Private foundations (family foundations, endowed foundations) - primarily make grants")),
              tags$li(HTML("<strong>Form 990:</strong> Public charities that also make grants (community foundations, corporate giving programs)"))
            )
          ),

          h4("How to Use This Information"),
          tags$ol(
            tags$li(HTML("<strong>Start with the map:</strong> Look for green circles (≥5% payout) with large sizes (more assets)")),
            tags$li(HTML("<strong>Check payout trends:</strong> Foundations paying 7%+ annually often welcome new grantees")),
            tags$li(HTML("<strong>Review admin ratios:</strong> Lower overhead often means more capacity for grant reviews")),
            tags$li(HTML("<strong>Research further:</strong> Click circles for details, then visit foundation websites for guidelines")),
            tags$li(HTML("<strong>Geographic proximity:</strong> Many foundations prefer local/regional nonprofits"))
          ),

          h4("Important Notes"),
          tags$ul(
            tags$li(HTML("Data reflects most recent IRS filings (typically 1-2 years behind current year)")),
            tags$li(HTML("Some foundations may not accept unsolicited proposals - check their websites")),
            tags$li(HTML("Payout rates can vary year-to-year based on market conditions and strategy")),
            tags$li(HTML("Circle size is logarithmic - small differences in size can represent significant asset differences"))
          )
        )
      ),

      tabPanel(
        "How to Research Grants",
        icon = icon("graduation-cap"),
        value = "Research Guide",
        br(),

        div(class = "info-box", style = "background: linear-gradient(135deg, rgba(214, 137, 147, 0.1), rgba(173, 146, 177, 0.1)); border-left: 4px solid #D68A93;",
          h3(style = "margin-top: 0;", "🔍 Finding Foundations That Fund Organizations Like Yours"),

          div(style = "background: #fff3cd; padding: 15px; border-radius: 8px; border-left: 4px solid #ffc107; margin-bottom: 20px;",
            h4(style = "margin-top: 0; color: #856404;", "💡 The Key Question"),
            p(style = "margin: 0; color: #856404; font-size: 1.05em;",
              strong("\"Has this foundation funded organizations similar to mine?\""),
              " This tool helps you identify promising foundations, then research their actual grant recipients to find the best matches."
            )
          ),

          h4("Step 1: Filter to Find Relevant Foundations"),
          p("Use the filters in the upper right to narrow down foundations:"),
          tags$ul(
            tags$li(HTML("<strong>Annual Grantmaking:</strong> Choose a range that matches your typical ask amount<br><em>Example: If you need $25K, filter for foundations giving $100K-$500K annually</em>")),
            tags$li(HTML("<strong>State:</strong> Many foundations prefer local organizations<br><em>Try filtering by your organization's state first</em>")),
            tags$li(HTML("<strong>Asset Size:</strong> Smaller foundations may be more accessible<br><em>Foundations with $1M-$10M often support grassroots organizations</em>")),
            tags$li(HTML("<strong>Payout Rate (map colors):</strong> Green circles (≥5%) indicate active grantmakers"))
          ),

          h4("Step 2: Review Foundation Details"),
          p("Click on map circles or review the table to find foundations that look promising. Look for:"),
          tags$ul(
            tags$li(HTML("<strong>Consistent grantmaking:</strong> Healthy payout rates (5%+) indicate active grant programs")),
            tags$li(HTML("<strong>Reasonable overhead:</strong> Admin ratios <20% suggest more capacity for grants")),
            tags$li(HTML("<strong>Geographic proximity:</strong> Foundations in your city/state often prioritize local work")),
            tags$li(HTML("<strong>Appropriate scale:</strong> Match foundation size to your organization's budget"))
          ),

          h4("Step 3: Research Their Grant Recipients"),
          p(style = "margin-bottom: 10px;", strong("This is where you discover if they fund organizations like yours!")),
          p("Each foundation's 990 or 990-PF tax form includes a complete list of grant recipients. To access this:"),
          tags$ol(
            tags$li(HTML("<strong>Click the foundation name</strong> in the table view to copy their EIN (tax ID number)")),
            tags$li(HTML("<strong>Visit ProPublica Nonprofit Explorer:</strong> <a href='https://projects.propublica.org/nonprofits/' target='_blank'>projects.propublica.org/nonprofits</a>")),
            tags$li(HTML("<strong>Search by the foundation's name or EIN</strong>")),
            tags$li(HTML("<strong>Click on their most recent filing</strong> (look for Form 990-PF for private foundations)")),
            tags$li(HTML("<strong>Find the grants list:</strong> Look for Schedule I or the 'Statement of Program Service Accomplishments' section")),
            tags$li(HTML("<strong>Analyze their recipients:</strong> Do you see organizations similar to yours? Same mission area? Geographic region? Budget size?"))
          ),

          h4("Step 4: Evaluate the Match"),
          p("As you review grant recipients, ask yourself:"),
          tags$ul(
            tags$li(HTML("<strong>Mission alignment:</strong> Do they fund work similar to yours? (education, health, arts, etc.)")),
            tags$li(HTML("<strong>Organizational type:</strong> Do they support grassroots groups, established nonprofits, or both?")),
            tags$li(HTML("<strong>Grant sizes:</strong> What's the typical range? Match your request to their giving pattern")),
            tags$li(HTML("<strong>Geographic focus:</strong> Where are most recipients located?")),
            tags$li(HTML("<strong>Funding types:</strong> General operating support? Program grants? Capital campaigns?"))
          ),

          h4("Step 5: Visit Foundation Websites"),
          p("Once you've identified foundations funding similar work:"),
          tags$ul(
            tags$li(HTML("<strong>Search for their website</strong> (Google the foundation name + 'grants')")),
            tags$li(HTML("<strong>Review application guidelines:</strong> Do they accept unsolicited proposals?")),
            tags$li(HTML("<strong>Check deadlines and cycles:</strong> When can you apply?")),
            tags$li(HTML("<strong>Read funding priorities:</strong> Confirm your work aligns with their current focus areas")),
            tags$li(HTML("<strong>Note any restrictions:</strong> Geographic, population served, project types, etc."))
          ),

          h4("Pro Tips for Grant Research"),
          div(style = "background: #d4edda; padding: 15px; border-radius: 8px; border-left: 4px solid #28a745;",
            tags$ul(style = "margin-bottom: 0;",
              tags$li(HTML("<strong>Look for peer organizations:</strong> If a foundation funded an organization similar to yours, they're likely a good prospect")),
              tags$li(HTML("<strong>Start local:</strong> Community foundations often prioritize local nonprofits and can be more accessible")),
              tags$li(HTML("<strong>Track multi-year support:</strong> Foundations giving to the same organizations repeatedly value long-term partnerships")),
              tags$li(HTML("<strong>Small foundations, big impact:</strong> Don't overlook smaller foundations - they may have less competition and more personal relationships")),
              tags$li(HTML("<strong>Use this tool iteratively:</strong> After researching a few foundations, return and adjust filters based on what you learned")),
              tags$li(HTML("<strong>Build a prospect list:</strong> Export the table data and add your research notes about each foundation's fit"))
            )
          ),

          h4("Resources"),
          tags$ul(
            tags$li(HTML("<strong>ProPublica Nonprofit Explorer:</strong> <a href='https://projects.propublica.org/nonprofits/' target='_blank'>Free access to all IRS nonprofit filings</a>")),
            tags$li(HTML("<strong>Foundation Directory Online:</strong> Candid's paid database with advanced search features")),
            tags$li(HTML("<strong>Your state's grantmakers association:</strong> Many states have local foundations collaboratives with resources")),
            tags$li(HTML("<strong>GuideStar/Candid:</strong> <a href='https://www.guidestar.org/' target='_blank'>Additional nonprofit and foundation data</a>"))
          )
        )
      )
    )
  ),

  # Footer
  div(
    class = "app-footer",
    fluidRow(
      column(7,
        h4("Need More Custom Analytics Tools?", style = "color: white; margin-bottom: 1rem; margin-top: 0;"),
        p(
          style = "color: rgba(255,255,255,0.9); margin-bottom: 1.5rem;",
          "This grant research assistant demonstrates the power of custom-built nonprofit analytics solutions. ",
          "Daly Analytics specializes in creating tailored tools that solve your organization's unique challenges."
        ),
        tags$div(
          style = "color: rgba(255,255,255,0.85);",
          tags$div(style = "margin-bottom: 8px;", HTML("✓ Custom grant research tools integrated with your CRM")),
          tags$div(style = "margin-bottom: 8px;", HTML("✓ Automated prospect scoring with AI/ML predictions")),
          tags$div(style = "margin-bottom: 8px;", HTML("✓ Board meeting dashboards with funding insights")),
          tags$div(style = "margin-bottom: 8px;", HTML("✓ Multi-region expansion of this tool (nationwide coverage)"))
        )
      ),
      column(5,
        div(
          style = "border: 2px solid rgba(255,255,255,0.3); border-radius: 12px; padding: 24px; background: rgba(255,255,255,0.05);",
          h5("Ready to Get Started?", style = "color: white; margin-bottom: 1.5rem; margin-top: 0;"),
          tags$a(
            "Schedule Free Consultation →",
            href = "https://www.dalyanalytics.com/contact",
            class = "btn btn-lg",
            style = "background: linear-gradient(-45deg, #F9B397, #D68A93, #AD92B1, #B07891); color: #2c3e50; font-weight: 600; width: 100%; padding: 12px; margin-bottom: 15px; text-decoration: none; border-radius: 8px;",
            target = "_blank"
          ),
          tags$a(
            "View Our Portfolio →",
            href = "https://www.dalyanalytics.com",
            class = "btn btn-outline-light",
            style = "width: 100%; padding: 12px; border: 2px solid white; text-decoration: none; border-radius: 8px;",
            target = "_blank"
          ),
          div(
            style = "color: rgba(255,255,255,0.8); font-size: 0.95rem; margin-top: 1.5rem;",
            icon("envelope"), " hello@dalyanalytics.com"
          )
        )
      )
    ),
    tags$hr(style = "border-color: rgba(255,255,255,0.2); margin: 2.5rem 0 1.5rem 0;"),
    div(
      class = "text-center",
      style = "color: rgba(255,255,255,0.6); font-size: 0.9rem;",
      p(
        class = "mb-0",
        "© 2025 Daly Analytics LLC. This free tool was built to demonstrate our expertise in nonprofit analytics. ",
        tags$a(
          "Contact us",
          href = "https://www.dalyanalytics.com/contact",
          style = "color: #F9B397;",
          target = "_blank"
        ),
        " to build custom solutions for your organization."
      )
    )
  )
)

# Server
server <- function(input, output, session) {

  # Create a reactive value to track when to update
  trigger_update <- reactiveVal(0)

  # Reset button observer
  observeEvent(input$reset_btn, {
    updateTextInput(session, "search_name", value = "")
    updateSelectInput(session, "filter_state", selected = "all")
    updateSelectInput(session, "filter_assets", selected = "all")
    updateSelectInput(session, "filter_grants", selected = "all")
    # Trigger update
    trigger_update(trigger_update() + 1)
  })

  # Search button observer
  observeEvent(input$search_btn, {
    trigger_update(trigger_update() + 1)
  })

  # Reactive filtered data (shows all initially, updates on search or reset)
  filtered_foundations <- reactive({
    # Depend on trigger to update
    trigger_update()
    data <- foundations_data

    # Filter by name
    if (!is.null(input$search_name) && input$search_name != "") {
      data <- data %>%
        filter(grepl(input$search_name, foundation_name, ignore.case = TRUE))
    }

    # Filter by state
    if (input$filter_state != "all") {
      data <- data %>%
        filter(foundation_state == input$filter_state)
    }

    # Filter by asset size
    if (input$filter_assets != "all") {
      data <- data %>%
        filter(
          case_when(
            input$filter_assets == "small" ~ total_assets < 1e6,
            input$filter_assets == "medium" ~ total_assets >= 1e6 & total_assets < 10e6,
            input$filter_assets == "large" ~ total_assets >= 10e6 & total_assets < 100e6,
            input$filter_assets == "xlarge" ~ total_assets >= 100e6,
            TRUE ~ TRUE
          )
        )
    }

    # Filter by grant amount
    if (input$filter_grants != "all") {
      data <- data %>%
        filter(
          case_when(
            input$filter_grants == "small" ~ grants_paid < 100000,
            input$filter_grants == "medium" ~ grants_paid >= 100000 & grants_paid < 500000,
            input$filter_grants == "large" ~ grants_paid >= 500000 & grants_paid < 2000000,
            input$filter_grants == "xlarge" ~ grants_paid >= 2000000,
            TRUE ~ TRUE
          )
        )
    }

    return(data)
  })

  # Render data table with enhanced styling
  output$foundation_table <- renderDT({
    data <- filtered_foundations()

    # Format the data for display
    data <- data %>%
      mutate(
        # Format form type as readable text
        form_display = case_when(
          form_type == 0 ~ "990",
          form_type == 2 ~ "990-PF",
          TRUE ~ as.character(form_type)
        ),
        # Add red flag indicator
        flag_display = if_else(has_red_flags, "🚩", "")
      )

    # Select and rename columns for table
    table_data <- data %>%
      select(
        `Foundation Name` = foundation_name,
        City = foundation_city,
        State = foundation_state,
        Form = form_display,
        Year = filing_year,
        `Total Assets` = total_assets,
        `Grants Paid` = grants_paid,
        `Payout Rate` = payout_rate,
        `Admin Ratio` = admin_ratio,
        ` ` = flag_display,
        EIN = foundation_ein
      ) %>%
      mutate(
        # Convert percentages to decimals for formatPercentage (5.0 -> 0.05)
        `Payout Rate` = `Payout Rate` / 100,
        `Admin Ratio` = `Admin Ratio` / 100,
        # Add ProPublica link
        `Research` = sprintf(
          '<a href="https://projects.propublica.org/nonprofits/organizations/%s" target="_blank" style="color: #D68A93; text-decoration: none; font-weight: 600;">View Recipients →</a>',
          EIN
        )
      ) %>%
      select(-EIN)  # Remove EIN column since we have it in the link

    # Create datatable with enhanced styling
    datatable(
      table_data,
      options = list(
        pageLength = 25,
        order = list(list(5, 'desc')),  # Sort by Total Assets
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        scrollX = TRUE,
        columnDefs = list(
          list(className = 'dt-left', targets = c(0, 1, 2, 3)),
          list(className = 'dt-center', targets = c(4, 9, 10)),  # Year, flag, Research link
          list(className = 'dt-right', targets = c(5, 6, 7, 8))  # Assets, Grants, Payout, Admin
        )
      ),
      rownames = FALSE,
      class = 'display stripe hover',
      escape = FALSE
    ) %>%
      # Format currency columns
      formatCurrency(c('Total Assets', 'Grants Paid'), '$', digits = 0) %>%
      # Format percentage columns
      formatPercentage(c('Payout Rate', 'Admin Ratio'), digits = 1) %>%
      # Color code payout rate (Green ≥5%, Yellow 3-5%, Red <3%)
      # Note: thresholds are in decimal form (0.03 = 3%, 0.05 = 5%)
      formatStyle(
        'Payout Rate',
        backgroundColor = styleInterval(
          c(0.03, 0.05),
          c('#fadbd8', '#fef9e7', '#d5f4e6')
        ),
        fontWeight = 'bold',
        color = '#333'
      ) %>%
      # Highlight high admin ratios (>20%)
      # Note: threshold is in decimal form (0.20 = 20%)
      formatStyle(
        'Admin Ratio',
        backgroundColor = styleInterval(
          c(0.20),
          c('white', '#fadbd8')
        ),
        color = '#333'
      )
  })

  # Render map
  output$foundation_map <- renderLeaflet({
    data <- filtered_foundations()

    # Filter to only rows with valid coordinates
    map_data <- data %>%
      filter(!is.na(latitude) & !is.na(longitude))

    if (nrow(map_data) == 0) {
      # Return empty map if no geocoded data
      return(
        leaflet() %>%
          addTiles() %>%
          setView(lng = -71.5, lat = 43.5, zoom = 6)  # Center on New England
      )
    }

    # Assign colors based on payout rate
    map_data <- map_data %>%
      mutate(
        color = case_when(
          is.na(payout_rate) ~ "#95a5a6",              # Gray - no data
          payout_rate >= 5 ~ "#27ae60",                # Green - meeting IRS minimum
          payout_rate >= 3 ~ "#f1c40f",                # Yellow - moderate
          payout_rate > 0 ~ "#e74c3c",                 # Red - conservative/low
          TRUE ~ "#95a5a6"                             # Gray - no grants
        ),
        # Size circles by assets (log scale)
        circle_size = pmin(20, pmax(5, log10(total_assets + 1) * 2))
      )

    # Build popup HTML separately to avoid scoping issues
    map_data$popup_html <- sapply(1:nrow(map_data), function(i) {
      row <- map_data[i, ]

      # Base info
      # Format form type display
      form_type_display <- if (!is.na(row$form_type)) {
        if (row$form_type == 0) "Form 990" else if (row$form_type == 2) "Form 990-PF" else paste0("Form Type ", row$form_type)
      } else {
        ""
      }

      html <- paste0(
        '<div style="font-family: Inter, sans-serif;">',
        '<h4 style="margin: 0 0 5px 0; color: #2c3e50; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">', row$foundation_name, '</h4>',
        '<p style="margin: 0 0 10px 0; color: #7f8c8d; font-size: 12px;">',
        row$foundation_city, ", ", row$foundation_state, " • ", row$filing_year,
        if (form_type_display != "") paste0(" • ", form_type_display) else "",
        '</p>'
      )

      # Red flag alert
      if ("has_red_flags" %in% names(row) && !is.na(row$has_red_flags) && row$has_red_flags) {
        html <- paste0(html,
          '<div style="background: #fee; border-left: 3px solid #e74c3c; padding: 8px; margin-bottom: 10px; font-size: 12px;">',
          '<strong style="color: #c0392b;">🚩 Red Flag:</strong> ',
          ifelse(!is.na(row$red_flags) && row$red_flags != "", row$red_flags, "See details"),
          '</div>'
        )
      }

      # Simple div layout - labels and values on left, contained width
      # Assets
      html <- paste0(html,
        '<div style="padding: 6px 0; border-bottom: 1px solid #ecf0f1; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">',
        '<span style="color: #7f8c8d;">Total Assets: </span>',
        '<strong>', scales::dollar(row$total_assets, accuracy = 1), '</strong>',
        '</div>'
      )

      # Grants Paid
      if ("grants_paid" %in% names(row) && !is.na(row$grants_paid)) {
        html <- paste0(html,
          '<div style="padding: 6px 0; border-bottom: 1px solid #ecf0f1; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">',
          '<span style="color: #7f8c8d;">Grants Paid: </span>',
          '<strong>', scales::dollar(row$grants_paid, accuracy = 1), '</strong>',
          '</div>'
        )
      }

      # Payout Rate - colors match map circles
      if ("payout_rate" %in% names(row) && !is.na(row$payout_rate)) {
        # Background colors that match circle colors (lighter versions)
        if (row$payout_rate >= 5) {
          bg_color <- "#d5f4e6"  # Light green
          icon <- "✓"
        } else if (row$payout_rate >= 3) {
          bg_color <- "#fef9e7"  # Light yellow
          icon <- "→"
        } else {
          bg_color <- "#fadbd8"  # Light red
          icon <- "⚠"
        }

        html <- paste0(html,
          '<div style="padding: 6px 0; border-bottom: 1px solid #ecf0f1; background: ', bg_color, '; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">',
          '<span style="color: #7f8c8d;">Payout Rate: </span>',
          '<strong>', row$payout_rate, '%</strong> ', icon,
          '</div>'
        )
      }

      # Admin Ratio
      if ("admin_ratio" %in% names(row) && !is.na(row$admin_ratio)) {
        html <- paste0(html,
          '<div style="padding: 6px 0; border-bottom: 1px solid #ecf0f1; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">',
          '<span style="color: #7f8c8d;">Admin Ratio: </span>',
          '<strong>', round(row$admin_ratio, 1), '%</strong>',
          '</div>'
        )
      }

      # Add ProPublica link
      propublica_url <- sprintf("https://projects.propublica.org/nonprofits/organizations/%s", row$foundation_ein)
      html <- paste0(html,
        '<div style="margin-top: 12px; padding-top: 10px; border-top: 1px solid #ecf0f1;">',
        '<a href="', propublica_url, '" target="_blank" style="color: #D68A93; text-decoration: none; font-size: 13px; font-weight: 600; display: block;">',
        'View on ProPublica →',
        '</a>',
        '</div>',
        '</div>'
      )

      return(html)
    })

    # Create Leaflet map
    leaflet(map_data) %>%
      addTiles() %>%
      setView(
        lng = mean(map_data$longitude, na.rm = TRUE),
        lat = mean(map_data$latitude, na.rm = TRUE),
        zoom = 6
      ) %>%
      addCircleMarkers(
        lng = ~longitude,
        lat = ~latitude,
        radius = ~circle_size,
        color = "white",
        weight = 2,
        opacity = 1,
        fillColor = ~color,
        fillOpacity = 0.8,
        popup = ~popup_html
      )
  })
}

# Run app
shinyApp(ui = ui, server = server)
