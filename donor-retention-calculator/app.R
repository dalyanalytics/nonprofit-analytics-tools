# Donor Retention Calculator - Shinylive App with bslib
# File: donor-retention-calculator/app.R

library(shiny)
library(bslib)
library(dplyr)
library(lubridate)
library(reactable)
library(sparkline)
library(shinyjs)

# Generate realistic dummy data for demo
set.seed(123)
generate_sample_data <- function() {
  # Create 500 donors with varying giving patterns
  donors <- data.frame(
    donor_id = 1:500,
    first_gift_date = sample(seq(as.Date("2019-01-01"), as.Date("2023-12-31"), by = "day"), 500),
    stringsAsFactors = FALSE
  )
  
  # Generate gifts for each donor with realistic retention patterns
  all_gifts <- data.frame()
  
  for(i in 1:nrow(donors)) {
    donor_id <- donors$donor_id[i]
    first_date <- donors$first_gift_date[i]
    
    # Create giving history with declining probability over time
    current_date <- first_date
    gifts <- data.frame()
    
    # First year - 100% retention (they gave at least once)
    first_gift_amount <- round(runif(1, 25, 1000), 2)
    gifts <- rbind(gifts, data.frame(
      donor_id = donor_id,
      gift_date = current_date,
      amount = first_gift_amount,
      year = year(current_date)
    ))
    
    # Subsequent years with declining retention
    retention_probs <- c(0.65, 0.45, 0.35, 0.30, 0.25) # Realistic nonprofit retention rates
    
    for(year_offset in 1:5) {
      if(current_date + years(year_offset) <= Sys.Date()) {
        if(runif(1) < retention_probs[min(year_offset, 5)]) {
          # If they give this year, they might give multiple times
          num_gifts <- sample(1:3, 1, prob = c(0.7, 0.25, 0.05))
          
          for(gift_num in 1:num_gifts) {
            gift_date <- current_date + years(year_offset) + days(sample(0:364, 1))
            if(gift_date <= Sys.Date()) {
              # Amounts tend to increase slightly over time for retained donors
              amount_multiplier <- runif(1, 0.8, 1.4)
              gift_amount <- round(first_gift_amount * amount_multiplier, 2)
              
              gifts <- rbind(gifts, data.frame(
                donor_id = donor_id,
                gift_date = gift_date,
                amount = gift_amount,
                year = year(gift_date)
              ))
            }
          }
        }
      }
    }
    
    all_gifts <- rbind(all_gifts, gifts)
  }
  
  return(list(donors = donors, gifts = all_gifts))
}

# Pre-generate sample data
sample_data <- generate_sample_data()

# Helper functions
calculate_retention_metrics <- function(gifts_data) {
  # Create donor summary
  donor_summary <- gifts_data %>%
    group_by(donor_id) %>%
    summarise(
      first_gift_year = min(year),
      last_gift_year = max(year),
      total_gifts = n(),
      total_amount = sum(amount),
      years_active = length(unique(year)),
      .groups = 'drop'
    )
  
  # Calculate retention by cohort (first gift year)
  cohort_analysis <- donor_summary %>%
    group_by(first_gift_year) %>%
    summarise(
      total_donors = n(),
      year_2_retained = sum(years_active >= 2),
      year_3_retained = sum(years_active >= 3),
      year_4_retained = sum(years_active >= 4),
      year_5_retained = sum(years_active >= 5),
      .groups = 'drop'
    ) %>%
    mutate(
      year_2_rate = round(year_2_retained / total_donors * 100, 1),
      year_3_rate = round(year_3_retained / total_donors * 100, 1),
      year_4_rate = round(year_4_retained / total_donors * 100, 1),
      year_5_rate = round(year_5_retained / total_donors * 100, 1)
    )
  
  # Overall retention rates
  current_year <- max(gifts_data$year)
  overall_retention <- donor_summary %>%
    filter(first_gift_year < current_year) %>%
    summarise(
      total_donors = n(),
      second_year_donors = sum(years_active >= 2),
      retention_rate = round(second_year_donors / total_donors * 100, 1)
    )
  
  # Calculate lifetime value projections
  avg_annual_gift <- gifts_data %>%
    group_by(donor_id, year) %>%
    summarise(annual_total = sum(amount), .groups = 'drop') %>%
    pull(annual_total) %>%
    mean()
  
  return(list(
    cohort_analysis = cohort_analysis,
    overall_retention = overall_retention,
    donor_summary = donor_summary,
    avg_annual_gift = avg_annual_gift
  ))
}

# Define theme colors matching Daly Analytics
theme_colors <- list(
  primary = "#F9B397",
  secondary = "#D68A93", 
  success = "#aecbed",
  info = "#AD92B1",
  warning = "#B07891",
  danger = "#dc3545"
)

# Custom theme
custom_theme <- bs_theme(
  version = 5,
  preset = "bootstrap",
  primary = theme_colors$primary,
  secondary = theme_colors$secondary,
  success = theme_colors$success,
  info = theme_colors$info,
  warning = theme_colors$warning,
  danger = theme_colors$danger,
  font_scale = 1.1
)

# Professional CSS styling to match board packet generator
professional_css <- "
/* Global styles */
html, body {
  height: 100%;
  margin: 0;
  padding: 0;
}

body {
  color: #2c3e50;
  background-color: #f8f9fa;
  line-height: 1.6;
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.main-content {
  flex: 1 0 auto;
}

footer {
  flex-shrink: 0;
  margin-top: auto !important;
}

/* Headers styling */
h1, h2, h3, h4, h5, h6, .display-font {
  color: #2c3e50;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin-bottom: 1rem;
}

/* Navbar styling - professional dark blue */
.navbar {
  background-color: #2c3e50 !important;
  border-radius: 0;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.navbar-brand {
  color: white !important;
  font-size: 1.5rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.navbar-nav .nav-link {
  color: rgba(255,255,255,0.8) !important;
  font-weight: 500;
  transition: all 0.2s ease;
}

.navbar-nav .nav-link:hover {
  color: white !important;
  background-color: rgba(255,255,255,0.1);
}

.navbar-nav .nav-link.active {
  color: white !important;
  background-color: rgba(255,255,255,0.15);
}

/* Card styling */
.card {
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.05);
  transition: all 0.3s ease;
  background: white;
  overflow: hidden;
}

.card:hover {
  box-shadow: 0 8px 24px rgba(0,0,0,0.1);
  transform: translateY(-2px);
}

.card-header {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-bottom: 2px solid #2c3e50;
  font-weight: 600;
  font-size: 1.1rem;
  color: #2c3e50;
  padding: 1rem 1.5rem;
}

/* Sidebar styling */
.bslib-sidebar-layout > .sidebar {
  background: #f8f9fa;
  border-right: 1px solid #dee2e6;
  padding: 1.5rem;
}

/* Professional form controls */
.form-control, .form-select {
  border: 2px solid #e9ecef;
  border-radius: 8px;
  padding: 0.75rem;
  font-size: 1rem;
  transition: all 0.2s ease;
}

.form-control:focus, .form-select:focus {
  border-color: #2c3e50;
  box-shadow: 0 0 0 0.2rem rgba(44, 62, 80, 0.15);
  outline: none;
}

/* Professional buttons */
.btn {
  font-weight: 500;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  transition: all 0.2s ease;
  text-transform: none;
  font-size: 1rem;
  letter-spacing: 0.02em;
}

.btn-primary {
  background: #2c3e50;
  border-color: #2c3e50;
  color: white;
  box-shadow: 0 4px 12px rgba(44, 62, 80, 0.3);
}

.btn-primary:hover {
  background: #34495e;
  border-color: #34495e;
  box-shadow: 0 6px 20px rgba(44, 62, 80, 0.4);
  transform: translateY(-1px);
}

.btn-secondary {
  background: #34495e;
  border-color: #34495e;
  color: white;
}

.btn-secondary:hover {
  background: #2c3e50;
  border-color: #2c3e50;
}

.btn-outline-primary {
  color: #2c3e50;
  border-color: #2c3e50;
  background: transparent;
}

.btn-outline-primary:hover {
  background: #2c3e50;
  border-color: #2c3e50;
  color: white;
}

/* Value boxes - Dark blue gradient theme */
.value-box {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.05);
  padding: 1.5rem;
  border-top: 4px solid #2c3e50;
}

/* Primary value box - Darkest blue */
.bslib-value-box.bg-primary,
.value-box.bg-primary {
  border-top: 4px solid #1a252f !important;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%) !important;
}

.bslib-value-box.bg-primary .value-box-showcase,
.value-box.bg-primary .value-box-showcase {
  color: #1a252f !important;
}

/* Info value box - Medium blue */
.bslib-value-box.bg-info,
.value-box.bg-info {
  border-top: 4px solid #2c3e50 !important;
  background: linear-gradient(135deg, #f9fafb 0%, #ecf0f1 100%) !important;
}

.bslib-value-box.bg-info .value-box-showcase,
.value-box.bg-info .value-box-showcase {
  color: #2c3e50 !important;
}

/* Success value box - Lightest blue */
.bslib-value-box.bg-success,
.value-box.bg-success {
  border-top: 4px solid #34495e !important;
  background: linear-gradient(135deg, #fbfcfc 0%, #f0f3f4 100%) !important;
}

.bslib-value-box.bg-success .value-box-showcase,
.value-box.bg-success .value-box-showcase {
  color: #34495e !important;
}

.value-box-title {
  color: #7f8c8d;
  font-size: 0.9rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.5rem;
}

.value-box-value {
  color: #2c3e50;
  font-size: 2rem;
  font-weight: 700;
  font-family: serif;
}

/* Professional tables */
.dataTable {
  font-size: 0.95rem;
}

.table thead th {
  background: #f8f9fa;
  color: #2c3e50;
  font-weight: 600;
  text-transform: uppercase;
  font-size: 0.85rem;
  letter-spacing: 0.05em;
  padding: 0.75rem;
  border-bottom: 2px solid #2c3e50;
}

.table tbody tr:hover {
  background-color: rgba(44, 62, 80, 0.05);
}

/* Loading screen overlay */
#loading-content {
  position: fixed;
  background: linear-gradient(135deg, rgba(44, 62, 80, 0.95), rgba(52, 73, 94, 0.95));
  background-size: 200% 200%;
  animation: gradientShift 8s ease infinite;
  z-index: 9999;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  height: 100vh;
  width: 100vw;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  color: white;
  font-family: sans-serif;
}

@keyframes gradientShift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

.loading-spinner {
  width: 60px;
  height: 60px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  border-top-color: white;
  animation: spin 1s ease-in-out infinite;
  margin-bottom: 30px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.loading-text {
  font-size: 1.8rem;
  font-weight: 600;
  margin-bottom: 15px;
  text-align: center;
}

.loading-subtitle {
  font-size: 1.1rem;
  opacity: 0.9;
  text-align: center;
  max-width: 400px;
  line-height: 1.4;
}

.loading-icon {
  font-size: 4rem;
  margin-bottom: 30px;
  opacity: 0.9;
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 20%, 50%, 80%, 100% {
    transform: translateY(0);
  }
  40% {
    transform: translateY(-10px);
  }
  60% {
    transform: translateY(-5px);
  }
}
"

# UI
ui <- tagList(
  tags$head(tags$style(HTML(professional_css))),
  
  # Main app content
  div(
      div(
        class = "main-content",
        page_navbar(
          title = div(icon("chart-line"), "Donor Retention Calculator"),
          theme = custom_theme,
  
          nav_panel(
            title = "Analysis Dashboard",
            icon = icon("chart-line"),
  
  
  # Sample data card
  card(
    class = "mb-4",
    card_header(
      h4("Try Sample Data", class = "mb-0")
    ),
    card_body(
      p("Explore with realistic nonprofit data (500 donors, 5 years of history). Upload your own CSV for personalized insights."),
      div(
        class = "d-flex align-items-center gap-3",
        actionButton("load_sample", "Load Sample Data", 
                    class = "btn-outline-primary btn-lg"),
        span("or upload your data below", class = "text-muted fst-italic")
      )
    )
  ),
  
  # Main layout
  layout_sidebar(
    fillable = TRUE,
    
    # Sidebar
    sidebar = sidebar(
      title = "Data Upload & Settings",
      width = 300,
      
      # File upload
      card(
        card_header("Upload Your Data"),
        card_body(
          fileInput("file", "Choose CSV File",
                   accept = c(".csv"),
                   placeholder = "donor_data.csv"),
          
          div(
            class = "alert alert-info small",
            icon("info-circle", class = "me-2"),
            strong("Privacy Note: "), 
            "This tool processes data locally in your browser. However, avoid uploading files with sensitive personal information (names, addresses, emails). Use anonymized donor IDs only."
          ),
          
          hr(),
          
          h6("Required CSV Format:", class = "fw-bold"),
          tags$ul(
            class = "list-unstyled small",
            tags$li(tags$strong("donor_id:"), " Unique identifier"),
            tags$li(tags$strong("gift_date:"), " Date (YYYY-MM-DD)"),
            tags$li(tags$strong("amount:"), " Gift amount (numeric)")
          ),
          
          tags$code("donor_id,gift_date,amount\n123,2023-01-15,100.00", 
                   class = "small text-muted")
        )
      ),
      
      # Analysis options
      conditionalPanel(
        condition = "output.data_loaded",
        br(),
        card(
          card_header("Analysis Options"),
          card_body(
            sliderInput("min_gift", "Minimum Gift Amount ($):",
                       min = 0, max = 1000, value = 0, step = 25),
            
            checkboxInput("exclude_current_year", 
                         "Exclude current year from calculations", 
                         value = TRUE),
            
            tags$small("Excluding current year provides more accurate retention rates.", 
                      class = "text-muted fst-italic")
          )
        )
      )
    ),
    
    # Main content area
    conditionalPanel(
      condition = "!output.data_loaded",
      div(
        class = "text-center py-5",
        style = "min-height: 400px; display: flex; flex-direction: column; justify-content: center; align-items: center;",
        icon("chart-line", class = "display-1 text-muted mb-4"),
        h2("Get Started", class = "mb-3"),
        p("Load sample data or upload your CSV to begin analysis", class = "lead mb-4"),
        hr(class = "w-50 mx-auto mb-4"),
        h5("What You'll Discover:", class = "mb-4"),
        div(
          class = "row g-3 mt-3 justify-content-center",
          style = "max-width: 600px;",
          div(class = "col-md-6 text-center",
            div(class = "d-flex flex-column align-items-center",
              icon("percentage", class = "text-muted mb-2", style = "font-size: 1.5rem;"),
              span("Retention rates vs industry benchmarks", class = "small")
            )
          ),
          div(class = "col-md-6 text-center",
            div(class = "d-flex flex-column align-items-center",
              icon("dollar-sign", class = "text-muted mb-2", style = "font-size: 1.5rem;"),
              span("Lifetime value projections", class = "small")
            )
          ),
          div(class = "col-md-6 text-center",
            div(class = "d-flex flex-column align-items-center",
              icon("users", class = "text-muted mb-2", style = "font-size: 1.5rem;"),
              span("Cohort analysis by acquisition year", class = "small")
            )
          ),
          div(class = "col-md-6 text-center",
            div(class = "d-flex flex-column align-items-center",
              icon("chart-pie", class = "text-muted mb-2", style = "font-size: 1.5rem;"),
              span("Donor segmentation insights", class = "small")
            )
          )
        )
      )
    ),
    
    # Results when data is loaded
    conditionalPanel(
      condition = "output.data_loaded",
      
      # Key metrics cards
      div(
        class = "row g-3 mb-4",
        div(
          class = "col-md-4",
          value_box(
            title = "Overall Retention Rate",
            value = textOutput("overall_retention"),
            showcase = icon("chart-line"),
            theme = "primary",
            p(textOutput("benchmark_comparison"), class = "mt-2")
          )
        ),
        div(
          class = "col-md-4",
          value_box(
            title = "Total Donors",
            value = textOutput("total_donors"),
            showcase = icon("users"),
            theme = "info"
          )
        ),
        div(
          class = "col-md-4",
          value_box(
            title = "Average Annual Gift",
            value = textOutput("avg_gift"),
            showcase = icon("dollar-sign"),
            theme = "success"
          )
        )
      ),
      
      # Industry benchmarks card
      card(
        class = "mb-4",
        card_header(
          h5("Industry Benchmarks", class = "mb-0")
        ),
        card_body(
          div(
            class = "row",
            div(
              class = "col-md-3 text-center",
              h6("Excellent", class = "text-success"),
              p(">70%", class = "fw-bold"),
              tags$small("Top 10%")
            ),
            div(
              class = "col-md-3 text-center",
              h6("Good", class = "text-info"),
              p("50-70%", class = "fw-bold"),
              tags$small("Above average")
            ),
            div(
              class = "col-md-3 text-center",
              h6("Average", class = "text-warning"),
              p("35-50%", class = "fw-bold"),
              tags$small("Industry standard")
            ),
            div(
              class = "col-md-3 text-center",
              h6("Needs Work", class = "text-danger"),
              p("<35%", class = "fw-bold"),
              tags$small("Below average")
            )
          )
        )
      ),
      
      # Analysis tabs
      navset_card_tab(
        height = "600px",
        nav_panel(
          "Lifetime Value",
          icon = icon("dollar-sign"),
          p("See how improving retention rates impacts donor lifetime value:"),
          reactableOutput("ltv_reactable"),
          br(),
          div(
            class = "alert alert-info",
            h6("Key Insight", class = "alert-heading"),
            p("Small improvements in retention create massive LTV increases. A 10% retention improvement can boost LTV by 25-40%.", 
              class = "mb-0")
          )
        ),
        
        nav_panel(
          "Cohort Analysis", 
          icon = icon("users"),
          p("Track retention performance by donor acquisition year:", class = "mb-4"),
          div(
            h5("Retention Trends by Cohort", class = "mb-3"),
            p("Each sparkline shows the retention rate progression from Year 2 through Year 5.", 
              class = "text-muted small mb-3"),
            reactableOutput("cohort_reactable"),
            class = "mb-5"
          ),
          div(
            h5("Detailed Cohort Data", class = "mb-3"),
            reactableOutput("cohort_table")
          )
        ),
        
        nav_panel(
          "Donor Segments",
          icon = icon("chart-pie"),
          p("Understand your donor base composition and value concentration:", class = "mb-4"),
          div(
            h5("Detailed Segment Breakdown", class = "mb-3"),
            reactableOutput("segment_table")
          )
        )
      )
    )
  ),
  
  # CTA footer
  # conditionalPanel(
  #   condition = "output.data_loaded",
  #   br(),
  #   card(
  #     style = "background: linear-gradient(135deg, rgba(44, 62, 80, 0.95), rgba(52, 73, 94, 0.95)); color: white;",
  #     card_body(
  #       class = "text-center py-4",
  #       h4("Want Automated Retention Tracking?", class = "text-white mb-3"),
  #       p("Stop doing this analysis manually. Get custom dashboards with predictive analytics, churn risk modeling, and automated insights.", 
  #         class = "lead text-white-50 mb-4"),
  #       a(href = "https://www.dalyanalytics.com/contact", 
  #         target = "_blank", 
  #         class = "btn btn-lg",
  #         style = "background: linear-gradient(135deg, #aecbed, #F9B397); color: #2c3e50; font-weight: 600;",
  #         "Schedule Free Consultation")
  #     )
  #   )
  # ),
  
  # Add footer at the very bottom
  tags$footer(
    class = "footer mt-5 py-4",
    style = "background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%); color: white;",
    div(
      class = "container",
      div(
        class = "row align-items-center",
        div(
          class = "col-md-8",
          h5("Need More Custom Analytics Tools?", style = "color: white; margin-bottom: 1rem;"),
          p(
            style = "color: rgba(255,255,255,0.9); margin-bottom: 1rem;",
            "This donor retention calculator demonstrates the power of automated analytics. ",
            "Daly Analytics specializes in creating custom dashboards that eliminate manual work and provide deeper insights."
          ),
          div(
            class = "mb-3",
            tags$ul(
              class = "list-unstyled",
              style = "color: rgba(255,255,255,0.8);",
              tags$li(icon("check"), " Real-time donor retention tracking"),
              tags$li(icon("check"), " Predictive churn risk modeling"),
              tags$li(icon("check"), " Automated monthly retention reports"),
              tags$li(icon("check"), " Donor segmentation & targeting"),
              tags$li(icon("check"), " Integration with your CRM/database")
            )
          )
        ),
        div(
          class = "col-md-4 text-center",
          div(
            style = "background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 12px;",
            h6("Ready to Get Started?", style = "color: white; margin-bottom: 1rem;"),
            tags$a(
              "Schedule Free Consultation",
              href = "https://www.dalyanalytics.com/contact",
              class = "btn btn-lg mb-2",
              style = "background: linear-gradient(135deg, #aecbed, #F9B397); color: #2c3e50; font-weight: 600; width: 100%;",
              target = "_blank"
            ),

            
            tags$a(
              "View Our Portfolio",
              href = "https://www.dalyanalytics.com",
              class = "btn btn-outline-light",
              style = "width: 100%;",
              target = "_blank"
            ),
            div(
              class = "mt-3",
              style = "color: rgba(255,255,255,0.7); font-size: 0.9rem;",
              icon("envelope"), " jasmine@dalyanalytics.com"
            )
          )
        )
      ),
      hr(style = "border-color: rgba(255,255,255,0.2); margin: 2rem 0;"),
      div(
        class = "text-center",
        style = "color: rgba(255,255,255,0.6);",
        p(
          class = "mb-0",
          "© 2025 Daly Analytics. This free tool was built to demonstrate our expertise in donor analytics. ",
          tags$a(
            "Contact us",
            href = "https://www.dalyanalytics.com/contact",
            style = "color: #bdc3c7;",
            target = "_blank"
          ),
          " to build automated retention tracking for your organization."
        )
      )
    )
  )
          ) # Close nav_panel
        ) # Close page_navbar
      ) # Close main-content div
  ) # Close main div
)

# Server
server <- function(input, output, session) {
  
  
  # Reactive values
  values <- reactiveValues(
    data_loaded = FALSE,
    gifts_data = NULL,
    metrics = NULL
  )
  
  # Load sample data
  observeEvent(input$load_sample, {
    values$gifts_data <- sample_data$gifts
    values$data_loaded <- TRUE
    updateSliderInput(session, "min_gift", 
                     max = max(sample_data$gifts$amount),
                     value = 0)
    
    showNotification("Sample data loaded successfully!", 
                    type = "message", duration = 3)
  })
  
  # File upload
  observeEvent(input$file, {
    req(input$file)
    
    tryCatch({
      df <- read.csv(input$file$datapath, stringsAsFactors = FALSE)
      
      # Validate required columns
      required_cols <- c("donor_id", "gift_date", "amount")
      if(!all(required_cols %in% names(df))) {
        showNotification("Error: CSV must contain columns: donor_id, gift_date, amount", 
                        type = "error", duration = 8)
        return()
      }
      
      # Convert and validate data
      df$gift_date <- as.Date(df$gift_date)
      df$amount <- as.numeric(df$amount)
      df$year <- year(df$gift_date)
      
      # Remove invalid rows
      df <- df[!is.na(df$gift_date) & !is.na(df$amount) & df$amount > 0, ]
      
      if(nrow(df) == 0) {
        showNotification("Error: No valid data found in CSV", type = "error", duration = 8)
        return()
      }
      
      values$gifts_data <- df
      values$data_loaded <- TRUE
      
      updateSliderInput(session, "min_gift", 
                       max = max(df$amount, na.rm = TRUE),
                       value = 0)
      
      showNotification(paste("Success! Loaded", nrow(df), "gift records."), 
                      type = "message", duration = 3)
      
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message), 
                      type = "error", duration = 8)
    })
  })
  
  # Calculate metrics reactively
  observe({
    req(values$gifts_data)
    
    # Filter data based on inputs
    filtered_data <- values$gifts_data %>%
      filter(amount >= input$min_gift)
    
    if(input$exclude_current_year) {
      filtered_data <- filtered_data %>%
        filter(year < year(Sys.Date()))
    }
    
    if(nrow(filtered_data) > 0) {
      values$metrics <- calculate_retention_metrics(filtered_data)
    }
  })
  
  # Output: Data loaded flag
  output$data_loaded <- reactive({
    values$data_loaded
  })
  outputOptions(output, "data_loaded", suspendWhenHidden = FALSE)
  
  # Output: Key metrics
  output$overall_retention <- renderText({
    req(values$metrics)
    paste0(values$metrics$overall_retention$retention_rate, "%")
  })
  
  output$total_donors <- renderText({
    req(values$metrics)
    format(nrow(values$metrics$donor_summary), big.mark = ",")
  })
  
  output$avg_gift <- renderText({
    req(values$metrics)
    paste0("$", format(round(values$metrics$avg_annual_gift, 0), big.mark = ","))
  })
  
  output$benchmark_comparison <- renderText({
    req(values$metrics)
    rate <- values$metrics$overall_retention$retention_rate
    
    if(rate >= 70) "Excellent performance!"
    else if(rate >= 50) "Good performance"
    else if(rate >= 35) "Average performance"
    else "Room for improvement"
  })
  
  # Output: LTV reactable
  output$ltv_reactable <- renderReactable({
    req(values$metrics)
    
    # Ensure we have valid metrics
    if(is.null(values$metrics$overall_retention) || is.null(values$metrics$avg_annual_gift)) {
      return(NULL)
    }
    
    retention_rate <- values$metrics$overall_retention$retention_rate / 100
    avg_gift <- values$metrics$avg_annual_gift
    
    # Ensure numeric values
    if(!is.numeric(retention_rate) || !is.numeric(avg_gift) || is.na(retention_rate) || is.na(avg_gift)) {
      return(NULL)
    }
    
    # Calculate year-by-year LTV for each scenario
    current_ret <- retention_rate
    improved_10 <- min(1, retention_rate + 0.1)
    improved_20 <- min(1, retention_rate + 0.2)
    best_practice <- 0.7
    
    scenarios <- data.frame(
      Scenario = c("Current Retention", "Improved by 10%", "Improved by 20%", "Best Practice (70%)"),
      retention_rate_num = c(
        retention_rate * 100,
        min(100, (retention_rate + 0.1) * 100),
        min(100, (retention_rate + 0.2) * 100),
        70.0
      ),
      ltv_value = c(
        avg_gift * (1 + current_ret^1 + current_ret^2 + current_ret^3 + current_ret^4),
        avg_gift * (1 + improved_10^1 + improved_10^2 + improved_10^3 + improved_10^4),
        avg_gift * (1 + improved_20^1 + improved_20^2 + improved_20^3 + improved_20^4),
        avg_gift * (1 + best_practice^1 + best_practice^2 + best_practice^3 + best_practice^4)
      ),
      # Calculate cumulative LTV for each year for sparklines
      year1 = rep(avg_gift, 4),
      year2 = c(
        avg_gift * (1 + current_ret^1),
        avg_gift * (1 + improved_10^1),
        avg_gift * (1 + improved_20^1),
        avg_gift * (1 + best_practice^1)
      ),
      year3 = c(
        avg_gift * (1 + current_ret^1 + current_ret^2),
        avg_gift * (1 + improved_10^1 + improved_10^2),
        avg_gift * (1 + improved_20^1 + improved_20^2),
        avg_gift * (1 + best_practice^1 + best_practice^2)
      ),
      year4 = c(
        avg_gift * (1 + current_ret^1 + current_ret^2 + current_ret^3),
        avg_gift * (1 + improved_10^1 + improved_10^2 + improved_10^3),
        avg_gift * (1 + improved_20^1 + improved_20^2 + improved_20^3),
        avg_gift * (1 + best_practice^1 + best_practice^2 + best_practice^3)
      ),
      year5 = c(
        avg_gift * (1 + current_ret^1 + current_ret^2 + current_ret^3 + current_ret^4),
        avg_gift * (1 + improved_10^1 + improved_10^2 + improved_10^3 + improved_10^4),
        avg_gift * (1 + improved_20^1 + improved_20^2 + improved_20^3 + improved_20^4),
        avg_gift * (1 + best_practice^1 + best_practice^2 + best_practice^3 + best_practice^4)
      ),
      ltv_trend = "sparkline_placeholder",
      stringsAsFactors = FALSE
    )
    
    reactable(
      scenarios,
      pagination = FALSE,
      striped = TRUE,
      bordered = TRUE,
      highlight = TRUE,
      columns = list(
        Scenario = colDef(
          width = 180,
          style = list(fontWeight = "600")
        ),
        retention_rate_num = colDef(
          name = "Retention Rate",
          width = 120,
          format = colFormat(suffix = "%", digits = 1),
          style = function(value) {
            if(is.na(value)) return(list())
            if (value >= 70) list(color = "#28a745", fontWeight = "600")
            else if (value >= 50) list(color = "#ffc107", fontWeight = "600")
            else if (value >= 35) list(color = "#fd7e14", fontWeight = "600")
            else list(color = "#dc3545", fontWeight = "600")
          }
        ),
        ltv_value = colDef(
          name = "5-Year LTV",
          width = 120,
          format = colFormat(prefix = "$", separators = TRUE, digits = 0),
          style = function(value) {
            if(is.na(value)) return(list())
            list(fontWeight = "600", color = "#2c3e50")
          }
        ),
        ltv_trend = colDef(
          name = "LTV Growth",
          width = 200,
          cell = function(value, index) {
            # Get the LTV values for this row
            row_data <- scenarios[index, ]
            ltv_values <- c(
              as.numeric(row_data$year1),
              as.numeric(row_data$year2),
              as.numeric(row_data$year3),
              as.numeric(row_data$year4),
              as.numeric(row_data$year5)
            )
            
            # Remove any NA values
            ltv_values <- ltv_values[!is.na(ltv_values)]
            
            if (length(ltv_values) >= 2) {
              # Color based on scenario
              line_color <- if(index == 1) {
                "#6c757d"  # Current - gray
              } else if(index == 2) {
                "#ffc107"  # 10% improvement - yellow
              } else if(index == 3) {
                "#fd7e14"  # 20% improvement - orange
              } else {
                "#28a745"  # Best practice - green
              }
              
              sparkline(
                values = ltv_values,
                type = "line",
                lineColor = line_color,
                fillColor = FALSE,
                spotColor = line_color,
                minSpotColor = line_color,
                maxSpotColor = line_color,
                spotRadius = 3,
                lineWidth = 3,
                width = 180,
                height = 40,
                chartRangeMin = min(ltv_values) * 0.95,
                chartRangeMax = max(ltv_values) * 1.05
              )
            } else {
              span("No data", style = "color: #6c757d; font-style: italic;")
            }
          }
        ),
        # Hide the year columns
        year1 = colDef(show = FALSE),
        year2 = colDef(show = FALSE),
        year3 = colDef(show = FALSE),
        year4 = colDef(show = FALSE),
        year5 = colDef(show = FALSE)
      ),
      theme = reactableTheme(
        borderColor = "#e9ecef",
        stripedColor = "#f8f9fa",
        highlightColor = "#f5f5f5",
        cellPadding = "12px 16px",
        style = list(
          fontFamily = "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
          fontSize = "15px"
        ),
        headerStyle = list(
          background = "#f8f9fa",
          color = "#495057",
          fontWeight = "600",
          borderBottom = "2px solid #dee2e6"
        )
      )
    )
  })
  
  # Output: Cohort table
  output$cohort_table <- renderReactable({
    req(values$metrics)
    
    # Ensure we have valid cohort data
    if(is.null(values$metrics$cohort_analysis) || nrow(values$metrics$cohort_analysis) == 0) {
      return(NULL)
    }
    
    cohort_data <- values$metrics$cohort_analysis %>%
      select(first_gift_year, total_donors, year_2_rate, year_3_rate, year_4_rate, year_5_rate) %>%
      # Ensure all rate columns are numeric
      mutate(
        across(contains("rate"), ~as.numeric(.x)),
        total_donors = as.numeric(total_donors),
        first_gift_year = as.numeric(first_gift_year)
      ) %>%
      # Remove any rows with invalid data
      filter(!is.na(first_gift_year) & !is.na(total_donors)) %>%
      # Rename for display
      select(`First Gift Year` = first_gift_year,
             `New Donors` = total_donors,
             `Year 2 Rate` = year_2_rate,
             `Year 3 Rate` = year_3_rate,
             `Year 4 Rate` = year_4_rate,
             `Year 5 Rate` = year_5_rate)
    
    # Return NULL if no valid data
    if(nrow(cohort_data) == 0) {
      return(NULL)
    }
    
    reactable(
      cohort_data,
      pagination = FALSE,
      striped = TRUE,
      bordered = TRUE,
      highlight = TRUE,
      defaultSorted = "First Gift Year",
      columns = list(
        `First Gift Year` = colDef(
          width = 120,
          style = list(fontWeight = "600")
        ),
        `New Donors` = colDef(
          width = 100,
          format = colFormat(separators = TRUE)
        ),
        `Year 2 Rate` = colDef(
          width = 100,
          format = colFormat(suffix = "%", digits = 1),
          style = function(value) {
            if(is.na(value)) return(list())
            if (value >= 60) list(color = "#28a745")
            else if (value >= 40) list(color = "#ffc107")
            else list(color = "#dc3545")
          }
        ),
        `Year 3 Rate` = colDef(
          width = 100,
          format = colFormat(suffix = "%", digits = 1),
          style = function(value) {
            if(is.na(value)) return(list())
            if (value >= 40) list(color = "#28a745")
            else if (value >= 25) list(color = "#ffc107")
            else list(color = "#dc3545")
          }
        ),
        `Year 4 Rate` = colDef(
          width = 100,
          format = colFormat(suffix = "%", digits = 1),
          style = function(value) {
            if(is.na(value)) return(list())
            if (value >= 30) list(color = "#28a745")
            else if (value >= 15) list(color = "#ffc107")
            else list(color = "#dc3545")
          }
        ),
        `Year 5 Rate` = colDef(
          width = 100,
          format = colFormat(suffix = "%", digits = 1),
          style = function(value) {
            if(is.na(value)) return(list())
            if (value >= 25) list(color = "#28a745")
            else if (value >= 10) list(color = "#ffc107")
            else list(color = "#dc3545")
          }
        )
      ),
      theme = reactableTheme(
        borderColor = "#e9ecef",
        stripedColor = "#f8f9fa",
        highlightColor = "#f5f5f5",
        cellPadding = "8px 12px",
        style = list(
          fontFamily = "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
          fontSize = "14px"
        ),
        headerStyle = list(
          background = "#f8f9fa",
          color = "#495057",
          fontWeight = "600",
          borderBottom = "2px solid #dee2e6"
        )
      )
    )
  })
  
  # Output: Cohort reactable with sparklines
  output$cohort_reactable <- renderReactable({
    req(values$metrics)
    
    # Keep original data for sparkline calculation
    original_cohort <- values$metrics$cohort_analysis %>%
      filter(total_donors >= 5)  # Only show cohorts with meaningful sample sizes
    
    cohort_data <- original_cohort %>%
      mutate(
        trend_direction = case_when(
          year_5_rate > year_2_rate ~ "Improving",
          year_5_rate < year_2_rate ~ "Declining",
          TRUE ~ "Stable"
        ),
        # Add placeholder column for sparklines
        `Retention Pattern` = "sparkline_placeholder"
      ) %>%
      select(
        `First Gift Year` = first_gift_year,
        `New Donors` = total_donors,
        `Latest Rate` = year_5_rate,
        `Trend` = trend_direction,
        `Retention Pattern`
      )
    
    reactable(
      cohort_data,
      pagination = FALSE,
      striped = TRUE,
      bordered = TRUE,
      highlight = TRUE,
      defaultSorted = "First Gift Year",
      columns = list(
        `First Gift Year` = colDef(
          width = 120,
          style = list(fontWeight = "600")
        ),
        `New Donors` = colDef(
          width = 100,
          format = colFormat(separators = TRUE)
        ),
        `Latest Rate` = colDef(
          width = 100,
          format = colFormat(suffix = "%", digits = 1),
          style = function(value) {
            if (is.na(value)) return(list())
            if (value >= 50) list(color = "#28a745", fontWeight = "600")
            else if (value >= 35) list(color = "#ffc107", fontWeight = "600") 
            else list(color = "#dc3545", fontWeight = "600")
          }
        ),
        `Trend` = colDef(
          width = 100,
          style = function(value) {
            if (is.na(value)) return(list())
            color <- case_when(
              value == "Improving" ~ "#28a745",
              value == "Declining" ~ "#dc3545",
              TRUE ~ "#6c757d"
            )
            list(color = color, fontWeight = "600")
          }
        ),
        `Retention Pattern` = colDef(
          width = 200,
          cell = function(value, index) {
            # Get the retention values from original data
            row_data <- original_cohort[index, ]
            retention_values <- c(
              as.numeric(row_data$year_2_rate),
              as.numeric(row_data$year_3_rate),
              as.numeric(row_data$year_4_rate),
              as.numeric(row_data$year_5_rate)
            )
            
            # Remove any NA values
            retention_values <- retention_values[!is.na(retention_values)]
            
            if (length(retention_values) >= 2) {
              sparkline(
                values = retention_values,
                type = "line",
                lineColor = "#F9B397",
                fillColor = FALSE,
                spotColor = "#D68A93",
                minSpotColor = "#dc3545",
                maxSpotColor = "#28a745",
                spotRadius = 3,
                lineWidth = 2,
                width = 180,
                height = 40
              )
            } else {
              span("Insufficient data", style = "color: #6c757d; font-style: italic;")
            }
          }
        )
      ),
      theme = reactableTheme(
        borderColor = "#e9ecef",
        stripedColor = "#f8f9fa",
        highlightColor = "#f5f5f5",
        cellPadding = "8px 12px",
        style = list(
          fontFamily = "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
          fontSize = "14px"
        ),
        headerStyle = list(
          background = "#f8f9fa",
          color = "#495057",
          fontWeight = "600",
          borderBottom = "2px solid #dee2e6"
        )
      )
    )
  })
  
  output$segment_table <- renderReactable({
    req(values$metrics)
    
    # Ensure we have valid donor summary data
    if(is.null(values$metrics$donor_summary) || nrow(values$metrics$donor_summary) == 0) {
      return(NULL)
    }
    
    segments <- values$metrics$donor_summary %>%
      # Ensure numeric columns
      mutate(
        years_active = as.numeric(years_active),
        total_amount = as.numeric(total_amount)
      ) %>%
      # Remove invalid rows
      filter(!is.na(years_active) & !is.na(total_amount) & total_amount > 0) %>%
      # Create segments
      mutate(
        segment = case_when(
          years_active == 1 & total_amount < 100 ~ "One-time Small",
          years_active == 1 & total_amount >= 100 ~ "One-time Large", 
          years_active %in% 2:3 ~ "Occasional",
          years_active >= 4 & total_amount/years_active < 200 ~ "Loyal Small",
          years_active >= 4 & total_amount/years_active >= 200 ~ "Major Donor",
          TRUE ~ "Other"
        )
      ) %>%
      group_by(segment) %>%
      summarise(
        donors = n(),
        avg_annual = round(mean(total_amount/years_active, na.rm = TRUE), 0),
        total_value = round(sum(total_amount, na.rm = TRUE), 0),
        .groups = 'drop'
      ) %>%
      # Calculate percentages safely
      mutate(
        pct_donors = round(donors/sum(donors, na.rm = TRUE)*100, 1),
        pct_value = round(total_value/sum(total_value, na.rm = TRUE)*100, 1),
        # Add sparkline visual column
        trend_visual = "sparkline_placeholder"
      ) %>%
      # Ensure no NA values in final data
      filter(!is.na(donors) & !is.na(avg_annual) & !is.na(total_value)) %>%
      select(`Donor Segment` = segment,
             `Count` = donors,
             `Avg Annual Gift` = avg_annual,
             `Total Value` = total_value,
             `% of Donors` = pct_donors,
             `% of Revenue` = pct_value,
             `Donor vs Revenue` = trend_visual)
    
    # Return NULL if no valid segments
    if(nrow(segments) == 0) {
      return(NULL)
    }
    
    reactable(
      segments,
      pagination = FALSE,
      striped = TRUE,
      bordered = TRUE,
      highlight = TRUE,
      defaultSorted = "% of Revenue",
      defaultSortOrder = "desc",
      columns = list(
        `Donor Segment` = colDef(
          width = 130,
          style = list(fontWeight = "600")
        ),
        `Count` = colDef(
          width = 70,
          format = colFormat(separators = TRUE)
        ),
        `Avg Annual Gift` = colDef(
          width = 110,
          format = colFormat(prefix = "$", separators = TRUE, digits = 0)
        ),
        `Total Value` = colDef(
          width = 100,
          format = colFormat(prefix = "$", separators = TRUE, digits = 0),
          style = list(fontWeight = "600")
        ),
        `% of Donors` = colDef(
          width = 90,
          format = colFormat(suffix = "%", digits = 1),
          style = function(value) {
            if(is.na(value)) return(list())
            if (value >= 50) list(color = "#dc3545", fontWeight = "600")
            else if (value >= 20) list(color = "#ffc107", fontWeight = "600")
            else list(color = "#28a745", fontWeight = "600")
          }
        ),
        `% of Revenue` = colDef(
          width = 90,
          format = colFormat(suffix = "%", digits = 1),
          style = function(value) {
            if(is.na(value)) return(list())
            if (value >= 40) list(color = "#28a745", fontWeight = "600")
            else if (value >= 20) list(color = "#ffc107", fontWeight = "600")
            else list(color = "#dc3545", fontWeight = "600")
          }
        ),
        `Donor vs Revenue` = colDef(
          width = 180,
          cell = function(value, index) {
            # Get the balance data for this row
            row_data <- segments[index, ]
            donor_pct <- as.numeric(row_data$`% of Donors`)
            revenue_pct <- as.numeric(row_data$`% of Revenue`)
            
            if(!is.na(donor_pct) && !is.na(revenue_pct)) {
              # Create a simple bar chart showing donor % vs revenue %
              balance_values <- c(donor_pct, revenue_pct)
              
              # Color based on efficiency (revenue per donor)
              efficiency <- revenue_pct / donor_pct
              bar_color <- if(efficiency > 2) {
                "#28a745"  # High efficiency - green
              } else if(efficiency > 1) {
                "#ffc107"  # Medium efficiency - yellow
              } else {
                "#dc3545"  # Low efficiency - red
              }
              
              sparkline(
                values = balance_values,
                type = "bar",
                barColor = bar_color,
                width = 160,
                height = 30,
                chartRangeMin = 0,
                tooltipFormat = paste0(
                  "<span style='color: {{color}}'>{{offset:names}}: {{value}}%</span>"
                ),
                tooltipValueLookups = list(names = c("Donors", "Revenue"))
              )
            } else {
              span("No data", style = "color: #6c757d; font-style: italic;")
            }
          }
        )
      ),
      theme = reactableTheme(
        borderColor = "#e9ecef",
        stripedColor = "#f8f9fa",
        highlightColor = "#f5f5f5",
        cellPadding = "8px 12px",
        style = list(
          fontFamily = "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
          fontSize = "14px"
        ),
        headerStyle = list(
          background = "#f8f9fa",
          color = "#495057",
          fontWeight = "600",
          borderBottom = "2px solid #dee2e6"
        )
      )
    )
  })
}

# Run the app
shinyApp(ui = ui, server = server)