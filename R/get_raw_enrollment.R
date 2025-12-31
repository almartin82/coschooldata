# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from CDE.
# Data comes from the Student October Count collection, available as Excel files.
#
# Colorado's data is published annually with consistent URL patterns:
# - Current/recent years: cde.state.co.us/cdereval/[year]-[year]pupilmembership
# - Archive files: Various Excel formats by year
#
# Format eras:
# - 2019-present: Modern format with Race/Ethnicity, Gender, Grade by School
# - 2009-2018: Older format with different column naming conventions
#
# Key files used:
# - PK-12 Membership Grade Level by School
# - PK-12 Race/Ethnicity and Gender by Grade and School
# - PK-12 Membership, FRL, Race/Ethnicity, Gender with School Flags (2023+)
#
# ==============================================================================

#' Download raw enrollment data from CDE
#'
#' Downloads school and district enrollment data from CDE's Pupil Membership
#' data files. Uses the Student October Count collection.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with school-level data frame
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year range
  # Data available from 2009-present via CDE website
  if (end_year < 2009 || end_year > 2025) {
    stop("end_year must be between 2009 and 2025")
  }

  message(paste("Downloading CDE enrollment data for", end_year, "..."))

  # Use appropriate download function based on year
  # 2019+: Modern format with consistent file naming
  # 2009-2018: Older format with slightly different structure

  if (end_year >= 2019) {
    school_data <- download_modern_enrollment(end_year)
  } else {
    school_data <- download_legacy_enrollment(end_year)
  }

  # Add end_year column
  school_data$end_year <- end_year

  list(
    school = school_data
  )
}


#' Download modern format enrollment data (2019+)
#'
#' Downloads enrollment data from CDE's modern Excel files. These files
#' have consistent column naming and are available at predictable URLs.
#'
#' @param end_year School year end (2019-2025)
#' @return Data frame with school-level enrollment data
#' @keywords internal
download_modern_enrollment <- function(end_year) {

  message("  Downloading school-level enrollment data...")

  # Build URL for the combined membership file
  # CDE uses format like: 2023-24pk-12membershipfrlethnicitygenderschoolflags
  # or: 2022-23pk-12raceethnicitygenderbygradeschool

  year_str <- format_cde_year(end_year, "dash2")

  # Try the combined file first (available for recent years)
  # This file has membership, FRL, race/ethnicity, gender with school flags
  combined_url <- build_cde_url(end_year, "combined")

  # Also try the grade-level file and race/ethnicity file
  grade_url <- build_cde_url(end_year, "grade")
  race_url <- build_cde_url(end_year, "race")

  # Attempt download - try combined first, then fall back to separate files
  school_data <- NULL

  # Try combined file
  tryCatch({
    school_data <- download_cde_excel(combined_url)
    if (!is.null(school_data) && nrow(school_data) > 0) {
      message("    Using combined membership file")
      return(school_data)
    }
  }, error = function(e) {
    message("    Combined file not available, trying separate files...")
  })

  # Try race/ethnicity file (most comprehensive for demographics)
  tryCatch({
    school_data <- download_cde_excel(race_url)
    if (!is.null(school_data) && nrow(school_data) > 0) {
      message("    Using race/ethnicity file")
      return(school_data)
    }
  }, error = function(e) {
    message("    Race/ethnicity file not available, trying grade file...")
  })

  # Try grade-level file
  tryCatch({
    school_data <- download_cde_excel(grade_url)
    if (!is.null(school_data) && nrow(school_data) > 0) {
      message("    Using grade-level file")
      return(school_data)
    }
  }, error = function(e) {
    stop(paste("Failed to download enrollment data for year", end_year,
               "\nTried URLs:", combined_url, race_url, grade_url))
  })

  if (is.null(school_data) || nrow(school_data) == 0) {
    stop(paste("No data available for year", end_year))
  }

  school_data
}


#' Download legacy format enrollment data (2009-2018)
#'
#' Downloads enrollment data from CDE's older Excel files.
#' These files have slightly different column naming and structure.
#'
#' @param end_year School year end (2009-2018)
#' @return Data frame with school-level enrollment data
#' @keywords internal
download_legacy_enrollment <- function(end_year) {

  message("  Downloading legacy format enrollment data...")

  # Build URL for legacy files
  # Legacy files use different URL patterns and file names
  url <- build_cde_legacy_url(end_year)

  school_data <- download_cde_excel(url)

  if (is.null(school_data) || nrow(school_data) == 0) {
    stop(paste("Failed to download enrollment data for year", end_year))
  }

  school_data
}


#' Build CDE URL for modern enrollment files
#'
#' Constructs the URL for downloading enrollment data from CDE.
#'
#' @param end_year School year end
#' @param file_type One of "combined", "grade", or "race"
#' @return URL string
#' @keywords internal
build_cde_url <- function(end_year, file_type = "combined") {

  year_str <- format_cde_year(end_year, "dash2")
  base_url <- "https://www.cde.state.co.us/cdereval"

  # CDE uses various file naming patterns
  # These patterns are based on observed file names on the CDE website
  if (file_type == "combined") {
    # Combined file with all data (2023+)
    # Example: 2023-24pk-12membershipfrlethnicitygenderschoolflags.xlsx
    file_name <- paste0(year_str, "pk-12membershipfrlethnicitygenderschoolflags")
  } else if (file_type == "grade") {
    # Grade level by school
    # Example: 2023-24pk-12membershipgradelevelbischool.xlsx
    file_name <- paste0(year_str, "pk-12membershipgradelevelbyschool")
  } else if (file_type == "race") {
    # Race/ethnicity and gender by grade and school
    # Example: 2023-24pk-12raceethnicitygenderbygradeschool.xlsx
    file_name <- paste0(year_str, "pk-12raceethnicitygenderbygradeschool")
  } else {
    stop("Unknown file_type: ", file_type)
  }

  paste0(base_url, "/", file_name, ".xlsx")
}


#' Build CDE URL for legacy enrollment files (2009-2018)
#'
#' @param end_year School year end
#' @return URL string
#' @keywords internal
build_cde_legacy_url <- function(end_year) {

  year_str <- format_cde_year(end_year, "dash2")
  base_url <- "https://www.cde.state.co.us/cdereval"

  # Legacy files use slightly different patterns
  # Try the most common pattern first
  file_name <- paste0(year_str, "pk-12membershipbyschool")

  paste0(base_url, "/", file_name, ".xlsx")
}


#' Download and read CDE Excel file
#'
#' Downloads an Excel file from CDE and reads it into a data frame.
#' Handles common issues like SSL certificates and multiple sheets.
#'
#' @param url URL of the Excel file
#' @return Data frame
#' @keywords internal
download_cde_excel <- function(url) {

  # Create temp file
  temp_file <- tempfile(fileext = ".xlsx")

  # Download with appropriate options
  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(120),
      httr::config(ssl_verifypeer = FALSE)  # CDE has certificate issues
    )

    # Check for HTTP errors
    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

    # Check file size
    file_info <- file.info(temp_file)
    if (file_info$size < 1000) {
      # Likely an error page, not an Excel file
      stop("Downloaded file too small, likely an error page")
    }

  }, error = function(e) {
    if (file.exists(temp_file)) unlink(temp_file)
    stop(paste("Download failed:", e$message))
  })

  # Read Excel file
  # Try to determine the correct sheet
  tryCatch({
    sheets <- readxl::excel_sheets(temp_file)

    # Use first sheet if only one, otherwise look for data sheet
    if (length(sheets) == 1) {
      sheet_name <- sheets[1]
    } else {
      # Look for a sheet with "data" or "membership" in the name
      data_sheets <- grep("data|membership|school", sheets, ignore.case = TRUE, value = TRUE)
      sheet_name <- if (length(data_sheets) > 0) data_sheets[1] else sheets[1]
    }

    df <- readxl::read_excel(
      temp_file,
      sheet = sheet_name,
      col_types = "text"  # Read everything as text for consistent handling
    )

    # Clean up temp file
    unlink(temp_file)

    df

  }, error = function(e) {
    if (file.exists(temp_file)) unlink(temp_file)
    stop(paste("Failed to read Excel file:", e$message))
  })
}


#' Get URL patterns for different years
#'
#' Returns a list of known working URL patterns for CDE data files.
#' This is useful for debugging and testing.
#'
#' @return Data frame with year, file_type, and url columns
#' @keywords internal
get_cde_url_patterns <- function() {

  # Known working URL patterns based on CDE website structure
  patterns <- data.frame(
    end_year = c(2024, 2024, 2024, 2023, 2023, 2022, 2021, 2020, 2019),
    file_type = c("combined", "grade", "race", "race", "grade", "race", "race", "race", "race"),
    url = c(
      "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipfrlethnicitygenderschoolflags.xlsx",
      "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool.xlsx",
      "https://www.cde.state.co.us/cdereval/2023-24pk-12raceethnicitygenderbygradeschool.xlsx",
      "https://www.cde.state.co.us/cdereval/2022-23pk-12raceethnicitygenderbygradeschool.xlsx",
      "https://www.cde.state.co.us/cdereval/2022-23pk-12membershipgradelevelbyschool.xlsx",
      "https://www.cde.state.co.us/cdereval/2021-22pk-12raceethnicitygenderbygradeschool.xlsx",
      "https://www.cde.state.co.us/cdereval/2020-21pk-12raceethnicitygenderbygradeschool.xlsx",
      "https://www.cde.state.co.us/cdereval/2019-20pk-12raceethnicitygenderbygradeschool.xlsx",
      "https://www.cde.state.co.us/cdereval/2018-19pk-12raceethnicitygenderbygradeschool.xlsx"
    ),
    stringsAsFactors = FALSE
  )

  patterns
}


#' Get column mappings for CDE data
#'
#' Returns a list mapping CDE column names to standardized names.
#' CDE uses various naming conventions across years.
#'
#' @return Named list of column mappings
#' @keywords internal
get_cde_column_map <- function() {
  list(
    # ID columns
    district_code = c("Organization Code", "District Code", "District Number",
                      "DISTRICT CODE", "ORG_CODE", "districtcode"),
    school_code = c("School Code", "School Number", "SCHOOL CODE", "schoolcode"),
    district_name = c("Organization Name", "District Name", "DISTRICT NAME",
                      "districtname", "District"),
    school_name = c("School Name", "SCHOOL NAME", "schoolname", "School"),

    # Enrollment totals
    total = c("Total", "TOTAL", "total", "Membership", "Total Membership"),

    # Gender
    male = c("Male", "MALE", "male", "M"),
    female = c("Female", "FEMALE", "female", "F"),

    # Race/Ethnicity (federal categories)
    white = c("White", "WHITE", "white"),
    black = c("Black or African American", "Black", "BLACK", "black",
              "African American"),
    hispanic = c("Hispanic or Latino", "Hispanic", "HISPANIC", "hispanic",
                 "Hispanic/Latino"),
    asian = c("Asian", "ASIAN", "asian"),
    native_american = c("American Indian or Alaska Native", "American Indian",
                        "Native American", "AMERICAN INDIAN", "AI/AN"),
    pacific_islander = c("Native Hawaiian or Other Pacific Islander",
                         "Pacific Islander", "PACIFIC ISLANDER", "NH/PI"),
    multiracial = c("Two or More Races", "Two or More", "Multiracial",
                    "TWO OR MORE", "Multi-Racial"),

    # Special populations
    frl = c("Free/Reduced Lunch", "Free and Reduced Lunch", "FRL",
            "Free or Reduced Price Lunch"),

    # Grade levels
    grade_pk = c("PK", "PreK", "Pre-K", "Preschool", "Pre-Kindergarten"),
    grade_k = c("K", "KG", "Kindergarten"),
    grade_01 = c("1", "01", "Grade 1", "1st"),
    grade_02 = c("2", "02", "Grade 2", "2nd"),
    grade_03 = c("3", "03", "Grade 3", "3rd"),
    grade_04 = c("4", "04", "Grade 4", "4th"),
    grade_05 = c("5", "05", "Grade 5", "5th"),
    grade_06 = c("6", "06", "Grade 6", "6th"),
    grade_07 = c("7", "07", "Grade 7", "7th"),
    grade_08 = c("8", "08", "Grade 8", "8th"),
    grade_09 = c("9", "09", "Grade 9", "9th"),
    grade_10 = c("10", "Grade 10", "10th"),
    grade_11 = c("11", "Grade 11", "11th"),
    grade_12 = c("12", "Grade 12", "12th")
  )
}
