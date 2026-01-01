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
#' Education.
#'
#' @param end_year School year end (2023-24 = 2024).
#' @param tidy If TRUE (default), returns data in tidy format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Data frame with enrollment data
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 enrollment data
#' enr_2024 <- fetch_enr(2024)
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

  # Check cache first
  if (use_cache && cache_exists(end_year, "enrollment")) {
    message(paste("Using cached data for", end_year))
    return(read_cache(end_year, "enrollment"))
  }

  # Get raw data
  raw <- get_raw_enr(end_year)

  # Extract from list if needed
  if (is.list(raw) && !is.data.frame(raw)) {
    if ("district" %in% names(raw)) {
      result <- raw$district
    } else if ("enrollment" %in% names(raw)) {
      result <- raw$enrollment
    } else {
      result <- raw[[1]]
    }
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache(result, end_year, "enrollment")
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
