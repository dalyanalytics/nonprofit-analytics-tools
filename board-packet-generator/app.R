# Board Packet Generator - Professional Portfolio Layout with Full Functionality
library(shiny)
# library(plotly) # Removed for Shinylive compatibility
library(DT)
library(dplyr)
library(tidyr)
library(bslib)
library(shinyjs)

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
        
        # Financial Summary Table instead of chart
        div(
          style = "margin-top: 2rem;",
          h5("Financial Performance Summary"),
          div(
            class = "table-responsive",
            tableOutput("financial_summary_table")
          )
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
  
  # Financial summary table (replaced plotly chart for Shinylive compatibility)
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
  }, striped = TRUE, hover = TRUE)
  
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
  
  # Generate board packet (Shinylive-compatible)
  observeEvent(input$generate_packet, {
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

# Conditional app creation based on environment
if (use_auth) {
  cat("🔒 Creating authenticated app with Auth0\n")
  app <- auth0::shinyAppAuth0(ui, server)
} else {
  cat("🌐 Creating public app (no authentication)\n")
  app <- shinyApp(ui = ui, server = server)
}