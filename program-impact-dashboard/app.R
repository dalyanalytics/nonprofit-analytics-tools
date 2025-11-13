library(shiny)
library(bslib)
library(plotly)
library(dplyr)
library(tidyr)
library(scales)
library(leaflet)
library(DT)

# Sample Connecticut towns data (simplified - will be replaced with tidycensus)
ct_towns_data <- data.frame(
  town = c("Hartford", "New Haven", "Bridgeport", "Stamford", "Waterbury",
           "Norwalk", "Danbury", "New Britain", "West Hartford", "Greenwich",
           "Hamden", "Meriden", "Bristol", "Manchester", "West Haven"),
  county = c("Hartford", "New Haven", "Fairfield", "Fairfield", "New Haven",
             "Fairfield", "Fairfield", "Hartford", "Hartford", "Fairfield",
             "New Haven", "New Haven", "Hartford", "Hartford", "New Haven"),
  population = c(121054, 134023, 148654, 135470, 107568,
                 91184, 86518, 73206, 63023, 63341,
                 62707, 60850, 60039, 58241, 55046),
  poverty_rate = c(28.2, 24.6, 18.7, 9.8, 20.1,
                   10.2, 11.5, 21.3, 5.4, 6.1,
                   11.8, 15.2, 12.4, 11.9, 19.7),
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

# Sample program data
sample_programs <- list(
  youth_literacy = list(
    name = "After-School Literacy Program",
    type = "Youth Development",
    towns = c("Hartford", "East Hartford"),
    budget = 75000,
    participants = 50,
    completion_rate = 82,
    pre_score = 2.3,
    post_score = 3.7,
    score_label = "Grade Level",
    time_series_pre = c(2.1, 2.2, 2.3, 2.2, 2.4, 2.5),
    time_series_post = c(3.1, 3.3, 3.5, 3.8, 4.0, 4.2),
    state_avg_pre = c(2.8, 2.9, 2.8, 2.9, 3.0, 3.0),
    state_avg_post = c(3.1, 3.1, 3.2, 3.2, 3.3, 3.3)
  ),
  workforce = list(
    name = "Manufacturing Skills Training",
    type = "Workforce Development",
    towns = c("New Haven", "West Haven"),
    budget = 120000,
    participants = 30,
    completion_rate = 87,
    pre_score = 35,
    post_score = 78,
    score_label = "Employment Rate (%)",
    time_series_pre = c(32, 34, 35, 33, 36, 37),
    time_series_post = c(65, 70, 75, 78, 80, 82),
    state_avg_pre = c(55, 56, 55, 57, 58, 58),
    state_avg_post = c(59, 60, 60, 61, 61, 62)
  ),
  health = list(
    name = "Diabetes Prevention Program",
    type = "Health Services",
    towns = c("Bridgeport", "Stamford"),
    budget = 90000,
    participants = 75,
    completion_rate = 71,
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
    pre_score = 2.8,
    post_score = 4.1,
    score_label = "Creative Confidence Score (1-5)",
    time_series_pre = c(2.6, 2.7, 2.8, 2.9, 2.8, 2.9),
    time_series_post = c(3.5, 3.7, 3.9, 4.0, 4.1, 4.2),
    state_avg_pre = c(3.0, 3.1, 3.0, 3.1, 3.2, 3.1),
    state_avg_post = c(3.2, 3.3, 3.3, 3.4, 3.4, 3.5)
  ),
  mindfulness_yoga = list(
    name = "Mindfulness & Yoga for Students",
    type = "Youth Development",
    towns = c("West Hartford", "Hartford"),
    budget = 48000,
    participants = 120,
    completion_rate = 92,
    pre_score = 3.2,
    post_score = 4.6,
    score_label = "Emotional Regulation Score (1-5)",
    time_series_pre = c(3.0, 3.1, 3.2, 3.3, 3.2, 3.3),
    time_series_post = c(4.0, 4.2, 4.3, 4.5, 4.6, 4.7),
    state_avg_pre = c(3.4, 3.5, 3.4, 3.5, 3.6, 3.5),
    state_avg_post = c(3.6, 3.7, 3.7, 3.8, 3.8, 3.9)
  )
)

# UI
ui <- page_sidebar(
  theme = bs_theme(version = 5),

  title = "Program Impact Dashboard",

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

      /* Sidebar styling */
      .bslib-sidebar-layout > .sidebar {
        background: #f8f9fa;
        border-radius: 12px;
        padding: 1rem;
      }
    "))
  ),

  # Sidebar
  sidebar = sidebar(
    width = 280,

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

    numericInput("pre_score", "Pre-Program Score:", value = 2.3, step = 0.1),
    numericInput("post_score", "Post-Program Score:", value = 3.7, step = 0.1),
    textInput("score_label", "Score Label:", value = "Grade Level"),

    hr(),

    actionButton("analyze", "Analyze Impact", class = "btn-primary w-100",
                 style = "background: linear-gradient(135deg, #D68A93, #AD92B1); border: none;")
  ),

  # Main content
  div(class = "main-container",
    h2("Program Impact Dashboard"),
    div(class = "subtitle", "Measure and communicate your program's impact in Connecticut communities"),

    div(class = "info-box",
      HTML("<strong>About this tool:</strong> Analyze your program's impact with data-driven insights. Compare outcomes to Connecticut benchmarks, visualize community need, and generate board-ready reports.")
    ),

    # Impact Overview Section
    div(class = "section-header", "📊 Impact Overview"),

    layout_columns(
      col_widths = c(3, 3, 3, 3),
      value_box(
        title = "Participants Served",
        value = textOutput("participants_display"),
        showcase = bsicons::bs_icon("people-fill"),
        theme = "primary"
      ),
      value_box(
        title = "Completion Rate",
        value = textOutput("completion_display"),
        showcase = bsicons::bs_icon("check-circle-fill"),
        theme = "success"
      ),
      value_box(
        title = "Outcome Improvement",
        value = textOutput("improvement_display"),
        showcase = bsicons::bs_icon("graph-up-arrow"),
        theme = "success"
      ),
      value_box(
        title = "Cost Per Participant",
        value = textOutput("cost_display"),
        showcase = bsicons::bs_icon("currency-dollar"),
        theme = "info"
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
    ),

    # Connecticut Context
    div(class = "section-header", "📍 Connecticut Community Context"),

    layout_columns(
      col_widths = c(8, 4),
      card(
        card_header("Service Area Map"),
        leafletOutput("ct_map", height = "400px")
      ),
      card(
        card_header("Community Data"),
        uiOutput("community_stats")
      )
    ),

    # Demographics Section
    div(class = "section-header", "👥 Demographics & Reach"),

    card(
      card_header("Program Reach Analysis"),
      plotlyOutput("reach_chart", height = "300px")
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
    )
  )
)

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
    updateNumericInput(session, "pre_score", value = program$pre_score)
    updateNumericInput(session, "post_score", value = program$post_score)
    updateTextInput(session, "score_label", value = program$score_label)

    current_program(program)
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
      config(displayModeBar = FALSE)
  })

  # Time series chart
  output$time_series_chart <- renderPlotly({
    program <- current_program()

    if (is.null(program)) {
      # Default data if no sample loaded
      months <- 1:12
      pre_data <- rep(input$pre_score, 6)
      post_data <- rep(input$post_score, 6)
      state_pre <- rep(input$pre_score * 1.2, 6)
      state_post <- rep(input$post_score * 0.95, 6)
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
      config(displayModeBar = FALSE)
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
          "<br>Poverty Rate: ", poverty_rate, "%",
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
    avg_poverty <- mean(selected_data$poverty_rate)
    avg_income <- mean(selected_data$median_income)

    tagList(
      div(style = "padding: 15px;",
        div(style = "margin-bottom: 15px;",
          div(style = "font-size: 0.9rem; color: #666;", "Total Population"),
          div(style = "font-size: 1.8rem; font-weight: 600; color: #2c3e50;", comma(total_pop))
        ),
        div(style = "margin-bottom: 15px;",
          div(style = "font-size: 0.9rem; color: #666;", "Avg Poverty Rate"),
          div(style = "font-size: 1.8rem; font-weight: 600; color: #D68A93;", paste0(round(avg_poverty, 1), "%"))
        ),
        div(style = "margin-bottom: 15px;",
          div(style = "font-size: 0.9rem; color: #666;", "Avg Median Income"),
          div(style = "font-size: 1.8rem; font-weight: 600; color: #28a745;", paste0("$", comma(round(avg_income))))
        ),
        hr(style = "margin: 20px 0;"),
        div(style = "margin-top: 15px;",
          div(style = "font-size: 0.9rem; color: #666;", "Program Reach"),
          div(style = "font-size: 1.5rem; font-weight: 600; color: #AD92B1;",
              paste0(round((input$participants / total_pop) * 100, 2), "%")
          ),
          div(style = "font-size: 0.85rem; color: #999; margin-top: 5px;",
              paste0(comma(input$participants), " of ", comma(total_pop), " residents")
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
      config(displayModeBar = FALSE)
  })
}

# Run the app
shinyApp(ui, server)
