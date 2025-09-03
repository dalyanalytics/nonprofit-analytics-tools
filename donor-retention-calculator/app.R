# Donor Retention Calculator - Portfolio Layout
library(shiny)
library(bslib)
library(dplyr)
library(lubridate)
library(DT)
library(shinyjs)

# Generate sample data
set.seed(123)
generate_sample_data <- function() {
  donors <- data.frame(
    donor_id = 1:500,
    first_gift_date = sample(seq(as.Date("2019-01-01"), as.Date("2023-12-31"), by = "day"), 500),
    stringsAsFactors = FALSE
  )
  
  all_gifts <- data.frame()
  
  for(i in 1:nrow(donors)) {
    donor_id <- donors$donor_id[i]
    first_date <- donors$first_gift_date[i]
    current_date <- first_date
    gifts <- data.frame()
    
    first_gift_amount <- round(runif(1, 25, 1000), 2)
    gifts <- rbind(gifts, data.frame(
      donor_id = donor_id,
      gift_date = current_date,
      amount = first_gift_amount,
      year = year(current_date)
    ))
    
    retention_probs <- c(0.65, 0.45, 0.35, 0.30, 0.25)
    
    for(year_offset in 1:5) {
      if(current_date + years(year_offset) <= Sys.Date()) {
        if(runif(1) < retention_probs[min(year_offset, 5)]) {
          num_gifts <- sample(1:3, 1, prob = c(0.7, 0.25, 0.05))
          
          for(gift_num in 1:num_gifts) {
            gift_date <- current_date + years(year_offset) + days(sample(0:364, 1))
            if(gift_date <= Sys.Date()) {
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

sample_data <- generate_sample_data()

# Calculate metrics
calculate_retention_metrics <- function(gifts_data) {
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
  
  current_year <- max(gifts_data$year)
  overall_retention <- donor_summary %>%
    filter(first_gift_year < current_year) %>%
    summarise(
      total_donors = n(),
      second_year_donors = sum(years_active >= 2),
      retention_rate = round(second_year_donors / total_donors * 100, 1)
    )
  
  avg_annual_gift <- gifts_data %>%
    group_by(donor_id, year) %>%
    summarise(annual_total = sum(amount), .groups = 'drop') %>%
    pull(annual_total) %>%
    mean()
  
  return(list(
    overall_retention = overall_retention,
    donor_summary = donor_summary,
    avg_annual_gift = avg_annual_gift
  ))
}

# Use shared CSS
addResourcePath("www", "../www")

# UI  
ui <- fluidPage(
  theme = bs_theme(version = 5),
  
  tags$head(
    tags$link(rel="stylesheet", type="text/css", href="www/shared-styles.css")
  ),
  
  useShinyjs(),
    
    # Hero Section with Brand Gradient
    div(
      class = "hero-section",
      style = "background: linear-gradient(-45deg, #F9B397, #D68A93, #AD92B1, #B07891); background-size: 200% 100%; animation: gradient 15s ease infinite; color: white; text-align: center; padding: 3rem 2rem; margin-bottom: 2rem;",
      div(icon("calculator"), style = "font-size: 3rem; margin-bottom: 1rem;"),
      h1("Donor Retention Analysis", style = "color: white; font-size: 2.5rem; font-weight: 700; margin-bottom: 1rem;"),
      p("Advanced analytics to understand donor behavior and maximize lifetime value", 
        style = "color: rgba(255,255,255,0.9); font-size: 1.2rem; margin-bottom: 0;")
    ),
    
    # Guided Steps Navigation
    div(
      style = "display: flex; justify-content: center; align-items: center; margin: 2rem 0; gap: 1rem;",
      span(class = "step-item active", id = "step1", "Upload Data"),
      span("→", style = "color: #bdc3c7; margin: 0 0.5rem;"),
      span(class = "step-item", id = "step2", "Review Executive Summary"),
      span("→", style = "color: #bdc3c7; margin: 0 0.5rem;"),
      span(class = "step-item", id = "step3", "Advanced Analysis")
    ),
    
    # Main content
    layout_sidebar(
      sidebar = sidebar(
        title = "Data Upload",
        width = 300,
        
        # Sample data button
        div(
          style = "margin-bottom: 2rem;",
          h5("Try Sample Data"),
          p("Explore with 500 donors and 5 years of history", style = "font-size: 0.9rem; color: #666;"),
          actionButton("load_sample", "Load Sample Data", class = "btn-primary w-100")
        ),
        
        # File upload
        fileInput("file", "Upload Your CSV",
                 accept = c(".csv"),
                 placeholder = "donor_data.csv"),
        
        div(
          class = "alert alert-info",
          style = "font-size: 0.85rem;",
          strong("Required format:"), br(),
          "donor_id, gift_date (YYYY-MM-DD), amount"
        )
      ),
      
      # Main content area
      conditionalPanel(
        condition = "!output.data_loaded",
        div(
          style = "text-align: center; padding: 4rem 2rem;",
          icon("chart-line", style = "font-size: 4rem; color: #d68a93; margin-bottom: 2rem;"),
          h3("Load Data to Begin Analysis"),
          p("Use sample data or upload your CSV to discover retention insights", 
            style = "color: #666; font-size: 1.1rem;")
        )
      ),
      
      # Results when data is loaded
      conditionalPanel(
        condition = "output.data_loaded",
        
        # Executive Summary
        div(
          class = "insight-callout",
          h4("Executive Summary"),
          p(textOutput("executive_summary"))
        ),
        
        br(),
        
        # Key Metrics
        div(
          class = "metric-group",
          div(
            class = "metric-display",
            div(class = "metric-number", textOutput("overall_retention")),
            div(class = "metric-label", "Overall Retention Rate")
          ),
          div(
            class = "metric-display",
            div(class = "metric-number", textOutput("total_donors")),
            div(class = "metric-label", "Total Donors")
          ),
          div(
            class = "metric-display",
            div(class = "metric-number", textOutput("avg_gift")),
            div(class = "metric-label", "Average Annual Gift")
          ),
          div(
            class = "metric-display",
            div(class = "metric-number", textOutput("projected_ltv")),
            div(class = "metric-label", "Projected 5-Year LTV")
          )
        ),
        
        br(),
        
        # Industry Benchmark
        div(
          class = "disclosure-section",
          div(
            class = "disclosure-header",
            onclick = "$(this).parent().toggleClass('expanded')",
            h4("Industry Benchmark Analysis", class = "disclosure-title"),
            span("▼", class = "disclosure-icon")
          ),
          div(
            class = "disclosure-content",
            p("Your retention rate compared to nonprofit industry standards:"),
            div(
              class = "benchmark-comparison",
              div(class = "benchmark-label", 
                  span("Your Organization: ", style = "font-weight: 600;"),
                  span(textOutput("retention_vs_benchmark", inline = TRUE)),
                  span(" vs. Industry Average: 43%", style = "color: #666;")
              ),
              div(
                class = "benchmark-bar",
                div(class = "benchmark-fill", id = "benchmark-fill", style = "width: 0%; transition: width 2s ease;"),
                div(class = "benchmark-marker", style = "left: 43%;", title = "Industry Average: 43%")
              )
            ),
            br(),
            div(
              style = "display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; text-align: center;",
              div(
                h6("Excellent", style = "color: #28a745; margin-bottom: 0.5rem;"),
                strong(">70%"),
                br(),
                tags$small("Top performers")
              ),
              div(
                h6("Good", style = "color: #17a2b8; margin-bottom: 0.5rem;"),
                strong("50-70%"),
                br(),
                tags$small("Above average")
              ),
              div(
                h6("Average", style = "color: #ffc107; margin-bottom: 0.5rem;"),
                strong("35-50%"),
                br(),
                tags$small("Industry standard")
              ),
              div(
                h6("Needs Work", style = "color: #dc3545; margin-bottom: 0.5rem;"),
                strong("<35%"),
                br(),
                tags$small("Below average")
              )
            )
          )
        ),
        
        br(),
        
        # Additional Analysis - FAST SUMMARY VERSION
        div(
          class = "disclosure-section",
          div(
            class = "disclosure-header",
            onclick = "$(this).parent().toggleClass('expanded'); if($(this).parent().hasClass('expanded')) { $('#step3').addClass('completed').removeClass('active'); }",
            h4("Donor Segmentation Analysis", class = "disclosure-title"),
            span("▼", class = "disclosure-icon")
          ),
          div(
            class = "disclosure-content",
            p("Key donor segments and patterns in your database:"),
            div(
              style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin: 2rem 0;",
              div(
                style = "background: #f8f9fa; padding: 1.5rem; border-radius: 8px; text-align: center;",
                h5(textOutput("one_time_count"), style = "color: #dc3545; margin-bottom: 0.5rem;"),
                p("One-time Donors", style = "margin: 0; font-weight: 500;")
              ),
              div(
                style = "background: #f8f9fa; padding: 1.5rem; border-radius: 8px; text-align: center;",
                h5(textOutput("repeat_count"), style = "color: #28a745; margin-bottom: 0.5rem;"),
                p("Multi-year Donors", style = "margin: 0; font-weight: 500;")
              ),
              div(
                style = "background: #f8f9fa; padding: 1.5rem; border-radius: 8px; text-align: center;",
                h5(textOutput("major_donor_count"), style = "color: #ffc107; margin-bottom: 0.5rem;"),
                p("Major Donors ($500+)", style = "margin: 0; font-weight: 500;")
              )
            ),
            hr(),
            div(
              style = "background: #e8f5e8; padding: 1rem; border-radius: 8px;",
              h6("💡 Key Insight", style = "color: #28a745; margin-bottom: 0.5rem;"),
              p(textOutput("segment_insight"), style = "margin: 0; color: #2c3e50;")
            )
          )
        ),
        
        br(),
        
        # Branding
        div(
          class = "powered-by",
          "Advanced analytics powered by ",
          tags$a("Daly Analytics", href = "https://www.dalyanalytics.com", target = "_blank")
        )
      )
    ),
  
  # Footer
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
            "This donor retention calculator demonstrates the power of custom-built nonprofit analytics solutions. ",
            "Daly Analytics specializes in creating tailored tools that solve your organization's unique challenges."
          ),
          div(
            class = "mb-3",
            tags$ul(
              class = "list-unstyled",
              style = "color: rgba(255,255,255,0.8);",
              tags$li(icon("check"), " Custom donor dashboards with ML predictions"),
              tags$li(icon("check"), " Automated grant reporting systems"),
              tags$li(icon("check"), " Real-time fundraising campaign tracking"),
              tags$li(icon("check"), " Board meeting analysis and insights"),
              tags$li(icon("check"), " Integration with your existing CRM/database")
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
              style = "background: linear-gradient(-45deg, #F9B397, #D68A93, #AD92B1, #B07891); color: #2c3e50; font-weight: 600; width: 100%;",
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
          "© 2025 Daly Analytics LLC. This free tool was built to demonstrate our expertise in nonprofit analytics. ",
          tags$a(
            "Contact us",
            href = "https://www.dalyanalytics.com/contact",
            style = "color: #d68a93;",
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
  
  values <- reactiveValues(
    data_loaded = FALSE,
    gifts_data = NULL,
    metrics = NULL
  )
  
  # Load sample data
  observeEvent(input$load_sample, {
    values$gifts_data <- sample_data$gifts
    values$data_loaded <- TRUE
    showNotification("Sample data loaded successfully!", type = "message", duration = 3)
  })
  
  # File upload
  observeEvent(input$file, {
    req(input$file)
    
    tryCatch({
      df <- read.csv(input$file$datapath, stringsAsFactors = FALSE)
      
      required_cols <- c("donor_id", "gift_date", "amount")
      if(!all(required_cols %in% names(df))) {
        showNotification("Error: CSV must contain columns: donor_id, gift_date, amount", 
                        type = "error", duration = 8)
        return()
      }
      
      df$gift_date <- as.Date(df$gift_date)
      df$amount <- as.numeric(df$amount)
      df$year <- year(df$gift_date)
      
      df <- df[!is.na(df$gift_date) & !is.na(df$amount) & df$amount > 0, ]
      
      if(nrow(df) == 0) {
        showNotification("Error: No valid data found in CSV", type = "error", duration = 8)
        return()
      }
      
      values$gifts_data <- df
      values$data_loaded <- TRUE
      
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
    if(nrow(values$gifts_data) > 0) {
      tryCatch({
        values$metrics <- calculate_retention_metrics(values$gifts_data)
        
        # Only run JS if we have shinyjs loaded, otherwise skip
        tryCatch({
          shinyjs::runjs("
            $('#step1').addClass('completed').removeClass('active');
            $('#step2').addClass('active completed').removeClass('');
            $('#step3').addClass('active').removeClass('completed');
          ")
          
          # Animate benchmark bar
          retention_rate <- values$metrics$overall_retention$retention_rate
          shinyjs::runjs(paste0("
            setTimeout(function() {
              $('#benchmark-fill').css('width', '", min(retention_rate, 100), "%');
            }, 1000);
          "))
        }, error = function(e) {
          # JS failed, but continue without it
          cat("JavaScript update failed:", e$message, "\n")
        })
        
      }, error = function(e) {
        showNotification(paste("Error calculating metrics:", e$message), 
                        type = "error", duration = 5)
        cat("Metrics calculation error:", e$message, "\n")
      })
    }
  })
  
  # Output: Data loaded flag
  output$data_loaded <- reactive({
    values$data_loaded
  })
  outputOptions(output, "data_loaded", suspendWhenHidden = FALSE)
  
  # Key metrics outputs
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
  
  output$projected_ltv <- renderText({
    req(values$metrics)
    retention_rate <- values$metrics$overall_retention$retention_rate / 100
    avg_gift <- values$metrics$avg_annual_gift
    
    ltv <- avg_gift * (1 + retention_rate^1 + retention_rate^2 + retention_rate^3 + retention_rate^4)
    paste0("$", format(round(ltv, 0), big.mark = ","))
  })
  
  output$retention_vs_benchmark <- renderText({
    req(values$metrics)
    rate <- values$metrics$overall_retention$retention_rate
    paste0(rate, "%")
  })
  
  output$executive_summary <- renderText({
    req(values$metrics)
    rate <- values$metrics$overall_retention$retention_rate
    total_donors <- nrow(values$metrics$donor_summary)
    avg_gift <- round(values$metrics$avg_annual_gift, 0)
    
    if(rate >= 50) {
      paste0("Your organization demonstrates strong donor stewardship with a ", rate, "% retention rate across ", 
             format(total_donors, big.mark = ","), " donors, significantly outperforming the 43% industry average. ",
             "With an average annual gift of $", format(avg_gift, big.mark = ","), 
             ", your donor base represents substantial long-term value potential.")
    } else {
      paste0("Analysis of your ", format(total_donors, big.mark = ","), " donor database reveals a ", rate, 
             "% retention rate with potential for improvement compared to the 43% industry benchmark. ",
             "Your average annual gift of $", format(avg_gift, big.mark = ","), 
             " indicates strong individual donor capacity that could benefit from enhanced retention strategies.")
    }
  })
  
  # Fast donor segmentation - NO TABLES, JUST SIMPLE STATS
  output$one_time_count <- renderText({
    req(values$metrics)
    one_time <- sum(values$metrics$donor_summary$years_active == 1)
    total <- nrow(values$metrics$donor_summary)
    paste0(format(one_time, big.mark = ","), " (", round(one_time/total*100, 1), "%)")
  })
  
  output$repeat_count <- renderText({
    req(values$metrics)
    multi_year <- sum(values$metrics$donor_summary$years_active >= 3)
    total <- nrow(values$metrics$donor_summary)
    paste0(format(multi_year, big.mark = ","), " (", round(multi_year/total*100, 1), "%)")
  })
  
  output$major_donor_count <- renderText({
    req(values$metrics)
    major_donors <- sum((values$metrics$donor_summary$total_amount / values$metrics$donor_summary$total_gifts) >= 500, na.rm = TRUE)
    total <- nrow(values$metrics$donor_summary)
    paste0(format(major_donors, big.mark = ","), " (", round(major_donors/total*100, 1), "%)")
  })
  
  output$segment_insight <- renderText({
    req(values$metrics)
    retention_rate <- values$metrics$overall_retention$retention_rate
    
    if(retention_rate >= 50) {
      "Your strong retention suggests effective donor stewardship. Focus on upgrading mid-level donors to maximize impact."
    } else {
      "Consider implementing donor welcome series and regular engagement touchpoints to improve retention rates."
    }
  })
}

shinyApp(ui = ui, server = server)
