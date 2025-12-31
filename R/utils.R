# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL


#' Convert school year string to end year
#'
#' Converts various school year formats (2023-24, 2023-2024, etc.) to end year.
#'
#' @param year_string School year string (e.g., "2023-24")
#' @return Integer end year (e.g., 2024)
#' @keywords internal
parse_school_year <- function(year_string) {
  # Handle various formats
  year_string <- trimws(as.character(year_string))

  # Format: 2023-24 or 2023-2024

  if (grepl("^\\d{4}-\\d{2,4}$", year_string)) {
    parts <- strsplit(year_string, "-")[[1]]
    start_year <- as.integer(parts[1])
    end_part <- parts[2]

    if (nchar(end_part) == 2) {
      # Convert 24 to 2024
      century <- substr(as.character(start_year), 1, 2)
      end_year <- as.integer(paste0(century, end_part))
    } else {
      end_year <- as.integer(end_part)
    }

    return(end_year)
  }

  # Just a single year
  if (grepl("^\\d{4}$", year_string)) {
    return(as.integer(year_string))
  }

  NA_integer_
}


#' Format end year as school year string
#'
#' @param end_year End year (e.g., 2024)
#' @return School year string (e.g., "2023-24")
#' @keywords internal
format_school_year <- function(end_year) {
  start_year <- end_year - 1
  end_short <- substr(as.character(end_year), 3, 4)
  paste0(start_year, "-", end_short)
}


#' Get the academic year label for file names
#'
#' CDE uses various naming conventions for files. This function
#' generates the appropriate year string for file URLs.
#'
#' @param end_year End year (e.g., 2024)
#' @param format One of "dash2" (2023-24), "dash4" (2023-2024), or "single" (2024)
#' @return Formatted year string
#' @keywords internal
format_cde_year <- function(end_year, format = "dash2") {
  start_year <- end_year - 1

  switch(format,
    "dash2" = paste0(start_year, "-", substr(as.character(end_year), 3, 4)),
    "dash4" = paste0(start_year, "-", end_year),
    "single" = as.character(end_year),
    paste0(start_year, "-", substr(as.character(end_year), 3, 4))
  )
}


#' Clean and standardize text columns
#'
#' Removes extra whitespace, converts to proper case, etc.
#'
#' @param x Character vector
#' @return Cleaned character vector
#' @keywords internal
clean_text <- function(x) {
  x <- trimws(x)
  x <- gsub("\\s+", " ", x)
  x
}


#' Standardize Colorado district code
#'
#' Colorado district codes are typically 4 digits, left-padded with zeros.
#'
#' @param code District code (numeric or character)
#' @return Character string of 4-digit code
#' @keywords internal
standardize_district_code <- function(code) {
  code <- as.character(code)
  code <- trimws(code)
  code <- gsub("[^0-9]", "", code)  # Remove non-numeric chars
  sprintf("%04d", as.integer(code))
}


#' Standardize Colorado school code
#'
#' Colorado school codes are typically 4 digits.
#'
#' @param code School code (numeric or character)
#' @return Character string of 4-digit code
#' @keywords internal
standardize_school_code <- function(code) {
  code <- as.character(code)
  code <- trimws(code)
  code <- gsub("[^0-9]", "", code)  # Remove non-numeric chars
  sprintf("%04d", as.integer(code))
}


#' Create combined school ID
#'
#' Combines district and school codes into a single unique identifier.
#'
#' @param district_code District code
#' @param school_code School code
#' @return 8-character ID (district + school)
#' @keywords internal
create_school_id <- function(district_code, school_code) {
  district_std <- standardize_district_code(district_code)
  school_std <- standardize_school_code(school_code)
  paste0(district_std, school_std)
}
