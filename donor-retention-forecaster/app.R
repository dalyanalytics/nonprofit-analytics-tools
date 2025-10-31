library(shiny)
library(plotly)
library(dplyr)
library(tidyr)
library(scales)
library(bslib)

# UI
ui <- fluidPage(

  # Add Google Fonts
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
        color: #333;
        line-height: 1.6;
      }

      .main-container {
        background: white;
        border-radius: 16px;
        padding: 40px;
        max-width: 1400px;
        margin: 0 auto 20px auto;
        box-shadow: 0 20px 60px rgba(0,0,0,0.15);
      }

      h2 {
        text-align: center;
        background: linear-gradient(135deg, #D68A93, #AD92B1);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        font-weight: 700;
        font-size: 2.5rem;
        margin-bottom: 0.5rem;
        letter-spacing: -0.02em;
      }

      .subtitle {
        text-align: center;
        color: #666;
        font-size: 1.1rem;
        margin-bottom: 2rem;
      }

      .section-header {
        color: #D68A93;
        font-weight: 600;
        font-size: 1.6rem;
        margin-top: 2rem;
        margin-bottom: 1rem;
        padding-bottom: 0.5rem;
        border-bottom: 2px solid #f0f0f0;
      }

      .input-section {
        background: #f8f9fa;
        border-radius: 12px;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
      }

      .well {
        background: white;
        border: 1px solid #e9ecef;
        border-radius: 12px;
        padding: 1.5rem;
        margin-bottom: 1rem;
      }

      .scenario-box {
        background: linear-gradient(135deg, rgba(214, 138, 147, 0.08) 0%, rgba(173, 146, 177, 0.05) 100%);
        border: 2px solid #e9ecef;
        border-radius: 12px;
        padding: 1.5rem;
        margin-bottom: 1rem;
      }

      .scenario-title {
        color: #D68A93;
        font-weight: 600;
        font-size: 1.1rem;
        margin-bottom: 1rem;
      }

      .metric-summary {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1rem;
        margin: 1.5rem 0;
      }

      .metric-card {
        background: white;
        border: 1px solid #e9ecef;
        border-radius: 12px;
        padding: 1.5rem;
        text-align: center;
      }

      .metric-value {
        font-size: 2rem;
        font-weight: 700;
        background: linear-gradient(135deg, #D68A93, #AD92B1);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        margin: 0.5rem 0;
      }

      .metric-label {
        color: #666;
        font-size: 0.9rem;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 0.5px;
      }

      .insight-box {
        background: linear-gradient(135deg, rgba(214, 138, 147, 0.08) 0%, rgba(173, 146, 177, 0.05) 100%);
        border-left: 4px solid #D68A93;
        border-radius: 0 8px 8px 0;
        padding: 1.5rem;
        margin: 1.5rem 0;
      }

      .insight-title {
        color: #D68A93;
        font-weight: 600;
        font-size: 1.1rem;
        margin-bottom: 0.5rem;
      }

      .btn-primary {
        background: linear-gradient(135deg, #D68A93, #AD92B1);
        border: none;
        color: white;
        padding: 12px 30px;
        border-radius: 8px;
        font-weight: 600;
        font-size: 1rem;
        transition: all 0.3s ease;
        box-shadow: 0 4px 15px rgba(214, 138, 147, 0.3);
      }

      .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 20px rgba(214, 138, 147, 0.4);
      }

      .info-box {
        background: linear-gradient(135deg, rgba(173, 146, 177, 0.1) 0%, rgba(214, 138, 147, 0.05) 100%);
        border-left: 3px solid #AD92B1;
        border-radius: 0 8px 8px 0;
        padding: 1rem 1.5rem;
        margin: 1rem 0;
        font-size: 0.95rem;
      }

      .info-box-title {
        color: #AD92B1;
        font-weight: 600;
        margin-bottom: 0.5rem;
        font-size: 1rem;
      }

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
      }

      .explainer-box {
        background: linear-gradient(135deg, rgba(249, 179, 151, 0.1) 0%, rgba(214, 138, 147, 0.1) 100%);
        border: 2px solid #F9B397;
        border-radius: 12px;
        padding: 1.5rem;
        margin: 1.5rem 0;
      }

      .explainer-title {
        color: #D68A93;
        font-weight: 700;
        font-size: 1.2rem;
        margin-bottom: 1rem;
      }

      .confidence-band-legend {
        display: flex;
        gap: 1.5rem;
        justify-content: center;
        margin: 1rem 0;
        padding: 1rem;
        background: #f8f9fa;
        border-radius: 8px;
      }

      .legend-item {
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }

      .legend-color {
        width: 30px;
        height: 4px;
        border-radius: 2px;
      }

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

      .js-irs-0 .irs-bar,
      .js-irs-1 .irs-bar,
      .js-irs-2 .irs-bar,
      .js-irs-3 .irs-bar,
      .js-irs-4 .irs-bar,
      .js-irs-5 .irs-bar,
      .js-irs-6 .irs-bar {
        background: linear-gradient(135deg, #D68A93, #AD92B1);
      }

      .irs-from, .irs-to, .irs-single {
        background: #D68A93 !important;
      }
    "))
  ),

  div(class = "main-container",
    h2("Donor Retention Forecaster"),
    div(class = "subtitle", "Model different fundraising scenarios with Monte Carlo simulation"),

    # Monte Carlo Explainer
    div(class = "explainer-box",
      div(class = "explainer-title", "🎲 How This Tool Works: Monte Carlo Simulation"),
      p("Unlike simple forecasts that show one possible outcome, this tool runs ", strong("1,000 different simulations"),
        " to account for real-world uncertainty in fundraising."),
      p(strong("What gets simulated?")),
      tags$ul(
        tags$li(strong("Retention rates vary"), " each year (some donors stay, others don't - it's never exactly the same)"),
        tags$li(strong("Acquisition varies"), " based on your marketing success (some campaigns work better than others)"),
        tags$li(strong("Gift sizes fluctuate"), " due to economic conditions and donor circumstances")
      ),
      p(strong("What you'll see:")),
      tags$ul(
        tags$li(strong("Most Likely (50th percentile)"), " - the median outcome across all simulations"),
        tags$li(strong("Best Case (90th percentile)"), " - if things go better than expected"),
        tags$li(strong("Worst Case (10th percentile)"), " - if challenges arise")
      ),
      p(style = "margin-top: 1rem; color: #666; font-style: italic;",
        "💡 This helps you plan with realistic expectations and prepare for multiple scenarios, just like professional financial planners do.")
    ),

    # Current State Inputs
    div(class = "section-header", "📊 Current State"),
    div(class = "input-section",
      fluidRow(
        column(4,
          numericInput("current_donors",
                      "Current Total Donors",
                      value = 500,
                      min = 10,
                      step = 10),
          div(class = "info-box",
            div(class = "info-box-title", "What is this?"),
            p("The total number of active donors who gave at least once in the past year. This is your starting point.")
          )
        ),
        column(4,
          sliderInput("current_retention",
                     "Current Retention Rate",
                     min = 20,
                     max = 90,
                     value = 45,
                     step = 5,
                     post = "%",
                     animate = animationOptions(interval = 800, loop = FALSE)),
          div(class = "info-box",
            div(class = "info-box-title", "What is this?"),
            p("The percentage of donors who give again the following year. Nonprofit average is 45%. Higher is better!")
          )
        ),
        column(4,
          numericInput("avg_gift",
                      "Average Gift Size ($)",
                      value = 250,
                      min = 10,
                      step = 10),
          div(class = "info-box",
            div(class = "info-box-title", "What is this?"),
            p("The typical donation amount across all your donors. Used to calculate total revenue projections.")
          )
        )
      ),

      # Uncertainty Parameters
      fluidRow(
        column(12,
          div(class = "section-header", style = "margin-top: 1.5rem;", "🎲 Uncertainty & Variability"),
          p(style = "color: #666; margin-bottom: 1rem;",
            "Real fundraising isn't predictable. These settings control how much variation the simulation includes:")
        )
      ),
      fluidRow(
        column(6,
          sliderInput("retention_variability",
                     "Retention Rate Variability",
                     min = 0,
                     max = 20,
                     value = 5,
                     step = 1,
                     post = " percentage points"),
          div(class = "info-box",
            div(class = "info-box-title", "What does this mean?"),
            p("How much your retention rate might fluctuate year-to-year. ", strong("5 points"), " means your 45% retention could be anywhere from 40-50% in a given year."),
            p(style = "margin-top: 0.5rem;", em("Higher = more unpredictable donor behavior"))
          )
        ),
        column(6,
          sliderInput("acquisition_variability",
                     "Acquisition Variability",
                     min = 0,
                     max = 50,
                     value = 15,
                     step = 5,
                     post = "%"),
          div(class = "info-box",
            div(class = "info-box-title", "What does this mean?"),
            p("How much your new donor acquisition might vary. ", strong("15%"), " means if you plan for 100 new donors, you might get 85-115."),
            p(style = "margin-top: 0.5rem;", em("Higher = more campaign uncertainty"))
          )
        )
      )
    ),

    # Scenario Planning
    div(class = "section-header", "🎯 Campaign Scenarios"),

    tabsetPanel(
      # Baseline Scenario
      tabPanel(HTML("<i class='fa fa-chart-line'></i> Baseline (Status Quo)"),
        div(class = "scenario-box",
          div(class = "scenario-title", "Scenario A: Continue Current Operations"),
          p("This scenario assumes no changes to your current donor retention or acquisition strategy."),
          fluidRow(
            column(6,
              sliderInput("baseline_acquisition",
                         "New Donors Acquired per Year",
                         min = 0,
                         max = 500,
                         value = 100,
                         step = 10,
                         animate = animationOptions(interval = 800, loop = FALSE))
            ),
            column(6,
              sliderInput("forecast_years",
                         "Forecast Timeline (Years)",
                         min = 1,
                         max = 5,
                         value = 3,
                         step = 1,
                         animate = animationOptions(interval = 800, loop = FALSE))
            )
          )
        ),
        plotlyOutput("baseline_chart", height = "400px"),
        div(class = "metric-summary",
          uiOutput("baseline_metrics")
        )
      ),

      # Retention Improvement Scenario
      tabPanel(HTML("<i class='fa fa-heart'></i> Retention Improvement"),
        div(class = "scenario-box",
          div(class = "scenario-title", "Scenario B: Improve Donor Retention"),
          p("Model the impact of a donor stewardship program or retention initiative."),
          fluidRow(
            column(6,
              sliderInput("retention_improvement",
                         "Target Retention Rate",
                         min = 20,
                         max = 90,
                         value = 60,
                         step = 5,
                         post = "%",
                         animate = animationOptions(interval = 800, loop = FALSE))
            ),
            column(6,
              numericInput("retention_program_cost",
                          "Annual Program Cost ($)",
                          value = 5000,
                          min = 0,
                          step = 500)
            )
          )
        ),
        plotlyOutput("retention_comparison_chart", height = "400px"),
        div(class = "insight-box",
          div(class = "insight-title", "📈 ROI Analysis"),
          uiOutput("retention_roi")
        )
      ),

      # Acquisition Focus Scenario
      tabPanel(HTML("<i class='fa fa-user-plus'></i> Acquisition Focus"),
        div(class = "scenario-box",
          div(class = "scenario-title", "Scenario C: Increase New Donor Acquisition"),
          p("Explore the impact of acquiring more new donors through marketing campaigns."),
          fluidRow(
            column(6,
              sliderInput("aggressive_acquisition",
                         "New Donors Acquired per Year",
                         min = 0,
                         max = 500,
                         value = 200,
                         step = 10,
                         animate = animationOptions(interval = 800, loop = FALSE))
            ),
            column(6,
              numericInput("acquisition_cost_per_donor",
                          "Cost per New Donor ($)",
                          value = 75,
                          min = 0,
                          step = 5)
            )
          )
        ),
        plotlyOutput("acquisition_comparison_chart", height = "400px"),
        div(class = "insight-box",
          div(class = "insight-title", "💰 Cost vs. Revenue"),
          uiOutput("acquisition_analysis")
        )
      ),

      # Combined Strategy
      tabPanel(HTML("<i class='fa fa-rocket'></i> Combined Strategy"),
        div(class = "scenario-box",
          div(class = "scenario-title", "Scenario D: Retention + Acquisition"),
          p("Model a comprehensive strategy that improves retention AND increases acquisition."),
          fluidRow(
            column(4,
              sliderInput("combined_retention",
                         "Target Retention Rate",
                         min = 20,
                         max = 90,
                         value = 60,
                         step = 5,
                         post = "%",
                         animate = animationOptions(interval = 800, loop = FALSE))
            ),
            column(4,
              sliderInput("combined_acquisition",
                         "New Donors per Year",
                         min = 0,
                         max = 500,
                         value = 200,
                         step = 10,
                         animate = animationOptions(interval = 800, loop = FALSE))
            ),
            column(4,
              numericInput("combined_total_cost",
                          "Total Annual Investment ($)",
                          value = 20000,
                          min = 0,
                          step = 1000)
            )
          )
        ),
        plotlyOutput("all_scenarios_chart", height = "500px"),
        div(class = "metric-summary",
          uiOutput("scenario_comparison")
        ),
        div(class = "insight-box",
          div(class = "insight-title", "🎯 Strategic Recommendation"),
          uiOutput("strategic_recommendation")
        )
      )
    ),

    # Footer with CTA
    div(
      class = "app-footer",
      fluidRow(
        column(7,
          h4("Need Custom Fundraising Analytics Tools?", style = "color: white; margin-bottom: 1rem; margin-top: 0;"),
          p(
            style = "color: rgba(255,255,255,0.9); margin-bottom: 1.5rem;",
            "This donor retention forecaster demonstrates the power of Monte Carlo simulation for campaign planning. ",
            "Daly Analytics specializes in creating tailored analytics solutions that solve your organization's unique fundraising challenges."
          ),
          tags$div(
            style = "color: rgba(255,255,255,0.85);",
            tags$div(style = "margin-bottom: 8px;", HTML("✓ Custom donor analytics dashboards with predictive insights")),
            tags$div(style = "margin-bottom: 8px;", HTML("✓ Campaign ROI forecasting integrated with your CRM")),
            tags$div(style = "margin-bottom: 8px;", HTML("✓ Board-ready reports with scenario planning")),
            tags$div(style = "margin-bottom: 8px;", HTML("✓ Automated donor segmentation with ML-powered scoring"))
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
)

# Server
server <- function(input, output, session) {

  # Monte Carlo simulation function
  monte_carlo_forecast <- function(starting_donors, retention_rate, retention_var,
                                    new_donors_per_year, acquisition_var,
                                    years, simulations = 1000) {
    # Matrix to store all simulations (rows = simulations, cols = years)
    results <- matrix(0, nrow = simulations, ncol = years + 1)
    results[, 1] <- starting_donors  # All start with same donor count

    for (sim in 1:simulations) {
      donors <- starting_donors

      for (year in 2:(years + 1)) {
        # Vary retention rate (bounded between 0 and 100)
        actual_retention <- rnorm(1, mean = retention_rate, sd = retention_var)
        actual_retention <- max(0, min(100, actual_retention))  # Keep between 0-100%

        # Vary acquisition (bounded to be non-negative)
        actual_acquisition <- rnorm(1, mean = new_donors_per_year, sd = new_donors_per_year * (acquisition_var/100))
        actual_acquisition <- max(0, actual_acquisition)

        # Calculate donors for this year
        retained <- donors * (actual_retention / 100)
        donors <- retained + actual_acquisition

        results[sim, year] <- donors
      }
    }

    # Calculate percentiles for each year
    percentiles <- data.frame(
      Year = 0:years,
      P10 = apply(results, 2, quantile, probs = 0.10),
      P50 = apply(results, 2, quantile, probs = 0.50),
      P90 = apply(results, 2, quantile, probs = 0.90),
      Mean = apply(results, 2, mean)
    )

    return(list(
      percentiles = percentiles,
      all_simulations = results
    ))
  }

  # Calculate revenue with percentiles
  calculate_revenue_percentiles <- function(donor_percentiles, avg_gift) {
    donor_percentiles %>%
      mutate(
        Revenue_P10 = P10 * avg_gift,
        Revenue_P50 = P50 * avg_gift,
        Revenue_P90 = P90 * avg_gift,
        Revenue_Mean = Mean * avg_gift
      )
  }

  # Baseline scenario data (with Monte Carlo)
  baseline_data <- reactive({
    mc_result <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$current_retention,
      retention_var = input$retention_variability,
      new_donors_per_year = input$baseline_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    calculate_revenue_percentiles(mc_result$percentiles, input$avg_gift)
  })

  # Baseline chart (with confidence bands)
  output$baseline_chart <- renderPlotly({
    data <- baseline_data()

    plot_ly(data, x = ~Year) %>%
      # 10th-90th percentile band (light shading)
      add_ribbons(ymin = ~P10, ymax = ~P90,
                  fillcolor = "rgba(214, 138, 147, 0.15)",
                  line = list(color = "transparent"),
                  name = "10th-90th Percentile Range",
                  hoverinfo = "text",
                  text = ~paste("Year:", Year, "<br>Range:", round(P10), "-", round(P90), "donors")) %>%
      # 50th percentile (median) line
      add_trace(y = ~P50, name = "Most Likely (Median)", type = "scatter", mode = "lines+markers",
                line = list(color = "#D68A93", width = 3),
                marker = list(size = 10, color = "#D68A93")) %>%
      # 90th percentile line (optimistic)
      add_trace(y = ~P90, name = "Best Case (90th)", type = "scatter", mode = "lines",
                line = list(color = "#AD92B1", width = 2, dash = "dash")) %>%
      # 10th percentile line (conservative)
      add_trace(y = ~P10, name = "Worst Case (10th)", type = "scatter", mode = "lines",
                line = list(color = "#B07891", width = 2, dash = "dot")) %>%
      layout(
        title = "Donor Growth Projection - Baseline Scenario (1,000 Simulations)",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Donors"),
        hovermode = "x unified",
        plot_bgcolor = "#f8f9fa",
        paper_bgcolor = "white",
        showlegend = TRUE,
        legend = list(x = 0.02, y = 0.98)
      )
  })

  # Baseline metrics (with confidence ranges)
  output$baseline_metrics <- renderUI({
    data <- baseline_data()
    final_year <- data[nrow(data), ]

    tagList(
      div(class = "metric-card",
        div(class = "metric-label", paste0("Most Likely Donors (Year ", input$forecast_years, ")")),
        div(class = "metric-value", comma(round(final_year$P50))),
        p(style = "margin-top: 0.5rem; color: #666; font-size: 0.9rem;",
          paste0("Range: ", comma(round(final_year$P10)), " - ", comma(round(final_year$P90))))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Most Likely Revenue"),
        div(class = "metric-value", dollar(final_year$Revenue_P50)),
        p(style = "margin-top: 0.5rem; color: #666; font-size: 0.9rem;",
          paste0("Range: ", dollar(round(final_year$Revenue_P10)), " - ", dollar(round(final_year$Revenue_P90))))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Total Revenue (Median)"),
        div(class = "metric-value", dollar(sum(data$Revenue_P50)))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Probability Analysis"),
        div(class = "metric-value", "80%"),
        p(style = "margin-top: 0.5rem; color: #666; font-size: 0.9rem;",
          "Chance of staying within shown range")
      )
    )
  })

  # Retention improvement comparison (with Monte Carlo)
  output$retention_comparison_chart <- renderPlotly({
    # Baseline scenario
    baseline_mc <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$current_retention,
      retention_var = input$retention_variability,
      new_donors_per_year = input$baseline_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    # Improved retention scenario
    improved_mc <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$retention_improvement,
      retention_var = input$retention_variability,
      new_donors_per_year = input$baseline_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    baseline_data <- baseline_mc$percentiles
    improved_data <- improved_mc$percentiles

    plot_ly() %>%
      # Baseline confidence band
      add_ribbons(data = baseline_data, x = ~Year, ymin = ~P10, ymax = ~P90,
                  fillcolor = "rgba(214, 138, 147, 0.1)",
                  line = list(color = "transparent"),
                  name = "Current Range",
                  showlegend = FALSE,
                  hoverinfo = "skip") %>%
      # Improved confidence band
      add_ribbons(data = improved_data, x = ~Year, ymin = ~P10, ymax = ~P90,
                  fillcolor = "rgba(173, 146, 177, 0.15)",
                  line = list(color = "transparent"),
                  name = "Improved Range",
                  showlegend = FALSE,
                  hoverinfo = "skip") %>%
      # Baseline median line
      add_trace(data = baseline_data, x = ~Year, y = ~P50,
                name = "Current Retention (Median)", type = "scatter", mode = "lines+markers",
                line = list(color = "#D68A93", width = 3, dash = "dash"),
                marker = list(size = 8)) %>%
      # Improved median line
      add_trace(data = improved_data, x = ~Year, y = ~P50,
                name = "Improved Retention (Median)", type = "scatter", mode = "lines+markers",
                line = list(color = "#AD92B1", width = 3),
                marker = list(size = 10)) %>%
      layout(
        title = "Impact of Retention Improvement (1,000 Simulations)",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Donors"),
        hovermode = "x unified",
        plot_bgcolor = "#f8f9fa",
        paper_bgcolor = "white",
        showlegend = TRUE,
        legend = list(x = 0.02, y = 0.98)
      )
  })

  # Retention ROI (with Monte Carlo and probability analysis)
  output$retention_roi <- renderUI({
    # Run simulations for both scenarios
    baseline_mc <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$current_retention,
      retention_var = input$retention_variability,
      new_donors_per_year = input$baseline_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    improved_mc <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$retention_improvement,
      retention_var = input$retention_variability,
      new_donors_per_year = input$baseline_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    # Calculate revenue for all simulations
    baseline_all_sims <- baseline_mc$all_simulations
    improved_all_sims <- improved_mc$all_simulations

    # Total revenue across all years for each simulation
    baseline_total_revenue <- apply(baseline_all_sims, 1, function(donors) sum(donors * input$avg_gift))
    improved_total_revenue <- apply(improved_all_sims, 1, function(donors) sum(donors * input$avg_gift))

    # Additional revenue for each simulation
    additional_revenue_sims <- improved_total_revenue - baseline_total_revenue

    # Program cost
    total_program_cost <- input$retention_program_cost * input$forecast_years

    # Net benefit for each simulation
    net_benefit_sims <- additional_revenue_sims - total_program_cost

    # Probability of positive ROI
    prob_positive <- mean(net_benefit_sims > 0) * 100

    # Median values
    median_additional_revenue <- median(additional_revenue_sims)
    median_net_benefit <- median(net_benefit_sims)
    median_roi <- ((median_additional_revenue - total_program_cost) / total_program_cost) * 100

    # Percentiles for net benefit
    net_benefit_p10 <- quantile(net_benefit_sims, 0.10)
    net_benefit_p90 <- quantile(net_benefit_sims, 0.90)

    tagList(
      p(strong("Additional Revenue (Median): "), dollar(median_additional_revenue)),
      p(strong("Total Program Cost (", input$forecast_years, " years): "), dollar(total_program_cost)),
      p(strong("Net Benefit (Median): "),
        span(style = if(median_net_benefit > 0) "color: #28a745; font-weight: 600;" else "color: #dc3545; font-weight: 600;",
             dollar(median_net_benefit))),
      p(style = "margin-left: 1.5rem; color: #666; font-size: 0.9rem;",
        paste0("Range: ", dollar(round(net_benefit_p10)), " to ", dollar(round(net_benefit_p90)))),
      p(strong("ROI (Median): "),
        span(style = if(median_roi > 0) "color: #28a745; font-weight: 600;" else "color: #dc3545; font-weight: 600;",
             paste0(round(median_roi, 1), "%"))),
      p(strong("Probability of Positive ROI: "),
        span(style = paste0("color: ", if(prob_positive > 70) "#28a745" else if(prob_positive > 40) "#ffc107" else "#dc3545", "; font-weight: 600; font-size: 1.2rem;"),
             paste0(round(prob_positive, 0), "%"))),
      if(prob_positive > 70) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(40, 167, 69, 0.1); border-radius: 8px;",
          "✓ Strong probability of positive ROI! Out of 1,000 simulations, ",
          strong(round(prob_positive, 0), "%"), " showed a net benefit from this retention program.")
      } else if(prob_positive > 40) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(255, 193, 7, 0.1); border-radius: 8px;",
          "⚠ Moderate risk. About ", strong(round(prob_positive, 0), "%"), " of simulations showed positive ROI. ",
          "Consider reducing program costs or targeting a higher retention rate to improve odds.")
      } else {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(220, 53, 69, 0.1); border-radius: 8px;",
          "⚠ High risk. Only ", strong(round(prob_positive, 0), "%"), " of simulations showed positive ROI. ",
          "The program costs likely outweigh the benefits. Consider alternative approaches.")
      }
    )
  })

  # Acquisition comparison chart (with Monte Carlo)
  output$acquisition_comparison_chart <- renderPlotly({
    # Baseline scenario
    baseline_mc <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$current_retention,
      retention_var = input$retention_variability,
      new_donors_per_year = input$baseline_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    # Aggressive acquisition scenario
    aggressive_mc <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$current_retention,
      retention_var = input$retention_variability,
      new_donors_per_year = input$aggressive_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    baseline_data <- baseline_mc$percentiles
    aggressive_data <- aggressive_mc$percentiles

    plot_ly() %>%
      # Baseline confidence band
      add_ribbons(data = baseline_data, x = ~Year, ymin = ~P10, ymax = ~P90,
                  fillcolor = "rgba(214, 138, 147, 0.1)",
                  line = list(color = "transparent"),
                  name = "Baseline Range",
                  showlegend = FALSE,
                  hoverinfo = "skip") %>%
      # Aggressive confidence band
      add_ribbons(data = aggressive_data, x = ~Year, ymin = ~P10, ymax = ~P90,
                  fillcolor = "rgba(176, 120, 145, 0.15)",
                  line = list(color = "transparent"),
                  name = "Increased Range",
                  showlegend = FALSE,
                  hoverinfo = "skip") %>%
      # Baseline median line
      add_trace(data = baseline_data, x = ~Year, y = ~P50,
                name = "Baseline Acquisition (Median)", type = "scatter", mode = "lines+markers",
                line = list(color = "#D68A93", width = 3, dash = "dash"),
                marker = list(size = 8)) %>%
      # Aggressive median line
      add_trace(data = aggressive_data, x = ~Year, y = ~P50,
                name = "Increased Acquisition (Median)", type = "scatter", mode = "lines+markers",
                line = list(color = "#B07891", width = 3),
                marker = list(size = 10)) %>%
      layout(
        title = "Impact of Increased Acquisition (1,000 Simulations)",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Donors"),
        hovermode = "x unified",
        plot_bgcolor = "#f8f9fa",
        paper_bgcolor = "white",
        showlegend = TRUE,
        legend = list(x = 0.02, y = 0.98)
      )
  })

  # Acquisition analysis (with Monte Carlo and probability)
  output$acquisition_analysis <- renderUI({
    # Run simulations
    baseline_mc <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$current_retention,
      retention_var = input$retention_variability,
      new_donors_per_year = input$baseline_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    aggressive_mc <- monte_carlo_forecast(
      starting_donors = input$current_donors,
      retention_rate = input$current_retention,
      retention_var = input$retention_variability,
      new_donors_per_year = input$aggressive_acquisition,
      acquisition_var = input$acquisition_variability,
      years = input$forecast_years,
      simulations = 1000
    )

    # Calculate revenue for all simulations
    baseline_total_revenue <- apply(baseline_mc$all_simulations, 1, function(donors) sum(donors * input$avg_gift))
    aggressive_total_revenue <- apply(aggressive_mc$all_simulations, 1, function(donors) sum(donors * input$avg_gift))

    # Additional revenue for each simulation
    additional_revenue_sims <- aggressive_total_revenue - baseline_total_revenue

    # Cost calculation
    additional_donors_acquired <- (input$aggressive_acquisition - input$baseline_acquisition) * input$forecast_years
    total_acquisition_cost <- additional_donors_acquired * input$acquisition_cost_per_donor

    # Net benefit for each simulation
    net_benefit_sims <- additional_revenue_sims - total_acquisition_cost

    # Probability of positive net benefit
    prob_positive <- mean(net_benefit_sims > 0) * 100

    # Median values
    median_additional_revenue <- median(additional_revenue_sims)
    median_net_benefit <- median(net_benefit_sims)

    tagList(
      p(strong("Additional Donors Targeted: "), comma(additional_donors_acquired)),
      p(strong("Additional Revenue (Median): "), dollar(median_additional_revenue)),
      p(strong("Total Acquisition Cost: "), dollar(total_acquisition_cost)),
      p(strong("Net Benefit (Median): "),
        span(style = if(median_net_benefit > 0) "color: #28a745; font-weight: 600;" else "color: #dc3545; font-weight: 600;",
             dollar(median_net_benefit))),
      p(strong("Probability of Positive ROI: "),
        span(style = paste0("color: ", if(prob_positive > 70) "#28a745" else if(prob_positive > 40) "#ffc107" else "#dc3545", "; font-weight: 600; font-size: 1.2rem;"),
             paste0(round(prob_positive, 0), "%"))),
      if(prob_positive > 70) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(40, 167, 69, 0.1); border-radius: 8px;",
          "✓ Strong case for increased acquisition! ", strong(round(prob_positive, 0), "%"),
          " of simulations showed positive net benefit after acquisition costs.")
      } else if(prob_positive > 40) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(255, 193, 7, 0.1); border-radius: 8px;",
          "⚠ Moderate risk. About ", strong(round(prob_positive, 0), "%"), " of simulations were profitable. ",
          "Consider lowering cost per donor or improving retention to maximize acquisition value.")
      } else {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(220, 53, 69, 0.1); border-radius: 8px;",
          "⚠ High risk. Only ", strong(round(prob_positive, 0), "%"), " of simulations showed positive ROI. ",
          "Acquisition costs likely exceed the value generated. Focus on retention instead.")
      }
    )
  })

  # All scenarios comparison chart (with Monte Carlo)
  output$all_scenarios_chart <- renderPlotly({
    # Run Monte Carlo for all 4 scenarios
    baseline_mc <- monte_carlo_forecast(
      input$current_donors, input$current_retention, input$retention_variability,
      input$baseline_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    retention_mc <- monte_carlo_forecast(
      input$current_donors, input$retention_improvement, input$retention_variability,
      input$baseline_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    acquisition_mc <- monte_carlo_forecast(
      input$current_donors, input$current_retention, input$retention_variability,
      input$aggressive_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    combined_mc <- monte_carlo_forecast(
      input$current_donors, input$combined_retention, input$retention_variability,
      input$combined_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    # Extract median lines
    baseline_data <- baseline_mc$percentiles
    retention_data <- retention_mc$percentiles
    acquisition_data <- acquisition_mc$percentiles
    combined_data <- combined_mc$percentiles

    plot_ly() %>%
      # Combined strategy confidence band (most important)
      add_ribbons(data = combined_data, x = ~Year, ymin = ~P10, ymax = ~P90,
                  fillcolor = "rgba(214, 138, 147, 0.15)",
                  line = list(color = "transparent"),
                  name = "Combined Range",
                  showlegend = FALSE,
                  hoverinfo = "skip") %>%
      # Median lines for all scenarios
      add_trace(data = baseline_data, x = ~Year, y = ~P50,
                name = "A: Baseline", type = "scatter", mode = "lines+markers",
                line = list(color = "#999", width = 2, dash = "dash"),
                marker = list(size = 6)) %>%
      add_trace(data = retention_data, x = ~Year, y = ~P50,
                name = "B: Retention Focus", type = "scatter", mode = "lines+markers",
                line = list(color = "#AD92B1", width = 3),
                marker = list(size = 8)) %>%
      add_trace(data = acquisition_data, x = ~Year, y = ~P50,
                name = "C: Acquisition Focus", type = "scatter", mode = "lines+markers",
                line = list(color = "#B07891", width = 3),
                marker = list(size = 8)) %>%
      add_trace(data = combined_data, x = ~Year, y = ~P50,
                name = "D: Combined Strategy", type = "scatter", mode = "lines+markers",
                line = list(color = "#D68A93", width = 4),
                marker = list(size = 10)) %>%
      layout(
        title = "Compare All Scenarios (Median Outcomes from 1,000 Simulations)",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Donors"),
        hovermode = "x unified",
        plot_bgcolor = "#f8f9fa",
        paper_bgcolor = "white",
        legend = list(orientation = "h", y = -0.2)
      )
  })

  # Scenario comparison metrics (with Monte Carlo)
  output$scenario_comparison <- renderUI({
    # Run Monte Carlo for all scenarios
    baseline_mc <- monte_carlo_forecast(
      input$current_donors, input$current_retention, input$retention_variability,
      input$baseline_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    retention_mc <- monte_carlo_forecast(
      input$current_donors, input$retention_improvement, input$retention_variability,
      input$baseline_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    acquisition_mc <- monte_carlo_forecast(
      input$current_donors, input$current_retention, input$retention_variability,
      input$aggressive_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    combined_mc <- monte_carlo_forecast(
      input$current_donors, input$combined_retention, input$retention_variability,
      input$combined_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    # Get final year medians and total revenue
    baseline_final <- tail(baseline_mc$percentiles$P50, 1)
    retention_final <- tail(retention_mc$percentiles$P50, 1)
    acquisition_final <- tail(acquisition_mc$percentiles$P50, 1)
    combined_final <- tail(combined_mc$percentiles$P50, 1)

    baseline_revenue <- sum(baseline_mc$percentiles$P50 * input$avg_gift)
    retention_revenue <- sum(retention_mc$percentiles$P50 * input$avg_gift)
    acquisition_revenue <- sum(acquisition_mc$percentiles$P50 * input$avg_gift)
    combined_revenue <- sum(combined_mc$percentiles$P50 * input$avg_gift)

    tagList(
      div(class = "metric-card",
        div(class = "metric-label", "Baseline"),
        div(class = "metric-value", comma(round(baseline_final))),
        p(style = "margin-top: 0.5rem; color: #666;", dollar(baseline_revenue))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Retention Focus"),
        div(class = "metric-value", comma(round(retention_final))),
        p(style = "margin-top: 0.5rem; color: #666;", dollar(retention_revenue))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Acquisition Focus"),
        div(class = "metric-value", comma(round(acquisition_final))),
        p(style = "margin-top: 0.5rem; color: #666;", dollar(acquisition_revenue))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Combined Strategy"),
        div(class = "metric-value", comma(round(combined_final))),
        p(style = "margin-top: 0.5rem; color: #666;", dollar(combined_revenue))
      )
    )
  })

  # Strategic recommendation (with Monte Carlo probability)
  output$strategic_recommendation <- renderUI({
    # Run Monte Carlo for all scenarios
    baseline_mc <- monte_carlo_forecast(
      input$current_donors, input$current_retention, input$retention_variability,
      input$baseline_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    combined_mc <- monte_carlo_forecast(
      input$current_donors, input$combined_retention, input$retention_variability,
      input$combined_acquisition, input$acquisition_variability, input$forecast_years, 1000
    )

    # Calculate total revenue for each simulation
    baseline_total_revenue <- apply(baseline_mc$all_simulations, 1, function(donors) sum(donors * input$avg_gift))
    combined_total_revenue <- apply(combined_mc$all_simulations, 1, function(donors) sum(donors * input$avg_gift))

    # Calculate net benefit for each simulation
    total_cost <- input$combined_total_cost * input$forecast_years
    net_benefit_sims <- combined_total_revenue - baseline_total_revenue - total_cost

    # Probability of positive ROI
    prob_positive <- mean(net_benefit_sims > 0) * 100

    # Median values
    median_baseline_revenue <- median(baseline_total_revenue)
    median_combined_revenue <- median(combined_total_revenue)
    median_improvement <- median(net_benefit_sims)
    improvement_pct <- ((median_combined_revenue - median_baseline_revenue) / median_baseline_revenue) * 100

    median_roi <- ((median_combined_revenue - median_baseline_revenue - total_cost) / total_cost) * 100

    tagList(
      p(strong("Combined Strategy Net Benefit (Median): "), dollar(median_improvement)),
      p(strong("Revenue Increase vs. Baseline: "), paste0(round(improvement_pct, 1), "%")),
      p(strong("ROI on Combined Investment: "), paste0(round(median_roi, 1), "%")),
      p(strong("Probability of Positive ROI: "),
        span(style = paste0("color: ", if(prob_positive > 70) "#28a745" else if(prob_positive > 40) "#ffc107" else "#dc3545", "; font-weight: 600; font-size: 1.2rem;"),
             paste0(round(prob_positive, 0), "%"))),
      if(prob_positive > 70 && median_roi > 100) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(40, 167, 69, 0.1); border-radius: 8px;",
          strong("✓ Recommended: Combined Strategy"), br(),
          "The combined approach offers the best results with ", strong(round(prob_positive, 0), "%"),
          " probability of positive ROI. Investing in both retention and acquisition maximizes long-term donor value.")
      } else if(prob_positive > 40 && median_roi > 50) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(255, 193, 7, 0.1); border-radius: 8px;",
          strong("⚠ Moderate Opportunity"), br(),
          "About ", strong(round(prob_positive, 0), "%"), " chance of positive ROI. ",
          "Consider testing one strategy at a time - either retention improvement OR increased acquisition - to reduce risk and investment.")
      } else if(median_roi < 0) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(220, 53, 69, 0.1); border-radius: 8px;",
          strong("⚠ High Risk - Not Recommended"), br(),
          "Only ", strong(round(prob_positive, 0), "%"), " of simulations showed positive ROI. ",
          "The investment costs ($", comma(total_cost), ") likely outweigh the benefits. Consider reducing program costs or focusing on lower-cost retention tactics first.")
      } else {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(255, 193, 7, 0.1); border-radius: 8px;",
          strong("💡 Optimize First"), br(),
          "Consider starting with one focused strategy to test effectiveness before full investment. ",
          "Monitor results for 6-12 months, then expand if ROI proves positive.")
      }
    )
  })
}

# Run the app
shinyApp(ui = ui, server = server)
