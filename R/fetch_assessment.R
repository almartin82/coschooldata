# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains the main user-facing functions for fetching Colorado
# CMAS assessment data.
#
# CMAS (Colorado Measures of Academic Success) is Colorado's state assessment
# system, administered since 2014. It replaced TCAP (2012-2014) and CSAP (1997-2011).
#
# Available years: 2015-2019, 2021-2025 (no 2020 due to COVID-19 waiver)
#
# ==============================================================================


#' Fetch Colorado CMAS assessment data
#'
#' Downloads and returns CMAS assessment data from the Colorado Department of
#' Education.
#'
#' @param end_year School year end (2023-24 = 2024). Valid range: 2015-2025 (except 2020).
#' @param subject Subject to fetch: "all" (default), "ela", "math", "science", or "csla"
#' @param tidy If TRUE (default), returns data in long format with proficiency_level column.
#'   If FALSE, returns wide format with separate pct_* columns.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Data frame with assessment data
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 CMAS assessment data
#' assess_2024 <- fetch_assessment(2024)
#'
#' # Get only Math results
#' math_2024 <- fetch_assessment(2024, subject = "math")
#'
#' # Get wide format (separate columns for each proficiency level)
#' assess_wide <- fetch_assessment(2024, tidy = FALSE)
#'
#' # Force fresh download
#' assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
#' }
fetch_assessment <- function(end_year, subject = "all", tidy = TRUE, use_cache = TRUE) {

  # Validate year
  available <- get_available_assessment_years()

  # Special handling for 2020 (COVID waiver year)
  if (end_year == 2020) {
    stop("2020 assessment data is not available due to COVID-19 testing waiver. ",
         "No statewide CMAS testing was administered in Spring 2020.")
  }

  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "), ". ",
      "Got: ", end_year, "\n",
      "Note: 2020 had no testing due to COVID-19 pandemic."
    ))
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "assessment_tidy" else "assessment_wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached assessment data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data
  raw <- get_raw_assessment(end_year, subject = subject)

  # Check if data was returned
  if (is.null(raw) || nrow(raw) == 0) {
    warning(paste("No assessment data available for year", end_year,
                  "\nThis may be due to CDE server issues. Please try again later."))
    if (tidy) {
      return(create_empty_tidy_assessment())
    } else {
      return(create_empty_assessment_result(end_year))
    }
  }

  # Process to standard schema
  processed <- process_assessment(raw, end_year)

  # Optionally tidy
  if (tidy) {
    result <- tidy_assessment(processed)
  } else {
    result <- processed
  }

  # Cache the result
  if (use_cache && nrow(result) > 0) {
    write_cache(result, end_year, cache_type)
  }

  result
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#' Note: 2020 is automatically excluded (COVID-19 testing waiver).
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param subject Subject to fetch: "all" (default), "ela", "math", "science", or "csla"
#' @param tidy If TRUE (default), returns data in long format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with assessment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' assess_multi <- fetch_assessment_multi(2022:2024)
#'
#' # Get Math data for 5 years
#' math_trend <- fetch_assessment_multi(2019:2024, subject = "math")
#' }
fetch_assessment_multi <- function(end_years, subject = "all", tidy = TRUE, use_cache = TRUE) {

  # Get available years
  available <- get_available_assessment_years()

  # Remove 2020 if present (COVID waiver year)
  if (2020 %in% end_years) {
    warning("2020 excluded: No assessment data due to COVID-19 testing waiver.")
    end_years <- end_years[end_years != 2020]
  }

  # Validate years
  invalid_years <- end_years[!end_years %in% available$years]
  if (length(invalid_years) > 0) {
    stop(paste0(
      "Invalid years: ", paste(invalid_years, collapse = ", "), "\n",
      "Valid years are: ", paste(available$years, collapse = ", ")
    ))
  }

  if (length(end_years) == 0) {
    stop("No valid years to fetch")
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      tryCatch({
        fetch_assessment(yr, subject = subject, tidy = tidy, use_cache = use_cache)
      }, error = function(e) {
        warning(paste("Failed to fetch year", yr, ":", e$message))
        if (tidy) {
          create_empty_tidy_assessment()
        } else {
          create_empty_assessment_result(yr)
        }
      })
    }
  )

  # Combine, filtering out empty data frames
  results <- results[!sapply(results, function(x) nrow(x) == 0)]
  dplyr::bind_rows(results)
}


#' Fetch assessment data for a specific district
#'
#' Convenience function to fetch assessment data for a single district.
#'
#' @param end_year School year end
#' @param district_id 4-digit district code (e.g., "0880" for Denver Public Schools)
#' @param subject Subject to fetch: "all" (default), "ela", "math", "science", or "csla"
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified district
#' @export
#' @examples
#' \dontrun{
#' # Get Denver Public Schools (0880) assessment data
#' denver_assess <- fetch_district_assessment(2024, "0880")
#'
#' # Get Jefferson County (0870) Math data
#' jeffco_math <- fetch_district_assessment(2024, "0870", subject = "math")
#' }
fetch_district_assessment <- function(end_year, district_id, subject = "all",
                                       tidy = TRUE, use_cache = TRUE) {

  # Normalize district_id
  district_id <- sprintf("%04d", as.integer(district_id))

  # Fetch all data for year
  df <- fetch_assessment(end_year, subject = subject, tidy = tidy, use_cache = use_cache)

  # Filter to requested district
  df |>
    dplyr::filter(district_id == !!district_id)
}


#' Fetch assessment data for a specific school
#'
#' Convenience function to fetch assessment data for a single school.
#'
#' @param end_year School year end
#' @param district_id 4-digit district code
#' @param school_id 4-digit school code
#' @param subject Subject to fetch: "all" (default), "ela", "math", "science", or "csla"
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified school
#' @export
#' @examples
#' \dontrun{
#' # Get a specific school's assessment data
#' school_assess <- fetch_school_assessment(2024, "0880", "0001")
#' }
fetch_school_assessment <- function(end_year, district_id, school_id, subject = "all",
                                     tidy = TRUE, use_cache = TRUE) {

  # Normalize IDs
  district_id <- sprintf("%04d", as.integer(district_id))
  school_id <- sprintf("%04d", as.integer(school_id))

  # Fetch all data for year
  df <- fetch_assessment(end_year, subject = subject, tidy = tidy, use_cache = use_cache)

  # Filter to requested school
  df |>
    dplyr::filter(district_id == !!district_id, school_id == !!school_id)
}


#' Clear assessment cache
#'
#' Removes cached assessment data files.
#'
#' @param end_year Optional school year to clear. If NULL, clears all years.
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear all cached assessment data
#' clear_assessment_cache()
#'
#' # Clear only 2024 assessment data
#' clear_assessment_cache(2024)
#' }
clear_assessment_cache <- function(end_year = NULL) {
  cache_dir <- get_cache_dir()

  if (!is.null(end_year)) {
    # Clear specific year
    files <- list.files(
      cache_dir,
      pattern = paste0("assessment.*_", end_year, "\\.rds$"),
      full.names = TRUE
    )
  } else {
    # Clear all assessment cache
    files <- list.files(
      cache_dir,
      pattern = "^enr_assessment.*\\.rds$",
      full.names = TRUE
    )
  }

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached assessment file(s)"))
  } else {
    message("No cached assessment files to remove")
  }

  invisible(length(files))
}
