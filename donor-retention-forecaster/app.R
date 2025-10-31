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
        font-size: 1.3rem;
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

      .footer {
        text-align: center;
        padding: 2rem 0 1rem 0;
        color: #666;
        font-size: 0.9rem;
        border-top: 1px solid #e9ecef;
        margin-top: 3rem;
      }

      .footer a {
        color: #D68A93;
        text-decoration: none;
        font-weight: 500;
      }

      .footer a:hover {
        text-decoration: underline;
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
      tabPanel("Baseline (Status Quo)",
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
      tabPanel("Retention Improvement",
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
      tabPanel("Acquisition Focus",
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
      tabPanel("Combined Strategy",
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

    # Footer
    div(class = "footer",
      p(
        "Built with ❤️ by ",
        tags$a(href = "https://www.dalyanalytics.com", "Daly Analytics", target = "_blank"),
        " • ",
        tags$a(href = "mailto:hello@dalyanalytics.com", "hello@dalyanalytics.com")
      ),
      p(
        tags$a(href = "https://github.com/yourusername/nonprofit-analytics-tools",
               "View on GitHub", target = "_blank"),
        " • ",
        tags$a(href = "https://dalyanalytics.github.io/nonprofit-analytics-tools/",
               "More Free Tools", target = "_blank")
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

  # Retention improvement comparison
  output$retention_comparison_chart <- renderPlotly({
    years <- 0:input$forecast_years

    baseline <- forecast_donors(
      input$current_donors,
      input$current_retention,
      input$baseline_acquisition,
      input$forecast_years
    )

    improved <- forecast_donors(
      input$current_donors,
      input$retention_improvement,
      input$baseline_acquisition,
      input$forecast_years
    )

    data <- data.frame(
      Year = years,
      Baseline = baseline,
      Improved = improved
    )

    plot_ly(data, x = ~Year) %>%
      add_trace(y = ~Baseline, name = "Current Retention", type = "scatter", mode = "lines+markers",
                line = list(color = "#D68A93", width = 3, dash = "dash"),
                marker = list(size = 8)) %>%
      add_trace(y = ~Improved, name = "Improved Retention", type = "scatter", mode = "lines+markers",
                line = list(color = "#AD92B1", width = 3),
                marker = list(size = 10)) %>%
      layout(
        title = "Impact of Retention Improvement",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Donors"),
        hovermode = "x unified",
        plot_bgcolor = "#f8f9fa",
        paper_bgcolor = "white"
      )
  })

  # Retention ROI
  output$retention_roi <- renderUI({
    years <- 0:input$forecast_years

    baseline_donors <- forecast_donors(
      input$current_donors,
      input$current_retention,
      input$baseline_acquisition,
      input$forecast_years
    )

    improved_donors <- forecast_donors(
      input$current_donors,
      input$retention_improvement,
      input$baseline_acquisition,
      input$forecast_years
    )

    baseline_revenue <- sum(calculate_revenue(baseline_donors, input$avg_gift))
    improved_revenue <- sum(calculate_revenue(improved_donors, input$avg_gift))
    additional_revenue <- improved_revenue - baseline_revenue

    total_program_cost <- input$retention_program_cost * input$forecast_years
    net_benefit <- additional_revenue - total_program_cost
    roi <- ((additional_revenue - total_program_cost) / total_program_cost) * 100

    tagList(
      p(strong("Additional Revenue: "), dollar(additional_revenue)),
      p(strong("Total Program Cost (", input$forecast_years, " years): "), dollar(total_program_cost)),
      p(strong("Net Benefit: "),
        span(style = if(net_benefit > 0) "color: #28a745; font-weight: 600;" else "color: #dc3545; font-weight: 600;",
             dollar(net_benefit))),
      p(strong("ROI: "),
        span(style = if(roi > 0) "color: #28a745; font-weight: 600;" else "color: #dc3545; font-weight: 600;",
             paste0(round(roi, 1), "%"))),
      if(net_benefit > 0) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(40, 167, 69, 0.1); border-radius: 8px;",
          "✓ This retention program would generate a positive return on investment!")
      } else {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(220, 53, 69, 0.1); border-radius: 8px;",
          "⚠ This program would cost more than the additional revenue it generates. Consider adjusting the program cost or retention target.")
      }
    )
  })

  # Acquisition comparison chart
  output$acquisition_comparison_chart <- renderPlotly({
    years <- 0:input$forecast_years

    baseline <- forecast_donors(
      input$current_donors,
      input$current_retention,
      input$baseline_acquisition,
      input$forecast_years
    )

    aggressive <- forecast_donors(
      input$current_donors,
      input$current_retention,
      input$aggressive_acquisition,
      input$forecast_years
    )

    data <- data.frame(
      Year = years,
      Baseline = baseline,
      Aggressive = aggressive
    )

    plot_ly(data, x = ~Year) %>%
      add_trace(y = ~Baseline, name = "Baseline Acquisition", type = "scatter", mode = "lines+markers",
                line = list(color = "#D68A93", width = 3, dash = "dash"),
                marker = list(size = 8)) %>%
      add_trace(y = ~Aggressive, name = "Increased Acquisition", type = "scatter", mode = "lines+markers",
                line = list(color = "#B07891", width = 3),
                marker = list(size = 10)) %>%
      layout(
        title = "Impact of Increased Acquisition",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Donors"),
        hovermode = "x unified",
        plot_bgcolor = "#f8f9fa",
        paper_bgcolor = "white"
      )
  })

  # Acquisition analysis
  output$acquisition_analysis <- renderUI({
    baseline_donors <- forecast_donors(
      input$current_donors,
      input$current_retention,
      input$baseline_acquisition,
      input$forecast_years
    )

    aggressive_donors <- forecast_donors(
      input$current_donors,
      input$current_retention,
      input$aggressive_acquisition,
      input$forecast_years
    )

    baseline_revenue <- sum(calculate_revenue(baseline_donors, input$avg_gift))
    aggressive_revenue <- sum(calculate_revenue(aggressive_donors, input$avg_gift))
    additional_revenue <- aggressive_revenue - baseline_revenue

    additional_donors_acquired <- (input$aggressive_acquisition - input$baseline_acquisition) * input$forecast_years
    total_acquisition_cost <- additional_donors_acquired * input$acquisition_cost_per_donor
    net_benefit <- additional_revenue - total_acquisition_cost

    tagList(
      p(strong("Additional Donors Acquired: "), comma(additional_donors_acquired)),
      p(strong("Additional Revenue: "), dollar(additional_revenue)),
      p(strong("Total Acquisition Cost: "), dollar(total_acquisition_cost)),
      p(strong("Net Benefit: "),
        span(style = if(net_benefit > 0) "color: #28a745; font-weight: 600;" else "color: #dc3545; font-weight: 600;",
             dollar(net_benefit))),
      if(net_benefit > 0) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(40, 167, 69, 0.1); border-radius: 8px;",
          paste0("✓ Increasing acquisition would generate ", dollar(net_benefit),
                 " in net revenue after acquisition costs."))
      } else {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(220, 53, 69, 0.1); border-radius: 8px;",
          "⚠ The acquisition cost exceeds the additional revenue generated. Consider lowering acquisition costs or improving retention to maximize value.")
      }
    )
  })

  # All scenarios comparison chart
  output$all_scenarios_chart <- renderPlotly({
    years <- 0:input$forecast_years

    baseline <- forecast_donors(
      input$current_donors,
      input$current_retention,
      input$baseline_acquisition,
      input$forecast_years
    )

    retention_only <- forecast_donors(
      input$current_donors,
      input$retention_improvement,
      input$baseline_acquisition,
      input$forecast_years
    )

    acquisition_only <- forecast_donors(
      input$current_donors,
      input$current_retention,
      input$aggressive_acquisition,
      input$forecast_years
    )

    combined <- forecast_donors(
      input$current_donors,
      input$combined_retention,
      input$combined_acquisition,
      input$forecast_years
    )

    data <- data.frame(
      Year = years,
      Baseline = baseline,
      RetentionOnly = retention_only,
      AcquisitionOnly = acquisition_only,
      Combined = combined
    )

    plot_ly(data, x = ~Year) %>%
      add_trace(y = ~Baseline, name = "A: Baseline", type = "scatter", mode = "lines+markers",
                line = list(color = "#999", width = 2, dash = "dash"),
                marker = list(size = 6)) %>%
      add_trace(y = ~RetentionOnly, name = "B: Retention Focus", type = "scatter", mode = "lines+markers",
                line = list(color = "#AD92B1", width = 3),
                marker = list(size = 8)) %>%
      add_trace(y = ~AcquisitionOnly, name = "C: Acquisition Focus", type = "scatter", mode = "lines+markers",
                line = list(color = "#B07891", width = 3),
                marker = list(size = 8)) %>%
      add_trace(y = ~Combined, name = "D: Combined Strategy", type = "scatter", mode = "lines+markers",
                line = list(color = "#D68A93", width = 4),
                marker = list(size = 10)) %>%
      layout(
        title = "Compare All Scenarios",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Donors"),
        hovermode = "x unified",
        plot_bgcolor = "#f8f9fa",
        paper_bgcolor = "white",
        legend = list(orientation = "h", y = -0.2)
      )
  })

  # Scenario comparison metrics
  output$scenario_comparison <- renderUI({
    years <- 0:input$forecast_years

    baseline <- forecast_donors(input$current_donors, input$current_retention, input$baseline_acquisition, input$forecast_years)
    retention_only <- forecast_donors(input$current_donors, input$retention_improvement, input$baseline_acquisition, input$forecast_years)
    acquisition_only <- forecast_donors(input$current_donors, input$current_retention, input$aggressive_acquisition, input$forecast_years)
    combined <- forecast_donors(input$current_donors, input$combined_retention, input$combined_acquisition, input$forecast_years)

    baseline_revenue <- sum(calculate_revenue(baseline, input$avg_gift))
    retention_revenue <- sum(calculate_revenue(retention_only, input$avg_gift))
    acquisition_revenue <- sum(calculate_revenue(acquisition_only, input$avg_gift))
    combined_revenue <- sum(calculate_revenue(combined, input$avg_gift))

    tagList(
      div(class = "metric-card",
        div(class = "metric-label", "Baseline"),
        div(class = "metric-value", comma(tail(baseline, 1))),
        p(style = "margin-top: 0.5rem; color: #666;", dollar(baseline_revenue))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Retention Focus"),
        div(class = "metric-value", comma(tail(retention_only, 1))),
        p(style = "margin-top: 0.5rem; color: #666;", dollar(retention_revenue))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Acquisition Focus"),
        div(class = "metric-value", comma(tail(acquisition_only, 1))),
        p(style = "margin-top: 0.5rem; color: #666;", dollar(acquisition_revenue))
      ),
      div(class = "metric-card",
        div(class = "metric-label", "Combined Strategy"),
        div(class = "metric-value", comma(tail(combined, 1))),
        p(style = "margin-top: 0.5rem; color: #666;", dollar(combined_revenue))
      )
    )
  })

  # Strategic recommendation
  output$strategic_recommendation <- renderUI({
    baseline <- forecast_donors(input$current_donors, input$current_retention, input$baseline_acquisition, input$forecast_years)
    retention_only <- forecast_donors(input$current_donors, input$retention_improvement, input$baseline_acquisition, input$forecast_years)
    acquisition_only <- forecast_donors(input$current_donors, input$current_retention, input$aggressive_acquisition, input$forecast_years)
    combined <- forecast_donors(input$current_donors, input$combined_retention, input$combined_acquisition, input$forecast_years)

    baseline_revenue <- sum(calculate_revenue(baseline, input$avg_gift))
    retention_revenue <- sum(calculate_revenue(retention_only, input$avg_gift))
    acquisition_revenue <- sum(calculate_revenue(acquisition_only, input$avg_gift))
    combined_revenue <- sum(calculate_revenue(combined, input$avg_gift))

    combined_net <- combined_revenue - (input$combined_total_cost * input$forecast_years)
    baseline_net <- baseline_revenue

    improvement <- combined_net - baseline_net
    improvement_pct <- (improvement / baseline_net) * 100

    roi <- ((combined_revenue - baseline_revenue - (input$combined_total_cost * input$forecast_years)) /
            (input$combined_total_cost * input$forecast_years)) * 100

    best_scenario <- which.max(c(baseline_revenue, retention_revenue, acquisition_revenue, combined_revenue))
    scenario_names <- c("Baseline (Status Quo)", "Retention Focus", "Acquisition Focus", "Combined Strategy")

    tagList(
      p(strong("Highest Revenue Scenario: "), scenario_names[best_scenario]),
      p(strong("Combined Strategy Net Benefit: "), dollar(improvement)),
      p(strong("Revenue Increase vs. Baseline: "), paste0(round(improvement_pct, 1), "%")),
      p(strong("ROI on Combined Investment: "), paste0(round(roi, 1), "%")),
      if(combined_revenue > baseline_revenue && roi > 100) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(40, 167, 69, 0.1); border-radius: 8px;",
          "✓ The combined strategy offers the best results and generates strong ROI. Investing in both retention and acquisition maximizes long-term donor value.")
      } else if(best_scenario == 2) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(255, 193, 7, 0.1); border-radius: 8px;",
          "💡 Focus on retention improvement. With your current metrics, improving donor retention offers better ROI than aggressive acquisition.")
      } else if(best_scenario == 3) {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(255, 193, 7, 0.1); border-radius: 8px;",
          "💡 Focus on acquisition. Your retention rate is relatively strong, so growing your donor base through acquisition is a good strategy.")
      } else {
        p(style = "margin-top: 1rem; padding: 1rem; background: rgba(220, 53, 69, 0.1); border-radius: 8px;",
          "⚠ The investment costs outweigh the benefits. Consider reducing program costs or adjusting targets to achieve better ROI.")
      }
    )
  })
}

# Run the app
shinyApp(ui = ui, server = server)
