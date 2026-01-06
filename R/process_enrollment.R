# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw Colorado enrollment data
# into a standardized wide format, and transforming to tidy format.
#
# ==============================================================================

#' Process raw enrollment data to wide format
#'
#' Transforms the raw Excel data into a standardized wide format with proper
#' column names and data types. Colorado's data has a 2-row header structure
#'
#' @param df Raw data frame from download_cde_excel
#' @param end_year School year end
#' @return Data frame in wide format with standardized columns
#' @keywords internal
process_enr <- function(df, end_year) {

  # Skip first row (title row), second row contains actual column headers
  # Remove rows 1-2 and use row 2 as column names
  col_names <- as.character(unlist(df[2, ]))
  data_rows <- df[3:nrow(df), , drop = FALSE]

  # Set proper column names
  colnames(data_rows) <- col_names

  # Remove rows where critical identifier columns are NA
  org_code_col <- "Organization Code"
  data_rows <- data_rows[!is.na(data_rows[[org_code_col]]), ]

  # Convert numeric columns - all enrollment count columns
  race_gender_cols <- c(
    "American Indian or Alaskan Native Female",
    "American Indian or Alaskan Native Male",
    "Asian Female",
    "Asian Male",
    "Black or African American Female",
    "Black or African American Male",
    "Hispanic or Latino Female",
    "Hispanic or Latino Male",
    "White Female",
    "White Male",
    "Native Hawaiian or Other Pacific Islander Female",
    "Native Hawaiian or Other Pacific Islander Male",
    "Two or More Races Female",
    "Two or More Races Male",
    "PK-12 Total"
  )

  # Convert columns that exist in the data
  cols_to_convert <- race_gender_cols[race_gender_cols %in% col_names]
  for (col in cols_to_convert) {
    data_rows[[col]] <- as.numeric(data_rows[[col]])
  }

  # Extract columns by name to avoid issues with special characters
  district_id <- data_rows[["Organization Code"]]
  district_name <- data_rows[["Organization Name"]]
  campus_id <- data_rows[["School Code"]]
  campus_name <- data_rows[["School Name"]]
  grade_level_raw <- data_rows[["Grade Level"]]

  # Parse grade level
  grade_level <- dplyr::case_when(
    grade_level_raw == "ALL GRADE LEVELS" ~ "TOTAL",
    grepl("PK|004", grade_level_raw, ignore.case = TRUE) ~ "PK",
    grepl("K|007", grade_level_raw) ~ "K",
    grepl("010|1st", grade_level_raw) ~ "01",
    grepl("020|2nd", grade_level_raw) ~ "02",
    grepl("030|3rd", grade_level_raw) ~ "03",
    grepl("040|4th", grade_level_raw) ~ "04",
    grepl("050|5th", grade_level_raw) ~ "05",
    grepl("060|6th", grade_level_raw) ~ "06",
    grepl("070|7th", grade_level_raw) ~ "07",
    grepl("080|8th", grade_level_raw) ~ "08",
    grepl("090|9th", grade_level_raw) ~ "09",
    grepl("100|10th", grade_level_raw) ~ "10",
    grepl("110|11th", grade_level_raw) ~ "11",
    grepl("120|12th", grade_level_raw) ~ "12",
    TRUE ~ grade_level_raw
  )

  # Create demographic columns (summing male and female)
  native_american <- data_rows[["American Indian or Alaskan Native Female"]] +
                     data_rows[["American Indian or Alaskan Native Male"]]
  asian <- data_rows[["Asian Female"]] + data_rows[["Asian Male"]]
  black <- data_rows[["Black or African American Female"]] +
          data_rows[["Black or African American Male"]]
  hispanic <- data_rows[["Hispanic or Latino Female"]] +
             data_rows[["Hispanic or Latino Male"]]
  white <- data_rows[["White Female"]] + data_rows[["White Male"]]
  pacific_islander <- data_rows[["Native Hawaiian or Other Pacific Islander Female"]] +
                     data_rows[["Native Hawaiian or Other Pacific Islander Male"]]
  multiracial <- data_rows[["Two or More Races Female"]] +
                data_rows[["Two or More Races Male"]]
  male <- data_rows[["American Indian or Alaskan Native Male"]] +
         data_rows[["Asian Male"]] +
         data_rows[["Black or African American Male"]] +
         data_rows[["Hispanic or Latino Male"]] +
         data_rows[["White Male"]] +
         data_rows[["Native Hawaiian or Other Pacific Islander Male"]] +
         data_rows[["Two or More Races Male"]]
  female <- data_rows[["American Indian or Alaskan Native Female"]] +
           data_rows[["Asian Female"]] +
           data_rows[["Black or African American Female"]] +
           data_rows[["Hispanic or Latino Female"]] +
           data_rows[["White Female"]] +
           data_rows[["Native Hawaiian or Other Pacific Islander Female"]] +
           data_rows[["Two or More Races Female"]]
  row_total <- data_rows[["PK-12 Total"]]

  # Determine type (district/campus)
  type <- dplyr::if_else(campus_id == "0000", "District", "Campus")

  # Create wide data frame
  wide <- data.frame(
    end_year = end_year,
    district_id = district_id,
    district_name = district_name,
    campus_id = campus_id,
    campus_name = campus_name,
    type = type,
    grade_level = grade_level,
    row_total = row_total,
    male = male,
    female = female,
    native_american = native_american,
    asian = asian,
    black = black,
    hispanic = hispanic,
    white = white,
    pacific_islander = pacific_islander,
    multiracial = multiracial,
    stringsAsFactors = FALSE
  )

  # Replace NaN and Inf with NA (can occur from division operations)
  wide[is.nan(wide)] <- NA
  wide[is.infinite(wide)] <- NA

  wide
}


#' Tidy enrollment data
#'
#' Transforms wide enrollment data to long format with subgroup column.
#' Matches the PRD specification for tidy format.
#'
#' @param df A wide data.frame of processed enrollment data
#' @return A long data.frame of tidied enrollment data
#' @importFrom magrittr `%>%`
#' @export
tidy_enr <- function(df) {

  # Ensure row_total exists for percentage calculations
  if (!"row_total" %in% names(df)) {
    stop("Input data must have 'row_total' column")
  }

  # Identify aggregation level from type
  if (!"type" %in% names(df)) {
    df$type <- dplyr::if_else(
      is.na(df$campus_id) | df$campus_id == "0000",
      "District",
      "Campus"
    )
  }

  # Invariant columns that identify each row
  invariants <- c(
    "end_year",
    "district_id",
    "district_name",
    "campus_id",
    "campus_name",
    "type",
    "grade_level"
  )

  # Subgroup columns to tidy (demographic breakdowns)
  to_tidy <- c(
    "total_enrollment",  # Will be created from row_total
    "male",
    "female",
    "native_american",
    "asian",
    "black",
    "hispanic",
    "white",
    "pacific_islander",
    "multiracial"
  )

  # Add total_enrollment as row_total if not present
  if (!"total_enrollment" %in% names(df)) {
    df$total_enrollment <- df$row_total
  }

  # Filter to columns that exist in df (including total_enrollment we just added)
  to_tidy <- to_tidy[to_tidy %in% c("row_total", names(df))]

  # Iterate over subgroup columns, creating long format rows
  tidy_subgroups <- purrr::map_df(
    to_tidy,
    function(.x) {
      .col_name <- if (.x == "total_enrollment") "row_total" else .x

      df %>%
        dplyr::mutate(n_students = .data[[.col_name]]) %>%
        dplyr::select(dplyr::one_of(c(invariants, "n_students", "row_total"))) %>%
        dplyr::mutate(
          subgroup = .x,
          pct = dplyr::case_when(
            row_total > 0 ~ pmin(n_students / row_total, 1.0),
            TRUE ~ 0.0
          )
        ) %>%
        dplyr::select(dplyr::one_of(c(invariants, "subgroup", "n_students", "pct")))
    }
  )

  # Handle division by zero and NA values
  tidy_subgroups$pct[!is.finite(tidy_subgroups$pct)] <- NA

  # Return tidy data
  tidy_subgroups %>%
    dplyr::mutate(aggregation_flag = dplyr::case_when(
      !is.na(district_id) & !is.na(campus_id) & district_id != "" & campus_id != "" & campus_id != "0000" ~ "campus",
      !is.na(district_id) & district_id != "" ~ "district",
      TRUE ~ "state"
    )) %>%
    dplyr::arrange(end_year, district_id, campus_id, grade_level, subgroup)
}
