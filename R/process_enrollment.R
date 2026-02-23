# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw Colorado enrollment data
# into a standardized wide format, and transforming to tidy format.
#
# Colorado has TWO data formats:
# - 2020-2022: Race/Ethnicity by Gender by Grade by School (per-grade rows)
#   Has district-level aggregate rows (school code 0000)
#   Columns: Org. Code, Organization Name, School Code, School Name, Grade Level,
#            [Race] Female, [Race] Male, PK-12 Total
# - 2023+: Combined Membership, FRL, Race/Ethnicity, Gender with School Flags
#   School-level only (one row per school, no per-grade breakdown)
#   Columns: Organization Code, Organization Name, School Code, School Name,
#            Lowest/Highest Grade Level, Charter Y/N, PK-12 Total,
#            Free/Reduced/Paid Lunch, [Race], Female, Male, Non-Binary
#
# ==============================================================================

#' Process raw enrollment data to wide format
#'
#' Transforms the raw Excel data into a standardized wide format with proper
#' column names and data types. Colorado's data has a 2-row header structure
#' and different column layouts across years.
#'
#' @param df Raw data frame from download_cde_excel
#' @param end_year School year end
#' @return Data frame in wide format with standardized columns
#' @keywords internal
process_enr <- function(df, end_year) {

  # Extract column headers from row 2 and data from row 3 onwards
  col_names <- trimws(as.character(unlist(df[2, ])))
  data_rows <- df[3:nrow(df), , drop = FALSE]
  colnames(data_rows) <- col_names

  # Detect format: legacy has "Race Female" / "Race Male" columns
  has_gender_race <- any(grepl(".+ Female$|.+ Male$", col_names))

  if (has_gender_race) {
    process_enr_legacy(data_rows, end_year)
  } else {
    process_enr_modern(data_rows, end_year)
  }
}


#' Process legacy format enrollment data (2020-2022)
#'
#' Legacy format has per-grade rows with Male/Female splits by race.
#' Includes both school-level and district-level (school code 0000) rows.
#'
#' @param data_rows Data frame with proper column names
#' @param end_year School year end
#' @return Wide format data frame
#' @keywords internal
process_enr_legacy <- function(data_rows, end_year) {

  # Find org code column (varies: "Org. Code" or "Organization Code")
  org_col <- intersect(c("Org. Code", "Organization Code"), names(data_rows))
  if (length(org_col) == 0) stop("Cannot find organization code column")
  org_col <- org_col[1]

  # Remove rows where org code is NA
  data_rows <- data_rows[!is.na(data_rows[[org_col]]) & data_rows[[org_col]] != "", ]

  # Helper to safely get and convert a column
  get_col <- function(name) {
    if (name %in% names(data_rows)) {
      suppressWarnings(as.numeric(data_rows[[name]]))
    } else {
      rep(0, nrow(data_rows))
    }
  }

  # Convert numeric columns
  native_american <- get_col("American Indian or Alaskan Native Female") +
    get_col("American Indian or Alaskan Native Male")
  asian <- get_col("Asian Female") + get_col("Asian Male")
  black <- get_col("Black or African American Female") +
    get_col("Black or African American Male")
  hispanic <- get_col("Hispanic or Latino Female") +
    get_col("Hispanic or Latino Male")
  white <- get_col("White Female") + get_col("White Male")
  pacific_islander <- get_col("Native Hawaiian or Other Pacific Islander Female") +
    get_col("Native Hawaiian or Other Pacific Islander Male")
  multiracial <- get_col("Two or More Races Female") +
    get_col("Two or More Races Male")

  male <- get_col("American Indian or Alaskan Native Male") +
    get_col("Asian Male") +
    get_col("Black or African American Male") +
    get_col("Hispanic or Latino Male") +
    get_col("White Male") +
    get_col("Native Hawaiian or Other Pacific Islander Male") +
    get_col("Two or More Races Male")

  female <- get_col("American Indian or Alaskan Native Female") +
    get_col("Asian Female") +
    get_col("Black or African American Female") +
    get_col("Hispanic or Latino Female") +
    get_col("White Female") +
    get_col("Native Hawaiian or Other Pacific Islander Female") +
    get_col("Two or More Races Female")

  # Extract identifiers
  district_id <- as.character(data_rows[[org_col]])
  district_name <- as.character(data_rows[["Organization Name"]])
  campus_id <- as.character(data_rows[["School Code"]])
  campus_name <- as.character(data_rows[["School Name"]])
  grade_level_raw <- as.character(data_rows[["Grade Level"]])
  grade_level <- parse_grade_level(grade_level_raw)
  row_total <- get_col("PK-12 Total")

  wide <- data.frame(
    end_year = end_year,
    district_id = district_id,
    district_name = district_name,
    campus_id = campus_id,
    campus_name = campus_name,
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
    is_charter = FALSE,
    free_lunch = NA_real_,
    reduced_lunch = NA_real_,
    stringsAsFactors = FALSE
  )

  # Remove rows with NA grade level and NA totals
  wide <- wide[!is.na(wide$grade_level) & !is.na(wide$row_total), ]

  wide
}


#' Process modern format enrollment data (2023+)
#'
#' Modern format has one row per school with combined race totals.
#' No per-grade breakdown; each row is a school-level TOTAL.
#'
#' @param data_rows Data frame with proper column names
#' @param end_year School year end
#' @return Wide format data frame
#' @keywords internal
process_enr_modern <- function(data_rows, end_year) {

  org_col <- "Organization Code"
  data_rows <- data_rows[!is.na(data_rows[[org_col]]) & data_rows[[org_col]] != "", ]

  get_col <- function(name) {
    if (name %in% names(data_rows)) {
      suppressWarnings(as.numeric(data_rows[[name]]))
    } else {
      rep(NA_real_, nrow(data_rows))
    }
  }

  district_id <- as.character(data_rows[["Organization Code"]])
  district_name <- as.character(data_rows[["Organization Name"]])
  campus_id <- as.character(data_rows[["School Code"]])
  campus_name <- as.character(data_rows[["School Name"]])
  grade_level <- rep("TOTAL", nrow(data_rows))

  native_american <- get_col("Amer Indian/Alaskan Native")
  asian <- get_col("Asian")
  black <- get_col("Black or African American")
  hispanic <- get_col("Hispanic or Latino")
  white <- get_col("White")
  pacific_islander <- get_col("Hawaiian/Pacific Islander")
  multiracial <- get_col("Two or More Races")
  male <- get_col("Male")
  female <- get_col("Female")
  row_total <- get_col("PK-12 Total")

  charter_raw <- as.character(data_rows[["Charter Y/N"]])
  is_charter <- !is.na(charter_raw) & toupper(charter_raw) == "Y"
  free_lunch <- get_col("Free Lunch")
  reduced_lunch <- get_col("Reduced Lunch")

  wide <- data.frame(
    end_year = end_year,
    district_id = district_id,
    district_name = district_name,
    campus_id = campus_id,
    campus_name = campus_name,
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
    is_charter = is_charter,
    free_lunch = free_lunch,
    reduced_lunch = reduced_lunch,
    stringsAsFactors = FALSE
  )

  wide <- wide[!is.na(wide$row_total), ]
  wide
}


#' Parse grade level strings to standard format
#'
#' Converts CDE grade level strings to standard format (PK, K, 01-12, TOTAL).
#'
#' @param grade_raw Character vector of raw grade level strings
#' @return Character vector of standardized grade levels
#' @keywords internal
parse_grade_level <- function(grade_raw) {
  dplyr::case_when(
    is.na(grade_raw) ~ NA_character_,
    grepl("ALL GRADE LEVELS", grade_raw, ignore.case = TRUE) ~ "TOTAL",
    grepl("^004|PK|Pre-?K|Preschool", grade_raw, ignore.case = TRUE) ~ "PK",
    grepl("^006|1/2 Day K|Half.Day K", grade_raw, ignore.case = TRUE) ~ "K",
    grepl("^007|Full Day K|^K$|Kindergarten", grade_raw, ignore.case = TRUE) ~ "K",
    grepl("^010|^1st", grade_raw) ~ "01",
    grepl("^020|^2nd", grade_raw) ~ "02",
    grepl("^030|^3rd", grade_raw) ~ "03",
    grepl("^040|^4th", grade_raw) ~ "04",
    grepl("^050|^5th", grade_raw) ~ "05",
    grepl("^060|^6th", grade_raw) ~ "06",
    grepl("^070|^7th", grade_raw) ~ "07",
    grepl("^080|^8th", grade_raw) ~ "08",
    grepl("^090|^9th", grade_raw) ~ "09",
    grepl("^100|^10th", grade_raw) ~ "10",
    grepl("^110|^11th", grade_raw) ~ "11",
    grepl("^120|^12th", grade_raw) ~ "12",
    TRUE ~ grade_raw
  )
}


#' Tidy enrollment data
#'
#' Transforms wide enrollment data to long format with subgroup column.
#' Creates district-level and state-level aggregates from school-level data.
#' Adds standard entity flags: is_state, is_district, is_school, is_charter.
#'
#' @param df A wide data.frame of processed enrollment data
#' @return A long data.frame of tidied enrollment data with standard columns:
#'   end_year, district_id, district_name, campus_id, campus_name,
#'   grade_level, subgroup, n_students, pct, is_state, is_district,
#'   is_school, is_charter
#' @importFrom magrittr `%>%`
#' @export
tidy_enr <- function(df) {

  if (!"row_total" %in% names(df)) {
    stop("Input data must have 'row_total' column. Use process_enr() first.")
  }

  # Identify raw entity types from school code
  is_school_row <- !is.na(df$campus_id) & df$campus_id != "" & df$campus_id != "0000"
  is_district_row <- !is.na(df$campus_id) & df$campus_id == "0000"

  # Mark entity flags on input data
  df$is_school <- is_school_row
  df$is_district <- is_district_row
  df$is_state <- FALSE

  if (!"is_charter" %in% names(df)) {
    df$is_charter <- FALSE
  }

  # Add total_enrollment
  df$total_enrollment <- df$row_total

  # Subgroup columns to pivot
  subgroups <- c(
    "total_enrollment", "male", "female",
    "native_american", "asian", "black", "hispanic",
    "white", "pacific_islander", "multiracial"
  )

  # Add free_reduced_lunch if FRL data exists
  if ("free_lunch" %in% names(df) && "reduced_lunch" %in% names(df)) {
    has_frl <- any(!is.na(df$free_lunch) | !is.na(df$reduced_lunch))
    if (has_frl) {
      df$free_reduced_lunch <- ifelse(
        is.na(df$free_lunch) & is.na(df$reduced_lunch), NA_real_,
        ifelse(is.na(df$free_lunch), 0, df$free_lunch) +
          ifelse(is.na(df$reduced_lunch), 0, df$reduced_lunch)
      )
      subgroups <- c(subgroups, "free_reduced_lunch")
    }
  }

  subgroups <- subgroups[subgroups %in% names(df)]

  # Only keep school-level rows for pivoting (exclude sparse district rows
  # from legacy format -- we'll re-aggregate those properly)
  df_schools <- df[df$is_school, ]

  # Pivot school-level rows to long format
  school_tidy <- pivot_to_long(df_schools, subgroups)

  # Create district aggregates from school-level data
  district_agg <- create_district_aggregates(school_tidy, df)

  # Create state aggregates from district aggregates
  state_agg <- create_state_aggregates_from_districts(district_agg)

  # Combine all levels
  result <- rbind(school_tidy, district_agg, state_agg)

  # Sort
  result <- result[order(
    result$end_year, result$is_state, result$district_id,
    result$campus_id, result$grade_level, result$subgroup
  ), ]
  rownames(result) <- NULL

  result
}


#' Pivot wide data to long format
#'
#' @param df Wide data frame
#' @param subgroups Character vector of subgroup column names
#' @return Long format data frame
#' @keywords internal
pivot_to_long <- function(df, subgroups) {

  invariants <- c(
    "end_year", "district_id", "district_name", "campus_id", "campus_name",
    "grade_level", "is_state", "is_district", "is_school", "is_charter"
  )

  tidy_list <- lapply(subgroups, function(sg) {
    out <- df[, c(invariants, sg, "row_total"), drop = FALSE]
    out$subgroup <- sg
    out$n_students <- out[[sg]]
    out$pct <- ifelse(
      !is.na(out$row_total) & out$row_total > 0,
      pmin(out$n_students / out$row_total, 1.0),
      NA_real_
    )
    out[, c(invariants, "subgroup", "n_students", "pct"), drop = FALSE]
  })

  do.call(rbind, tidy_list)
}


#' Create district-level aggregates from school-level data
#'
#' Sums school-level data within each district to create district totals.
#' Always aggregates from school-level data to ensure all districts are
#' covered (legacy format only has sparse district-level rows for ~9 districts).
#'
#' @param school_tidy Long format data (may include sparse district rows)
#' @param wide_df Original wide data (unused, kept for API compatibility)
#' @return Data frame of district-level tidy rows
#' @keywords internal
create_district_aggregates <- function(school_tidy, wide_df) {

  # Always aggregate from school-level data to ensure completeness
  schools_only <- school_tidy[school_tidy$is_school, ]
  if (nrow(schools_only) == 0) return(data.frame())

  end_years <- unique(schools_only$end_year)
  grade_levels <- unique(schools_only$grade_level)
  subgroups_list <- unique(schools_only$subgroup)

  agg_list <- list()

  for (yr in end_years) {
    for (gl in grade_levels) {
      yr_gl <- schools_only[schools_only$end_year == yr & schools_only$grade_level == gl, ]
      if (nrow(yr_gl) == 0) next

      districts <- unique(yr_gl$district_id)

      for (did in districts) {
        dist_data <- yr_gl[yr_gl$district_id == did, ]
        dname <- dist_data$district_name[1]

        for (sg in subgroups_list) {
          sg_data <- dist_data[dist_data$subgroup == sg, ]
          if (nrow(sg_data) == 0) next

          total_n <- sum(sg_data$n_students, na.rm = TRUE)

          if (sg == "total_enrollment") {
            dist_total <- total_n
          } else {
            te_data <- dist_data[dist_data$subgroup == "total_enrollment", ]
            dist_total <- sum(te_data$n_students, na.rm = TRUE)
          }

          pct_val <- if (dist_total > 0) pmin(total_n / dist_total, 1.0) else NA_real_

          agg_list[[length(agg_list) + 1]] <- data.frame(
            end_year = yr,
            district_id = did,
            district_name = dname,
            campus_id = "0000",
            campus_name = NA_character_,
            grade_level = gl,
            is_state = FALSE,
            is_district = TRUE,
            is_school = FALSE,
            is_charter = FALSE,
            subgroup = sg,
            n_students = total_n,
            pct = pct_val,
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }

  if (length(agg_list) == 0) return(data.frame())
  do.call(rbind, agg_list)
}


#' Create state-level aggregates from district data
#'
#' @param district_tidy Long format district-level data
#' @return Data frame of state-level tidy rows
#' @keywords internal
create_state_aggregates_from_districts <- function(district_tidy) {

  if (nrow(district_tidy) == 0) return(data.frame())

  end_years <- unique(district_tidy$end_year)
  grade_levels <- unique(district_tidy$grade_level)
  subgroups_list <- unique(district_tidy$subgroup)

  state_list <- list()

  for (yr in end_years) {
    for (gl in grade_levels) {
      for (sg in subgroups_list) {
        subset <- district_tidy[
          district_tidy$end_year == yr &
          district_tidy$grade_level == gl &
          district_tidy$subgroup == sg,
        ]
        if (nrow(subset) == 0) next

        total_n <- sum(subset$n_students, na.rm = TRUE)

        # Get state total enrollment for pct
        if (sg == "total_enrollment") {
          state_total <- total_n
        } else {
          te_sub <- district_tidy[
            district_tidy$end_year == yr &
            district_tidy$grade_level == gl &
            district_tidy$subgroup == "total_enrollment",
          ]
          state_total <- sum(te_sub$n_students, na.rm = TRUE)
        }

        pct_val <- if (state_total > 0) pmin(total_n / state_total, 1.0) else NA_real_

        state_list[[length(state_list) + 1]] <- data.frame(
          end_year = yr,
          district_id = NA_character_,
          district_name = "Colorado",
          campus_id = NA_character_,
          campus_name = NA_character_,
          grade_level = gl,
          is_state = TRUE,
          is_district = FALSE,
          is_school = FALSE,
          is_charter = FALSE,
          subgroup = sg,
          n_students = total_n,
          pct = pct_val,
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(state_list) == 0) return(data.frame())
  do.call(rbind, state_list)
}
