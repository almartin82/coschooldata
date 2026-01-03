# ==============================================================================
# URL Discovery Functions
# ==============================================================================
#
# CDE uses inconsistent URL patterns across years. This file provides functions
# to dynamically discover data file URLs by scraping the CDE archive pages.
#
# Key pages:
# - Archive: ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives
# - Current: cde.state.co.us/cdereval/pupilcurrent
# - Prior years: cde.state.co.us/cdereval/rvprioryearpmdata
#
# ==============================================================================


#' Get enrollment data URLs for a specific year
#'
#' Discovers the correct URLs for enrollment data files by scraping CDE's
#' archive pages. CDE uses inconsistent URL patterns, so this function
#' provides a reliable way to find current file locations.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @return Named list with URLs for grade and race_gender files, or NULL if not found
#' @keywords internal
get_enrollment_urls <- function(end_year) {

 # First check the hardcoded lookup for known-good URLs
 known_urls <- get_known_enrollment_urls(end_year)
 if (!is.null(known_urls)) {
   return(known_urls)
 }

 # Fall back to scraping the archive page
 scraped_urls <- scrape_enrollment_urls(end_year)
 if (!is.null(scraped_urls)) {
   return(scraped_urls)
 }

 NULL
}


#' Hardcoded lookup table for known-good enrollment URLs
#'
#' CDE URLs are inconsistent across years. This lookup table contains
#' verified URLs that have been tested and confirmed working.
#'
#' NOTE: As of January 2026, www.cde.state.co.us is DOWN. The new site
#' ed.cde.state.co.us hosts pages but files still point to the old domain.
#' This function tries both domains.
#'
#' @param end_year School year end
#' @return Named list with URLs, or NULL if year not in lookup
#' @keywords internal
get_known_enrollment_urls <- function(end_year) {

 # Base domains to try (new domain first, then old)
 # www.cde.state.co.us is DOWN as of Jan 2026, but files may return there
 # ed.cde.state.co.us is UP but currently returns 404 for files
 base_domains <- c(
   "https://www.cde.state.co.us",
   "https://ed.cde.state.co.us"
 )

 # Lookup table of verified URL PATHS (updated 2026-01-03)
 paths <- list(
   "2025" = list(
     grade = "/cdereval/2024-25pk-12membershipgradelevelbyschool",
     race_gender = "/cdereval/2024-25pk-12membershipraceethnicitygendergradeandschool",
     combined = "/cdereval/2024-25pk-12membershipfrlraceethnicitygenderwithflags"
   ),
   "2024" = list(
     grade = "/cdereval/2023-24pk-12membershipgradelevelbyschool",
     race_gender = "/cdereval/2023-24pk-12raceethnicityandgenderbygradeandschool",
     combined = "/cdereval/pk-12membershipfrlracegenderbyschoolwithflags"
   ),
   "2023" = list(
     grade = "/cdereval/2022-2023schoolmembershipgrade",
     race_gender = "/cdereval/2022-2023schoolmembershipethnicityracegender"
   ),
   "2022" = list(
     grade = "/cdereval/2021-2022schoolmembershipgrade",
     race_gender = "/cdereval/2021-2022schoolmembershipethnicityracegender"
   ),
   "2021" = list(
     grade = "/cdereval/2020-21membershipgradelevelbyschool",
     race_gender = "/cdereval/2020-21raceethnicityandgenderbyschool"
   ),
   "2020" = list(
     grade = "/cdereval/2019-20pk-12membershipgradelevelbyschool",
     race_gender = "/cdereval/2019-20pk-12race/ethnicityandgenderbygradeandschool"
   )
 )

 year_paths <- paths[[as.character(end_year)]]
 if (is.null(year_paths)) {
   return(NULL)
 }

 # Try each domain to find working URLs
 for (base in base_domains) {
   urls <- lapply(year_paths, function(path) paste0(base, path))
   names(urls) <- names(year_paths)

   # Test if any URL is reachable
   for (url in urls) {
     tryCatch({
       response <- httr::HEAD(url, httr::timeout(5), httr::config(ssl_verifypeer = FALSE))
       if (!httr::http_error(response)) {
         # Found working domain!
         return(urls)
       }
     }, error = function(e) {
       # Connection failed, try next domain
     })
   }
 }

 # Fall back to www.cde.state.co.us URLs even if not reachable
 # (user will get a clear error message)
 urls <- lapply(year_paths, function(path) paste0(base_domains[1], path))
 names(urls) <- names(year_paths)
 urls
}


#' Scrape CDE archive page to find enrollment URLs
#'
#' Scrapes the CDE data archive page to find URLs for enrollment data files.
#' This is used as a fallback when URLs aren't in the hardcoded lookup table.
#'
#' @param end_year School year end
#' @return Named list with URLs, or NULL if not found
#' @keywords internal
scrape_enrollment_urls <- function(end_year) {

 archive_url <- "https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives"

 tryCatch({
   # Fetch the archive page
   response <- httr::GET(
     archive_url,
     httr::timeout(30),
     httr::config(ssl_verifypeer = FALSE)
   )

   if (httr::http_error(response)) {
     message("  Failed to fetch archive page")
     return(NULL)
   }

   # Parse HTML
   page <- rvest::read_html(httr::content(response, "text", encoding = "UTF-8"))

   # Find all links
   links <- page |>
     rvest::html_elements("a") |>
     rvest::html_attr("href")

   # Filter for enrollment-related links
   # Look for patterns like "membershipgrade", "gradelevel", "raceethnicity"
   year_patterns <- c(
     paste0(end_year - 1, "-", substr(end_year, 3, 4)),  # e.g., "2023-24"
     paste0(end_year - 1, "-", end_year)  # e.g., "2023-2024"
   )

   grade_url <- NULL
   race_url <- NULL

   for (link in links) {
     if (is.na(link)) next

     link_lower <- tolower(link)

     # Check if link matches year pattern
     year_match <- any(sapply(year_patterns, function(p) grepl(tolower(p), link_lower)))
     if (!year_match) next

     # Check for grade-level file
     if (grepl("gradelevel|membershipgrade", link_lower) && is.null(grade_url)) {
       grade_url <- link
     }

     # Check for race/ethnicity file
     if (grepl("race|ethnicity", link_lower) && is.null(race_url)) {
       race_url <- link
     }
   }

   if (!is.null(grade_url) || !is.null(race_url)) {
     # Make URLs absolute if they're relative
     base_url <- "https://www.cde.state.co.us"
     if (!is.null(grade_url) && !grepl("^http", grade_url)) {
       grade_url <- paste0(base_url, grade_url)
     }
     if (!is.null(race_url) && !grepl("^http", race_url)) {
       race_url <- paste0(base_url, race_url)
     }

     return(list(
       grade = grade_url,
       race_gender = race_url
     ))
   }

   NULL

 }, error = function(e) {
   message("  Error scraping archive page: ", e$message)
   NULL
 })
}


#' Scrape CDE to discover all available years
#'
#' Scrapes the CDE archive page to find all years for which enrollment
#' data is available.
#'
#' @return Integer vector of available end years
#' @keywords internal
scrape_available_years <- function() {

 archive_url <- "https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives"

 tryCatch({
   response <- httr::GET(
     archive_url,
     httr::timeout(30),
     httr::config(ssl_verifypeer = FALSE)
   )

   if (httr::http_error(response)) {
     # Fall back to known years if scraping fails
     return(2020:2025)
   }

   page <- rvest::read_html(httr::content(response, "text", encoding = "UTF-8"))

   # Get all text content
   text <- page |>
     rvest::html_text2()

   # Find year patterns like "2023-24" or "2022-2023"
   short_years <- stringr::str_extract_all(text, "20\\d{2}-\\d{2}")[[1]]
   long_years <- stringr::str_extract_all(text, "20\\d{2}-20\\d{2}")[[1]]

   # Convert to end years
   end_years <- c()

   for (y in short_years) {
     parts <- strsplit(y, "-")[[1]]
     start <- as.integer(parts[1])
     end_short <- parts[2]
     end_year <- as.integer(paste0(substr(as.character(start), 1, 2), end_short))
     end_years <- c(end_years, end_year)
   }

   for (y in long_years) {
     parts <- strsplit(y, "-")[[1]]
     end_year <- as.integer(parts[2])
     end_years <- c(end_years, end_year)
   }

   # Get unique years and sort
   end_years <- sort(unique(end_years))

   # Filter to reasonable range
   end_years <- end_years[end_years >= 2015 & end_years <= as.integer(format(Sys.Date(), "%Y")) + 1]

   if (length(end_years) == 0) {
     return(2020:2025)  # Fallback
   }

   end_years

 }, error = function(e) {
   # Fall back to known years
   2020:2025
 })
}


#' Verify a URL returns a valid Excel file
#'
#' Tests if a URL returns an actual Excel file (not an HTML error page).
#'
#' @param url URL to test
#' @return TRUE if URL returns a valid Excel file, FALSE otherwise
#' @keywords internal
verify_excel_url <- function(url) {

 tryCatch({
   response <- httr::HEAD(
     url,
     httr::timeout(10),
     httr::config(ssl_verifypeer = FALSE)
   )

   if (httr::http_error(response)) {
     return(FALSE)
   }

   # Check content type
   content_type <- httr::headers(response)[["content-type"]]
   if (!is.null(content_type)) {
     if (grepl("excel|spreadsheet|octet-stream", content_type, ignore.case = TRUE)) {
       return(TRUE)
     }
   }

   # CDE sometimes doesn't set proper content type, so also check
   # that it's not returning HTML
   if (!is.null(content_type) && grepl("html", content_type, ignore.case = TRUE)) {
     return(FALSE)
   }

   # Assume it's OK if we get here
   TRUE

 }, error = function(e) {
   FALSE
 })
}
