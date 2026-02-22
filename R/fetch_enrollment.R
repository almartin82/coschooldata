# ==============================================================================
# Enrollment Data Fetching Functions
# ==============================================================================
#
# This file contains the main user-facing functions for fetching Colorado
# enrollment data.
#
# ==============================================================================

#' Fetch Colorado enrollment data
#'
#' Downloads and returns enrollment data from the Colorado Department of
#' Education. When tidy=TRUE (default), returns data in long format with
#' standard columns: end_year, district_id, district_name, campus_id,
#' campus_name, grade_level, subgroup, n_students, pct, is_state,
#' is_district, is_school, is_charter.
#'
#' @param end_year School year end (2023-24 = 2024).
#' @param tidy If TRUE (default), returns data in tidy long format.
#'   If FALSE, returns processed wide format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Data frame with enrollment data
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 enrollment data (tidy format)
#' enr_2024 <- fetch_enr(2024)
#'
#' # Get wide format
#' enr_wide <- fetch_enr(2024, tidy = FALSE)
#'
#' # Force fresh download
#' enr_fresh <- fetch_enr(2024, use_cache = FALSE)
#' }
fetch_enr <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year
  available <- get_available_years()
  if (end_year < available$min_year || end_year > available$max_year) {
    stop(paste0(
      "end_year must be between ", available$min_year, " and ", available$max_year,
      ".\nUse get_available_years() for details on data availability."
    ))
  }

  # Determine cache type
  cache_type <- if (tidy) "tidy" else "wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached", cache_type, "data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Check if we have raw data cached (from previous fetch_enr calls)
  if (use_cache && cache_exists(end_year, "enrollment")) {
    message(paste("Processing cached raw data for", end_year))
    raw_df <- read_cache(end_year, "enrollment")
  } else {
    # Download raw data
    raw_list <- get_raw_enr(end_year)

    # Extract data frame from list
    if (is.list(raw_list) && !is.data.frame(raw_list)) {
      if ("school" %in% names(raw_list)) {
        raw_df <- raw_list$school
      } else if ("district" %in% names(raw_list)) {
        raw_df <- raw_list$district
      } else if ("enrollment" %in% names(raw_list)) {
        raw_df <- raw_list$enrollment
      } else {
        raw_df <- raw_list[[1]]
      }
    } else {
      raw_df <- raw_list
    }

    # Cache raw data
    if (use_cache) {
      write_cache(raw_df, end_year, "enrollment")
    }
  }

  # Process raw data to wide format
  wide <- process_enr(raw_df, end_year)

  if (!tidy) {
    if (use_cache) {
      write_cache(wide, end_year, "wide")
    }
    return(wide)
  }

  # Tidy the wide data
  result <- tidy_enr(wide)

  # Cache tidy result
  if (use_cache) {
    write_cache(result, end_year, "tidy")
  }

  result
}


#' Fetch enrollment data for multiple years
#'
#' Downloads and combines enrollment data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param tidy If TRUE (default), returns data in tidy format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with enrollment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' enr_multi <- fetch_enr_multi(2022:2024)
#' }
fetch_enr_multi <- function(end_years, tidy = TRUE, use_cache = TRUE) {

  # Validate years
  available <- get_available_years()
  invalid_years <- end_years[end_years < available$min_year | end_years > available$max_year]
  if (length(invalid_years) > 0) {
    stop(paste("Invalid years:", paste(invalid_years, collapse = ", "),
               "\nend_year must be between", available$min_year, "and", available$max_year))
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      fetch_enr(yr, tidy = tidy, use_cache = use_cache)
    }
  )

  # Combine
  dplyr::bind_rows(results)
}
