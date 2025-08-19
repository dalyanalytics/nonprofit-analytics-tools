# Donor Retention Calculator - Shinylive App
# File: donor-retention-calculator/app.R

library(shiny)
library(DT)
library(plotly)
library(dplyr)
library(lubridate)

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

# UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .metric-box {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 20px;
        border-radius: 8px;
        text-align: center;
        margin-bottom: 10px;
      }
      .metric-value {
        font-size: 2.5em;
        font-weight: bold;
        margin: 0;
      }
      .metric-label {
        font-size: 1.1em;
        margin: 5px 0 0 0;
        opacity: 0.9;
      }
      .sample-data-box {
        background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        color: white;
        padding: 20px;
        border-radius: 8px;
        margin-bottom: 20px;
      }
      .info-box {
        background: #f8f9fa;
        padding: 15px;
        border-radius: 5px;
        border-left: 4px solid #007bff;
        margin-bottom: 20px;
      }
      .benchmark-box {
        background: #e8f5e8;
        padding: 15px;
        border-radius: 5px;
        border-left: 4px solid #28a745;
        margin-bottom: 20px;
      }
      .cta-box {
        background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
        color: white;
        padding: 25px;
        border-radius: 8px;
        text-align: center;
        margin-top: 30px;
      }
      .cta-button {
        background: #f39c12;
        color: white;
        padding: 12px 25px;
        border: none;
        border-radius: 5px;
        font-size: 1.1em;
        font-weight: bold;
        text-decoration: none;
        display: inline-block;
        margin-top: 10px;
        transition: background 0.3s ease;
      }
      .cta-button:hover {
        background: #e67e22;
        color: white;
        text-decoration: none;
      }
    "))
  ),
  
  titlePanel(
    div(
      h1("📊 Nonprofit Donor Retention Calculator", style = "margin-bottom: 5px;"),
      p("Analyze retention patterns, calculate lifetime value, and benchmark against industry standards", 
        style = "color: #666; font-size: 1.2em; margin-top: 0;")
    )
  ),
  
  div(class = "sample-data-box",
    h4("🚀 Try with Sample Data", style = "margin-top: 0; color: white;"),
    p("Explore realistic nonprofit data (500 donors, 5 years of history). Upload your own CSV for personalized insights.", 
      style = "margin-bottom: 15px;"),
    div(style = "text-align: center;",
      actionButton("load_sample", "Load Sample Data", 
                   style = "background: white; color: #333; font-weight: bold; padding: 10px 20px; border: none; border-radius: 5px; margin-right: 15px;"),
      span("Or upload your data below ↓", style = "color: white; font-style: italic; font-size: 1.1em;")
    )
  ),
  
  sidebarLayout(
    sidebarPanel(
      h4("📁 Upload Your Data"),
      fileInput("file", "Choose CSV File",
                accept = c(".csv"),
                placeholder = "donor_data.csv"),
      
      div(class = "info-box",
        h5("📋 Required CSV Format:", style = "margin-top: 0;"),
        tags$ul(
          tags$li(strong("donor_id:"), " Unique identifier"),
          tags$li(strong("gift_date:"), " Date (YYYY-MM-DD)"),
          tags$li(strong("amount:"), " Gift amount (numeric)")
        ),
        p(strong("Example:"), style = "margin-bottom: 5px;"),
        tags$code("donor_id,gift_date,amount\n123,2023-01-15,100.00")
      ),
      
      conditionalPanel(
        condition = "output.data_loaded",
        br(),
        h4("⚙️ Analysis Options"),
        sliderInput("min_gift", "Minimum Gift Amount ($):",
                   min = 0, max = 1000, value = 0, step = 25),
        
        checkboxInput("exclude_current_year", 
                     "Exclude current year from retention calculations", 
                     value = TRUE),
        
        br(),
        div(class = "info-box",
          h5("💡 Pro Tip:", style = "margin-top: 0;"),
          p("Excluding the current year gives more accurate retention rates since the year isn't complete yet.")
        )
      )
    ),
    
    mainPanel(
      conditionalPanel(
        condition = "!output.data_loaded",
        div(style = "text-align: center; padding: 60px 20px; color: #666;",
          h2("👆 Load sample data or upload your CSV to begin"),
          p("Get instant insights into donor retention patterns, lifetime value projections, and industry benchmarks.", 
            style = "font-size: 1.2em;"),
          hr(),
          h4("What You'll Discover:"),
          div(style = "text-align: left; max-width: 500px; margin: 0 auto;",
            tags$ul(
              tags$li("Your organization's retention rate vs industry benchmarks"),
              tags$li("Lifetime value projections for different retention scenarios"),
              tags$li("Cohort analysis showing which acquisition years performed best"),
              tags$li("Donor segmentation revealing your most valuable supporters")
            )
          )
        )
      ),
      
      conditionalPanel(
        condition = "output.data_loaded",
        
        # Key Metrics Row
        h3("📈 Key Metrics"),
        fluidRow(
          column(4,
            div(class = "metric-box",
              h3(textOutput("overall_retention"), class = "metric-value"),
              p("Overall Retention Rate", class = "metric-label")
            )
          ),
          column(4,
            div(class = "metric-box",
              h3(textOutput("total_donors"), class = "metric-value"),
              p("Total Donors Analyzed", class = "metric-label")
            )
          ),
          column(4,
            div(class = "metric-box",
              h3(textOutput("avg_gift"), class = "metric-value"),
              p("Average Annual Gift", class = "metric-label")
            )
          )
        ),
        
        br(),
        
        # Benchmark Section
        div(class = "benchmark-box",
          h4("🎯 Industry Benchmarks", style = "margin-top: 0;"),
          p(strong("Your retention rate: "), textOutput("benchmark_comparison", inline = TRUE)),
          tags$ul(
            tags$li(strong("Excellent:"), " >70% (Top 10% of nonprofits)"),
            tags$li(strong("Good:"), " 50-70% (Above average)"),
            tags$li(strong("Average:"), " 35-50% (Industry standard)"),
            tags$li(strong("Needs Improvement:"), " <35% (Below average)")
          )
        ),
        
        # Tabbed Analysis
        tabsetPanel(
          tabPanel("💰 Lifetime Value", 
            br(),
            h4("Lifetime Value Projections"),
            p("See how improving retention rates impacts donor lifetime value:"),
            DT::dataTableOutput("ltv_table"),
            br(),
            div(class = "info-box",
              h5("💡 Key Insight:", style = "margin-top: 0;"),
              p("Small improvements in retention rates create massive increases in lifetime value. 
                A 10% retention improvement can increase LTV by 25-40%.")
            )
          ),
          
          tabPanel("📊 Cohort Analysis",
            br(),
            h4("Retention by Acquisition Year"),
            p("Track how well you retain donors based on when they first gave:"),
            DT::dataTableOutput("cohort_table"),
            br(),
            plotlyOutput("cohort_plot", height = "400px")
          ),
          
          tabPanel("👥 Donor Segments",
            br(),
            h4("Donor Segmentation Analysis"),
            plotlyOutput("segment_plot", height = "400px"),
            br(),
            DT::dataTableOutput("segment_table")
          )
        )
      )
    )
  ),
  
  # CTA Section
  conditionalPanel(
    condition = "output.data_loaded",
    div(class = "cta-box",
      h3("🎯 Want Automated Retention Tracking?", style = "margin-top: 0; color: white;"),
      p("Stop doing this analysis manually every quarter. Get custom dashboards that automatically track retention, predict churn risk, and identify major gift prospects.", 
        style = "font-size: 1.1em;"),
      a(href = "https://www.dalyanalytics.com/contact", target = "_blank", class = "cta-button",
        "Schedule Free Consultation →")
    )
  ),
  
  br(),
  div(style = "text-align: center; color: #666; padding: 20px;",
    p("Built with ❤️ for nonprofits | ", 
      a(href = "https://www.dalyanalytics.com", target = "_blank", "Daly Analytics", style = "color: #007bff;"),
      " | Open source on ",
      a(href = "https://github.com", target = "_blank", "GitHub", style = "color: #007bff;"))
  )
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
    
    showNotification("Sample data loaded! Explore the analysis below.", 
                    type = "message", duration = 5)
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
                        type = "error", duration = 10)
        return()
      }
      
      # Convert and validate data
      df$gift_date <- as.Date(df$gift_date)
      df$amount <- as.numeric(df$amount)
      df$year <- year(df$gift_date)
      
      # Remove invalid rows
      df <- df[!is.na(df$gift_date) & !is.na(df$amount) & df$amount > 0, ]
      
      if(nrow(df) == 0) {
        showNotification("Error: No valid data found in CSV", type = "error", duration = 10)
        return()
      }
      
      values$gifts_data <- df
      values$data_loaded <- TRUE
      
      updateSliderInput(session, "min_gift", 
                       max = max(df$amount, na.rm = TRUE),
                       value = 0)
      
      showNotification(paste("Success! Loaded", nrow(df), "gift records."), 
                      type = "message", duration = 5)
      
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message), 
                      type = "error", duration = 10)
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
    
    if(rate >= 70) "Excellent! 🌟"
    else if(rate >= 50) "Good! 👍"
    else if(rate >= 35) "Average 📊"
    else "Needs Improvement 📈"
  })
  
  # Output: LTV table
  output$ltv_table <- DT::renderDataTable({
    req(values$metrics)
    
    retention_rate <- values$metrics$overall_retention$retention_rate / 100
    avg_gift <- values$metrics$avg_annual_gift
    
    scenarios <- data.frame(
      Scenario = c("Current Retention", "Improved by 10%", "Improved by 20%", "Best Practice (70%)"),
      `Retention Rate` = c(
        paste0(round(retention_rate * 100, 1), "%"),
        paste0(round(min(100, (retention_rate + 0.1) * 100), 1), "%"),
        paste0(round(min(100, (retention_rate + 0.2) * 100), 1), "%"),
        "70.0%"
      ),
      `5-Year LTV` = c(
        paste0("$", format(round(avg_gift * (1 + retention_rate^1 + retention_rate^2 + retention_rate^3 + retention_rate^4), 0), big.mark = ",")),
        paste0("$", format(round(avg_gift * (1 + min(1, retention_rate + 0.1)^1 + min(1, retention_rate + 0.1)^2 + min(1, retention_rate + 0.1)^3 + min(1, retention_rate + 0.1)^4), 0), big.mark = ",")),
        paste0("$", format(round(avg_gift * (1 + min(1, retention_rate + 0.2)^1 + min(1, retention_rate + 0.2)^2 + min(1, retention_rate + 0.2)^3 + min(1, retention_rate + 0.2)^4), 0), big.mark = ",")),
        paste0("$", format(round(avg_gift * (1 + 0.7^1 + 0.7^2 + 0.7^3 + 0.7^4), 0), big.mark = ","))
      ),
      check.names = FALSE
    )
    
    DT::datatable(scenarios, 
                  options = list(dom = 't', pageLength = 10, scrollX = TRUE),
                  rownames = FALSE) %>%
      DT::formatStyle(columns = 1:3, fontSize = '14px')
    
  }, server = FALSE)
  
  # Output: Cohort table
  output$cohort_table <- DT::renderDataTable({
    req(values$metrics)
    
    cohort_data <- values$metrics$cohort_analysis %>%
      select(`First Gift Year` = first_gift_year,
             `New Donors` = total_donors,
             `Year 2 Rate` = year_2_rate,
             `Year 3 Rate` = year_3_rate,
             `Year 4 Rate` = year_4_rate,
             `Year 5 Rate` = year_5_rate) %>%
      mutate(across(contains("Rate"), ~ paste0(.x, "%")))
    
    DT::datatable(cohort_data, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  rownames = FALSE) %>%
      DT::formatStyle(columns = 1:6, fontSize = '14px')
    
  }, server = FALSE)
  
  # Output: Cohort plot
  output$cohort_plot <- renderPlotly({
    req(values$metrics)
    
    if(nrow(values$metrics$cohort_analysis) == 0) return(NULL)
    
    cohort_long <- values$metrics$cohort_analysis %>%
      select(first_gift_year, year_2_rate, year_3_rate, year_4_rate, year_5_rate) %>%
      tidyr::pivot_longer(cols = contains("rate"), 
                         names_to = "retention_year", 
                         values_to = "rate") %>%
      mutate(retention_year = case_when(
        retention_year == "year_2_rate" ~ "Year 2",
        retention_year == "year_3_rate" ~ "Year 3", 
        retention_year == "year_4_rate" ~ "Year 4",
        retention_year == "year_5_rate" ~ "Year 5"
      ))
    
    p <- plot_ly(cohort_long, 
                x = ~factor(first_gift_year), 
                y = ~rate, 
                color = ~retention_year, 
                type = 'bar') %>%
      layout(title = "Retention Rates by Acquisition Cohort",
             xaxis = list(title = "First Gift Year"),
             yaxis = list(title = "Retention Rate (%)"),
             barmode = 'group',
             hovermode = 'x unified')
    
    p
  })
  
  # Output: Segment plot and table
  output$segment_plot <- renderPlotly({
    req(values$metrics)
    
    # Create donor segments
    segments <- values$metrics$donor_summary %>%
      mutate(
        segment = case_when(
          years_active == 1 & total_amount < 100 ~ "One-time Small",
          years_active == 1 & total_amount >= 100 ~ "One-time Large", 
          years_active %in% 2:3 ~ "Occasional",
          years_active >= 4 & total_amount/years_active < 200 ~ "Loyal Small",
          years_active >= 4 & total_amount/years_active >= 200 ~ "Major Donor"
        )
      ) %>%
      group_by(segment) %>%
      summarise(
        count = n(),
        avg_annual_gift = mean(total_amount/years_active),
        total_value = sum(total_amount),
        .groups = 'drop'
      ) %>%
      mutate(pct_donors = round(count/sum(count)*100, 1),
             pct_value = round(total_value/sum(total_value)*100, 1))
    
    if(nrow(segments) == 0) return(NULL)
    
    p <- plot_ly(segments, 
                x = ~pct_donors, 
                y = ~pct_value, 
                size = ~count, 
                color = ~segment,
                type = 'scatter',
                mode = 'markers',
                text = ~paste("Segment:", segment, "<br>Donors:", count, "<br>% of Base:", pct_donors, "%<br>% of Revenue:", pct_value, "%"),
                hovertemplate = "%{text}<extra></extra>") %>%
      layout(title = "Donor Segments: Base vs Revenue Concentration",
             xaxis = list(title = "% of Donor Base"),
             yaxis = list(title = "% of Total Revenue"))
    
    p
  })
  
  output$segment_table <- DT::renderDataTable({
    req(values$metrics)
    
    segments <- values$metrics$donor_summary %>%
      mutate(
        segment = case_when(
          years_active == 1 & total_amount < 100 ~ "One-time Small",
          years_active == 1 & total_amount >= 100 ~ "One-time Large", 
          years_active %in% 2:3 ~ "Occasional",
          years_active >= 4 & total_amount/years_active < 200 ~ "Loyal Small",
          years_active >= 4 & total_amount/years_active >= 200 ~ "Major Donor"
        )
      ) %>%
      group_by(segment) %>%
      summarise(
        donors = n(),
        avg_annual = round(mean(total_amount/years_active), 0),
        total_value = round(sum(total_amount), 0),
        pct_donors = round(n()/nrow(values$metrics$donor_summary)*100, 1),
        pct_value = round(sum(total_amount)/sum(values$metrics$donor_summary$total_amount)*100, 1),
        .groups = 'drop'
      ) %>%
      select(`Donor Segment` = segment,
             `Count` = donors,
             `Avg Annual Gift` = avg_annual,
             `Total Value` = total_value,
             `% of Donors` = pct_donors,
             `% of Revenue` = pct_value)
    
    DT::datatable(segments, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  rownames = FALSE) %>%
      DT::formatCurrency(c("Avg Annual Gift", "Total Value"), "$") %>%
      DT::formatString(c("% of Donors", "% of Revenue"), "%")
    
  }, server = FALSE)
}

# Run the app
shinyApp(ui = ui, server = server)