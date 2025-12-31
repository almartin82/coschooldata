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
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
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
#'   \item Data Pipeline: \url{https://www.cde.state.co.us/datapipeline}
#' }
#'
#' @section Data Availability:
#' The package supports three format eras:
#' \itemize{
#'   \item 2009-2018: Excel files with older column format
#'   \item 2019-2023: Excel files with modern column naming
#'   \item 2024+: Current format with enhanced school flags
#' }
#'
#' @docType package
#' @name coschooldata-package
#' @aliases coschooldata
#' @keywords internal
"_PACKAGE"

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
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
