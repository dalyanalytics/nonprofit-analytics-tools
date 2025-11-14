library(shiny)
library(bslib)
library(plotly)
library(dplyr)
library(tidyr)
library(scales)
library(leaflet)
library(DT)
library(tidycensus)
library(tidygeocoder)
library(CausalImpact)
library(zoo)

# Load Census API key from .Renviron
census_api_key(Sys.getenv("CENSUS_API_KEY"), overwrite = TRUE)

# Fetch Connecticut place (town/city) data from Census Bureau ACS 5-year estimates
# This fetches live data instead of using hardcoded samples
ct_towns_data <- tryCatch({
  # Get ACS data for Connecticut places
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

  # Geocode the town addresses to get lat/lng for mapping
  acs_data %>%
    mutate(address = paste0(town, ", Connecticut")) %>%
    geocode(address, method = "osm", lat = lat, long = lng) %>%
    filter(!is.na(lat) & !is.na(lng)) %>%  # Remove rows with failed geocoding
    select(GEOID, town, population, median_income, lat, lng)

}, error = function(e) {
  # Fallback to sample data if Census API fails (no key, rate limit, etc.)
  warning("Failed to fetch Census data. Using sample data. Error: ", e$message)
  data.frame(
    GEOID = paste0("sample_", 1:15),
    town = c("Hartford", "New Haven", "Bridgeport", "Stamford", "Waterbury",
             "Norwalk", "Danbury", "New Britain", "West Hartford", "Greenwich",
             "Hamden", "Meriden", "Bristol", "Manchester", "West Haven"),
    population = c(121054, 134023, 148654, 135470, 107568,
                   91184, 86518, 73206, 63023, 63341,
                   62707, 60850, 60039, 58241, 55046),
    median_income = c(34658, 44120, 52124, 89269, 45240,
                      82766, 73921, 43240, 96342, 141243,
                      65432, 54321, 58976, 62345, 47890),
    lat = c(41.7658, 41.3083, 41.1792, 41.0534, 41.5582,
            41.1177, 41.3948, 41.6612, 41.7621, 41.0268,
            41.3959, 41.5382, 41.6718, 41.7798, 41.2706),
    lng = c(-72.6734, -72.9279, -73.1894, -73.5387, -73.0515,
            -73.4079, -73.4540, -72.7795, -72.7420, -73.6282,
            -72.8968, -72.8071, -72.9493, -72.5215, -72.9473)
  )
})

# Sample program data with multiple outcome metrics
sample_programs <- list(
  youth_literacy = list(
    name = "After-School Literacy Program",
    type = "Youth Development",
    towns = c("Hartford", "East Hartford"),
    budget = 75000,
    participants = 50,
    completion_rate = 82,
    # Multiple outcome metrics
    outcome_metrics = list(
      "Reading Fluency (Words Per Minute)" = list(
        pre_score = 65,
        post_score = 110,
        time_series_pre = c(62, 63, 65, 64, 66, 67),
        time_series_post = c(85, 92, 98, 105, 110, 115),
        state_avg_pre = c(75, 76, 75, 77, 78, 78),
        state_avg_post = c(80, 81, 82, 83, 84, 85)
      ),
      "Comprehension Test Score (0-100)" = list(
        pre_score = 58,
        post_score = 82,
        time_series_pre = c(55, 56, 58, 57, 59, 60),
        time_series_post = c(70, 74, 78, 80, 82, 85),
        state_avg_pre = c(65, 66, 65, 67, 68, 68),
        state_avg_post = c(70, 71, 72, 73, 74, 75)
      ),
      "Books Read Independently" = list(
        pre_score = 2,
        post_score = 12,
        time_series_pre = c(1, 2, 2, 1, 3, 2),
        time_series_post = c(8, 9, 10, 11, 12, 14),
        state_avg_pre = c(4, 4, 4, 5, 5, 5),
        state_avg_post = c(6, 6, 7, 7, 8, 8)
      ),
      "School Attendance Rate (%)" = list(
        pre_score = 78,
        post_score = 91,
        time_series_pre = c(75, 76, 78, 77, 79, 80),
        time_series_post = c(85, 87, 89, 90, 91, 92),
        state_avg_pre = c(82, 83, 82, 84, 85, 85),
        state_avg_post = c(86, 87, 87, 88, 88, 89)
      )
    ),
    # Default metric
    pre_score = 65,
    post_score = 110,
    score_label = "Reading Fluency (Words Per Minute)",
    time_series_pre = c(62, 63, 65, 64, 66, 67),
    time_series_post = c(85, 92, 98, 105, 110, 115),
    state_avg_pre = c(75, 76, 75, 77, 78, 78),
    state_avg_post = c(80, 81, 82, 83, 84, 85)
  ),
  workforce = list(
    name = "Manufacturing Skills Training",
    type = "Workforce Development",
    towns = c("New Haven", "West Haven"),
    budget = 120000,
    participants = 30,
    completion_rate = 87,
    # Multiple outcome metrics
    outcome_metrics = list(
      "Average Hourly Wage ($)" = list(
        pre_score = 12.50,
        post_score = 22.75,
        time_series_pre = c(12.00, 12.25, 12.50, 12.40, 12.60, 12.75),
        time_series_post = c(18.50, 19.75, 21.00, 22.00, 22.75, 23.50),
        state_avg_pre = c(15.00, 15.25, 15.00, 15.50, 15.75, 15.75),
        state_avg_post = c(16.00, 16.25, 16.50, 16.75, 17.00, 17.25)
      ),
      "Job Placement Within 90 Days (%)" = list(
        pre_score = 35,
        post_score = 85,
        time_series_pre = c(32, 34, 35, 33, 36, 37),
        time_series_post = c(70, 75, 80, 83, 85, 88),
        state_avg_pre = c(45, 46, 45, 47, 48, 48),
        state_avg_post = c(50, 51, 52, 53, 54, 55)
      ),
      "Industry Certifications Earned" = list(
        pre_score = 0,
        post_score = 2.3,
        time_series_pre = c(0, 0, 0, 0, 0.1, 0.1),
        time_series_post = c(1.5, 1.8, 2.0, 2.2, 2.3, 2.5),
        state_avg_pre = c(0.5, 0.5, 0.5, 0.6, 0.6, 0.6),
        state_avg_post = c(0.8, 0.9, 0.9, 1.0, 1.0, 1.1)
      ),
      "6-Month Job Retention Rate (%)" = list(
        pre_score = 45,
        post_score = 88,
        time_series_pre = c(42, 43, 45, 44, 46, 47),
        time_series_post = c(78, 82, 85, 87, 88, 90),
        state_avg_pre = c(60, 61, 60, 62, 63, 63),
        state_avg_post = c(65, 66, 67, 68, 69, 70)
      )
    ),
    # Default metric
    pre_score = 12.50,
    post_score = 22.75,
    score_label = "Average Hourly Wage ($)",
    time_series_pre = c(12.00, 12.25, 12.50, 12.40, 12.60, 12.75),
    time_series_post = c(18.50, 19.75, 21.00, 22.00, 22.75, 23.50),
    state_avg_pre = c(15.00, 15.25, 15.00, 15.50, 15.75, 15.75),
    state_avg_post = c(16.00, 16.25, 16.50, 16.75, 17.00, 17.25)
  ),
  health = list(
    name = "Diabetes Prevention Program",
    type = "Health Services",
    towns = c("Bridgeport", "Stamford"),
    budget = 90000,
    participants = 75,
    completion_rate = 71,
    outcome_metrics = list(
      "Average A1C Level" = list(
        pre_score = 7.2,
        post_score = 6.1,
        time_series_pre = c(7.4, 7.3, 7.2, 7.3, 7.1, 7.2),
        time_series_post = c(6.8, 6.5, 6.3, 6.1, 6.0, 6.0),
        state_avg_pre = c(7.0, 7.1, 7.0, 7.1, 7.0, 7.1),
        state_avg_post = c(7.0, 6.9, 6.9, 6.9, 6.8, 6.8)
      ),
      "Healthy Days per Month" = list(
        pre_score = 12,
        post_score = 22,
        time_series_pre = c(10, 11, 12, 11, 13, 12),
        time_series_post = c(18, 19, 20, 21, 22, 23),
        state_avg_pre = c(15, 15, 15, 16, 16, 16),
        state_avg_post = c(17, 17, 18, 18, 19, 19)
      ),
      "Emergency Room Visits (per year)" = list(
        pre_score = 3.2,
        post_score = 0.8,
        time_series_pre = c(3.5, 3.4, 3.2, 3.3, 3.1, 3.2),
        time_series_post = c(1.8, 1.5, 1.2, 1.0, 0.8, 0.7),
        state_avg_pre = c(2.5, 2.6, 2.5, 2.6, 2.5, 2.6),
        state_avg_post = c(2.4, 2.3, 2.3, 2.2, 2.2, 2.1)
      )
    ),
    pre_score = 7.2,
    post_score = 6.1,
    score_label = "Average A1C Level",
    time_series_pre = c(7.4, 7.3, 7.2, 7.3, 7.1, 7.2),
    time_series_post = c(6.8, 6.5, 6.3, 6.1, 6.0, 6.0),
    state_avg_pre = c(7.0, 7.1, 7.0, 7.1, 7.0, 7.1),
    state_avg_post = c(7.0, 6.9, 6.9, 6.9, 6.8, 6.8)
  ),
  arts_enrichment = list(
    name = "Arts Enrichment for Children",
    type = "Youth Development",
    towns = c("New Haven", "Hamden", "West Haven"),
    budget = 62000,
    participants = 85,
    completion_rate = 88,
    outcome_metrics = list(
      "School Engagement Index (0-100)" = list(
        pre_score = 52,
        post_score = 78,
        time_series_pre = c(48, 50, 52, 51, 53, 54),
        time_series_post = c(68, 72, 75, 77, 78, 80),
        state_avg_pre = c(60, 61, 60, 62, 63, 63),
        state_avg_post = c(65, 66, 67, 68, 69, 70)
      ),
      "Creative Problem-Solving Score (1-5)" = list(
        pre_score = 3.2,
        post_score = 4.5,
        time_series_pre = c(3.0, 3.1, 3.2, 3.1, 3.3, 3.4),
        time_series_post = c(4.0, 4.2, 4.3, 4.4, 4.5, 4.6),
        state_avg_pre = c(3.5, 3.6, 3.5, 3.6, 3.7, 3.7),
        state_avg_post = c(3.8, 3.9, 3.9, 4.0, 4.0, 4.1)
      ),
      "Public Performances per Year" = list(
        pre_score = 0,
        post_score = 3,
        time_series_pre = c(0, 0, 0, 0, 0, 0),
        time_series_post = c(1, 1, 2, 2, 3, 3),
        state_avg_pre = c(0.5, 0.5, 0.5, 0.5, 0.6, 0.6),
        state_avg_post = c(1.0, 1.0, 1.1, 1.2, 1.3, 1.3)
      )
    ),
    pre_score = 52,
    post_score = 78,
    score_label = "School Engagement Index (0-100)",
    time_series_pre = c(48, 50, 52, 51, 53, 54),
    time_series_post = c(68, 72, 75, 77, 78, 80),
    state_avg_pre = c(60, 61, 60, 62, 63, 63),
    state_avg_post = c(65, 66, 67, 68, 69, 70)
  ),
  mindfulness_yoga = list(
    name = "Mindfulness & Yoga for Students",
    type = "Youth Development",
    towns = c("West Hartford", "Hartford"),
    budget = 48000,
    participants = 120,
    completion_rate = 92,
    outcome_metrics = list(
      "Student Stress Index (0-10, lower is better)" = list(
        pre_score = 7.8,
        post_score = 4.2,
        time_series_pre = c(8.0, 7.9, 7.8, 7.9, 7.7, 7.8),
        time_series_post = c(5.5, 5.0, 4.6, 4.4, 4.2, 4.0),
        state_avg_pre = c(7.2, 7.3, 7.2, 7.3, 7.2, 7.3),
        state_avg_post = c(6.8, 6.7, 6.6, 6.5, 6.4, 6.3)
      ),
      "School Behavior Incidents (per month)" = list(
        pre_score = 2.4,
        post_score = 0.6,
        time_series_pre = c(2.6, 2.5, 2.4, 2.5, 2.3, 2.4),
        time_series_post = c(1.2, 1.0, 0.8, 0.7, 0.6, 0.5),
        state_avg_pre = c(2.0, 2.1, 2.0, 2.1, 2.0, 2.1),
        state_avg_post = c(1.8, 1.7, 1.7, 1.6, 1.6, 1.5)
      ),
      "Attendance Rate (%)" = list(
        pre_score = 82,
        post_score = 94,
        time_series_pre = c(80, 81, 82, 81, 83, 82),
        time_series_post = c(90, 91, 92, 93, 94, 95),
        state_avg_pre = c(85, 86, 85, 86, 87, 87),
        state_avg_post = c(88, 89, 89, 90, 90, 91)
      )
    ),
    pre_score = 7.8,
    post_score = 4.2,
    score_label = "Student Stress Index (0-10, lower is better)",
    time_series_pre = c(8.0, 7.9, 7.8, 7.9, 7.7, 7.8),
    time_series_post = c(5.5, 5.0, 4.6, 4.4, 4.2, 4.0),
    state_avg_pre = c(7.2, 7.3, 7.2, 7.3, 7.2, 7.3),
    state_avg_post = c(6.8, 6.7, 6.6, 6.5, 6.4, 6.3)
  )
)

# UI
ui <- fluidPage(
  theme = bs_theme(version = 5),

  # Add custom CSS
  tags$head(
    tags$link(
      rel = "stylesheet",
      href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
    ),
    tags$style(HTML("
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

      h2 {
        text-align: center;
        color: #2c3e50;
        font-weight: 700;
        font-size: 2rem;
        margin-bottom: 0.3rem;
        letter-spacing: -0.02em;
      }

      .subtitle {
        color: #666;
        font-size: 1.1rem;
        margin-bottom: 2rem;
        font-weight: 300;
        text-align: center;
      }

      .info-box {
        background: linear-gradient(135deg, rgba(249, 179, 151, 0.1), rgba(214, 138, 147, 0.1));
        border-left: 4px solid #D68A93;
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 25px;
      }

      .section-header {
        color: #2c3e50;
        font-weight: 600;
        font-size: 1.3rem;
        margin-bottom: 1rem;
        margin-top: 1.5rem;
      }

      /* Help icon tooltip styling */
      .help-icon {
        display: inline-block;
        width: 18px;
        height: 18px;
        background: #AD92B1;
        color: white;
        border-radius: 50%;
        text-align: center;
        line-height: 18px;
        font-size: 12px;
        font-weight: 600;
        margin-left: 8px;
        cursor: help;
        transition: all 0.2s ease;
        position: relative;
      }

      .help-icon:hover {
        background: #D68A93;
        transform: scale(1.1);
      }

      /* Enhanced tooltip styling */
      .help-icon[title]:hover::after {
        content: attr(title);
        position: absolute;
        left: 50%;
        bottom: calc(100% + 8px);
        transform: translateX(-50%);
        background: rgba(44, 62, 80, 0.95);
        color: white;
        padding: 8px 12px;
        border-radius: 6px;
        font-size: 13px;
        font-weight: 400;
        white-space: normal;
        width: 300px;
        z-index: 1000;
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        pointer-events: none;
        text-align: left;
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

      /* Value box styling */
      .bslib-value-box {
        border: none;
        box-shadow: 0 4px 12px rgba(0,0,0,0.08);
        border-radius: 12px;
      }

      /* Card styling */
      .card {
        border: none;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        margin-bottom: 1.5rem;
      }

      .card-header {
        background: linear-gradient(135deg, rgba(214, 138, 147, 0.1), rgba(173, 146, 177, 0.1));
        border-bottom: 2px solid #D68A93;
        font-weight: 600;
        color: #2c3e50;
      }
      
      /* Tab styling */
      .nav-tabs .nav-link {
        color: #666;
        border: none;
        background: transparent;
        font-weight: 500;
        padding: 0.75rem 1.25rem;
      }
      
      .nav-tabs .nav-link.active {
        color: #AD92B1;
        background: rgba(173, 146, 177, 0.1);
        border-bottom: 3px solid #AD92B1;
      }
      
      .nav-tabs .nav-link:hover {
        color: #D68A93;
        background: rgba(214, 138, 147, 0.05);
      }
      
      /* Plotly toolbar styling */
      .modebar {
        background: transparent !important;
        border-radius: 8px;
        padding: 4px !important;
        box-shadow: none !important;
      }
      
      .modebar-btn {
        color: #666 !important;
      }
      
      .modebar-btn:hover {
        color: #AD92B1 !important;
      }
    "))
  ),

  div(class = "main-container",
    h2("Program Impact Dashboard"),
    div(class = "subtitle", "Measure and communicate your program's impact in Connecticut communities"),

    div(class = "info-box",
      HTML("<strong>About this tool:</strong> Analyze your program's impact with data-driven insights. Compare outcomes to Connecticut benchmarks, visualize community need, and generate board-ready reports.")
    ),

    # Sidebar Layout
    layout_sidebar(
      sidebar = sidebar(
        width = 250,
        style = "background: #f8f9fa; border-radius: 12px; padding: 1rem;",

    h4("Program Setup", style = "margin-top: 0; color: #2c3e50;"),

    selectInput(
      "sample_program",
      "Load Sample Program:",
      choices = c(
        "Select a sample..." = "",
        "After-School Literacy" = "youth_literacy",
        "Manufacturing Training" = "workforce",
        "Diabetes Prevention" = "health",
        "Arts Enrichment" = "arts_enrichment",
        "Mindfulness & Yoga" = "mindfulness_yoga"
      )
    ),

    hr(),

    textInput("program_name", "Program Name", value = ""),

    selectInput(
      "program_type",
      "Program Type:",
      choices = c(
        "Youth Development",
        "Workforce Development",
        "Health Services",
        "Food Security",
        "Education"
      )
    ),

    selectInput(
      "service_towns",
      "Service Area (CT Towns):",
      choices = sort(unique(ct_towns_data$town)),
      multiple = TRUE
    ),

    numericInput("participants", "Participants Served:", value = 50, min = 1),
    numericInput("budget", "Annual Budget ($):", value = 75000, min = 0, step = 1000),
    numericInput("completion_rate", "Completion Rate (%):", value = 82, min = 0, max = 100),

    hr(),

    h5("Outcome Metrics", style = "color: #2c3e50; margin-top: 0;"),
    
    selectInput("outcome_metric", "Select Outcome Metric:",
                choices = list(
                  "Choose a metric..." = ""
                ),
                selected = ""),

    numericInput("pre_score", "Pre-Program Score:", value = 2.3, step = 0.1),
    numericInput("post_score", "Post-Program Score:", value = 3.7, step = 0.1),
    textInput("score_label", "Score Label:", value = "Grade Level"),

    hr(),

    actionButton("analyze", "Analyze Impact", class = "btn-primary w-100",
                 style = "background: linear-gradient(135deg, #D68A93, #AD92B1); border: none;")
      ),  # Close sidebar

      # Main content with tabbed interface
      navset_card_tab(
        nav_panel(
          title = "Impact Overview",
          icon = bsicons::bs_icon("bar-chart-line-fill"),
          
          # Impact Overview Section
          div(class = "section-header", "📊 Impact Overview"),
          
          layout_columns(
            col_widths = c(3, 3, 3, 3),
            value_box(
              title = "Participants Served",
              value = textOutput("participants_display"),
              showcase = bsicons::bs_icon("people-fill"),
              theme = "info"  # Blue - informational metric
            ),
            value_box(
              title = "Completion Rate",
              value = textOutput("completion_display"),
              showcase = bsicons::bs_icon("check-circle-fill"),
              theme = "success"  # Green - positive retention outcome
            ),
            value_box(
              title = "Outcome Improvement",
              value = textOutput("improvement_display"),
              showcase = bsicons::bs_icon("graph-up-arrow"),
              theme = "primary"  # Brand purple - main impact metric
            ),
            value_box(
              title = "Cost Per Participant",
              value = textOutput("cost_display"),
              showcase = bsicons::bs_icon("currency-dollar"),
              theme = "warning"  # Amber - cost metric requiring context
            )
          ),
          
          # Charts Section
          layout_columns(
            col_widths = c(6, 6),
            card(
              card_header("Outcome Improvement"),
              plotlyOutput("outcome_chart", height = "350px")
            ),
            card(
              card_header("Impact Over Time"),
              plotlyOutput("time_series_chart", height = "350px")
            )
          )
        ),
        
        nav_panel(
          title = "Statistical Impact",
          icon = bsicons::bs_icon("calculator-fill"),
          
          # Causal Impact Analysis
          div(class = "section-header",
            HTML('📈 Causal Impact Analysis
              <span class="help-icon" title="Bayesian structural time-series model estimating the causal effect of your program. Compares actual post-program outcomes against a statistical counterfactual (predicted outcomes without the program). Includes 95% credible intervals showing the range of likely impact.">?</span>')
          ),
          
          card(
            card_header("Statistical Impact Assessment"),
            plotlyOutput("causal_impact_plot", height = "450px"),
            div(style = "padding: 15px; margin-top: 10px; background: #f8f9fa; border-radius: 8px;",
              uiOutput("causal_impact_summary")
            )
          )
        ),
        
        nav_panel(
          title = "Community Context",
          icon = bsicons::bs_icon("geo-alt-fill"),
          
          # Connecticut Context
          div(class = "section-header",
            HTML('📍 Connecticut Community Context
              <span class="help-icon" title="Geographic and demographic data sourced from US Census Bureau American Community Survey (ACS) 5-year estimates via tidycensus API. Data is updated annually by the Census Bureau.">?</span>')
          ),
          
          layout_columns(
            col_widths = c(8, 4),
            card(
              card_header("Service Area Map"),
              leafletOutput("ct_map", height = "400px")
            ),
            card(
              card_header(
                HTML('Community Data
                  <span class="help-icon" title="Population and median household income from 2022 ACS 5-year estimates. Focus is on program reach and service coverage. Data fetched securely via Census API.">?</span>')
              ),
              uiOutput("community_stats")
            )
          ),
          
          # Demographics Section
          div(class = "section-header", "👥 Demographics & Reach"),
          
          card(
            card_header("Program Reach Analysis"),
            plotlyOutput("reach_chart", height = "300px")
          )
        )
      ),

    # Footer with CTA
    div(
      class = "app-footer",
      fluidRow(
        column(7,
          h4("Need Custom Impact Assessment Tools?", style = "color: white; margin-bottom: 1rem; margin-top: 0;"),
          p(
            style = "color: rgba(255,255,255,0.9); margin-bottom: 1.5rem;",
            "This program impact dashboard demonstrates data-driven evaluation capabilities. ",
            "Daly Analytics creates custom impact measurement solutions tailored to your organization's unique programs and reporting needs."
          ),
          tags$div(
            style = "color: rgba(255,255,255,0.85);",
            tags$div(style = "margin-bottom: 8px;", HTML("✓ Custom impact dashboards with longitudinal tracking")),
            tags$div(style = "margin-bottom: 8px;", HTML("✓ Automated board and grant reporting systems")),
            tags$div(style = "margin-bottom: 8px;", HTML("✓ Data integration with your CRM and survey tools")),
            tags$div(style = "margin-bottom: 8px;", HTML("✓ Strategic planning analytics with scenario modeling"))
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
          "© 2025 Daly Analytics LLC. This free tool was built to demonstrate our expertise in nonprofit impact measurement. ",
          tags$a(
            "Contact us",
            href = "https://www.dalyanalytics.com/contact",
            style = "color: #F9B397;",
            target = "_blank"
          ),
          " to build custom analytics solutions for your organization."
        )
      )
    )  # Close app-footer
    ),  # Close layout_sidebar
  )  # Close main-container
)  # Close fluidPage

# Server
server <- function(input, output, session) {

  # Reactive values for current program data
  current_program <- reactiveVal(NULL)

  # Load sample program data
  observeEvent(input$sample_program, {
    req(input$sample_program != "")

    program <- sample_programs[[input$sample_program]]

    updateTextInput(session, "program_name", value = program$name)
    updateSelectInput(session, "program_type", selected = program$type)
    updateSelectInput(session, "service_towns", selected = program$towns)
    updateNumericInput(session, "participants", value = program$participants)
    updateNumericInput(session, "budget", value = program$budget)
    updateNumericInput(session, "completion_rate", value = program$completion_rate)
    
    # Update outcome metrics dropdown if program has multiple metrics
    if (!is.null(program$outcome_metrics)) {
      metric_choices <- names(program$outcome_metrics)
      updateSelectInput(session, "outcome_metric", 
                       choices = metric_choices,
                       selected = metric_choices[1])
    } else {
      # For older programs without multiple metrics
      updateSelectInput(session, "outcome_metric", 
                       choices = list(program$score_label),
                       selected = program$score_label)
    }
    
    updateNumericInput(session, "pre_score", value = program$pre_score)
    updateNumericInput(session, "post_score", value = program$post_score)
    updateTextInput(session, "score_label", value = program$score_label)

    current_program(program)
  })
  
  # Update scores when outcome metric is selected
  observeEvent(input$outcome_metric, {
    req(input$outcome_metric != "")
    req(!is.null(current_program()))
    
    program <- current_program()
    
    # If program has multiple outcome metrics
    if (!is.null(program$outcome_metrics) && input$outcome_metric %in% names(program$outcome_metrics)) {
      metric_data <- program$outcome_metrics[[input$outcome_metric]]
      
      updateNumericInput(session, "pre_score", value = metric_data$pre_score)
      updateNumericInput(session, "post_score", value = metric_data$post_score)
      updateTextInput(session, "score_label", value = input$outcome_metric)
      
      # Update the program data with selected metric's time series
      program$pre_score <- metric_data$pre_score
      program$post_score <- metric_data$post_score
      program$score_label <- input$outcome_metric
      program$time_series_pre <- metric_data$time_series_pre
      program$time_series_post <- metric_data$time_series_post
      program$state_avg_pre <- metric_data$state_avg_pre
      program$state_avg_post <- metric_data$state_avg_post
      
      current_program(program)
    }
  })

  # Value boxes
  output$participants_display <- renderText({
    comma(input$participants)
  })

  output$completion_display <- renderText({
    paste0(input$completion_rate, "%")
  })

  output$improvement_display <- renderText({
    improvement <- input$post_score - input$pre_score
    percent_change <- (improvement / input$pre_score) * 100
    paste0("+", round(improvement, 1), " (", round(percent_change, 0), "%)")
  })

  output$cost_display <- renderText({
    cost_per_participant <- input$budget / input$participants
    paste0("$", comma(round(cost_per_participant)))
  })

  # Outcome improvement chart
  output$outcome_chart <- renderPlotly({
    plot_ly() %>%
      add_bars(
        x = c("Pre-Program", "Post-Program"),
        y = c(input$pre_score, input$post_score),
        name = "Your Program",
        marker = list(
          color = c("#D68A93", "#28a745"),
          line = list(color = "white", width = 2)
        ),
        text = c(
          paste0(input$score_label, ": ", input$pre_score),
          paste0(input$score_label, ": ", input$post_score)
        ),
        hoverinfo = "text"
      ) %>%
      layout(
        title = "",
        xaxis = list(title = ""),
        yaxis = list(title = input$score_label),
        showlegend = FALSE,
        plot_bgcolor = "rgba(0,0,0,0)",
        paper_bgcolor = "rgba(0,0,0,0)",
        margin = list(l = 60, r = 20, t = 20, b = 40)
      ) %>%
      config(displayModeBar = TRUE, toImageButtonOptions = list(
        format = "png",
        filename = "chart_export",
        width = 800,
        height = 500
      ))
  })

  # Time series chart
  output$time_series_chart <- renderPlotly({
    program <- current_program()

    if (is.null(program)) {
      # Default data if no sample loaded - add slight variation to avoid constant series
      months <- 1:12
      pre_data <- input$pre_score + c(-0.1, 0.05, -0.05, 0.1, 0, -0.02)
      post_data <- input$post_score + c(0.1, -0.05, 0.15, -0.1, 0.05, 0.2)
      state_pre <- input$pre_score * 1.2 + c(-0.05, 0.02, 0.03, -0.01, 0.04, -0.03)
      state_post <- input$post_score * 0.95 + c(0.02, -0.01, 0.03, 0.01, -0.02, 0.05)
    } else {
      months <- 1:12
      pre_data <- program$time_series_pre
      post_data <- program$time_series_post
      state_pre <- program$state_avg_pre
      state_post <- program$state_avg_post
    }

    plot_ly() %>%
      add_trace(
        x = 1:6,
        y = pre_data,
        type = "scatter",
        mode = "lines+markers",
        name = "Your Program (Pre)",
        line = list(color = "#D68A93", width = 3, dash = "dash"),
        marker = list(size = 8, color = "#D68A93")
      ) %>%
      add_trace(
        x = 7:12,
        y = post_data,
        type = "scatter",
        mode = "lines+markers",
        name = "Your Program (Post)",
        line = list(color = "#28a745", width = 3),
        marker = list(size = 8, color = "#28a745")
      ) %>%
      add_trace(
        x = 1:6,
        y = state_pre,
        type = "scatter",
        mode = "lines",
        name = "State Average (Pre)",
        line = list(color = "#999", width = 2, dash = "dot"),
        opacity = 0.6
      ) %>%
      add_trace(
        x = 7:12,
        y = state_post,
        type = "scatter",
        mode = "lines",
        name = "State Average (Post)",
        line = list(color = "#666", width = 2, dash = "dot"),
        opacity = 0.6
      ) %>%
      layout(
        xaxis = list(
          title = "Month",
          tickmode = "linear",
          tick0 = 1,
          dtick = 1
        ),
        yaxis = list(title = input$score_label),
        hovermode = "x unified",
        plot_bgcolor = "rgba(0,0,0,0)",
        paper_bgcolor = "rgba(0,0,0,0)",
        legend = list(
          orientation = "h",
          x = 0,
          y = -0.2
        ),
        shapes = list(
          list(
            type = "line",
            x0 = 6.5,
            x1 = 6.5,
            y0 = 0,
            y1 = 1,
            yref = "paper",
            line = list(color = "#2c3e50", width = 2, dash = "dash")
          )
        ),
        annotations = list(
          list(
            x = 3,
            y = 1.05,
            yref = "paper",
            text = "Pre-Program",
            showarrow = FALSE,
            font = list(size = 11, color = "#666")
          ),
          list(
            x = 9,
            y = 1.05,
            yref = "paper",
            text = "Post-Program",
            showarrow = FALSE,
            font = list(size = 11, color = "#666")
          )
        ),
        margin = list(l = 60, r = 20, t = 40, b = 60)
      ) %>%
      config(displayModeBar = TRUE, toImageButtonOptions = list(
        format = "png",
        filename = "chart_export",
        width = 800,
        height = 500
      ))
  })

  # Causal Impact Analysis
  output$causal_impact_plot <- renderPlotly({
    program <- current_program()

    if (is.null(program)) {
      # Default data if no sample loaded - add slight variation to avoid constant series
      pre_data <- input$pre_score + c(-0.1, 0.05, -0.05, 0.1, 0, -0.02)
      post_data <- input$post_score + c(0.1, -0.05, 0.15, -0.1, 0.05, 0.2)
      state_pre <- input$pre_score * 1.2 + c(-0.05, 0.02, 0.03, -0.01, 0.04, -0.03)
      state_post <- input$post_score * 0.95 + c(0.02, -0.01, 0.03, 0.01, -0.02, 0.05)
    } else {
      pre_data <- program$time_series_pre
      post_data <- program$time_series_post
      state_pre <- program$state_avg_pre
      state_post <- program$state_avg_post
    }

    # Prepare data for CausalImpact
    # Combine pre and post data
    y <- c(pre_data, post_data)  # Observed outcome (your program)
    x <- c(state_pre, state_post)  # Control/covariate (state average)

    # Create time series data
    data <- zoo::zoo(cbind(y, x))

    # Define pre and post intervention periods
    pre_period <- c(1, 6)
    post_period <- c(7, 12)

    # Check for constant data that would break CausalImpact
    if (length(unique(y)) <= 1 || length(unique(x)) <= 1 || var(y) == 0 || var(x) == 0) {
      impact <- NULL
    } else {
      # Run CausalImpact analysis
      impact <- tryCatch({
        CausalImpact(data, pre_period, post_period)
      }, error = function(e) {
        warning("CausalImpact failed: ", e$message)
        NULL
      })
    }

    if (is.null(impact)) {
      # If CausalImpact fails, show a simple message
      plot_ly() %>%
        add_annotations(
          text = "Unable to compute causal impact analysis with current data.\nTry loading a sample program or adjusting your metrics.",
          xref = "paper",
          yref = "paper",
          x = 0.5,
          y = 0.5,
          showarrow = FALSE,
          font = list(size = 14, color = "#666")
        ) %>%
        layout(
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)
        )
    } else {
      # Extract plot data from CausalImpact object safely
      impact_data <- impact$series
      time_points <- 1:nrow(impact_data)
      
      # Extract data vectors directly to avoid plotly data association issues
      observed_data <- as.vector(impact_data$response)
      predicted_data <- as.vector(impact_data$point.pred)
      lower_data <- as.vector(impact_data$point.pred.lower)
      upper_data <- as.vector(impact_data$point.pred.upper)

      # Create plot with explicit data vectors
      fig <- plot_ly() %>%
        # Confidence band first (so it's in background)
        add_ribbons(
          x = time_points,
          ymin = lower_data,
          ymax = upper_data,
          name = "95% Credible Interval",
          fillcolor = "rgba(214, 138, 147, 0.2)",
          line = list(color = "transparent"),
          hoverinfo = "none"
        ) %>%
        # Predicted/counterfactual line
        add_trace(
          x = time_points,
          y = predicted_data,
          type = "scatter",
          mode = "lines",
          name = "Predicted (Counterfactual)",
          line = list(color = "#D68A93", width = 2, dash = "dash")
        ) %>%
        # Observed data (on top)
        add_trace(
          x = time_points,
          y = observed_data,
          type = "scatter",
          mode = "lines+markers",
          name = "Observed",
          line = list(color = "#2c3e50", width = 2),
          marker = list(size = 6)
        )

      # Add vertical line at intervention point
      fig <- fig %>%
        layout(
          xaxis = list(
            title = "Time Period (Months)",
            tickmode = "linear",
            tick0 = 1,
            dtick = 1
          ),
          yaxis = list(title = input$score_label),
          hovermode = "x unified",
          plot_bgcolor = "rgba(0,0,0,0)",
          paper_bgcolor = "rgba(0,0,0,0)",
          legend = list(
            orientation = "h",
            x = 0,
            y = -0.15
          ),
          shapes = list(
            list(
              type = "line",
              x0 = 6.5,
              x1 = 6.5,
              y0 = 0,
              y1 = 1,
              yref = "paper",
              line = list(color = "#2c3e50", width = 2, dash = "dot")
            )
          ),
          annotations = list(
            list(
              x = 3,
              y = 1.05,
              yref = "paper",
              text = "Pre-Program",
              showarrow = FALSE,
              font = list(size = 11, color = "#666")
            ),
            list(
              x = 9,
              y = 1.05,
              yref = "paper",
              text = "Post-Program (Intervention)",
              showarrow = FALSE,
              font = list(size = 11, color = "#666")
            )
          ),
          margin = list(l = 60, r = 20, t = 40, b = 80)
        ) %>%
        config(displayModeBar = TRUE, toImageButtonOptions = list(
        format = "png",
        filename = "chart_export",
        width = 800,
        height = 500
      ))

      fig
    }
  })

  # Causal Impact Summary
  output$causal_impact_summary <- renderUI({
    program <- current_program()

    if (is.null(program)) {
      # Default data with variation to avoid constant series warnings
      pre_data <- input$pre_score + c(-0.1, 0.05, -0.05, 0.1, 0, -0.02)
      post_data <- input$post_score + c(0.1, -0.05, 0.15, -0.1, 0.05, 0.2)
      state_pre <- input$pre_score * 1.2 + c(-0.05, 0.02, 0.03, -0.01, 0.04, -0.03)
      state_post <- input$post_score * 0.95 + c(0.02, -0.01, 0.03, 0.01, -0.02, 0.05)
    } else {
      pre_data <- program$time_series_pre
      post_data <- program$time_series_post
      state_pre <- program$state_avg_pre
      state_post <- program$state_avg_post
    }

    # Prepare data for CausalImpact
    y <- c(pre_data, post_data)
    x <- c(state_pre, state_post)

    # Check for constant data that would break CausalImpact
    if (length(unique(y)) <= 1 || length(unique(x)) <= 1 || var(y) == 0 || var(x) == 0) {
      impact <- NULL
    } else {
      data <- zoo::zoo(cbind(y, x))
      pre_period <- c(1, 6)
      post_period <- c(7, 12)

      impact <- tryCatch({
        CausalImpact(data, pre_period, post_period)
      }, error = function(e) {
        NULL
      })
    }

    if (is.null(impact)) {
      return(div(
        style = "text-align: center; color: #999; padding: 20px;",
        "Causal impact analysis unavailable. Load a sample program to see statistical assessment."
      ))
    }

    # Extract summary statistics with safety checks
    summary_data <- impact$summary
    
    # Check if summary data has the expected structure
    if (is.null(summary_data) || nrow(summary_data) < 2 || is.null(summary_data$Actual) || 
        length(summary_data$Actual) < 2 || is.null(summary_data$p) || length(summary_data$p) < 2) {
      return(div(
        style = "text-align: center; color: #999; padding: 20px;",
        "Causal impact analysis incomplete. Try a different program configuration."
      ))
    }

    # Calculate key metrics safely
    absolute_effect <- tryCatch({
      summary_data$Actual[2] - summary_data$Pred[2]
    }, error = function(e) 0)
    
    absolute_effect_lower <- tryCatch({
      summary_data$Actual.lower[2] - summary_data$Pred.upper[2]
    }, error = function(e) 0)
    
    absolute_effect_upper <- tryCatch({
      summary_data$Actual.upper[2] - summary_data$Pred.lower[2]
    }, error = function(e) 0)

    relative_effect <- tryCatch({
      summary_data$RelEffect[2] * 100
    }, error = function(e) 0)
    
    relative_effect_lower <- tryCatch({
      summary_data$RelEffect.lower[2] * 100
    }, error = function(e) 0)
    
    relative_effect_upper <- tryCatch({
      summary_data$RelEffect.upper[2] * 100
    }, error = function(e) 0)

    p_value <- tryCatch({
      summary_data$p[2]
    }, error = function(e) 1)

    # Determine significance
    is_significant <- !is.na(p_value) && !is.null(p_value) && length(p_value) > 0 && p_value < 0.05
    significance_text <- if (is_significant) {
      "statistically significant"
    } else {
      "not statistically significant"
    }

    # Determine effect color
    effect_color <- if (absolute_effect > 0) "#28a745" else "#dc3545"

    tagList(
      div(style = "margin-bottom: 15px;",
        h5("Statistical Assessment", style = "color: #2c3e50; margin-top: 0;")
      ),
      div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 15px;",
        div(
          div(style = "font-size: 0.9rem; color: #666; margin-bottom: 5px;", "Absolute Effect"),
          div(style = paste0("font-size: 1.5rem; font-weight: 600; color: ", effect_color, ";"),
              sprintf("%+.2f points", absolute_effect)
          ),
          div(style = "font-size: 0.85rem; color: #999;",
              sprintf("95%% CI: [%.2f, %.2f]", absolute_effect_lower, absolute_effect_upper)
          )
        ),
        div(
          div(style = "font-size: 0.9rem; color: #666; margin-bottom: 5px;", "Relative Effect"),
          div(style = paste0("font-size: 1.5rem; font-weight: 600; color: ", effect_color, ";"),
              sprintf("%+.1f%%", relative_effect)
          ),
          div(style = "font-size: 0.85rem; color: #999;",
              sprintf("95%% CI: [%.1f%%, %.1f%%]", relative_effect_lower, relative_effect_upper)
          )
        )
      ),
      div(style = "padding: 15px; background: white; border-left: 4px solid #AD92B1; border-radius: 4px;",
        div(style = "font-size: 0.95rem; color: #2c3e50; line-height: 1.6;",
          HTML(sprintf(
            "<strong>Interpretation:</strong> The program's effect is <strong>%s</strong> (p = %.3f). ",
            significance_text, p_value
          )),
          if (absolute_effect > 0) {
            sprintf("Participants showed an improvement of approximately %.2f points compared to the predicted outcome without the program.", absolute_effect)
          } else {
            sprintf("The observed change was %.2f points less than would be expected without the program.", abs(absolute_effect))
          },
          HTML("<br><br><em>Note: This analysis uses Bayesian structural time-series modeling to estimate what would have happened without your program (the counterfactual) based on state averages.</em>")
        )
      )
    )
  })

  # Connecticut map
  output$ct_map <- renderLeaflet({
    selected_towns <- input$service_towns

    # Filter to selected towns
    map_data <- ct_towns_data %>%
      mutate(
        is_service_area = town %in% selected_towns,
        fill_color = ifelse(is_service_area, "#28a745", "#D68A93"),
        fill_opacity = ifelse(is_service_area, 0.8, 0.4)
      )

    leaflet(map_data) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~lng,
        lat = ~lat,
        radius = ~sqrt(population) / 20,
        fillColor = ~fill_color,
        fillOpacity = ~fill_opacity,
        stroke = TRUE,
        color = "white",
        weight = 2,
        label = ~paste0(
          town, ", CT",
          "<br>Population: ", comma(population),
          "<br>Median Income: $", comma(median_income)
        ) %>% lapply(HTML),
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "12px",
          direction = "auto"
        )
      ) %>%
      setView(lng = -72.7, lat = 41.6, zoom = 9)
  })

  # Community stats
  output$community_stats <- renderUI({
    req(input$service_towns)

    selected_data <- ct_towns_data %>%
      filter(town %in% input$service_towns)

    if (nrow(selected_data) == 0) {
      return(div(
        style = "padding: 20px; text-align: center; color: #999;",
        "Select service towns to view community data"
      ))
    }

    total_pop <- sum(selected_data$population)
    avg_income <- mean(selected_data$median_income)
    reach_percent <- (input$participants / total_pop) * 100

    tagList(
      div(style = "padding: 15px;",
        div(style = "margin-bottom: 20px;",
          div(style = "font-size: 0.9rem; color: #666;", "Total Population"),
          div(style = "font-size: 1.8rem; font-weight: 600; color: #2c3e50;", comma(total_pop))
        ),
        div(style = "margin-bottom: 20px;",
          div(style = "font-size: 0.9rem; color: #666;", "Median Household Income"),
          div(style = "font-size: 1.5rem; font-weight: 600; color: #7f8c8d;", paste0("$", comma(round(avg_income))))
        ),
        hr(style = "margin: 20px 0;"),
        div(style = "margin-top: 15px;",
          div(style = "font-size: 0.9rem; color: #666;", "Program Reach"),
          div(style = "font-size: 2rem; font-weight: 600; color: #AD92B1;",
              paste0(round(reach_percent, 2), "%")
          ),
          div(style = "font-size: 0.85rem; color: #999; margin-top: 5px;",
              paste0(comma(input$participants), " participants served")
          )
        )
      )
    )
  })

  # Reach chart
  output$reach_chart <- renderPlotly({
    req(input$service_towns)

    selected_data <- ct_towns_data %>%
      filter(town %in% input$service_towns)

    if (nrow(selected_data) == 0) {
      return(plotly_empty())
    }

    plot_ly(selected_data) %>%
      add_bars(
        x = ~town,
        y = ~population,
        name = "Total Population",
        marker = list(color = "#D68A93"),
        text = ~paste0(comma(population), " people"),
        hoverinfo = "text"
      ) %>%
      add_trace(
        x = input$service_towns,
        y = rep(input$participants, length(input$service_towns)),
        type = "scatter",
        mode = "markers",
        name = "Participants Served",
        marker = list(
          size = 15,
          color = "#28a745",
          symbol = "diamond",
          line = list(color = "white", width = 2)
        ),
        text = paste0(input$participants, " served"),
        hoverinfo = "text"
      ) %>%
      layout(
        xaxis = list(title = "Town"),
        yaxis = list(title = "Population", type = "log"),
        showlegend = TRUE,
        legend = list(
          orientation = "h",
          x = 0,
          y = -0.15
        ),
        plot_bgcolor = "rgba(0,0,0,0)",
        paper_bgcolor = "rgba(0,0,0,0)",
        margin = list(l = 60, r = 20, t = 20, b = 60)
      ) %>%
      config(displayModeBar = TRUE, toImageButtonOptions = list(
        format = "png",
        filename = "chart_export",
        width = 800,
        height = 500
      ))
  })
}

# Run the app
shinyApp(ui, server)
