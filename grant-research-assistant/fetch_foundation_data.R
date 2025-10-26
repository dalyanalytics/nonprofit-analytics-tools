# fetch_foundation_data.R
# Fetches foundation data from ProPublica Nonprofit Explorer API
# Focuses on New England states: CT, MA, ME, NH, RI, VT

library(httr2)
library(jsonlite)
library(dplyr)
library(purrr)
library(scales)
library(tidygeocoder)

# New England state codes
NEW_ENGLAND_STATES <- c("CT", "MA", "ME", "NH", "RI", "VT")

# Major community foundations to always include (by EIN)
MAJOR_COMMUNITY_FOUNDATIONS <- c(
  60699252,   # Hartford Foundation for Public Giving (CT)
  41813396,   # Boston Foundation (MA)
  205184097,  # Rhode Island Foundation (RI)
  237396756   # Maine Community Foundation (ME)
  # Add more as needed
)

#' Search for foundations in a given state using direct API calls
#' @param state Two-letter state code
#' @param search_term Search term (default: "foundation")
#' @param max_results Maximum number of results to retrieve
search_foundations_by_state <- function(state, search_term = "foundation", max_results = 100) {
  message(sprintf("Searching foundations in %s...", state))

  # Build and execute API request
  # Note: State parameter needs bracket notation: state[id]=MA
  req <- request("https://projects.propublica.org/nonprofits/api/v2/search.json") |>
    req_url_query(
      q = search_term,
      `state[id]` = state
    )

  # Perform request with error handling
  resp <- tryCatch({
    req |> req_perform()
  }, error = function(e) {
    message(sprintf("Error searching %s: %s", state, e$message))
    return(NULL)
  })

  if (is.null(resp)) return(NULL)

  # Parse JSON response
  data <- resp |> resp_body_json()

  if (is.null(data$organizations) || length(data$organizations) == 0) {
    message(sprintf("No organizations found in %s", state))
    return(NULL)
  }

  # Convert to data frame
  orgs_df <- map_df(data$organizations, function(org) {
    data.frame(
      ein = org$ein %||% NA,
      name = org$name %||% NA,
      city = org$city %||% NA,
      state = org$state %||% NA,
      ntee_code = org$ntee_code %||% NA,
      subseccd = org$subseccd %||% NA,
      stringsAsFactors = FALSE
    )
  })

  message(sprintf("Found %d organizations in %s", nrow(orgs_df), state))
  return(orgs_df)
}

#' Get detailed organization data including grants made
#' @param ein Employer Identification Number
get_foundation_details <- function(ein) {
  message(sprintf("Fetching details for EIN %s...", ein))

  Sys.sleep(0.5)  # Rate limiting - be respectful to API

  req <- request(sprintf("https://projects.propublica.org/nonprofits/api/v2/organizations/%s.json", ein))

  resp <- tryCatch({
    req |> req_perform()
  }, error = function(e) {
    message(sprintf("Error fetching EIN %s: %s", ein, e$message))
    return(NULL)
  })

  if (is.null(resp)) return(NULL)

  # Parse JSON response
  org_data <- resp |> resp_body_json()
  return(org_data)
}

#' Extract grant information from organization data
#' @param org_data Organization data from API
extract_grants <- function(org_data) {
  if (is.null(org_data) || is.null(org_data$filings_with_data) || length(org_data$filings_with_data) == 0) {
    return(NULL)
  }

  # Get most recent filing with data
  recent_filing <- org_data$filings_with_data[[1]]

  # Get form type to understand what fields to look for
  form_type <- recent_filing$formtype %||% "unknown"

  # Check for various fields that indicate grantmaking activity
  # Different form types have different field names:
  # form_type 0 = 990 (regular nonprofits) - use totcntrbgfts for grants PAID
  # form_type 2 = 990-PF (private foundations) - use distribamt for grants PAID

  # Try form-specific fields first
  grants_paid <- NULL

  if (form_type == 2) {
    # 990-PF: Private foundation that MAKES grants
    grants_paid <- recent_filing$distribamt %||%               # Distributions amount (actual grants paid)
                   recent_filing$qlfydistribtot %||%            # Qualifying distributions total
                   NULL
  } else if (form_type == 0) {
    # 990: Corporate/operating foundation - totcntrbgfts means grants PAID for these
    grants_paid <- recent_filing$totcntrbgfts %||%             # Total contributions & gifts
                   NULL
  }

  # Fallback to 0 if nothing found
  if (is.null(grants_paid)) {
    grants_paid <- 0
  }

  # Get total revenue and expenses for context
  total_revenue <- recent_filing$totrevenue %||% NA
  total_expenses <- recent_filing$totfuncexpns %||% NA
  total_assets <- recent_filing$totassetsend %||% NA

  # Get administrative expenses (form-specific fields)
  admin_expenses <- NULL

  if (form_type == 2) {
    # 990-PF: Look for administrative expenses specific to private foundations
    admin_expenses <- recent_filing$grsadminexpns %||%      # Gross administrative expenses
                      recent_filing$compnsatncurrofcr %||%  # Compensation of officers
                      NULL
  } else if (form_type == 0) {
    # 990: Regular foundation admin expenses
    admin_expenses <- recent_filing$compnsatncurrofcr %||%  # Compensation of officers
                      recent_filing$othrsalwages %||%       # Other salaries and wages
                      NULL
  }

  # If still null, set to NA
  if (is.null(admin_expenses)) {
    admin_expenses <- NA
  }

  # Calculate payout rate (grants as % of assets) - key metric for foundations
  # Only calculate for foundations with substantial assets (>$100k)
  # This avoids misleading percentages for pass-through organizations
  payout_rate <- if (!is.na(total_assets) && total_assets > 100000 && !is.null(grants_paid) && grants_paid > 0) {
    rate <- (grants_paid / total_assets) * 100
    # Cap at 100% to avoid misleading displays for special cases
    pmin(rate, 100)
  } else {
    NA
  }

  # Calculate admin expense ratio (as % of grants paid)
  admin_ratio <- if (!is.na(admin_expenses) && !is.null(grants_paid) && grants_paid > 0) {
    (admin_expenses / grants_paid) * 100
  } else {
    NA
  }

  # Red flag detection
  red_flags <- c()
  if (!is.na(payout_rate) && payout_rate < 5) {
    red_flags <- c(red_flags, "Low payout rate (<5%)")
  }
  if (!is.na(admin_ratio) && admin_ratio > 20) {
    red_flags <- c(red_flags, "High admin costs (>20%)")
  }

  has_red_flags <- length(red_flags) > 0

  # Only include organizations that have significant financial data
  # Focus on true grantmaking foundations with substantial assets
  # Exclude pass-through organizations or very small funds
  has_meaningful_grants <- !is.null(grants_paid) && grants_paid > 0
  has_substantial_assets <- !is.na(total_assets) && total_assets > 100000  # At least $100K in assets

  # Must have BOTH grants and substantial assets to be included
  # This filters out pass-through orgs and ensures payout rate is meaningful
  if (!has_meaningful_grants || !has_substantial_assets) {
    message(sprintf("  Skipping %s - no grants or insufficient assets (<$100K)", org_data$organization$name))
    return(NULL)
  }

  grants <- data.frame(
    foundation_name = org_data$organization$name %||% NA,
    foundation_ein = org_data$organization$ein %||% NA,
    foundation_city = org_data$organization$city %||% NA,
    foundation_state = org_data$organization$state %||% NA,
    form_type = form_type,
    total_assets = total_assets,
    total_revenue = total_revenue,
    total_expenses = total_expenses,
    admin_expenses = admin_expenses,
    grants_paid = grants_paid,
    payout_rate = round(payout_rate, 2),
    admin_ratio = round(admin_ratio, 2),
    has_red_flags = has_red_flags,
    red_flags = paste(red_flags, collapse = "; "),
    filing_year = recent_filing$tax_prd_yr %||% NA,
    stringsAsFactors = FALSE
  )

  message(sprintf("  ✓ %s | Assets: $%s | Grants: $%s | Payout: %s%% | Admin: %s%%%s",
                  org_data$organization$name,
                  scales::comma(total_assets),
                  scales::comma(grants_paid),
                  if(!is.na(payout_rate)) round(payout_rate, 1) else "N/A",
                  if(!is.na(admin_ratio)) round(admin_ratio, 1) else "N/A",
                  if(has_red_flags) " 🚩" else ""))

  return(grants)
}

# Main execution
main <- function() {
  message("Starting foundation data fetch for New England states...")

  all_foundations <- list()

  # Search each New England state
  for (state in NEW_ENGLAND_STATES) {
    state_foundations <- search_foundations_by_state(state)

    if (!is.null(state_foundations) && nrow(state_foundations) > 0) {
      all_foundations[[state]] <- state_foundations
    }

    Sys.sleep(1)  # Rate limiting between states
  }

  # Combine all results
  combined_foundations <- bind_rows(all_foundations)

  message(sprintf("Total organizations found: %d", nrow(combined_foundations)))

  # Sample from each state - take more to ensure we get quality foundations
  # Get 15 per state (will filter down based on grants/assets criteria)
  top_orgs <- combined_foundations %>%
    group_by(state) %>%
    slice_head(n = 15) %>%
    ungroup()

  message(sprintf("Fetching details for %d organizations (%d per state)...",
                  nrow(top_orgs),
                  15))

  # Get detailed data for each organization
  foundation_details <- top_orgs$ein %>%
    map(~{
      details <- get_foundation_details(.x)
      if (!is.null(details)) {
        return(extract_grants(details))
      }
      return(NULL)
    }) %>%
    compact()  # Remove NULL entries

  # Also fetch major community foundations that might not be in search results
  message("\nFetching major community foundations...")
  major_foundations <- MAJOR_COMMUNITY_FOUNDATIONS %>%
    map(~{
      details <- get_foundation_details(.x)
      if (!is.null(details)) {
        return(extract_grants(details))
      }
      return(NULL)
    }) %>%
    compact()

  # Combine all foundation details
  foundation_details <- c(foundation_details, major_foundations)

  # Convert to data frame
  if (length(foundation_details) == 0) {
    message("No foundation details retrieved!")
    return(invisible(NULL))
  }

  foundation_df <- bind_rows(foundation_details)

  # Add geocoding for mapping
  message("Geocoding foundation locations...")

  foundation_df <- foundation_df %>%
    mutate(
      # Create full address for geocoding
      full_address = paste(foundation_city, foundation_state, "USA", sep = ", ")
    ) %>%
    geocode(
      address = full_address,
      method = "osm",  # Use OpenStreetMap (free, no API key needed)
      lat = latitude,
      long = longitude,
      quiet = FALSE
    ) %>%
    select(-full_address)  # Remove helper column

  message(sprintf("Geocoded %d of %d locations",
                  sum(!is.na(foundation_df$latitude)),
                  nrow(foundation_df)))

  # Save to JSON
  output_file <- "grant-research-assistant/data/foundations.json"
  write_json(foundation_df, output_file, pretty = TRUE, auto_unbox = TRUE)

  message(sprintf("Saved %d foundations to %s", nrow(foundation_df), output_file))

  # Also save metadata
  metadata <- list(
    last_updated = Sys.time(),
    states_included = NEW_ENGLAND_STATES,
    total_foundations = nrow(foundation_df),
    data_source = "ProPublica Nonprofit Explorer API"
  )

  write_json(metadata, "grant-research-assistant/data/metadata.json",
             pretty = TRUE, auto_unbox = TRUE)

  message("Data fetch complete!")
}

# Run main function
if (!interactive()) {
  main()
}
