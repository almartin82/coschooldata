# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Colorado Department of Education (CDE) website.
#
# Data sources:
#   - School Addresses: https://cedar.cde.state.co.us/edulibdir/School%20Addresses-en.xlsx
#   - District Addresses: https://cedar.cde.state.co.us/edulibdir/District%20Addresses-en.xlsx
#   - School Codes: https://cedar.cde.state.co.us/edulibdir/School%20Building%20Codes-en-us.xlsx
#
# ==============================================================================

#' Fetch Colorado school directory data
#'
#' Downloads and processes school and district directory data from the Colorado
#' Department of Education. This includes all public schools and districts with
#' contact information, addresses, and grade level information.
#'
#' @param end_year Currently unused. The directory data represents current
#'   schools and is not year-specific. Included for API consistency with
#'   other fetch functions.
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from CDE.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from CDE.
#' @return A tibble with school directory data. Columns include:
#'   \itemize{
#'     \item \code{state_school_id}: Combined district + school code (8 digits)
#'     \item \code{state_district_id}: 4-digit district code
#'     \item \code{school_code}: 4-digit school code
#'     \item \code{school_name}: School name
#'     \item \code{district_name}: District name
#'     \item \code{school_type}: Type of school (District, School)
#'     \item \code{grades_served}: Low grade - High grade
#'     \item \code{low_grade}: Lowest grade served
#'     \item \code{high_grade}: Highest grade served
#'     \item \code{address}: Physical street address
#'     \item \code{city}: City
#'     \item \code{state}: State (always "CO")
#'     \item \code{zip}: ZIP code
#'     \item \code{phone}: Phone number
#'     \item \code{charter_status}: Charter indicator (Y/N)
#'     \item \code{agg_level}: Aggregation level ("S" = School, "D" = District)
#'   }
#' @details
#' The directory data is downloaded as Excel files from the CDE CEDAR library.
#' School addresses and district addresses are downloaded separately and combined.
#' This data represents the current state of Colorado schools and districts
#' and is updated regularly by CDE.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get school directory data
#' dir_data <- fetch_directory()
#'
#' # Get raw format (original CDE column names)
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Filter to schools only
#' library(dplyr)
#' schools <- dir_data |>
#'   filter(agg_level == "S")
#'
#' # Find all schools in a district
#' denver_schools <- dir_data |>
#'   filter(state_district_id == "0880", agg_level == "S")
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE) {

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists_directory(cache_type)) {
    message("Using cached school directory data")
    return(read_cache_directory(cache_type))
  }

  # Get raw data from CDE
  raw <- get_raw_directory()

  # Process to standard schema
  if (tidy) {
    result <- process_directory(raw)
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache_directory(result, cache_type)
  }

  result
}


#' Get raw school directory data from CDE
#'
#' Downloads the raw school directory Excel files from the Colorado
#' Department of Education CEDAR library. Downloads both school addresses
#' and district addresses.
#'
#' @return A list with two data frames: schools and districts
#' @keywords internal
get_raw_directory <- function() {

  message("Downloading school directory data from CDE...")

  # Download school addresses
  school_url <- "https://cedar.cde.state.co.us/edulibdir/School%20Addresses-en.xlsx"
  school_file <- tempfile(pattern = "co_school_addr_", fileext = ".xlsx")

  # Download district addresses
  district_url <- "https://cedar.cde.state.co.us/edulibdir/District%20Addresses-en.xlsx"
  district_file <- tempfile(pattern = "co_district_addr_", fileext = ".xlsx")

  # Set longer timeout for downloads
  old_timeout <- getOption("timeout")
  options(timeout = 300)

  tryCatch({
    # Download school addresses
    utils::download.file(school_url, destfile = school_file, mode = "wb", quiet = TRUE)

    # Check file size
    if (file.info(school_file)$size < 10000) {
      stop("School addresses download failed - file too small")
    }

    # Download district addresses
    utils::download.file(district_url, destfile = district_file, mode = "wb", quiet = TRUE)

    # Check file size
    if (file.info(district_file)$size < 10000) {
      stop("District addresses download failed - file too small")
    }

  }, error = function(e) {
    options(timeout = old_timeout)
    stop(paste("Failed to download directory data from CDE:", e$message))
  })

  options(timeout = old_timeout)

  message(paste("Downloaded school addresses:",
                round(file.info(school_file)$size / 1024, 1), "KB"))
  message(paste("Downloaded district addresses:",
                round(file.info(district_file)$size / 1024, 1), "KB"))

  # Read Excel files - both have header rows to skip
  schools <- readxl::read_excel(
    school_file,
    skip = 5,
    col_types = "text",
    .name_repair = "unique"
  )

  districts <- readxl::read_excel(
    district_file,
    skip = 5,
    col_types = "text",
    .name_repair = "unique"
  )

  message(paste("Loaded", nrow(schools), "school records and",
                nrow(districts), "district records"))

  # Return list of data frames
  list(
    schools = dplyr::as_tibble(schools),
    districts = dplyr::as_tibble(districts)
  )
}


#' Process raw school directory data to standard schema
#'
#' Takes raw school directory data from CDE and standardizes column names,
#' types, and combines schools and districts into a single data frame.
#'
#' @param raw_data List with schools and districts data frames from get_raw_directory()
#' @return Processed data frame with standard schema
#' @keywords internal
process_directory <- function(raw_data) {

  schools <- raw_data$schools
  districts <- raw_data$districts

  # Process schools
  schools_processed <- process_school_addresses(schools)
  schools_processed$agg_level <- "S"

  # Process districts
  districts_processed <- process_district_addresses(districts)
  districts_processed$agg_level <- "D"

  # Ensure both have same columns
  all_cols <- union(names(schools_processed), names(districts_processed))

  for (col in all_cols) {
    if (!col %in% names(schools_processed)) {
      schools_processed[[col]] <- NA_character_
    }
    if (!col %in% names(districts_processed)) {
      districts_processed[[col]] <- NA_character_
    }
  }

  # Combine
  result <- dplyr::bind_rows(schools_processed, districts_processed)

  # Reorder columns for consistency
  preferred_order <- c(
    "state_school_id", "state_district_id", "school_code",
    "agg_level", "school_name", "district_name",
    "school_type", "charter_status",
    "grades_served", "low_grade", "high_grade",
    "address", "mailing_address", "city", "state", "zip",
    "phone", "fax", "email_domain",
    "county_name", "county_code", "congressional_district",
    "district_size", "district_setting"
  )

  existing_cols <- preferred_order[preferred_order %in% names(result)]
  other_cols <- setdiff(names(result), preferred_order)

  result <- result |>
    dplyr::select(dplyr::all_of(c(existing_cols, other_cols)))

  result
}


#' Process school addresses data
#'
#' @param data Raw school addresses data frame
#' @return Processed data frame
#' @keywords internal
process_school_addresses <- function(data) {

  cols <- names(data)

  # Helper to find columns with flexible matching
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  result <- dplyr::tibble(.rows = nrow(data))

  # District Code
  district_col <- find_col(c("^District Code$", "^District.?Code$", "^DistrictCode$"))
  if (!is.null(district_col)) {
    result$state_district_id <- sprintf("%04d", as.integer(data[[district_col]]))
  }

  # School Code
  school_col <- find_col(c("^School Code$", "^School.?Code$", "^SchoolCode$"))
  if (!is.null(school_col)) {
    result$school_code <- sprintf("%04d", as.integer(data[[school_col]]))
  }

  # Create combined state_school_id
  if ("state_district_id" %in% names(result) && "school_code" %in% names(result)) {
    result$state_school_id <- paste0(result$state_district_id, result$school_code)
  }

  # District Name
  district_name_col <- find_col(c("^District Name$", "^District.?Name$", "^DistrictName$"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(data[[district_name_col]])
  }

  # School Name
  school_name_col <- find_col(c("^School Name$", "^School.?Name$", "^SchoolName$"))
  if (!is.null(school_name_col)) {
    result$school_name <- trimws(data[[school_name_col]])
  }

  # Charter status
  charter_col <- find_col(c("^Charter Y/N$", "^Charter$", "^Charter.?Y.?N$"))
  if (!is.null(charter_col)) {
    result$charter_status <- trimws(data[[charter_col]])
  }

  # Physical Address
  addr_col <- find_col(c("^Physical Address$", "^Address$", "^Street$"))
  if (!is.null(addr_col)) {
    result$address <- trimws(data[[addr_col]])
  }

  # Mailing Address
  mail_col <- find_col(c("^Mailing Address$", "^Mail.?Address$"))
  if (!is.null(mail_col)) {
    result$mailing_address <- trimws(data[[mail_col]])
  }

  # City
  city_col <- find_col(c("^City$"))
  if (!is.null(city_col)) {
    result$city <- trimws(data[[city_col]])
  }

  # State
  state_col <- find_col(c("^State$"))
  if (!is.null(state_col)) {
    result$state <- trimws(data[[state_col]])
  } else {
    result$state <- "CO"
  }

  # Zip Code
  zip_col <- find_col(c("^Zip Code$", "^Zip$", "^ZipCode$"))
  if (!is.null(zip_col)) {
    result$zip <- trimws(data[[zip_col]])
  }

  # Phone
  phone_col <- find_col(c("^Phone$", "^Telephone$"))
  if (!is.null(phone_col)) {
    result$phone <- trimws(data[[phone_col]])
  }

  # Low Grade
  low_col <- find_col(c("^Low grade$", "^Low.?Grade$", "^LowGrade$"))
  if (!is.null(low_col)) {
    result$low_grade <- trimws(data[[low_col]])
  }

  # High Grade
  high_col <- find_col(c("^High grade$", "^High.?Grade$", "^HighGrade$"))
  if (!is.null(high_col)) {
    result$high_grade <- trimws(data[[high_col]])
  }

  # Create grades_served from low and high
  if ("low_grade" %in% names(result) && "high_grade" %in% names(result)) {
    result$grades_served <- paste(result$low_grade, "-", result$high_grade)
  }

  # Congressional District
  cong_col <- find_col(c("^Congressional District$", "^Congressional.?District$"))
  if (!is.null(cong_col)) {
    result$congressional_district <- trimws(data[[cong_col]])
  }

  # School type - for schools, set as "School"
  result$school_type <- "School"

  result
}


#' Process district addresses data
#'
#' @param data Raw district addresses data frame
#' @return Processed data frame
#' @keywords internal
process_district_addresses <- function(data) {

  cols <- names(data)

  # Helper to find columns with flexible matching
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  result <- dplyr::tibble(.rows = nrow(data))

  # District Code
  district_col <- find_col(c("^District Code$", "^District.?Code$", "^DistrictCode$"))
  if (!is.null(district_col)) {
    result$state_district_id <- sprintf("%04d", as.integer(data[[district_col]]))
  }

  # For districts, school_code is 0000
  result$school_code <- "0000"

  # Create combined state_school_id (district only)
  if ("state_district_id" %in% names(result)) {
    result$state_school_id <- paste0(result$state_district_id, "0000")
  }

  # District Name (use as both district_name and school_name for consistency)
  district_name_col <- find_col(c("^District Name$", "^District.?Name$", "^DistrictName$"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(data[[district_name_col]])
    result$school_name <- trimws(data[[district_name_col]])
  }

  # Organization Type
  org_type_col <- find_col(c("^Organization Type$", "^Organization.?Type$"))
  if (!is.null(org_type_col)) {
    result$school_type <- trimws(data[[org_type_col]])
  } else {
    result$school_type <- "District"
  }

  # Physical Address
  addr_col <- find_col(c("^Physical Address$", "^Address$", "^Street$"))
  if (!is.null(addr_col)) {
    result$address <- trimws(data[[addr_col]])
  }

  # Mailing Address
  mail_col <- find_col(c("^Mailing Address$", "^Mail.?Address$"))
  if (!is.null(mail_col)) {
    result$mailing_address <- trimws(data[[mail_col]])
  }

  # City
  city_col <- find_col(c("^City$"))
  if (!is.null(city_col)) {
    result$city <- trimws(data[[city_col]])
  }

  # State
  state_col <- find_col(c("^State$"))
  if (!is.null(state_col)) {
    result$state <- trimws(data[[state_col]])
  } else {
    result$state <- "CO"
  }

  # Zip Code
  zip_col <- find_col(c("^Zipcode$", "^Zip Code$", "^Zip$"))
  if (!is.null(zip_col)) {
    result$zip <- trimws(data[[zip_col]])
  }

  # Phone
  phone_col <- find_col(c("^Phone$", "^Telephone$"))
  if (!is.null(phone_col)) {
    result$phone <- trimws(data[[phone_col]])
  }

  # Fax
  fax_col <- find_col(c("^Fax$"))
  if (!is.null(fax_col)) {
    result$fax <- trimws(data[[fax_col]])
  }

  # Email Domain
  email_col <- find_col(c("^Email Domain$", "^Email.?Domain$"))
  if (!is.null(email_col)) {
    result$email_domain <- trimws(data[[email_col]])
  }

  # County Name
  county_name_col <- find_col(c("^County Name$", "^County.?Name$"))
  if (!is.null(county_name_col)) {
    result$county_name <- trimws(data[[county_name_col]])
  }

  # County Code
  county_code_col <- find_col(c("^County Code$", "^County.?Code$"))
  if (!is.null(county_code_col)) {
    result$county_code <- trimws(data[[county_code_col]])
  }

  # Congressional District
  cong_col <- find_col(c("^Congressional District$", "^Congressional.?District$"))
  if (!is.null(cong_col)) {
    result$congressional_district <- trimws(data[[cong_col]])
  }

  # District Size
  size_col <- find_col(c("^District Size$", "^District.?Size$"))
  if (!is.null(size_col)) {
    result$district_size <- trimws(data[[size_col]])
  }

  # District Setting
  setting_col <- find_col(c("^District Setting$", "^District.?Setting$"))
  if (!is.null(setting_col)) {
    result$district_setting <- trimws(data[[setting_col]])
  }

  # Charter status - districts are not charters
  result$charter_status <- "N"

  result
}


# ==============================================================================
# Directory-specific cache functions
# ==============================================================================

#' Build cache file path for directory data
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return File path string
#' @keywords internal
build_cache_path_directory <- function(cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, ".rds"))
}


#' Check if cached directory data exists
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @param max_age Maximum age in days (default 30). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists_directory <- function(cache_type, max_age = 30) {
  cache_path <- build_cache_path_directory(cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read directory data from cache
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Cached data frame
#' @keywords internal
read_cache_directory <- function(cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param data Data frame to cache
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache_directory <- function(data, cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear school directory cache
#'
#' Removes cached school directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear cached directory data
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
