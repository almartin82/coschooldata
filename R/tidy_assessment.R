# ==============================================================================
# Tidy Assessment Data Functions
# ==============================================================================
#
# This file contains functions for converting processed assessment data to
# tidy (long) format.
#
# ==============================================================================


#' Convert assessment data to tidy format
#'
#' Pivots proficiency level columns to long format with proficiency_level and pct columns.
#'
#' @param df Processed assessment data frame from process_assessment
#' @return Tidy data frame with proficiency_level and pct columns
#' @keywords internal
tidy_assessment <- function(df) {

  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_tidy_assessment())
  }

  # Identify proficiency columns to pivot
  pct_cols <- c("pct_did_not_meet", "pct_partially_met", "pct_approached",
                "pct_met", "pct_exceeded")

  # Check which columns exist
  existing_pct_cols <- intersect(pct_cols, names(df))

  if (length(existing_pct_cols) == 0) {
    warning("No proficiency percentage columns found to pivot")
    return(df)
  }

  # Identify non-proficiency columns to keep
  id_cols <- setdiff(names(df), c(pct_cols, "pct_proficient"))

  # Pivot to long format
  tidy_df <- tidyr::pivot_longer(
    df,
    cols = dplyr::all_of(existing_pct_cols),
    names_to = "proficiency_level",
    values_to = "pct",
    names_prefix = "pct_"
  )

  # Standardize proficiency level names
  tidy_df$proficiency_level <- dplyr::case_when(
    tidy_df$proficiency_level == "did_not_meet" ~ "Did Not Yet Meet",
    tidy_df$proficiency_level == "partially_met" ~ "Partially Met",
    tidy_df$proficiency_level == "approached" ~ "Approached",
    tidy_df$proficiency_level == "met" ~ "Met",
    tidy_df$proficiency_level == "exceeded" ~ "Exceeded",
    TRUE ~ tidy_df$proficiency_level
  )

  # Add proficiency flag (Met + Exceeded = proficient)
  tidy_df$is_proficient <- tidy_df$proficiency_level %in% c("Met", "Exceeded")

  # Reorder columns
  col_order <- c("end_year", "district_id", "district_name", "school_id", "school_name",
                 "subject", "grade", "subgroup", "n_tested", "mean_scale_score",
                 "proficiency_level", "pct", "is_proficient",
                 "is_state", "is_district", "is_school", "aggregation_flag")

  # Keep only columns that exist
  col_order <- intersect(col_order, names(tidy_df))

  # Add any remaining columns
  remaining_cols <- setdiff(names(tidy_df), col_order)
  col_order <- c(col_order, remaining_cols)

  tidy_df[, col_order]
}


#' Create empty tidy assessment data frame
#'
#' @return Empty tidy data frame with expected columns
#' @keywords internal
create_empty_tidy_assessment <- function() {
  data.frame(
    end_year = integer(0),
    district_id = character(0),
    district_name = character(0),
    school_id = character(0),
    school_name = character(0),
    subject = character(0),
    grade = character(0),
    subgroup = character(0),
    n_tested = integer(0),
    mean_scale_score = numeric(0),
    proficiency_level = character(0),
    pct = numeric(0),
    is_proficient = logical(0),
    is_state = logical(0),
    is_district = logical(0),
    is_school = logical(0),
    aggregation_flag = character(0),
    stringsAsFactors = FALSE
  )
}


#' Calculate proficiency rates from tidy assessment data
#'
#' Summarizes tidy assessment data to get proficiency rates (Met + Exceeded).
#'
#' @param df Tidy assessment data frame from tidy_assessment
#' @param ... Grouping variables (unquoted)
#' @return Data frame with proficiency rates
#' @export
#' @examples
#' \dontrun{
#' assess <- fetch_assessment(2024)
#' proficiency_rates(assess, end_year, subject, grade)
#' }
proficiency_rates <- function(df, ...) {
  df |>
    dplyr::filter(is_proficient) |>
    dplyr::group_by(...) |>
    dplyr::summarize(
      pct_proficient = sum(pct, na.rm = TRUE),
      .groups = "drop"
    )
}
