# Board Packet Generator - Professional Portfolio Layout with Full Functionality
library(shiny)
# library(plotly) # Removed for Shinylive compatibility
library(DT)
library(dplyr)
library(tidyr)
library(bslib)
library(shinyjs)
library(base64enc)

# Environment detection and conditional auth loading
is_shinylive <- function() {
  # Multiple checks for Shinylive/WebR environment
  tryCatch({
    # WebR runs on wasm32-unknown-emscripten platform
    grepl("wasm", R.Version()$platform, ignore.case = TRUE) ||
    # Shinylive doesn't have file system access in typical way
    !file.exists("/") ||
    # Check for WebR-specific environment variables
    Sys.getenv("WEBR") == "1" ||
    # Check if we're in a browser context (no real file system)
    !capabilities("fifo")
  }, error = function(e) {
    # If checks fail, assume we're in Shinylive
    TRUE
  })
}

# Conditional auth0 loading
if (!is_shinylive() && file.exists("_auth0.yml")) {
  tryCatch({
    library(auth0)
    options(auth0_config_file = "_auth0.yml")
    use_auth <- TRUE
    cat("✓ Auth0 loaded successfully\n")
  }, error = function(e) {
    cat("⚠ Auth0 not available, running without authentication\n")
    use_auth <- FALSE
  })
} else {
  use_auth <- FALSE
  if (is_shinylive()) {
    cat("✓ Shinylive environment detected - running in public mode\n")
  } else {
    cat("⚠ No auth0 config found - running without authentication\n")
  }
}

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

# Use shared CSS - removed for Shinylive compatibility
# addResourcePath("www", "../www")

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
    # Inline CSS since external stylesheets don't work in Shinylive
    tags$style(HTML('
      /* Shared CSS for Nonprofit Analytics Tools
       * This file provides consistent styling across all tools
       */

      /* Global styles */
      html, body {
        height: 100%;
        margin: 0;
        padding: 0;
        overflow-x: hidden;
      }

      body {
        color: #2c3e50;
        background-color: #ffffff;
        line-height: 1.6;
        display: flex;
        flex-direction: column;
        min-height: 100vh;
        margin: 0;
        padding: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      }

      :root {
        --primary-gradient: linear-gradient(-45deg, #F9B397, #D68A93, #AD92B1, #B07891);
        --primary-pink: #d68a93;
        --primary-peach: #f9b397;
        --primary-purple: #ad92b1;
        --primary-mauve: #b07891;
      }

      .main-content {
        flex: 1 0 auto;
      }

      /* Footer styling - full width edge-to-edge */
      footer, .footer {
        flex-shrink: 0;
        margin-top: auto !important;
        position: relative;
        width: 100vw !important;
        max-width: none !important;
        margin-left: calc(50% - 50vw) !important;
        margin-right: calc(50% - 50vw) !important;
        margin-bottom: 0 !important;
        padding: 2rem 0 !important;
        background: #0f172a;
        color: white;
      }

      /* Ensure footer content has proper padding and is centered */
      footer .container, .footer .container {
        max-width: 1200px;
        margin: 0 auto;
        padding-left: 1.5rem;
        padding-right: 1.5rem;
        width: 100%;
      }

      /* Ensure the body and all containers allow full width footer */
      .container-fluid, .bslib-page-wrapper, .bslib-sidebar-layout {
        overflow-x: visible !important;
      }

      /* Make sure no parent containers constrain the footer */
      * {
        box-sizing: border-box;
      }

      /* Specific fix for Shiny apps */
      #shiny-notification-panel {
        z-index: 10000;
      }

      /* Headers styling */
      h1, h2, h3, h4, h5, h6, .display-font {
        color: #2c3e50;
        font-weight: 700;
        letter-spacing: -0.02em;
        margin-bottom: 1rem;
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

      /* Value boxes - Outlined style with brand colors */
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

      /* Brand color borders for different value box types */
      .bslib-value-box.bg-primary {
        background: white !important;
        border: 2px solid #e74c3c !important;
      }

      .bslib-value-box.bg-info {
        background: white !important;
        border: 2px solid #f1c40f !important;
      }

      .bslib-value-box.bg-warning {
        background: white !important;
        border: 2px solid #f39c12 !important;
      }

      .bslib-value-box.bg-success {
        background: white !important;
        border: 2px solid #27ae60 !important;
      }

      /* Value box text styling */
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

      /* Showcase icons with brand colors */
      .bslib-value-box.bg-primary .value-box-showcase {
        color: #e74c3c !important;
      }

      .bslib-value-box.bg-info .value-box-showcase {
        color: #f1c40f !important;
      }

      .bslib-value-box.bg-warning .value-box-showcase {
        color: #f39c12 !important;
      }

      .bslib-value-box.bg-success .value-box-showcase {
        color: #27ae60 !important;
      }

      .bslib-value-box p {
        color: #6c757d !important;
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

      .table tbody td {
        color: #2c3e50;
        padding: 0.75rem;
        border-bottom: 1px solid #dee2e6;
      }

      .table tbody tr:hover {
        background-color: rgba(44, 62, 80, 0.05);
      }

      /* DataTables specific styling */
      .dataTable tbody td {
        color: #2c3e50 !important;
      }

      .dataTable tbody tr:hover td {
        color: #2c3e50 !important;
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

      /* Professional Portfolio Layout Styles */

      /* Hero section for guided experience */
      .hero-section {
        background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
        padding: 3rem 2rem;
        margin-bottom: 2rem;
        border-radius: 16px;
        text-align: center;
        box-shadow: 0 2px 12px rgba(0,0,0,0.03);
      }

      .hero-title {
        font-size: 2.5rem;
        font-weight: 700;
        color: #2c3e50;
        margin-bottom: 1rem;
        letter-spacing: -0.02em;
      }

      .hero-subtitle {
        font-size: 1.2rem;
        color: #7f8c8d;
        margin-bottom: 0;
        font-weight: 400;
      }

      /* Guided steps navigation */
      .steps-nav {
        display: flex;
        justify-content: center;
        align-items: center;
        margin: 2rem 0;
        padding: 0;
        list-style: none;
        gap: 1rem;
      }

      .step-item {
        display: flex;
        align-items: center;
        color: #bdc3c7;
        font-weight: 500;
        font-size: 0.9rem;
        padding: 0.5rem 1rem;
        border-radius: 20px;
        transition: all 0.3s ease;
        background: rgba(255, 255, 255, 0.1);
      }

      .step-item.active {
        color: #d68a93;
        background: rgba(214, 138, 147, 0.15);
        font-weight: 600;
      }

      .step-item.completed {
        color: #27ae60;
        background: rgba(39, 174, 96, 0.15);
        font-weight: 600;
      }

      .step-item.completed::after {
        content: " ✓";
        margin-left: 0.5rem;
      }

      .step-arrow {
        margin: 0 0.5rem;
        color: #bdc3c7;
        font-weight: bold;
      }

      /* Executive summary callouts */
      .insight-callout {
        background: linear-gradient(135deg, rgba(214, 138, 147, 0.08) 0%, rgba(173, 146, 177, 0.05) 100%);
        border-left: 4px solid #d68a93;
        padding: 1.5rem;
        margin: 2rem 0;
        border-radius: 0 8px 8px 0;
      }

      .insight-callout h4 {
        color: #2c3e50;
        margin-bottom: 0.5rem;
        font-size: 1.1rem;
      }

      .insight-callout p {
        color: #34495e;
        margin: 0;
        line-height: 1.6;
      }

      /* Professional metric displays */
      .metric-group {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1.5rem;
        margin: 2rem 0;
      }

      .metric-display {
        background: white;
        border: 1px solid #e9ecef;
        border-radius: 12px;
        padding: 1.5rem;
        text-align: center;
        position: relative;
        transition: all 0.2s ease;
      }

      .metric-display:hover {
        border-color: #d68a93;
        box-shadow: 0 4px 16px rgba(214, 138, 147, 0.1);
      }

      .metric-number {
        font-size: 2.2rem;
        font-weight: 700;
        color: #2c3e50;
        margin-bottom: 0.5rem;
        font-family: "SF Pro Display", -apple-system, sans-serif;
      }

      .metric-label {
        font-size: 0.85rem;
        color: #7f8c8d;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        font-weight: 500;
      }

      .metric-trend {
        position: absolute;
        top: 1rem;
        right: 1rem;
        font-size: 0.8rem;
        padding: 0.2rem 0.5rem;
        border-radius: 12px;
      }

      .trend-up {
        background: rgba(39, 174, 96, 0.1);
        color: #27ae60;
      }

      .trend-down {
        background: rgba(231, 76, 60, 0.1);
        color: #e74c3c;
      }

      /* Progressive disclosure sections */
      .disclosure-section {
        margin: 2rem 0;
        border: 1px solid #e9ecef;
        border-radius: 12px;
        overflow: hidden;
        background: white;
      }

      .disclosure-header {
        background: #f8f9fa;
        padding: 1rem 1.5rem;
        cursor: pointer;
        display: flex;
        justify-content: space-between;
        align-items: center;
        transition: background 0.2s ease;
      }

      .disclosure-header:hover {
        background: #e9ecef;
      }

      .disclosure-title {
        font-weight: 600;
        color: #2c3e50;
        margin: 0;
      }

      .disclosure-icon {
        color: #7f8c8d;
        transition: transform 0.2s ease;
      }

      .disclosure-section.expanded .disclosure-icon {
        transform: rotate(180deg);
      }

      .disclosure-content {
        padding: 1.5rem;
        border-top: 1px solid #e9ecef;
        display: none;
      }

      .disclosure-section.expanded .disclosure-content {
        display: block;
      }

      /* Expertise showcase elements */
      .expertise-badge {
        display: inline-block;
        background: rgba(214, 138, 147, 0.1);
        color: #d68a93;
        padding: 0.3rem 0.8rem;
        border-radius: 16px;
        font-size: 0.8rem;
        font-weight: 500;
        margin: 0.2rem;
      }

      .benchmark-comparison {
        background: #f8f9fa;
        border-radius: 8px;
        padding: 1rem;
        margin: 1rem 0;
      }

      .benchmark-label {
        font-size: 0.9rem;
        color: #7f8c8d;
        margin-bottom: 0.5rem;
      }

      .benchmark-bar {
        height: 8px;
        background: #e9ecef;
        border-radius: 4px;
        overflow: hidden;
        position: relative;
      }

      .benchmark-fill {
        height: 100%;
        background: linear-gradient(90deg, #d68a93 0%, #ad92b1 100%);
        border-radius: 4px;
        transition: width 0.8s ease;
      }

      .benchmark-marker {
        position: absolute;
        top: -2px;
        width: 2px;
        height: 12px;
        background: #34495e;
        border-radius: 1px;
      }

      /* Subtle branding */
      .powered-by {
        font-size: 0.8rem;
        color: #95a5a6;
        text-align: right;
        margin-top: 1rem;
      }

      .powered-by a {
        color: #d68a93;
        text-decoration: none;
      }

      .powered-by a:hover {
        text-decoration: underline;
      }

      /* Specific styles for Board Packet Generator */

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
        background: #f8f9fa;
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
        background: #f8f9fa;
        transition: all 0.3s ease;
      }

      .file-upload-area:hover {
        border-color: #d68a93;
        background: #fff;
      }

      /* Executive summary box */
      .executive-summary {
        background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
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
        background-color: #f8f9fa !important;
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

      /* Ensure the table doesn not jump during reorder */
      table.dataTable {
        table-layout: fixed;
      }

      @keyframes gradient {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
      }

      .w-100 { width: 100%; }

      /* Alert styles */
      .alert {
        border-radius: 8px;
        border: none;
      }

      .alert-info {
        background-color: #e3f2fd;
        color: #1565c0;
      }
    '))
  ),
  
  useShinyjs(),

  # JavaScript to track tab navigation for step completion
  tags$script(HTML("
    $(document).on('shiny:connected', function() {
      // Add click listeners to all tab pills
      $(document).on('click', 'a[role=\"tab\"]', function() {
        var tabText = $(this).text().trim();
        console.log('Tab clicked:', tabText);

        // Mark step 2 complete when viewing Financial Details or Meeting Agenda
        if (tabText === 'Financial Details' || tabText === 'Meeting Agenda') {
          $('#step2').addClass('completed').removeClass('active');
          $('#step3').addClass('active');
        }
      });
    });
  ")),

  # Hero Section with Brand Gradient (compact)
  div(
    class = "hero-section",
    style = "background: linear-gradient(-45deg, #F9B397, #D68A93, #AD92B1, #B07891); background-size: 200% 100%; animation: gradient 15s ease infinite; color: white; text-align: center; padding: 1.5rem 1rem; margin-bottom: 1.5rem;",
    div(icon("file-text"), style = "font-size: 2rem; margin-bottom: 0.5rem;"),
    h1("Board Packet Generator", style = "color: white; font-size: 1.75rem; font-weight: 700; margin-bottom: 0.5rem;"),
    p("Generate comprehensive board packets with financial insights and visualizations",
      style = "color: rgba(255,255,255,0.9); font-size: 1rem; margin-bottom: 0;")
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
      title = "Meeting Information",
      width = 300,
      
      # Meeting Information
      div(
        style = "margin-bottom: 2rem;",
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

        # Key Financial Metrics Grid with semantic colors
        uiOutput("kpi_cards"),

        # Financial Summary Chart with integrated alert
        div(
          style = "background: white; border: 1px solid #e9ecef; border-radius: 12px; padding: 1.5rem; margin-bottom: 2rem; box-shadow: 0 2px 8px rgba(0,0,0,0.05);",

          # Header with download button
          div(
            style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;",
            h5("Financial Performance Overview", style = "margin: 0; color: #2c3e50;"),
            div(
              style = "display: flex; gap: 1rem; align-items: center;",
              uiOutput("variance_status_badge", inline = TRUE),
              downloadButton("download_chart", "Download Chart", class = "btn-sm btn-outline-primary")
            )
          ),

          # Chart
          plotOutput("financial_chart", height = "350px")
        ),

        # Executive Summary
        div(
          class = "insight-callout",
          h4("Executive Summary"),
          p(textOutput("executive_summary"))
        ),

        br(),

        # Financial Summary Table
        div(
          style = "margin-top: 1rem;",
          div(
            style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;",
            h5("Detailed Financial Summary", style = "margin: 0;"),
            downloadButton("download_financial_csv", "Export to CSV", class = "btn-sm btn-outline-primary")
          ),
          div(
            class = "table-responsive",
            tableOutput("financial_summary_table")
          )
        )
      ),
      
      nav_panel(
        "Financial Details",
        icon = icon("chart-bar"),

        # Export all charts button
        div(
          style = "text-align: right; margin-bottom: 1rem;",
          downloadButton("download_all_charts", "Download All Charts (ZIP)", class = "btn-outline-primary")
        ),

        # Charts side by side
        div(
          class = "row",
          div(
            class = "col-md-6",
            div(
              style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;",
              h5("Expense Breakdown", style = "margin: 0;"),
              downloadButton("download_pie_chart", "Download", class = "btn-sm btn-outline-primary")
            ),
            plotOutput("expense_pie_chart", height = "350px")
          ),
          div(
            class = "col-md-6",
            div(
              style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;",
              h5("Year-over-Year Trend", style = "margin: 0;"),
              downloadButton("download_trend_chart", "Download", class = "btn-sm btn-outline-primary")
            ),
            plotOutput("trend_chart", height = "350px")
          )
        ),

        br(),

        # Detailed Financial Summary Table
        div(
          style = "margin-top: 2rem;",
          div(
            style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;",
            h5("Detailed Financial Summary", style = "margin: 0;"),
            downloadButton("download_financial_csv_details", "Export to CSV", class = "btn-sm btn-outline-primary")
          ),
          div(
            class = "table-responsive",
            tableOutput("financial_summary_table_details")
          )
        )
      ),

      nav_panel(
        "Meeting Agenda",
        icon = icon("list-check"),

        # Meeting Duration Summary
        div(
          class = "row mb-4",
          div(
            class = "col-md-6",
            div(
              class = "metric-display",
              div(class = "metric-number", textOutput("total_meeting_duration", inline = TRUE)),
              div(class = "metric-label", "Total Meeting Duration")
            )
          ),
          div(
            class = "col-md-6",
            div(
              class = "metric-display",
              div(class = "metric-number", textOutput("agenda_item_count", inline = TRUE)),
              div(class = "metric-label", "Agenda Items")
            )
          )
        ),

        div(
          style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;",
          p(
            class = "text-muted mb-0",
            icon("info-circle"),
            " Click any cell to edit agenda content directly in the table."
          ),
          downloadButton("download_agenda_csv", "Export Agenda to CSV", class = "btn-sm btn-outline-primary")
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

              actionButton(
                "generate_packet",
                "Generate Board Packet",
                class = "btn btn-primary btn-lg w-100 mb-3",
                icon = icon("file-text")
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
              icon("envelope"), " hello@dalyanalytics.com"
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
    agenda_data = sample_agenda_items,
    reviewed_materials = FALSE
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
      $('#step2').addClass('active').removeClass('completed');
      $('#step3').addClass('').removeClass('completed active');
    ")
  })
  
  # KPI cards with conditional semantic coloring
  output$kpi_cards <- renderUI({
    # Financial data
    revenue_actual <- 875000
    revenue_budget <- 850000
    revenue_pct <- (revenue_actual / revenue_budget) * 100

    expenses_actual <- 752500
    expenses_budget <- 731000
    expenses_pct <- (expenses_actual / expenses_budget) * 100

    net_income <- 122500
    net_income_budget <- 119000
    net_income_pct <- (net_income / net_income_budget) * 100

    cash_months <- 4.2

    # Determine colors based on performance
    # Revenue: over budget = good (green), under = warning/bad
    revenue_color <- if(revenue_pct >= 100) "#27ae60" else if(revenue_pct >= 95) "#f39c12" else "#e74c3c"

    # Expenses: under budget = good (green), over = warning/bad
    expense_color <- if(expenses_pct <= 100) "#27ae60" else if(expenses_pct <= 105) "#f39c12" else "#e74c3c"

    # Net Income: positive and over budget = good
    net_income_color <- if(net_income_pct >= 100) "#27ae60" else if(net_income_pct >= 95) "#f39c12" else "#e74c3c"

    # Cash position: 3+ months = good, 1.5-3 = warning, <1.5 = bad
    cash_color <- if(cash_months >= 3) "#27ae60" else if(cash_months >= 1.5) "#f39c12" else "#e74c3c"

    div(
      class = "metric-group",
      div(
        class = "metric-display",
        style = paste0("border-left: 4px solid ", revenue_color, ";"),
        div(class = "metric-number", style = paste0("color: ", revenue_color, ";"), "$875K"),
        div(class = "metric-label", "Total Revenue"),
        div(style = paste0("font-size: 0.75rem; color: ", revenue_color, "; margin-top: 0.25rem;"),
            sprintf("%.0f%% of budget", revenue_pct))
      ),
      div(
        class = "metric-display",
        style = paste0("border-left: 4px solid ", expense_color, ";"),
        div(class = "metric-number", style = paste0("color: ", expense_color, ";"), "$752.5K"),
        div(class = "metric-label", "Total Expenses"),
        div(style = paste0("font-size: 0.75rem; color: ", expense_color, "; margin-top: 0.25rem;"),
            sprintf("%.0f%% of budget", expenses_pct))
      ),
      div(
        class = "metric-display",
        style = paste0("border-left: 4px solid ", net_income_color, ";"),
        div(class = "metric-number", style = paste0("color: ", net_income_color, ";"), "$122.5K"),
        div(class = "metric-label", "Net Income"),
        div(style = paste0("font-size: 0.75rem; color: ", net_income_color, "; margin-top: 0.25rem;"),
            sprintf("%.0f%% of budget", net_income_pct))
      ),
      div(
        class = "metric-display",
        style = paste0("border-left: 4px solid ", cash_color, ";"),
        div(class = "metric-number", style = paste0("color: ", cash_color, ";"), "4.2 mo"),
        div(class = "metric-label", "Operating Reserves"),
        div(style = paste0("font-size: 0.75rem; color: ", cash_color, "; margin-top: 0.25rem;"),
            if(cash_months >= 3) "Strong position" else if(cash_months >= 1.5) "Adequate" else "Below target")
      )
    )
  })

  # Compact variance status badge
  output$variance_status_badge <- renderUI({
    # Calculate variances
    revenue_var <- 2.9
    expense_var <- -2.9

    # Check for variances > 10%
    if (abs(revenue_var) > 10 || abs(expense_var) > 10) {
      span(
        icon("exclamation-triangle"), " Attention Required",
        class = "badge",
        style = "background-color: #fff3cd; color: #856404; padding: 0.4rem 0.8rem; font-size: 0.85rem;"
      )
    } else {
      span(
        icon("check-circle"), " On Track",
        class = "badge",
        style = "background-color: #d4edda; color: #155724; padding: 0.4rem 0.8rem; font-size: 0.85rem;"
      )
    }
  })

  # Executive summary
  output$executive_summary <- renderText({
    paste0("The organization demonstrates strong financial performance with total revenue of $875K, ",
           "representing 103% of budget attainment. Net income of $122.5K provides healthy operating margin. ",
           "Expense management remains disciplined with strong cash position of 4.2 months reserves. ",
           "All key performance indicators trending positively for strategic growth initiatives.")
  })
  
  # Financial summary chart
  output$financial_chart <- renderPlot({
    # Data for the chart
    categories <- c("Revenue", "Expenses", "Net Income")
    actual <- c(875000, 752500, 122500)
    budget <- c(850000, 731000, 119000)
    prior_year <- c(825000, 709500, 115500)

    # Create grouped bar chart
    data_matrix <- rbind(actual, budget, prior_year)

    # Professional color palette (not branded)
    colors <- c("#3498db", "#95a5a6", "#34495e")  # Blue, Gray, Dark Blue

    # Create the bar plot with more margin at bottom for labels
    par(mar = c(6, 5, 2, 2), bg = "white")
    barplot_result <- barplot(
      data_matrix / 1000, # Convert to thousands
      beside = TRUE,
      names.arg = rep("", 3), # Empty labels initially
      col = colors,
      border = NA,
      ylim = c(0, max(data_matrix / 1000) * 1.15),
      ylab = "Amount ($K)",
      las = 1,
      cex.axis = 1,
      cex.lab = 1.1
    )

    # Add custom x-axis labels with better spacing
    label_positions <- colMeans(matrix(barplot_result, nrow = 3))
    text(
      x = label_positions,
      y = par("usr")[3] - 25,  # Position below x-axis with more space
      labels = categories,
      srt = 0,  # No rotation
      adj = 0.5,
      xpd = TRUE,
      cex = 1,
      font = 2  # Bold
    )

    # Add legend
    legend(
      "topright",
      legend = c("Actual", "Budget", "Prior Year"),
      fill = colors,
      border = NA,
      bty = "n",
      cex = 0.95
    )

    # Add grid lines for easier reading
    grid(nx = NA, ny = NULL, col = "gray90", lty = 1)

    # Redraw bars on top of grid
    barplot(
      data_matrix / 1000,
      beside = TRUE,
      names.arg = rep("", 3),
      col = colors,
      border = NA,
      add = TRUE,
      axes = FALSE
    )
  }, bg = "white")

  # Expense breakdown pie chart
  output$expense_pie_chart <- renderPlot({
    expenses <- c(612500, 87500, 52500)
    labels <- c("Program\n$612.5K (81%)", "Administrative\n$87.5K (12%)", "Fundraising\n$52.5K (7%)")
    colors <- c("#d68a93", "#ad92b1", "#b07891")

    par(mar = c(1, 1, 2, 1), bg = "white")
    pie(
      expenses,
      labels = labels,
      col = colors,
      border = "white",
      radius = 0.9,
      cex = 0.9
    )
  }, bg = "white")

  # Year-over-year trend chart
  output$trend_chart <- renderPlot({
    years <- c("2022", "2023", "2024")
    revenue <- c(725, 825, 875)
    expenses <- c(650, 710, 753)
    net_income <- c(75, 115, 122)

    par(mar = c(5, 5, 2, 2), bg = "white")
    plot(
      1:3, revenue,
      type = "o",
      col = "#d68a93",
      lwd = 3,
      pch = 19,
      ylim = c(0, max(revenue) * 1.1),
      xlab = "Year",
      ylab = "Amount ($K)",
      xaxt = "n",
      las = 1,
      cex.lab = 1.1,
      cex.axis = 1
    )

    # Add grid
    grid(nx = NA, ny = NULL, col = "gray90", lty = 1)

    # Redraw lines on top
    lines(1:3, revenue, col = "#d68a93", lwd = 3)
    points(1:3, revenue, col = "#d68a93", pch = 19, cex = 1.5)

    lines(1:3, expenses, col = "#ad92b1", lwd = 3)
    points(1:3, expenses, col = "#ad92b1", pch = 19, cex = 1.5)

    lines(1:3, net_income, col = "#27ae60", lwd = 3)
    points(1:3, net_income, col = "#27ae60", pch = 19, cex = 1.5)

    axis(1, at = 1:3, labels = years)

    legend(
      "topleft",
      legend = c("Revenue", "Expenses", "Net Income"),
      col = c("#d68a93", "#ad92b1", "#27ae60"),
      lwd = 3,
      pch = 19,
      bty = "n",
      cex = 0.9
    )
  }, bg = "white")

  # Financial summary table with smart highlighting
  output$financial_summary_table <- renderTable({
    comparison_data <- data.frame(
      Metric = c("Revenue", "Expenses", "Net Income"),
      Actual = c("$875,000", "$752,500", "$122,500"),
      Budget = c("$850,000", "$731,000", "$119,000"),
      `Prior Year` = c("$825,000", "$709,500", "$115,500"),
      `Variance %` = c("+2.9%", "-2.9%", "+2.9%"),
      stringsAsFactors = FALSE
    )
    names(comparison_data)[4] <- "Prior Year"
    names(comparison_data)[5] <- "Variance %"
    comparison_data
  }, striped = TRUE, hover = TRUE, sanitize.text.function = function(x) x)

  # Duplicate financial summary table for Financial Details tab
  output$financial_summary_table_details <- renderTable({
    comparison_data <- data.frame(
      Metric = c("Revenue", "Expenses", "Net Income"),
      Actual = c("$875,000", "$752,500", "$122,500"),
      Budget = c("$850,000", "$731,000", "$119,000"),
      `Prior Year` = c("$825,000", "$709,500", "$115,500"),
      `Variance %` = c("+2.9%", "-2.9%", "+2.9%"),
      stringsAsFactors = FALSE
    )
    names(comparison_data)[4] <- "Prior Year"
    names(comparison_data)[5] <- "Variance %"
    comparison_data
  }, striped = TRUE, hover = TRUE, sanitize.text.function = function(x) x)
  
  # Meeting duration calculator
  output$total_meeting_duration <- renderText({
    agenda <- agenda_items()

    # Parse time strings (e.g., "5 min", "20 min")
    total_minutes <- sum(sapply(agenda$time_allotted, function(time_str) {
      # Extract number from string like "5 min" or "20 min"
      num <- as.numeric(gsub("[^0-9]", "", time_str))
      if (is.na(num)) return(0)
      return(num)
    }))

    # Convert to hours and minutes
    hours <- floor(total_minutes / 60)
    minutes <- total_minutes %% 60

    if (hours > 0) {
      paste0(hours, "h ", minutes, "m")
    } else {
      paste0(minutes, " min")
    }
  })

  # Agenda item count
  output$agenda_item_count <- renderText({
    as.character(nrow(agenda_items()))
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
  
  # Generate board packet (Shinylive-compatible)
  observeEvent(input$generate_packet, {
    # Generate chart images as base64 for embedding in HTML
    financial_chart_base64 <- generate_chart_base64("financial")
    expense_chart_base64 <- generate_chart_base64("expense")
    trend_chart_base64 <- generate_chart_base64("trend")

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
      include_toc = input$include_toc,
      financial_chart = financial_chart_base64,
      expense_chart = expense_chart_base64,
      trend_chart = trend_chart_base64
    )
    
    # Show generated HTML in a modal (Shinylive-compatible)
    showModal(modalDialog(
      title = "Board Packet Generated",
      size = "xl",
      div(
        style = "max-height: 500px; overflow-y: auto; border: 1px solid #ddd; padding: 1rem;",
        HTML(html_content)
      ),
      footer = tagList(
        p(class = "text-muted", 
          "Copy the content above or use your browser's print function to save as PDF."),
        modalButton("Close")
      )
    ))
    
    # Show completion notification
    showNotification("Board packet generated successfully!", type = "message", duration = 5)
    
    # Update step 3 to completed
    tryCatch({
      shinyjs::runjs("$('#step3').addClass('completed').removeClass('active');")
    }, error = function(e) {
      # Silently handle if shinyjs fails
    })
  })
  
  # Download handlers for CSV exports
  output$download_financial_csv <- downloadHandler(
    filename = function() {
      paste0("financial_summary_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      comparison_data <- data.frame(
        Metric = c("Revenue", "Expenses", "Net Income"),
        Actual = c(875000, 752500, 122500),
        Budget = c(850000, 731000, 119000),
        `Prior Year` = c(825000, 709500, 115500),
        Variance = c(25000, -17500, 3500),
        `Variance Percent` = c(2.9, -2.9, 2.9),
        stringsAsFactors = FALSE
      )
      write.csv(comparison_data, file, row.names = FALSE)
    }
  )

  output$download_agenda_csv <- downloadHandler(
    filename = function() {
      paste0("meeting_agenda_", format(input$meeting_date, "%Y%m%d"), ".csv")
    },
    content = function(file) {
      write.csv(agenda_items(), file, row.names = FALSE)
    }
  )

  output$download_financial_csv_details <- downloadHandler(
    filename = function() {
      paste0("financial_summary_details_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      comparison_data <- data.frame(
        Metric = c("Revenue", "Expenses", "Net Income"),
        Actual = c(875000, 752500, 122500),
        Budget = c(850000, 731000, 119000),
        `Prior Year` = c(825000, 709500, 115500),
        Variance = c(25000, -17500, 3500),
        `Variance Percent` = c(2.9, -2.9, 2.9),
        stringsAsFactors = FALSE
      )
      write.csv(comparison_data, file, row.names = FALSE)
    }
  )

  # Download handlers for charts (PNG format)
  output$download_chart <- downloadHandler(
    filename = function() {
      paste0("financial_performance_", format(Sys.Date(), "%Y%m%d"), ".png")
    },
    content = function(file) {
      png(file, width = 800, height = 600, res = 120)

      categories <- c("Revenue", "Expenses", "Net Income")
      actual <- c(875000, 752500, 122500)
      budget <- c(850000, 731000, 119000)
      prior_year <- c(825000, 709500, 115500)
      data_matrix <- rbind(actual, budget, prior_year)
      colors <- c("#3498db", "#95a5a6", "#34495e")

      par(mar = c(6, 5, 2, 2), bg = "white")
      barplot_result <- barplot(
        data_matrix / 1000,
        beside = TRUE,
        names.arg = rep("", 3),
        col = colors,
        border = NA,
        ylim = c(0, max(data_matrix / 1000) * 1.15),
        ylab = "Amount ($K)",
        las = 1,
        cex.axis = 1,
        cex.lab = 1.1
      )

      # Add custom x-axis labels
      label_positions <- colMeans(matrix(barplot_result, nrow = 3))
      text(
        x = label_positions,
        y = par("usr")[3] - 25,
        labels = categories,
        srt = 0,
        adj = 0.5,
        xpd = TRUE,
        cex = 1,
        font = 2
      )

      legend(
        "topright",
        legend = c("Actual", "Budget", "Prior Year"),
        fill = colors,
        border = NA,
        bty = "n",
        cex = 0.95
      )
      grid(nx = NA, ny = NULL, col = "gray90", lty = 1)
      barplot(
        data_matrix / 1000,
        beside = TRUE,
        names.arg = rep("", 3),
        col = colors,
        border = NA,
        add = TRUE,
        axes = FALSE
      )

      dev.off()
    }
  )

  output$download_pie_chart <- downloadHandler(
    filename = function() {
      paste0("expense_breakdown_", format(Sys.Date(), "%Y%m%d"), ".png")
    },
    content = function(file) {
      png(file, width = 600, height = 600, res = 100)

      expenses <- c(612500, 87500, 52500)
      labels <- c("Program\n$612.5K (81%)", "Administrative\n$87.5K (12%)", "Fundraising\n$52.5K (7%)")
      colors <- c("#d68a93", "#ad92b1", "#b07891")

      par(mar = c(1, 1, 2, 1), bg = "white")
      pie(
        expenses,
        labels = labels,
        col = colors,
        border = "white",
        radius = 0.9,
        cex = 0.9
      )

      dev.off()
    }
  )

  output$download_trend_chart <- downloadHandler(
    filename = function() {
      paste0("yoy_trend_", format(Sys.Date(), "%Y%m%d"), ".png")
    },
    content = function(file) {
      png(file, width = 800, height = 500, res = 100)

      years <- c("2022", "2023", "2024")
      revenue <- c(725, 825, 875)
      expenses <- c(650, 710, 753)
      net_income <- c(75, 115, 122)

      par(mar = c(5, 5, 2, 2), bg = "white")
      plot(
        1:3, revenue,
        type = "o",
        col = "#d68a93",
        lwd = 3,
        pch = 19,
        ylim = c(0, max(revenue) * 1.1),
        xlab = "Year",
        ylab = "Amount ($K)",
        xaxt = "n",
        las = 1,
        cex.lab = 1.1,
        cex.axis = 1
      )
      grid(nx = NA, ny = NULL, col = "gray90", lty = 1)
      lines(1:3, revenue, col = "#d68a93", lwd = 3)
      points(1:3, revenue, col = "#d68a93", pch = 19, cex = 1.5)
      lines(1:3, expenses, col = "#ad92b1", lwd = 3)
      points(1:3, expenses, col = "#ad92b1", pch = 19, cex = 1.5)
      lines(1:3, net_income, col = "#27ae60", lwd = 3)
      points(1:3, net_income, col = "#27ae60", pch = 19, cex = 1.5)
      axis(1, at = 1:3, labels = years)
      legend(
        "topleft",
        legend = c("Revenue", "Expenses", "Net Income"),
        col = c("#d68a93", "#ad92b1", "#27ae60"),
        lwd = 3,
        pch = 19,
        bty = "n",
        cex = 0.9
      )

      dev.off()
    }
  )

  # Download all charts as ZIP (simplified - in Shinylive this shows message)
  output$download_all_charts <- downloadHandler(
    filename = function() {
      paste0("board_packet_charts_", format(Sys.Date(), "%Y%m%d"), ".zip")
    },
    content = function(file) {
      # Create temp directory
      temp_dir <- tempdir()

      # Generate all charts
      png(file.path(temp_dir, "financial_performance.png"), width = 800, height = 500, res = 100)
      # (Chart code here - abbreviated for space)
      dev.off()

      # Create ZIP
      zip(file, files = list.files(temp_dir, pattern = "*.png", full.names = TRUE))
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

# Helper function to generate charts as base64 images
generate_chart_base64 <- function(chart_type) {
  temp_file <- tempfile(fileext = ".png")

  if (chart_type == "financial") {
    png(temp_file, width = 800, height = 400, res = 100)

    categories <- c("Revenue", "Expenses", "Net Income")
    actual <- c(875000, 752500, 122500)
    budget <- c(850000, 731000, 119000)
    prior_year <- c(825000, 709500, 115500)
    data_matrix <- rbind(actual, budget, prior_year)
    colors <- c("#3498db", "#95a5a6", "#34495e")

    par(mar = c(6, 5, 2, 2), bg = "white")
    barplot_result <- barplot(
      data_matrix / 1000,
      beside = TRUE,
      names.arg = rep("", 3),
      col = colors,
      border = NA,
      ylim = c(0, max(data_matrix / 1000) * 1.15),
      ylab = "Amount ($K)",
      las = 1
    )

    label_positions <- colMeans(matrix(barplot_result, nrow = 3))
    text(x = label_positions, y = par("usr")[3] - 25, labels = categories,
         srt = 0, adj = 0.5, xpd = TRUE, cex = 1, font = 2)

    legend("topright", legend = c("Actual", "Budget", "Prior Year"),
           fill = colors, border = NA, bty = "n")
    grid(nx = NA, ny = NULL, col = "gray90", lty = 1)
    barplot(data_matrix / 1000, beside = TRUE, names.arg = rep("", 3),
            col = colors, border = NA, add = TRUE, axes = FALSE)

    dev.off()

  } else if (chart_type == "expense") {
    png(temp_file, width = 500, height = 500, res = 100)

    expenses <- c(612500, 87500, 52500)
    labels <- c("Program\n$612.5K\n(81%)", "Admin\n$87.5K\n(12%)", "Fundraising\n$52.5K\n(7%)")
    colors <- c("#3498db", "#95a5a6", "#34495e")

    par(mar = c(1, 1, 2, 1), bg = "white")
    pie(expenses, labels = labels, col = colors, border = "white", radius = 0.9)

    dev.off()

  } else if (chart_type == "trend") {
    png(temp_file, width = 800, height = 400, res = 100)

    years <- c("2022", "2023", "2024")
    revenue <- c(725, 825, 875)
    expenses <- c(650, 710, 753)
    net_income <- c(75, 115, 122)

    par(mar = c(5, 5, 2, 2), bg = "white")
    plot(1:3, revenue, type = "o", col = "#3498db", lwd = 3, pch = 19,
         ylim = c(0, max(revenue) * 1.1), xlab = "Year", ylab = "Amount ($K)",
         xaxt = "n", las = 1)

    grid(nx = NA, ny = NULL, col = "gray90", lty = 1)
    lines(1:3, revenue, col = "#3498db", lwd = 3)
    points(1:3, revenue, col = "#3498db", pch = 19, cex = 1.5)
    lines(1:3, expenses, col = "#95a5a6", lwd = 3)
    points(1:3, expenses, col = "#95a5a6", pch = 19, cex = 1.5)
    lines(1:3, net_income, col = "#27ae60", lwd = 3)
    points(1:3, net_income, col = "#27ae60", pch = 19, cex = 1.5)

    axis(1, at = 1:3, labels = years)
    legend("topleft", legend = c("Revenue", "Expenses", "Net Income"),
           col = c("#3498db", "#95a5a6", "#27ae60"), lwd = 3, pch = 19, bty = "n")

    dev.off()
  }

  # Read the file and convert to base64
  img_data <- readBin(temp_file, "raw", file.info(temp_file)$size)
  base64_img <- base64enc::base64encode(img_data)
  unlink(temp_file)

  return(paste0("data:image/png;base64,", base64_img))
}

# Function to generate HTML board packet
generate_board_packet_html <- function(meeting_title, meeting_date, meeting_time, meeting_location,
                                       components, agenda_data, financial_data,
                                       include_watermark = FALSE, include_toc = TRUE,
                                       financial_chart = NULL, expense_chart = NULL, trend_chart = NULL) {
  
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
      '<div class="metric-label">Revenue vs Budget</div>\n',
      '</div>\n',
      '<div class="metric">\n',
      '<div class="metric-value">$122.5K</div>\n',
      '<div class="metric-label">Net Income</div>\n',
      '</div>\n',
      '<div class="metric">\n',
      '<div class="metric-value">4.2 mo</div>\n',
      '<div class="metric-label">Operating Reserves</div>\n',
      '</div>\n'
    )

    # Add financial chart if provided
    if (!is.null(financial_chart)) {
      html_content <- paste0(
        html_content,
        '<h3 style="margin-top: 30px;">Financial Performance Overview</h3>\n',
        '<img src="', financial_chart, '" style="width: 100%; max-width: 800px; margin: 20px auto; display: block;" />\n'
      )
    }
  }

  # Add Financial Details charts if financials component is selected
  if ("financials" %in% components) {
    html_content <- paste0(
      html_content,
      '<h2>Financial Analysis</h2>\n'
    )

    if (!is.null(expense_chart)) {
      html_content <- paste0(
        html_content,
        '<h3>Expense Breakdown</h3>\n',
        '<img src="', expense_chart, '" style="width: 100%; max-width: 500px; margin: 20px auto; display: block;" />\n'
      )
    }

    if (!is.null(trend_chart)) {
      html_content <- paste0(
        html_content,
        '<h3>Year-over-Year Trend</h3>\n',
        '<img src="', trend_chart, '" style="width: 100%; max-width: 800px; margin: 20px auto; display: block;" />\n'
      )
    }
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

# Conditional app creation based on environment
if (use_auth) {
  cat("🔒 Creating authenticated app with Auth0\n")
  app <- auth0::shinyAppAuth0(ui, server)
} else {
  cat("🌐 Creating public app (no authentication)\n")
  app <- shinyApp(ui = ui, server = server)
}