#' coschooldata: Fetch and Process Colorado School Data
#'
#' Downloads and processes school data from the Colorado Department of Education
#' (CDE). Provides functions for fetching enrollment data from the Student October
#' Count collection and transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{get_available_years}}}{Get available year range for data}
#' }
#'
#' @section ID System:
#' Colorado uses a hierarchical ID system:
#' \itemize{
#'   \item District IDs: 4 digits (e.g., 0880 = Denver County 1)
#'   \item School IDs: 4 digits (unique within district context)
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Colorado Department of Education:
#' \itemize{
#'   \item Pupil Membership: \url{https://www.cde.state.co.us/cdereval/pupilcurrent}
#'   \item Data Archive: \url{https://ed.cde.state.co.us/cdereval/pupilmembership-statistics}
#' }
#'
#' @section Data Availability:
#' The package currently supports years 2020-2025. Data comes from the Student
#' October Count collection published by CDE. Use \code{get_available_years()}
#' to check the current available range.
#'
#' @docType package
#' @name coschooldata-package
#' @aliases coschooldata
#' @keywords internal
"_PACKAGE"

