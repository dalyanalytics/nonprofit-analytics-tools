# Board Packet Generator - Professional Portfolio Layout with Full Functionality
library(shiny)
library(plotly)
library(DT)
library(dplyr)
library(tidyr)
library(bslib)
library(shinyjs)

# Professional corporate color scheme
corporate_colors <- list(
  primary = "#2c3e50",
  secondary = "#34495e", 
  accent = "#d68a93",
  success = "#27ae60",
  warning = "#f39c12",
  danger = "#e74c3c",
  light = "#ecf0f1",
  dark = "#2c3e50",
  text = "#2c3e50",
  muted = "#7f8c8d"
)

# Use shared CSS file
addResourcePath("www", "../www")

# Custom theme
professional_theme <- bs_theme(
  version = 5,
  preset = "bootstrap",
  primary = corporate_colors$primary,
  secondary = corporate_colors$secondary,
  success = corporate_colors$success,
  warning = corporate_colors$warning,
  danger = corporate_colors$danger
)

# Sample data
sample_agenda_items <- data.frame(
  item_no = 1:8,
  topic = c(
    "Call to Order & Welcome", 
    "Approval of Previous Meeting Minutes",
    "Executive Director's Report", 
    "Financial Review & Treasurer's Report",
    "Strategic Plan Progress Update", 
    "Development & Fundraising Update",
    "Committee Reports",
    "New Business & Adjournment"
  ),
  presenter = c(
    "Board Chair", "Secretary", "Executive Director",
    "Treasurer/CFO", "Strategic Planning Chair",
    "Development Director", "Committee Chairs", "Board Chair"
  ),
  time_allotted = c("5 min", "5 min", "20 min", "15 min", "20 min", "15 min", "20 min", "10 min"),
  materials = c(
    "Agenda", "Previous Minutes", "ED Report",
    "Financial Statements", "Progress Dashboard",
    "Campaign Update", "Committee Reports", "Action Items"
  ),
  stringsAsFactors = FALSE
)

sample_financials <- data.frame(
  category = c("Total Revenue", "Program Expenses", "Administrative", "Fundraising", "Total Expenses", "Net Income"),
  ytd_actual = c(875000, 612500, 87500, 52500, 752500, 122500),
  ytd_budget = c(850000, 595000, 85000, 51000, 731000, 119000),
  variance = c(25000, -17500, -2500, -1500, -21500, 3500),
  variance_pct = c(2.9, -2.9, -2.9, -2.9, -2.9, 2.9),
  prior_year = c(825000, 577500, 82500, 49500, 709500, 115500)
)

kpi_data <- data.frame(
  metric = c("Total Donors", "Retention Rate", "Avg Gift Size", "Programs Served"),
  current = c(1847, 68.5, 472, 3241),
  target = c(2000, 70.0, 500, 3500),
  trend = c("up", "stable", "up", "up")
)

# UI
ui <- fluidPage(
  theme = professional_theme,
  
  tags$head(
    tags$link(rel="stylesheet", type="text/css", href="www/shared-styles.css")
  ),
  
  useShinyjs(),
  
  # Hero Section with Brand Gradient
  div(
    class = "hero-section",
    style = "background: linear-gradient(-45deg, #F9B397, #D68A93, #AD92B1, #B07891); background-size: 200% 100%; animation: gradient 15s ease infinite; color: white; text-align: center; padding: 3rem 2rem; margin-bottom: 2rem;",
    div(icon("file-text"), style = "font-size: 3rem; margin-bottom: 1rem;"),
    h1("Board Packet Generator", style = "color: white; font-size: 2.5rem; font-weight: 700; margin-bottom: 1rem;"),
    p("Professional board materials with automated insights and data visualization", 
      style = "color: rgba(255,255,255,0.9); font-size: 1.2rem; margin-bottom: 0;")
  ),
  
  # Guided Steps Navigation
  div(
    style = "display: flex; justify-content: center; align-items: center; margin: 2rem 0; gap: 1rem;",
    span(class = "step-item active", id = "step1", "Upload Data"),
    span("→", style = "color: #bdc3c7; margin: 0 0.5rem;"),
    span(class = "step-item", id = "step2", "Review Materials"),
    span("→", style = "color: #bdc3c7; margin: 0 0.5rem;"),
    span(class = "step-item", id = "step3", "Generate Packet")
  ),
  
  # Main content
  layout_sidebar(
    sidebar = sidebar(
      title = "Meeting Setup",
      width = 300,
      
      # Meeting Information
      div(
        style = "margin-bottom: 2rem;",
        h5("Meeting Information"),
        textInput("meeting_title", "Meeting Title",
                 value = "Q4 2024 Board of Directors Meeting"),
        dateInput("meeting_date", "Meeting Date", value = Sys.Date() + 14),
        textInput("meeting_time", "Time", value = "5:30 PM"),
        textInput("meeting_location", "Location", value = "Executive Conference Room")
      ),
      
      # File upload
      div(
        style = "margin-bottom: 2rem;",
        h5("Financial Data"),
        fileInput("file", "Upload Financial Data (CSV)",
                 accept = c(".csv"),
                 placeholder = "budget_vs_actual.csv"),
        div(
          class = "alert alert-info",
          style = "font-size: 0.85rem;",
          strong("Sample data included"), br(),
          "Upload your budget vs. actual data for custom analysis"
        )
      ),
      
      # Board Packet Components
      checkboxGroupInput(
        "components",
        h5("Select Components"),
        choices = list(
          "Executive Summary" = "summary",
          "Financial Analysis" = "financials", 
          "Meeting Agenda" = "agenda",
          "KPI Dashboard" = "kpi",
          "Strategic Updates" = "strategy"
        ),
        selected = c("summary", "financials", "agenda", "kpi")
      )
    ),
    
    # Main content area - Professional tabbed interface
    navset_card_pill(
      nav_panel(
        "Executive Summary",
        icon = icon("chart-line"),
        
        # Key Financial Metrics Grid
        div(
          class = "metric-group",
          div(
            class = "metric-display",
            div(class = "metric-number", "$875K"),
            div(class = "metric-label", "Total Revenue")
          ),
          div(
            class = "metric-display", 
            div(class = "metric-number", "103%"),
            div(class = "metric-label", "Budget Attainment")
          ),
          div(
            class = "metric-display",
            div(class = "metric-number", "$122.5K"),
            div(class = "metric-label", "Net Income")
          ),
          div(
            class = "metric-display",
            div(class = "metric-number", "4.2 mo"),
            div(class = "metric-label", "Cash Position")
          )
        ),
        
        br(),
        
        # Executive Summary
        div(
          class = "insight-callout",
          h4("Executive Summary"),
          p(textOutput("executive_summary"))
        ),
        
        # Financial Chart
        div(
          style = "margin-top: 2rem;",
          h5("Financial Performance"),
          plotlyOutput("financial_overview", height = "300px")
        )
      ),
      
      nav_panel(
        "Meeting Agenda",
        icon = icon("list-check"),
        p(
          class = "text-muted mb-3",
          icon("info-circle"),
          " Click any cell to edit agenda content directly in the table."
        ),
        DTOutput("agenda_preview")
      ),
      
      nav_panel(
        "Generate Packet",
        icon = icon("download"),
        
        div(
          class = "row",
          div(
            class = "col-md-8",
            
            # Selected Components Preview
            div(
              class = "disclosure-section",
              div(
                class = "disclosure-header",
                onclick = "$(this).parent().toggleClass('expanded');",
                h4("Selected Components", class = "disclosure-title"),
                span("▼", class = "disclosure-icon")
              ),
              div(
                class = "disclosure-content",
                uiOutput("selected_components_list")
              )
            ),
            
            br(),
            
            # Quality Checklist
            div(
              style = "background: #f8f9fa; padding: 1.5rem; border-radius: 8px; margin-bottom: 2rem;",
              checkboxGroupInput(
                "quality_checklist",
                h5("Quality Checklist"),
                choices = list(
                  "All financial data is current" = "financial_current",
                  "Minutes have been reviewed" = "minutes_reviewed",
                  "All reports are complete" = "reports_complete",
                  "Confidential items marked" = "confidential_marked"
                ),
                selected = c("financial_current", "minutes_reviewed", "reports_complete")
              )
            )
          ),
          
          div(
            class = "col-md-4",
            
            # Download Options Card
            div(
              style = "background: white; border: 1px solid #e9ecef; border-radius: 12px; padding: 2rem;",
              h5("Download Options"),
              
              checkboxInput(
                "include_watermark",
                "Add 'CONFIDENTIAL' watermark",
                value = FALSE
              ),
              
              checkboxInput(
                "include_page_numbers",
                "Include page numbers",
                value = TRUE
              ),
              
              checkboxInput(
                "include_toc",
                "Generate table of contents",
                value = TRUE
              ),
              
              hr(),
              
              div(
                class = "text-center mb-3",
                p(class = "metric-value", textOutput("page_estimate", inline = TRUE), " pages estimated")
              ),
              
              downloadButton(
                "generate_packet",
                "Generate HTML Report",
                class = "btn btn-primary btn-lg w-100 mb-3",
                icon = icon("download")
              ),
              
              actionButton(
                "email_preview",
                "Preview Email to Board",
                class = "btn btn-outline-secondary w-100",
                icon = icon("envelope")
              )
            )
          )
        )
      )
    ),
    
    br(),
    
    # Branding
    div(
      class = "powered-by",
      "Professional board materials powered by ",
      tags$a("Daly Analytics", href = "https://www.dalyanalytics.com", target = "_blank")
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
          h5("Need Custom Board Analytics Tools?", style = "color: white; margin-bottom: 1rem;"),
          p(
            style = "color: rgba(255,255,255,0.9); margin-bottom: 1rem;",
            "This board packet generator demonstrates professional governance analytics capabilities. ",
            "Daly Analytics creates custom board reporting solutions that transform organizational data into strategic insights."
          ),
          div(
            class = "mb-3",
            tags$ul(
              class = "list-unstyled",
              style = "color: rgba(255,255,255,0.8);",
              tags$li(icon("check"), " Automated board packet generation"),
              tags$li(icon("check"), " Real-time financial dashboards"),
              tags$li(icon("check"), " Strategic KPI tracking systems"),
              tags$li(icon("check"), " Custom governance reporting"),
              tags$li(icon("check"), " Board portal integrations")
            )
          )
        ),
        div(
          class = "col-md-4 text-center",
          div(
            style = "background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 12px;",
            h6("Ready to Streamline Board Governance?", style = "color: white; margin-bottom: 1rem;"),
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
          "© 2025 Daly Analytics LLC. This free tool was built to demonstrate our expertise in board governance analytics. ",
          tags$a(
            "Contact us",
            href = "https://www.dalyanalytics.com/contact",
            style = "color: #d68a93;",
            target = "_blank"
          ),
          " to build custom board solutions for your organization."
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values
  agenda_items <- reactiveVal(sample_agenda_items)
  
  values <- reactiveValues(
    data_loaded = TRUE,
    financial_data = sample_financials,
    agenda_data = sample_agenda_items
  )
  
  # File upload handling
  observeEvent(input$file, {
    req(input$file)
    
    tryCatch({
      df <- read.csv(input$file$datapath, stringsAsFactors = FALSE)
      values$financial_data <- df
      showNotification("Financial data uploaded successfully!", type = "message", duration = 3)
      
      # Update steps
      shinyjs::runjs("
        $('#step1').addClass('completed').removeClass('active');
        $('#step2').addClass('active completed').removeClass('');
        $('#step3').addClass('active').removeClass('completed');
      ")
      
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message), 
                      type = "error", duration = 8)
    })
  })
  
  # Initially set steps for sample data
  observe({
    shinyjs::runjs("
      $('#step1').addClass('completed').removeClass('active');
      $('#step2').addClass('active completed').removeClass('');  
      $('#step3').addClass('active').removeClass('completed');
    ")
  })
  
  # Executive summary
  output$executive_summary <- renderText({
    paste0("The organization demonstrates strong financial performance with total revenue of $875K, ",
           "representing 103% of budget attainment. Net income of $122.5K provides healthy operating margin. ",
           "Expense management remains disciplined with strong cash position of 4.2 months reserves. ",
           "All key performance indicators trending positively for strategic growth initiatives.")
  })
  
  # Financial overview plot
  output$financial_overview <- renderPlotly({
    comparison_data <- data.frame(
      Category = rep(c("Revenue", "Expenses"), each = 3),
      Type = rep(c("Actual", "Budget", "Prior Year"), 2),
      Amount = c(875000, 850000, 825000, 752500, 731000, 709500)
    )
    
    p <- plot_ly(
      comparison_data,
      x = ~Category,
      y = ~Amount,
      color = ~Type,
      type = "bar",
      colors = c("#d68a93", "#34495e", "#7f8c8d"),
      text = ~paste0("$", format(Amount/1000, digits = 1), "K"),
      textposition = "outside",
      hovertemplate = "%{x}<br>$%{y:,.0f}<extra></extra>"
    ) %>%
      layout(
        title = "",
        xaxis = list(title = ""),
        yaxis = list(title = "Amount ($)", tickformat = "$,.0f"),
        barmode = "group",
        plot_bgcolor = "rgba(0,0,0,0)",
        paper_bgcolor = "rgba(0,0,0,0)",
        font = list(family = "Arial", size = 12),
        margin = list(l = 50, r = 50, t = 20, b = 50),
        showlegend = TRUE,
        legend = list(orientation = "h", y = -0.2)
      )
    
    p
  })
  
  # Agenda preview with editable cells
  output$agenda_preview <- renderDT({
    datatable(
      agenda_items(),
      options = list(
        pageLength = 15,
        dom = 'tp',
        columnDefs = list(
          list(width = '10%', targets = 0),
          list(width = '40%', targets = 1),
          list(width = '20%', targets = 2),
          list(width = '15%', targets = 3),
          list(width = '15%', targets = 4)
        ),
        scrollY = "400px",
        scrollCollapse = TRUE
      ),
      rownames = FALSE,
      colnames = c("Item #", "Topic", "Presenter", "Time", "Materials"),
      class = "display compact row-border hover",
      selection = "none",
      editable = TRUE,
      escape = FALSE
    )
  })
  
  # Handle agenda table edits
  observeEvent(input$agenda_preview_cell_edit, {
    info <- input$agenda_preview_cell_edit
    current_data <- agenda_items()
    current_data[info$row, info$col + 1] <- info$value
    agenda_items(current_data)
  })
  
  
  # Selected components list
  output$selected_components_list <- renderUI({
    components_map <- list(
      "summary" = "Executive Summary",
      "financials" = "Financial Analysis", 
      "agenda" = "Meeting Agenda",
      "kpi" = "KPI Dashboard",
      "strategy" = "Strategic Updates"
    )
    
    selected <- input$components
    if (length(selected) == 0) {
      return(p(class = "text-muted", "No components selected"))
    }
    
    tags$ul(
      class = "list-unstyled",
      lapply(selected, function(comp) {
        tags$li(
          icon("check-circle", class = "text-success me-2"),
          components_map[[comp]] %||% comp
        )
      })
    )
  })
  
  # Page estimate
  output$page_estimate <- renderText({
    base_pages <- length(input$components) * 2 + 3
    if ("financials" %in% input$components) base_pages <- base_pages + 3
    if ("strategy" %in% input$components) base_pages <- base_pages + 2
    as.character(base_pages)
  })
  
  # Generate board packet download
  output$generate_packet <- downloadHandler(
    filename = function() {
      paste0("Board_Packet_", format(input$meeting_date, "%Y%m%d"), ".html")
    },
    content = function(file) {
      # Generate HTML report
      html_content <- generate_board_packet_html(
        meeting_title = input$meeting_title,
        meeting_date = input$meeting_date,
        meeting_time = input$meeting_time,
        meeting_location = input$meeting_location,
        components = input$components,
        agenda_data = agenda_items(),
        financial_data = values$financial_data,
        include_watermark = input$include_watermark,
        include_toc = input$include_toc
      )
      
      writeLines(html_content, file)
      
      # Show completion notification
      showNotification("Board packet generated successfully!", type = "message", duration = 5)
      
      # Update step 3 to completed
      shinyjs::runjs("$('#step3').addClass('completed').removeClass('active');")
    }
  )
  
  # Email preview modal
  observeEvent(input$email_preview, {
    showModal(modalDialog(
      title = "Email Preview",
      size = "l",
      div(
        class = "email-preview",
        h5("To: Board of Directors"),
        h5("Subject: Board Packet - ", format(input$meeting_date, "%B %d, %Y"), " Meeting"),
        hr(),
        p("Dear Board Members,"),
        p("Please find attached the board packet for our upcoming meeting on ", 
          format(input$meeting_date, "%B %d, %Y"), " at ", input$meeting_time, "."),
        p("Meeting Location: ", input$meeting_location),
        br(),
        p("Best regards,"),
        p("Executive Director")
      ),
      footer = tagList(
        modalButton("Close"),
        actionButton("send_email", "Send Email", class = "btn btn-primary")
      )
    ))
  })
}

# Function to generate HTML board packet
generate_board_packet_html <- function(meeting_title, meeting_date, meeting_time, meeting_location, 
                                       components, agenda_data, financial_data, 
                                       include_watermark = FALSE, include_toc = TRUE) {
  
  # Basic HTML structure
  html_content <- paste0(
    '<!DOCTYPE html>\n',
    '<html lang="en">\n',
    '<head>\n',
    '  <meta charset="UTF-8">\n',
    '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n',
    '  <title>', meeting_title, '</title>\n',
    '  <style>\n',
    '    body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }\n',
    '    h1 { color: #2c3e50; border-bottom: 3px solid #d68a93; padding-bottom: 10px; }\n',
    '    h2 { color: #34495e; margin-top: 30px; }\n',
    '    .header { text-align: center; margin-bottom: 40px; }\n',
    '    .meeting-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }\n',
    '    table { width: 100%; border-collapse: collapse; margin: 20px 0; }\n',
    '    th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }\n',
    '    th { background: #f8f9fa; font-weight: 600; }\n',
    '    .watermark { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%) rotate(-45deg); \n',
    '                 font-size: 100px; color: rgba(220, 53, 69, 0.1); z-index: -1; }\n',
    '    .metric { display: inline-block; margin: 10px; padding: 15px; background: white; \n',
    '              border: 2px solid #e9ecef; border-radius: 8px; text-align: center; }\n',
    '    .metric-value { font-size: 24px; font-weight: bold; color: #2c3e50; }\n',
    '    .metric-label { color: #7f8c8d; font-size: 12px; }\n',
    '  </style>\n',
    '</head>\n',
    '<body>\n'
  )
  
  # Add watermark if requested
  if (include_watermark) {
    html_content <- paste0(html_content, '<div class="watermark">CONFIDENTIAL</div>\n')
  }
  
  # Header
  html_content <- paste0(
    html_content,
    '<div class="header">\n',
    '<h1>', meeting_title, '</h1>\n',
    '<div class="meeting-info">\n',
    '<p><strong>Date:</strong> ', format(meeting_date, "%B %d, %Y"), '</p>\n',
    '<p><strong>Time:</strong> ', meeting_time, '</p>\n',
    '<p><strong>Location:</strong> ', meeting_location, '</p>\n',
    '</div>\n',
    '</div>\n'
  )
  
  # Table of contents
  if (include_toc) {
    html_content <- paste0(
      html_content,
      '<h2>Table of Contents</h2>\n',
      '<ul>\n'
    )
    
    if ("summary" %in% components) html_content <- paste0(html_content, '<li>Executive Summary</li>\n')
    if ("agenda" %in% components) html_content <- paste0(html_content, '<li>Meeting Agenda</li>\n')
    if ("financials" %in% components) html_content <- paste0(html_content, '<li>Financial Analysis</li>\n')
    if ("kpi" %in% components) html_content <- paste0(html_content, '<li>Key Performance Indicators</li>\n')
    if ("strategy" %in% components) html_content <- paste0(html_content, '<li>Strategic Updates</li>\n')
    
    html_content <- paste0(html_content, '</ul>\n')
  }
  
  # Add selected components
  if ("summary" %in% components) {
    html_content <- paste0(
      html_content,
      '<h2>Executive Summary</h2>\n',
      '<p>The organization demonstrates strong financial performance with total revenue of $875K, ',
      'representing 103% of budget attainment. Net income of $122.5K provides healthy operating margin. ',
      'Cash position ensures adequate liquidity for operational needs and strategic initiatives.</p>\n',
      '<div class="metric">\n',
      '<div class="metric-value">$875K</div>\n',
      '<div class="metric-label">Total Revenue</div>\n',
      '</div>\n',
      '<div class="metric">\n',
      '<div class="metric-value">103%</div>\n',
      '<div class="metric-label">Budget Attainment</div>\n',
      '</div>\n',
      '<div class="metric">\n',
      '<div class="metric-value">$122.5K</div>\n',
      '<div class="metric-label">Net Income</div>\n',
      '</div>\n',
      '<div class="metric">\n',
      '<div class="metric-value">4.2 mo</div>\n',
      '<div class="metric-label">Cash Position</div>\n',
      '</div>\n'
    )
  }
  
  if ("agenda" %in% components) {
    html_content <- paste0(
      html_content,
      '<h2>Meeting Agenda</h2>\n',
      '<table>\n',
      '<thead><tr><th>Item #</th><th>Topic</th><th>Presenter</th><th>Time</th><th>Materials</th></tr></thead>\n',
      '<tbody>\n'
    )
    
    for (i in 1:nrow(agenda_data)) {
      html_content <- paste0(
        html_content,
        '<tr>',
        '<td>', agenda_data$item_no[i], '</td>',
        '<td>', agenda_data$topic[i], '</td>',
        '<td>', agenda_data$presenter[i], '</td>',
        '<td>', agenda_data$time_allotted[i], '</td>',
        '<td>', agenda_data$materials[i], '</td>',
        '</tr>\n'
      )
    }
    
    html_content <- paste0(html_content, '</tbody>\n</table>\n')
  }
  
  # Close HTML
  html_content <- paste0(html_content, '</body>\n</html>')
  
  return(html_content)
}

shinyApp(ui = ui, server = server)