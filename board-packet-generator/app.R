library(shiny)
library(plotly)
library(DT)
library(dplyr)
library(tidyr)
library(bslib)

# Professional corporate color scheme
corporate_colors <- list(
  primary = "#2c3e50",      # Professional dark blue-gray
  secondary = "#34495e",    # Slightly lighter blue-gray
  accent = "#d68a93",       # Your brand pink accent
  success = "#27ae60",      # Professional green
  warning = "#f39c12",      # Professional amber
  danger = "#e74c3c",       # Professional red
  light = "#ecf0f1",        # Light gray background
  dark = "#2c3e50",         # Dark blue-gray
  text = "#2c3e50",         # Dark text
  muted = "#7f8c8d"         # Muted gray text
)

# Professional CSS styling with system fonts
professional_css <- "
/* Use system fonts for better reliability */

/* Global styles */
html, body {
  height: 100%;
  margin: 0;
  padding: 0;
}

body {
  color: #2c3e50;
  background-color: #ffffff;
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

/* Navbar styling */
.navbar {
  background: linear-gradient(-45deg, #F9B397, #D68A93, #AD92B1, #B07891) !important;
  background-size: 200% 100%;
  animation: gradient 15s ease infinite;
  border-radius: 0;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

@keyframes gradient {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
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
  color: white !important;
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

/* Fix for bslib page_navbar active state */
.nav-pills .nav-link.active,
.nav-pills .show > .nav-link,
.navbar .nav-link.active,
.navbar .navbar-nav .active > .nav-link {
  background-color: #2c3e50 !important;
  color: white !important;
}

/* Override Bootstrap's default nav styling */
.nav-link {
  color: #2c3e50 !important;
  border-radius: 8px !important;
  transition: all 0.2s ease !important;
}

.nav-link:hover {
  background-color: rgba(255,255,255,0.1) !important;
  color: white !important;
}

/* Remove any borders from nav items */
.nav-item,
.nav-link,
.nav-pills .nav-link {
  border: none !important;
}

/* Ensure the navbar background stays consistent */
.navbar-nav {
  background: transparent !important;
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
  background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
  border-bottom: 2px solid #d68a93;
  font-weight: 600;
  font-size: 1.1rem;
  color: #2c3e50;
  padding: 1rem 1.5rem;
}

/* Sidebar styling */
.bslib-sidebar-layout > .sidebar {
  background: #fafafa;
  border-right: 1px solid #e9ecef;
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
  border-color: #d68a93;
  box-shadow: 0 0 0 0.2rem rgba(214, 138, 147, 0.15);
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
  background: #d68a93;
  border-color: #d68a93;
  color: white;
  box-shadow: 0 4px 12px rgba(214, 138, 147, 0.3);
}

.btn-primary:hover {
  background: #c17882;
  border-color: #c17882;
  box-shadow: 0 6px 20px rgba(214, 138, 147, 0.4);
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
  color: #d68a93;
  border-color: #d68a93;
  background: transparent;
}

.btn-outline-primary:hover {
  background: #d68a93;
  border-color: #d68a93;
  color: white;
}

/* Value boxes */
.value-box {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.05);
  padding: 1.5rem;
  border-top: 4px solid #d68a93;
}

/* Override bslib value box for outlined style */
.bslib-value-box {
  background: white !important;
  border: 2px solid #dee2e6 !important;
  color: #2c3e50 !important;
}

.bslib-value-box.bg-success {
  background: white !important;
  border: 2px solid #27ae60 !important;
}

.bslib-value-box.bg-primary {
  background: white !important;
  border: 2px solid #e74c3c !important;
}

.bslib-value-box.bg-warning {
  background: white !important;
  border: 2px solid #f39c12 !important;
}

.bslib-value-box.bg-info {
  background: white !important;
  border: 2px solid #f1c40f !important;
}

.bslib-value-box .value-box-title,
.value-box-title {
  color: #6c757d !important;
  font-size: 0.9rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.5rem;
}

.bslib-value-box .value-box-value,
.value-box-value {
  color: #2c3e50 !important;
  font-size: 2rem;
  font-weight: 700;
  font-family: serif;
}

.bslib-value-box.bg-success .value-box-showcase {
  color: #27ae60 !important;
}

.bslib-value-box.bg-primary .value-box-showcase {
  color: #e74c3c !important;
}

.bslib-value-box.bg-warning .value-box-showcase {
  color: #f39c12 !important;
}

.bslib-value-box.bg-info .value-box-showcase {
  color: #f1c40f !important;
}

.bslib-value-box p {
  color: #6c757d !important;
}

/* Professional tables */
.dataTable {
  font-size: 0.95rem;
}

.table thead th {
  background: #fafafa;
  color: #2c3e50;
  font-weight: 600;
  text-transform: uppercase;
  font-size: 0.85rem;
  letter-spacing: 0.05em;
  padding: 1rem;
  border-bottom: 2px solid #e9ecef;
}

/* Status badges */
.badge {
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 500;
  font-size: 0.85rem;
  letter-spacing: 0.02em;
}

.badge-success {
  background: #d4edda;
  color: #155724;
}

.badge-warning {
  background: #fff3cd;
  color: #856404;
}

.badge-info {
  background: #d1ecf1;
  color: #0c5460;
}

/* Preview sections */
.preview-section {
  background: #fafafa;
  border-left: 4px solid #d68a93;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
  border-radius: 0 8px 8px 0;
}

.preview-section h4 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

/* File upload area */
.file-upload-area {
  border: 2px dashed #e9ecef;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  background: #fafafa;
  transition: all 0.3s ease;
}

.file-upload-area:hover {
  border-color: #d68a93;
  background: #fff;
}

/* Checkbox and radio styling */
.checkbox label, .radio label {
  font-weight: 400;
  cursor: pointer;
  padding: 0.5rem 0;
}

/* Executive summary box */
.executive-summary {
  background: linear-gradient(135deg, #ffffff 0%, #fafafa 100%);
  border-left: 4px solid #d68a93;
  padding: 2rem;
  margin: 2rem 0;
  border-radius: 0 12px 12px 0;
}

/* Metric cards */
.metric-card {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  text-align: center;
  border: 1px solid #e9ecef;
  transition: all 0.3s ease;
}

.metric-card:hover {
  border-color: #d68a93;
  box-shadow: 0 4px 12px rgba(214, 138, 147, 0.15);
}

.metric-value {
  font-size: 2.5rem;
  font-weight: 700;
  color: #2c3e50;
  font-family: serif;
}

.metric-label {
  color: #7f8c8d;
  font-size: 0.9rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-top: 0.5rem;
}

/* Loading animation */
.loading-overlay {
  background: rgba(255,255,255,0.9);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

/* Tooltips */
.tooltip-inner {
  background: #2c3e50;
  font-size: 0.9rem;
  padding: 0.5rem 1rem;
  border-radius: 6px;
}

/* Professional navigation tabs */
.nav-tabs {
  border-bottom: 2px solid #e9ecef;
  margin-bottom: 2rem;
}

.nav-tabs .nav-link {
  color: #7f8c8d;
  font-weight: 500;
  padding: 0.75rem 1.5rem;
  border: none;
  border-bottom: 3px solid transparent;
  transition: all 0.2s ease;
}

.nav-tabs .nav-link:hover {
  color: #2c3e50;
  border-bottom-color: #e9ecef;
}

.nav-tabs .nav-link.active {
  color: #d68a93;
  background: transparent;
  border: none;
  border-bottom: 3px solid #d68a93;
}

/* Drag and drop styles */
.dt-rowReorder-moving {
  background-color: #d68a93 !important;
  opacity: 0.8;
}

.dt-rowReorder-drop-marker {
  border: 2px solid #d68a93 !important;
}

.draggable-row {
  cursor: move;
  transition: background-color 0.2s ease;
}

.draggable-row:hover {
  background-color: #fafafa !important;
}

.drag-handle {
  color: #7f8c8d;
  cursor: grab;
  margin-right: 0.5rem;
  font-size: 1.2rem;
  font-weight: bold;
  display: inline-block;
  width: 20px;
  text-align: center;
  user-select: none;
}

.drag-handle:hover {
  color: #d68a93;
}

.drag-handle:active {
  cursor: grabbing;
  color: #2c3e50;
}

/* Make sure table cells are properly positioned for drag and drop */
.dataTable tbody td {
  position: relative;
}

/* First column with reorder handle */
.dataTable tbody td.reorder {
  cursor: move !important;
}

/* Highlight row being dragged */
table.dataTable.dt-rowReorder-moving {
  opacity: 0.8;
  background-color: #f8f9fa !important;
}

/* Ensure the table doesn't jump during reorder */
table.dataTable {
  table-layout: fixed;
}
"

# Custom theme with natural fonts - using preset for Shinylive compatibility
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
    "Board Chair", 
    "Secretary", 
    "Executive Director",
    "Treasurer/CFO", 
    "Strategic Planning Chair",
    "Development Director",
    "Committee Chairs",
    "Board Chair"
  ),
  time_allotted = c(
    "5 min", 
    "5 min", 
    "20 min",
    "15 min", 
    "20 min",
    "15 min",
    "20 min",
    "10 min"
  ),
  materials = c(
    "Agenda", 
    "Previous Minutes", 
    "ED Report",
    "Financial Statements", 
    "Progress Dashboard",
    "Campaign Update",
    "Committee Reports",
    "Action Items"
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

# KPI data
kpi_data <- data.frame(
  metric = c("Total Donors", "Retention Rate", "Avg Gift Size", "Programs Served"),
  current = c(1847, 68.5, 472, 3241),
  target = c(2000, 70.0, 500, 3500),
  trend = c("up", "stable", "up", "up")
)

ui <- tagList(
  tags$head(tags$style(HTML(professional_css))),
  
  div(
    class = "main-content",
    page_navbar(
      title = div(icon("file-contract"), "Board Packet Generator"),
      theme = professional_theme,
  
  nav_panel(
    title = "Meeting Setup",
    icon = icon("cog"),
    
    layout_columns(
      col_widths = c(4, 8),
      
      # Left sidebar
      div(
        card(
          card_header("Meeting Information"),
          textInput(
            "meeting_title", 
            "Meeting Title",
            value = "Q4 2024 Board of Directors Meeting",
            width = "100%"
          ),
          dateInput(
            "meeting_date", 
            "Meeting Date",
            value = Sys.Date() + 14,
            width = "100%"
          ),
          div(
            class = "row",
            div(
              class = "col-6",
              textInput("meeting_time", "Time", value = "5:30 PM", width = "100%")
            ),
            div(
              class = "col-6",
              textInput("meeting_duration", "Duration", value = "2 hours", width = "100%")
            )
          ),
          textInput(
            "meeting_location", 
            "Location",
            value = "Executive Conference Room / Zoom",
            width = "100%"
          ),
          textAreaInput(
            "meeting_notes",
            "Special Instructions",
            value = "Light refreshments will be served at 5:00 PM",
            height = "100px",
            width = "100%"
          )
        ),
        
        card(
          card_header("Board Packet Components"),
          checkboxGroupInput(
            "components",
            "Select Components:",
            choices = list(
              "Cover Page & Table of Contents" = "cover",
              "Meeting Agenda" = "agenda",
              "Previous Meeting Minutes" = "minutes",
              "Executive Director's Report" = "ed_report",
              "Financial Statements & Analysis" = "financials",
              "Key Performance Indicators" = "kpi",
              "Committee Reports" = "committees",
              "Strategic Plan Update" = "strategy",
              "Development Report" = "development",
              "Appendices & Supporting Docs" = "appendix"
            ),
            selected = c("cover", "agenda", "minutes", "ed_report", "financials", "kpi")
          )
        )
      ),
      
      # Right content area
      div(
        navset_card_pill(
          nav_panel(
            "Executive Summary",
            icon = icon("chart-line"),
            
            layout_columns(
              col_widths = c(3, 3, 3, 3),
              value_box(
                title = "Organization Health",
                value = "Strong",
                showcase = icon("heart-pulse"),
                theme = "success",
                p("All key indicators positive")
              ),
              value_box(
                title = "YTD Revenue",
                value = "$875K",
                showcase = icon("dollar-sign"),
                theme = "primary",
                p("102.9% of budget")
              ),
              value_box(
                title = "Cash Position",
                value = "4.2 mo",
                showcase = icon("piggy-bank"),
                theme = "warning",
                p("Operating reserves")
              ),
              value_box(
                title = "Board Attendance",
                value = "87%",
                showcase = icon("users"),
                theme = "info",
                p("Last 3 meetings avg")
              )
            ),
            
            card(
              card_header("Financial Snapshot"),
              plotlyOutput("financial_overview", height = "300px")
            ),
            
            card(
              card_header("Key Performance Metrics"),
              DTOutput("kpi_table")
            )
          ),
          
          nav_panel(
            "Meeting Agenda",
            icon = icon("list-check"),
            card(
              card_header("Agenda Preview"),
              p(
                class = "text-muted mb-3",
                icon("info-circle"),
                " Click any cell to edit content. Drag rows using the ", 
                icon("bars"), " handle to reorder agenda items."
              ),
              DTOutput("agenda_preview")
            )
          ),
          
          nav_panel(
            "Reports & Documents",
            icon = icon("file-alt"),
            
            accordion(
              id = "reports_accordion",
              
              accordion_panel(
                "Executive Director's Report",
                icon = icon("user-tie"),
                textAreaInput(
                  "ed_report_text",
                  "Report Content",
                  value = "Dear Board Members,\n\nI'm pleased to present this quarter's executive report highlighting our significant achievements and strategic progress...\n\n### Program Highlights\n- Served 15% more beneficiaries than projected\n- Launched two new pilot programs\n- Received national recognition for innovation\n\n### Challenges & Opportunities\n- Staffing: Successfully filled 3 key positions\n- Funding: Secured $250K in new grants\n- Technology: Implemented new CRM system\n\n### Looking Ahead\nOur focus for the next quarter will be on scaling successful programs and strengthening our infrastructure for sustainable growth.",
                  height = "400px",
                  width = "100%"
                ),
                fileInput(
                  "ed_attachments",
                  "Attach Supporting Documents",
                  multiple = TRUE,
                  accept = c(".pdf", ".docx", ".xlsx")
                )
              ),
              
              accordion_panel(
                "Financial Reports",
                icon = icon("chart-pie"),
                p(class = "text-muted", "Financial data will be automatically generated from the sample data or your uploaded files."),
                radioButtons(
                  "financial_source",
                  "Data Source:",
                  choices = c("Use Sample Data" = "sample", "Upload Financial Statements" = "upload"),
                  selected = "sample",
                  inline = TRUE
                ),
                conditionalPanel(
                  condition = "input.financial_source == 'upload'",
                  fileInput(
                    "financial_upload",
                    "Upload Financial Statements",
                    accept = c(".xlsx", ".csv")
                  )
                )
              ),
              
              accordion_panel(
                "Previous Meeting Minutes",
                icon = icon("clock-rotate-left"),
                radioButtons(
                  "minutes_source",
                  "Minutes Source:",
                  choices = c("Enter Manually" = "manual", "Upload Document" = "upload"),
                  selected = "manual",
                  inline = TRUE
                ),
                conditionalPanel(
                  condition = "input.minutes_source == 'manual'",
                  textAreaInput(
                    "minutes_text",
                    "Meeting Minutes",
                    value = "MINUTES OF THE BOARD OF DIRECTORS\n[Previous Meeting Date]\n\nPresent: [List attendees]\nAbsent: [List absences]\n\nThe meeting was called to order at 5:30 PM by Board Chair...\n\n1. APPROVAL OF AGENDA\nMotion to approve the agenda. Motion carried unanimously.\n\n2. APPROVAL OF PREVIOUS MINUTES\nMotion to approve minutes from [date]. Motion carried.\n\n3. FINANCIAL REPORT\n[Treasurer] presented the financial statements...\n\nThe meeting was adjourned at 7:30 PM.",
                    height = "300px",
                    width = "100%"
                  )
                ),
                conditionalPanel(
                  condition = "input.minutes_source == 'upload'",
                  fileInput(
                    "minutes_upload",
                    "Upload Minutes Document",
                    accept = c(".docx", ".pdf", ".txt")
                  )
                )
              )
            )
          )
        )
      )
    )
  ),
  
  nav_panel(
    title = "Generate & Download",
    icon = icon("download"),
    
    layout_columns(
      col_widths = c(8, 4),
      
      card(
        card_header("Board Packet Preview"),
        div(
          class = "preview-section",
          h4("Selected Components"),
          uiOutput("selected_components_list"),
          hr(),
          h4("Estimated Page Count"),
          p(
            class = "metric-value",
            textOutput("page_estimate", inline = TRUE),
            " pages"
          )
        ),
        
        card(
          card_header("Quality Checklist"),
          div(
            class = "form-check mb-2",
            tags$input(type = "checkbox", class = "form-check-input", id = "check1", checked = TRUE),
            tags$label(class = "form-check-label", `for` = "check1", "All financial data is current")
          ),
          div(
            class = "form-check mb-2",
            tags$input(type = "checkbox", class = "form-check-input", id = "check2", checked = TRUE),
            tags$label(class = "form-check-label", `for` = "check2", "Minutes have been reviewed")
          ),
          div(
            class = "form-check mb-2",
            tags$input(type = "checkbox", class = "form-check-input", id = "check3", checked = TRUE),
            tags$label(class = "form-check-label", `for` = "check3", "All reports are complete")
          ),
          div(
            class = "form-check mb-2",
            tags$input(type = "checkbox", class = "form-check-input", id = "check4"),
            tags$label(class = "form-check-label", `for` = "check4", "Confidential items marked")
          )
        )
      ),
      
      card(
        card_header("Download Options"),
        
        p(
          class = "text-muted mb-3",
          icon("info-circle"),
          "Generate an HTML report that can be viewed in any browser and saved as PDF using your browser's print function."
        ),
        
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
        
        downloadButton(
          "generate_packet",
          "Generate HTML Report",
          class = "btn btn-primary btn-lg w-100",
          icon = icon("download")
        ),
        
        br(), br(),
        
        actionButton(
          "email_preview",
          "Preview Email to Board",
          class = "btn btn-outline-secondary w-100",
          icon = icon("envelope")
        ),
        
        br(), br(),
        
        div(
          class = "text-muted small",
          icon("info-circle"),
          "Board packets are automatically saved to your organization's document repository"
        )
      )
    )
  ),
  
  nav_spacer(),
  
  nav_item(
    tags$a(
      icon("question-circle"),
      "Help",
      href = "#",
      class = "nav-link"
    )
  )
    )
  ),
  
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
            "This board packet generator demonstrates the power of custom-built nonprofit analytics solutions. ",
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

server <- function(input, output, session) {
  
  # Reactive values
  agenda_items <- reactiveVal(sample_agenda_items)
  
  # Financial overview plot
  output$financial_overview <- renderPlotly({
    
    # Create comparison data
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
      text = ~paste0("$", format(Amount, big.mark = ",")),
      textposition = "outside",
      hovertemplate = "%{x}<br>%{text}<extra></extra>"
    ) %>%
      layout(
        title = list(text = "YTD Financial Performance", font = list(family = "serif")),
        xaxis = list(title = ""),
        yaxis = list(title = "Amount ($)", tickformat = "$,.0f"),
        barmode = "group",
        plot_bgcolor = "#ffffff",
        paper_bgcolor = "white",
        font = list(family = "sans-serif"),
        margin = list(t = 50)
      )
    
    p
  })
  
  # KPI table
  output$kpi_table <- renderDT({
    datatable(
      kpi_data,
      options = list(
        dom = 't',
        paging = FALSE,
        searching = FALSE,
        columnDefs = list(
          list(className = 'dt-center', targets = '_all')
        )
      ),
      rownames = FALSE,
      colnames = c("Metric", "Current", "Target", "Trend"),
      class = "display compact"
    ) %>%
      formatCurrency(columns = c("current", "target"), currency = "", digits = 0) %>%
      formatStyle(
        "trend",
        color = styleEqual(c("up", "down", "stable"), c("#27ae60", "#e74c3c", "#f39c12")),
        fontWeight = "bold"
      )
  })
  
  # Agenda preview with RowReorder - simplified approach matching the working example
  output$agenda_preview <- renderDT({
    datatable(
      agenda_items(),
      colnames = c("Item #" = 1),
      extensions = 'RowReorder',
      options = list(
        rowReorder = TRUE,
        order = list(c(0, 'asc')),
        pageLength = 15,
        dom = 't',
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
      class = "display compact row-border hover",
      selection = "none",
      editable = TRUE
    )
  }, server = FALSE)
  
  # Handle agenda table edits
  observeEvent(input$agenda_preview_cell_edit, {
    info <- input$agenda_preview_cell_edit
    
    # Get current data
    current_data <- agenda_items()
    
    # Update the cell (adjust for 1-based indexing)
    current_data[info$row, info$col + 1] <- info$value
    
    # Update reactive value
    agenda_items(current_data)
  })
  
  # Capture the reordered state for HTML generation
  observeEvent(input$agenda_preview_rows_all, {
    req(input$agenda_preview_rows_all)
    
    current_data <- agenda_items()
    displayed_order <- input$agenda_preview_rows_all
    
    # Only reorder if the order has actually changed and lengths match
    if (length(displayed_order) == nrow(current_data)) {
      original_order <- seq_len(nrow(current_data))
      
      # Check if order has changed
      if (!identical(displayed_order, original_order)) {
        cat("Reordering data based on display order:", paste(displayed_order, collapse = ", "), "\n")
        
        # Reorder the data according to the displayed order
        reordered_data <- current_data[displayed_order, ]
        
        # Update item numbers to maintain sequence
        reordered_data$item_no <- seq_len(nrow(reordered_data))
        
        cat("New topic order:", paste(reordered_data$topic, collapse = " | "), "\n")
        
        # Update the reactive value
        agenda_items(reordered_data)
      }
    }
  })
  
  # Selected components list
  output$selected_components_list <- renderUI({
    components_map <- list(
      cover = "Cover Page & Table of Contents",
      agenda = "Meeting Agenda",
      minutes = "Previous Meeting Minutes",
      ed_report = "Executive Director's Report",
      financials = "Financial Statements & Analysis",
      kpi = "Key Performance Indicators",
      committees = "Committee Reports",
      strategy = "Strategic Plan Update",
      development = "Development Report",
      appendix = "Appendices & Supporting Documents"
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
          components_map[[comp]]
        )
      })
    )
  })
  
  # Page estimate
  output$page_estimate <- renderText({
    base_pages <- length(input$components) * 3
    if ("financials" %in% input$components) base_pages <- base_pages + 5
    if ("ed_report" %in% input$components) base_pages <- base_pages + 2
    if ("committees" %in% input$components) base_pages <- base_pages + 4
    
    as.character(base_pages)
  })
  
  
  # Email preview
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
        p("The packet includes:"),
        uiOutput("email_components_list"),
        p("Please review all materials before the meeting. If you have any questions, don't hesitate to reach out."),
        p("Best regards,"),
        p("Board Secretary")
      ),
      footer = tagList(
        modalButton("Close"),
        actionButton("send_email", "Send Email", class = "btn-primary", icon = icon("paper-plane"))
      )
    ))
  })
  
  # Download handler
  output$generate_packet <- downloadHandler(
    filename = function() {
      paste0("Board_Packet_", format(input$meeting_date, "%Y-%m-%d"), ".html")
    },
    content = function(file) {
      # Create professional HTML content
      html_content <- paste0(
        '<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>', input$meeting_title, '</title>
  <style>
    body {
      color: #2c3e50;
      line-height: 1.6;
      margin: 0;
      padding: 2rem;
      background-color: #ffffff;
    }
    .container {
      max-width: 900px;
      margin: 0 auto;
    }
    h1, h2, h3 {
      color: #2c3e50;
      font-weight: 700;
    }
    h1 {
      font-size: 2.5rem;
      text-align: center;
      border-bottom: 3px solid #d68a93;
      padding-bottom: 1rem;
      margin-bottom: 2rem;
    }
    h2 {
      font-size: 1.8rem;
      margin-top: 3rem;
      margin-bottom: 1.5rem;
      color: #34495e;
    }
    .meeting-info {
      background-color: #f8f9fa;
      border-left: 4px solid #d68a93;
      padding: 2rem;
      margin: 2rem 0;
      border-radius: 0 8px 8px 0;
    }
    .meeting-info p {
      margin: 0.5rem 0;
      font-size: 1.1rem;
    }
    .meeting-info strong {
      color: #2c3e50;
      font-weight: 600;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 2rem 0;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      border-radius: 8px;
      overflow: hidden;
    }
    th {
      background-color: #2c3e50;
      color: white;
      font-weight: 600;
      text-transform: uppercase;
      font-size: 0.9rem;
      letter-spacing: 0.05em;
      padding: 1rem;
      text-align: left;
    }
    td {
      padding: 1rem;
      border-bottom: 1px solid #e9ecef;
    }
    tr:hover {
      background-color: #f8f9fa;
    }
    .financial-summary {
      background: linear-gradient(135deg, #f8f9fa 0%, #fff 100%);
      padding: 2rem;
      border-radius: 8px;
      margin: 2rem 0;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .footer {
      margin-top: 4rem;
      padding-top: 2rem;
      border-top: 1px solid #dee2e6;
      text-align: center;
      color: #7f8c8d;
      font-size: 0.9rem;
      font-style: italic;
    }
    .confidential {
      color: #e74c3c;
      font-weight: bold;
      font-size: 0.9rem;
      text-transform: uppercase;
      letter-spacing: 0.1em;
      position: fixed;
      top: 10px;
      right: 10px;
      background: rgba(231, 76, 60, 0.1);
      padding: 0.5rem 1rem;
      border-radius: 4px;
      border: 1px solid #e74c3c;
    }
    @media print {
      body { padding: 1rem; }
      .confidential { position: absolute; }
      h2 { page-break-before: always; }
      h2:first-of-type { page-break-before: avoid; }
      table { page-break-inside: avoid; }
    }
  </style>
</head>
<body>'
      )
      
      # Add watermark if requested
      if (input$include_watermark) {
        html_content <- paste0(html_content, 
          '<div class="confidential">CONFIDENTIAL</div>')
      }
      
      html_content <- paste0(html_content, 
        '<div class="container">',
        '<h1>', input$meeting_title, '</h1>'
      )
      
      # Meeting information
      html_content <- paste0(html_content, 
        '<div class="meeting-info">',
        '<p><strong>Date:</strong> ', format(input$meeting_date, "%B %d, %Y"), '</p>',
        '<p><strong>Time:</strong> ', input$meeting_time, '</p>',
        '<p><strong>Duration:</strong> ', input$meeting_duration, '</p>',
        '<p><strong>Location:</strong> ', input$meeting_location, '</p>'
      )
      
      if (!is.null(input$meeting_notes) && input$meeting_notes != "") {
        html_content <- paste0(html_content, 
          '<p><strong>Notes:</strong> ', input$meeting_notes, '</p>')
      }
      
      html_content <- paste0(html_content, '</div>')
      
      # Add agenda if selected
      if ("agenda" %in% input$components) {
        html_content <- paste0(html_content, 
          '<h2>Meeting Agenda</h2>',
          '<table>',
          '<tr><th>Item #</th><th>Topic</th><th>Presenter</th><th>Time</th><th>Materials</th></tr>'
        )
        
        agenda <- agenda_items()
        for(i in 1:nrow(agenda)) {
          html_content <- paste0(html_content,
            '<tr>',
            '<td>', agenda$item_no[i], '</td>',
            '<td><strong>', agenda$topic[i], '</strong></td>',
            '<td>', agenda$presenter[i], '</td>',
            '<td>', agenda$time_allotted[i], '</td>',
            '<td>', agenda$materials[i], '</td>',
            '</tr>'
          )
        }
        html_content <- paste0(html_content, '</table>')
      }
      
      # Add minutes if selected
      if ("minutes" %in% input$components) {
        minutes_text <- if (input$minutes_source == "manual") {
          input$minutes_text
        } else {
          "Minutes content would be loaded from uploaded file."
        }
        
        html_content <- paste0(html_content, 
          '<h2>Previous Meeting Minutes</h2>',
          '<div style="white-space: pre-wrap; line-height: 1.8; padding: 1rem; background: #f8f9fa; border-radius: 8px;">',
          minutes_text,
          '</div>'
        )
      }
      
      # Add ED report if selected
      if ("ed_report" %in% input$components) {
        html_content <- paste0(html_content, 
          '<h2>Executive Director\'s Report</h2>',
          '<div style="white-space: pre-wrap; line-height: 1.8; padding: 1rem;">',
          input$ed_report_text,
          '</div>'
        )
      }
      
      # Add financials if selected
      if ("financials" %in% input$components) {
        html_content <- paste0(html_content, 
          '<h2>Financial Report</h2>',
          '<div class="financial-summary">',
          '<h3>Year-to-Date Financial Summary</h3>',
          '<table>',
          '<tr><th>Category</th><th>YTD Actual</th><th>YTD Budget</th><th>Variance</th><th>Variance %</th><th>Prior Year</th></tr>'
        )
        
        for(i in 1:nrow(sample_financials)) {
          html_content <- paste0(html_content,
            '<tr>',
            '<td><strong>', sample_financials$category[i], '</strong></td>',
            '<td>$', format(sample_financials$ytd_actual[i], big.mark = ","), '</td>',
            '<td>$', format(sample_financials$ytd_budget[i], big.mark = ","), '</td>',
            '<td style="color: ', ifelse(sample_financials$variance[i] >= 0, '#27ae60', '#e74c3c'), ';">',
            ifelse(sample_financials$variance[i] >= 0, '+', ''), 
            '$', format(sample_financials$variance[i], big.mark = ","), '</td>',
            '<td style="color: ', ifelse(sample_financials$variance_pct[i] >= 0, '#27ae60', '#e74c3c'), ';">',
            ifelse(sample_financials$variance_pct[i] >= 0, '+', ''),
            sample_financials$variance_pct[i], '%</td>',
            '<td>$', format(sample_financials$prior_year[i], big.mark = ","), '</td>',
            '</tr>'
          )
        }
        html_content <- paste0(html_content, '</table></div>')
      }
      
      # Add KPI section if selected
      if ("kpi" %in% input$components) {
        html_content <- paste0(html_content, 
          '<h2>Key Performance Indicators</h2>',
          '<table>',
          '<tr><th>Metric</th><th>Current</th><th>Target</th><th>Status</th></tr>'
        )
        
        for(i in 1:nrow(kpi_data)) {
          status_color <- switch(kpi_data$trend[i],
                                "up" = "#27ae60",
                                "down" = "#e74c3c",
                                "stable" = "#f39c12")
          status_text <- switch(kpi_data$trend[i],
                               "up" = "↗ Improving",
                               "down" = "↘ Declining", 
                               "stable" = "→ Stable")
          
          html_content <- paste0(html_content,
            '<tr>',
            '<td><strong>', kpi_data$metric[i], '</strong></td>',
            '<td>', format(kpi_data$current[i], big.mark = ","), '</td>',
            '<td>', format(kpi_data$target[i], big.mark = ","), '</td>',
            '<td style="color: ', status_color, '; font-weight: 600;">', status_text, '</td>',
            '</tr>'
          )
        }
        html_content <- paste0(html_content, '</table>')
      }
      
      # Add footer
      html_content <- paste0(html_content,
        '<div class="footer">',
        '<p>This board packet was generated on ', format(Sys.Date(), "%B %d, %Y"), 
        ' using the Board Packet Generator tool by Daly Analytics.</p>',
        '<p>Need custom analytics tools for your organization? ',
        '<a href="https://www.dalyanalytics.com/contact" style="color: #d68a93;">Contact Daly Analytics</a> ',
        'to build tailored solutions that solve your unique challenges.</p>',
        '</div>',
        '</div></body></html>'
      )
      
      writeLines(html_content, file)
    }
  )
}

shinyApp(ui, server)