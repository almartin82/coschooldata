# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw CMAS assessment data from
# the Colorado Department of Education (CDE).
#
# Data Source: https://www.cde.state.co.us/assessment/cmas-dataandresults
#
# Assessment Systems:
# - CMAS (Colorado Measures of Academic Success): 2014-present
#   - Math and ELA: Grades 3-8
#   - Science: Grades 5, 8, 11
#   - Social Studies: Grades 4, 7 (sampled)
# - No data for 2020 (COVID-19 testing waiver)
#
# ==============================================================================


#' Get available assessment years
#'
#' Returns information about which school years have assessment data available.
#'
#' @return A list with:
#'   \item{years}{Vector of available end years (e.g., 2024 for 2023-24)}
#'   \item{note}{Information about data gaps (e.g., 2020)}
#'   \item{assessment_system}{Current assessment system name}
#' @export
#' @examples
#' get_available_assessment_years()
get_available_assessment_years <- function() {
  list(
    years = c(2015:2019, 2021:2025),
    note = "2020 data not available due to COVID-19 testing waiver",
    assessment_system = "CMAS (Colorado Measures of Academic Success)",
    subjects = c("ELA", "Math", "Science", "Social Studies", "CSLA")
  )
}


#' Get assessment URL for a given year and file type
#'
#' Constructs the URL for downloading CMAS assessment data from CDE.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @param file_type One of "ela", "math", "science", "csla", "ela_math_state",
#'   "ela_math_district_school", "science_state", "science_district_school"
#' @return URL string or NULL if not found
#' @keywords internal
get_assessment_url <- function(end_year, file_type) {

  base_url <- "https://www.cde.state.co.us/assessment/"

  # Normalize file type

  file_type <- tolower(file_type)

  # URL patterns by year and file type
  # Most recent years (2019+) use disaggregated files with consistent naming
  # Earlier years (2015-2018) may have different patterns

  # No data for 2020 (COVID waiver year)
  if (end_year == 2020) {
    return(NULL)
  }

  if (end_year >= 2019) {
    urls <- list(
      # Disaggregated summary files (have all levels and subgroups)
      ela = paste0(base_url, end_year, "_cmas_ela_disaggregatedachievementresults"),
      math = paste0(base_url, end_year, "_cmas_math_disaggregatedachievementresults"),
      science = paste0(base_url, end_year, "_cmas_science_disaggregatedachievementresults"),
      csla = paste0(base_url, end_year, "_cmas_csla_disaggregatedachievementresults"),

      # State summary files
      ela_math_state = paste0(base_url, end_year, "_cmas_ela_math_statesummaryachievementresults"),
      science_state = paste0(base_url, end_year, "_cmas_science_statesummaryachievementresults"),

      # District and school summary files
      ela_math_district_school = paste0(base_url, end_year, "_cmas_ela_math_districtschoolsummaryachievementresults"),
      science_district_school = paste0(base_url, end_year, "_cmas_science_districtschoolsummaryachievementresults")
    )
  } else if (end_year >= 2015) {
    # Older years may have slightly different naming
    # Try common patterns
    urls <- list(
      ela = paste0(base_url, end_year, "_cmas_ela_disaggregatedachievementresults"),
      math = paste0(base_url, end_year, "_cmas_math_disaggregatedachievementresults"),
      science = paste0(base_url, end_year, "_cmas_science_disaggregatedachievementresults"),
      csla = paste0(base_url, end_year, "_cmas_csla_disaggregatedachievementresults"),
      ela_math_state = paste0(base_url, end_year, "_cmas_ela_math_statesummaryachievementresults"),
      science_state = paste0(base_url, end_year, "_cmas_science_statesummaryachievementresults"),
      ela_math_district_school = paste0(base_url, end_year, "_cmas_ela_math_districtschoolsummaryachievementresults"),
      science_district_school = paste0(base_url, end_year, "_cmas_science_districtschoolsummaryachievementresults")
    )
  } else {
    return(NULL)
  }

  if (file_type %in% names(urls)) {
    return(urls[[file_type]])
  }

  NULL
}


#' Download raw CMAS assessment data
#'
#' Downloads assessment data from the Colorado Department of Education.
#' Returns the raw data as-is from the Excel file.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @param subject One of "ela", "math", "science", "csla", or "all" (default)
#' @return Data frame with raw assessment data, or list of data frames if subject="all"
#' @keywords internal
get_raw_assessment <- function(end_year, subject = "all") {

  # Validate year
  available <- get_available_assessment_years()

  if (end_year == 2020) {
    stop("Assessment data is not available for 2020 due to COVID-19 testing waiver.")
  }

  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "),
      "\nGot: ", end_year
    ))
  }

  message(paste("Downloading Colorado CMAS assessment data for", end_year, "..."))

  # Determine which subjects to download
  subject <- tolower(subject)
  if (subject == "all") {
    subjects_to_download <- c("ela", "math", "science")
  } else if (subject %in% c("ela", "math", "science", "csla")) {
    subjects_to_download <- subject
  } else {
    stop("subject must be one of 'all', 'ela', 'math', 'science', 'csla'")
  }

  # Download each subject
  result <- list()

  for (subj in subjects_to_download) {
    message(paste("  Downloading", toupper(subj), "data..."))
    df <- download_assessment_file(end_year, subj)

    if (!is.null(df) && nrow(df) > 0) {
      df$subject <- toupper(subj)
      df$end_year <- end_year
      result[[subj]] <- df
    }
  }

  # Return single dataframe or list depending on request
  if (length(subjects_to_download) == 1) {
    if (length(result) == 0) {
      return(create_empty_assessment_raw())
    }
    return(result[[1]])
  }

  # Combine all subjects
  if (length(result) == 0) {
    return(create_empty_assessment_raw())
  }

  dplyr::bind_rows(result)
}


#' Download a single assessment file
#'
#' @param end_year School year end
#' @param subject Subject code (ela, math, science, csla)
#' @return Data frame or NULL if download fails
#' @keywords internal
download_assessment_file <- function(end_year, subject) {

  url <- get_assessment_url(end_year, subject)

  if (is.null(url)) {
    message(paste("  No URL pattern defined for", end_year, subject))
    return(NULL)
  }

  # Create temp file - CDE uses .xlsx files that don't have extension in URL
  tname <- tempfile(
    pattern = paste0("co_cmas_", subject, "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  result <- tryCatch({
    # Download with httr
    response <- httr::GET(
      url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(180),
      httr::config(
        ssl_verifypeer = 0L,
        ssl_verifyhost = 0L,
        followlocation = TRUE
      ),
      httr::user_agent("Mozilla/5.0 (compatible; coschooldata R package)")
    )

    if (httr::http_error(response)) {
      status <- httr::status_code(response)
      message(paste("  HTTP error for", subject, ":", status))

      # Check if it's a server down issue
      if (status %in% c(0, 502, 503, 504)) {
        warning(paste(
          "CDE server may be temporarily unavailable.",
          "Assessment data for Colorado is hosted at www.cde.state.co.us",
          "which has been experiencing connectivity issues.",
          "Please try again later or visit https://ed.cde.state.co.us/assessment/cmas-dataandresults"
        ))
      }

      unlink(tname)
      return(NULL)
    }

    # Check file size
    file_info <- file.info(tname)
    if (is.na(file_info$size) || file_info$size < 1000) {
      message(paste("  Downloaded file too small for", subject))
      unlink(tname)
      return(NULL)
    }

    # Verify it's an Excel file (not HTML error page)
    # Read first few bytes to check for Excel magic number
    con <- file(tname, "rb")
    header <- readBin(con, "raw", 4)
    close(con)

    # Excel files start with PK (ZIP) for .xlsx or D0 CF 11 E0 for .xls
    if (!identical(header[1:2], as.raw(c(0x50, 0x4B))) &&
        !identical(header[1:4], as.raw(c(0xD0, 0xCF, 0x11, 0xE0)))) {
      # Check if it's HTML
      first_chars <- readChar(tname, 100)
      if (grepl("<html|<!DOCTYPE", first_chars, ignore.case = TRUE)) {
        message(paste("  Received HTML page instead of Excel file for", subject))
        unlink(tname)
        return(NULL)
      }
    }

    # Read the Excel file
    df <- read_assessment_excel(tname, end_year, subject)

    unlink(tname)

    df

  }, error = function(e) {
    message(paste("  Download error for", subject, ":", e$message))

    # Provide helpful message about server issues
    if (grepl("SSL|connect|timeout|refused", e$message, ignore.case = TRUE)) {
      warning(paste(
        "Could not connect to CDE server. This is a known issue as of January 2026.",
        "The www.cde.state.co.us domain may be temporarily unavailable.",
        "Assessment data pages are accessible at https://ed.cde.state.co.us/assessment/cmas-dataandresults",
        "but data files may still be hosted on the old domain."
      ))
    }

    unlink(tname)
    NULL
  })

  result
}


#' Read assessment data from Excel file
#'
#' Parses the CMAS assessment Excel file.
#'
#' @param filepath Path to downloaded Excel file
#' @param end_year School year end
#' @param subject Subject code
#' @return Data frame with assessment data
#' @keywords internal
read_assessment_excel <- function(filepath, end_year, subject) {

  # Get sheet names
  sheets <- tryCatch({
    readxl::excel_sheets(filepath)
  }, error = function(e) {
    stop(paste("Failed to read Excel file:", e$message))
  })

  message(paste("    Found", length(sheets), "sheet(s):", paste(sheets, collapse = ", ")))

  # CMAS files typically have multiple sheets for different subgroups
  # Main data is usually first sheet or sheet with "All" or "Summary"

  all_data <- list()

  for (sheet in sheets) {
    tryCatch({
      df <- suppressMessages(
        readxl::read_excel(
          filepath,
          sheet = sheet,
          col_types = "text"
        )
      )

      if (nrow(df) > 0) {
        # Add sheet name as subgroup indicator if not already present
        if (!"subgroup" %in% tolower(names(df))) {
          df$sheet_name <- sheet
        }

        all_data[[sheet]] <- df
      }
    }, error = function(e) {
      message(paste("    Could not read sheet:", sheet, "-", e$message))
    })
  }

  if (length(all_data) == 0) {
    return(create_empty_assessment_raw())
  }

  # Combine all sheets
  combined <- dplyr::bind_rows(all_data, .id = "source_sheet")

  # Clean column names
  names(combined) <- clean_assessment_column_names(names(combined))

  combined
}


#' Clean assessment column names
#'
#' Standardizes column names from CMAS Excel files.
#'
#' @param x Character vector of column names
#' @return Cleaned column names
#' @keywords internal
clean_assessment_column_names <- function(x) {
  x <- tolower(x)
  x <- gsub("\\s+", "_", x)
  x <- gsub("[^a-z0-9_]", "", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)

  # Handle common CMAS column name variations
  x <- gsub("^district_code$", "district_id", x)
  x <- gsub("^school_code$", "school_id", x)
  x <- gsub("^district_number$", "district_id", x)
  x <- gsub("^school_number$", "school_id", x)
  x <- gsub("^organization_code$", "district_id", x)

  x <- gsub("^number_of_valid_scores$", "n_tested", x)
  x <- gsub("^number_valid_scores$", "n_tested", x)
  x <- gsub("^n_valid$", "n_tested", x)
  x <- gsub("^valid_scores$", "n_tested", x)

  x <- gsub("^percent_.*did_not_yet_meet.*$", "pct_did_not_meet", x)
  x <- gsub("^percent_.*partially_met.*$", "pct_partially_met", x)
  x <- gsub("^percent_.*approached.*$", "pct_approached", x)
  x <- gsub("^percent_.*met.*expectations$", "pct_met", x)
  x <- gsub("^percent_.*exceeded.*$", "pct_exceeded", x)

  x <- gsub("^pct_level_1$", "pct_did_not_meet", x)
  x <- gsub("^pct_level_2$", "pct_partially_met", x)
  x <- gsub("^pct_level_3$", "pct_approached", x)
  x <- gsub("^pct_level_4$", "pct_met", x)
  x <- gsub("^pct_level_5$", "pct_exceeded", x)

  x <- gsub("^content_area$", "subject", x)
  x <- gsub("^grade_level$", "grade", x)
  x <- gsub("^tested_grade$", "grade", x)

  x
}


#' Create empty assessment raw data frame
#'
#' Returns an empty data frame with expected column structure.
#'
#' @return Empty data frame
#' @keywords internal
create_empty_assessment_raw <- function() {
  data.frame(
    source_sheet = character(0),
    district_id = character(0),
    district_name = character(0),
    school_id = character(0),
    school_name = character(0),
    grade = character(0),
    subject = character(0),
    n_tested = character(0),
    pct_did_not_meet = character(0),
    pct_partially_met = character(0),
    pct_approached = character(0),
    pct_met = character(0),
    pct_exceeded = character(0),
    end_year = integer(0),
    stringsAsFactors = FALSE
  )
}
