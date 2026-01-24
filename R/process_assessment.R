# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw CMAS assessment data into a
# clean, standardized format.
#
# CMAS proficiency levels (grades 3-8 ELA/Math):
# - Did Not Yet Meet Expectations (Level 1)
# - Partially Met Expectations (Level 2)
# - Approached Expectations (Level 3)
# - Met Expectations (Level 4)
# - Exceeded Expectations (Level 5)
#
# CMAS proficiency levels (Science/Social Studies):
# - Did Not Yet Meet Expectations
# - Partially Met Expectations
# - Met Expectations
# - Exceeded Expectations
#
# ==============================================================================


#' Process raw CMAS assessment data
#'
#' Transforms raw CMAS assessment data into a standardized schema.
#'
#' @param raw_data Data frame from get_raw_assessment
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_assessment <- function(raw_data, end_year) {

  if (is.null(raw_data) || nrow(raw_data) == 0) {
    return(create_empty_assessment_result(end_year))
  }

  cols <- names(raw_data)
  n_rows <- nrow(raw_data)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    stringsAsFactors = FALSE
  )

  # District ID - CDE uses various column names
  district_col <- find_col(c("^district_id$", "^district_code$", "^district_number$",
                             "^org_code$", "^organization_code$", "^districtcode$"))
  if (!is.null(district_col)) {
    district_vals <- trimws(as.character(raw_data[[district_col]]))
    result$district_id <- ifelse(
      district_vals == "" | district_vals == "STATE" | is.na(district_vals),
      NA_character_,
      sprintf("%04s", district_vals)
    )
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  # District name
  district_name_col <- find_col(c("^district_name$", "^district$", "^districtname$",
                                   "^organization_name$", "^org_name$"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(as.character(raw_data[[district_name_col]]))
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  # School ID
  school_col <- find_col(c("^school_id$", "^school_code$", "^school_number$", "^schoolcode$"))
  if (!is.null(school_col)) {
    school_vals <- trimws(as.character(raw_data[[school_col]]))
    result$school_id <- ifelse(
      school_vals == "" | school_vals == "0" | is.na(school_vals),
      NA_character_,
      sprintf("%04s", school_vals)
    )
  } else {
    result$school_id <- rep(NA_character_, n_rows)
  }

  # School name
  school_name_col <- find_col(c("^school_name$", "^school$", "^schoolname$"))
  if (!is.null(school_name_col)) {
    result$school_name <- trimws(as.character(raw_data[[school_name_col]]))
  } else {
    result$school_name <- rep(NA_character_, n_rows)
  }

  # Subject
  subject_col <- find_col(c("^subject$", "^content_area$", "^contentarea$", "^test_name$"))
  if (!is.null(subject_col)) {
    result$subject <- standardize_assessment_subject(raw_data[[subject_col]])
  } else if ("subject" %in% names(raw_data)) {
    result$subject <- standardize_assessment_subject(raw_data$subject)
  } else {
    result$subject <- rep(NA_character_, n_rows)
  }

  # Grade
  grade_col <- find_col(c("^grade$", "^grade_level$", "^gradelevel$", "^tested_grade$"))
  if (!is.null(grade_col)) {
    result$grade <- standardize_assessment_grade(raw_data[[grade_col]])
  } else {
    result$grade <- rep(NA_character_, n_rows)
  }

  # Subgroup
  subgroup_col <- find_col(c("^subgroup$", "^student_group$", "^demographic$",
                             "^disaggregation$", "^sheet_name$", "^source_sheet$"))
  if (!is.null(subgroup_col)) {
    result$subgroup <- standardize_assessment_subgroup(raw_data[[subgroup_col]])
  } else {
    result$subgroup <- rep("All Students", n_rows)
  }

  # Number tested
  n_tested_col <- find_col(c("^n_tested$", "^number_of_valid_scores$", "^valid_scores$",
                              "^n_valid$", "^num_tested$", "^count$"))
  if (!is.null(n_tested_col)) {
    result$n_tested <- safe_assessment_numeric(raw_data[[n_tested_col]])
  } else {
    result$n_tested <- rep(NA_integer_, n_rows)
  }

  # Mean scale score
  mean_col <- find_col(c("^mean_scale_score$", "^mean_ss$", "^avg_scale_score$", "^average_scale_score$"))
  if (!is.null(mean_col)) {
    result$mean_scale_score <- safe_assessment_numeric(raw_data[[mean_col]])
  } else {
    result$mean_scale_score <- rep(NA_real_, n_rows)
  }

  # Proficiency percentages - CMAS uses 4 or 5 levels depending on subject
  # Level 1: Did Not Yet Meet
  pct_l1_col <- find_col(c("^pct_did_not_meet$", "^percent_did_not_yet_meet",
                            "^pct_level_1$", "^level_1_pct$", "^did_not_meet_pct$"))
  if (!is.null(pct_l1_col)) {
    result$pct_did_not_meet <- safe_assessment_numeric(raw_data[[pct_l1_col]])
  } else {
    result$pct_did_not_meet <- rep(NA_real_, n_rows)
  }

  # Level 2: Partially Met
  pct_l2_col <- find_col(c("^pct_partially_met$", "^percent_partially_met",
                            "^pct_level_2$", "^level_2_pct$", "^partially_met_pct$"))
  if (!is.null(pct_l2_col)) {
    result$pct_partially_met <- safe_assessment_numeric(raw_data[[pct_l2_col]])
  } else {
    result$pct_partially_met <- rep(NA_real_, n_rows)
  }

  # Level 3: Approached (ELA/Math only, not Science/SS)
  pct_l3_col <- find_col(c("^pct_approached$", "^percent_approached",
                            "^pct_level_3$", "^level_3_pct$", "^approached_pct$"))
  if (!is.null(pct_l3_col)) {
    result$pct_approached <- safe_assessment_numeric(raw_data[[pct_l3_col]])
  } else {
    result$pct_approached <- rep(NA_real_, n_rows)
  }

  # Level 4: Met Expectations
  pct_l4_col <- find_col(c("^pct_met$", "^percent_met_expectations$", "^percent_met$",
                            "^pct_level_4$", "^level_4_pct$", "^met_pct$", "^met_expectations_pct$"))
  if (!is.null(pct_l4_col)) {
    result$pct_met <- safe_assessment_numeric(raw_data[[pct_l4_col]])
  } else {
    result$pct_met <- rep(NA_real_, n_rows)
  }

  # Level 5: Exceeded Expectations
  pct_l5_col <- find_col(c("^pct_exceeded$", "^percent_exceeded_expectations$", "^percent_exceeded$",
                            "^pct_level_5$", "^level_5_pct$", "^exceeded_pct$"))
  if (!is.null(pct_l5_col)) {
    result$pct_exceeded <- safe_assessment_numeric(raw_data[[pct_l5_col]])
  } else {
    result$pct_exceeded <- rep(NA_real_, n_rows)
  }

  # Calculate proficient (Met + Exceeded)
  if (!all(is.na(result$pct_met)) || !all(is.na(result$pct_exceeded))) {
    result$pct_proficient <- rowSums(
      cbind(
        ifelse(is.na(result$pct_met), 0, result$pct_met),
        ifelse(is.na(result$pct_exceeded), 0, result$pct_exceeded)
      ),
      na.rm = FALSE
    )
    # Set to NA if both components were NA
    result$pct_proficient <- ifelse(
      is.na(result$pct_met) & is.na(result$pct_exceeded),
      NA_real_,
      result$pct_proficient
    )
  } else {
    result$pct_proficient <- rep(NA_real_, n_rows)
  }

  # Add aggregation flags
  result <- id_assessment_aggs(result)

  result
}


#' Add aggregation flags to assessment data
#'
#' Identifies whether each row is state, district, or school level data.
#'
#' @param df Data frame with district_id and school_id columns
#' @return Data frame with is_state, is_district, is_school flags
#' @keywords internal
id_assessment_aggs <- function(df) {

  if (nrow(df) == 0) return(df)

  # Determine aggregation level based on IDs present
  df$is_state <- is.na(df$district_id) | df$district_id == ""
  df$is_district <- !df$is_state & (is.na(df$school_id) | df$school_id == "")
  df$is_school <- !df$is_state & !df$is_district

  # Add aggregation_flag column for compatibility
  df$aggregation_flag <- dplyr::case_when(
    df$is_state ~ "state",
    df$is_district ~ "district",
    df$is_school ~ "school",
    TRUE ~ "unknown"
  )

  df
}


#' Standardize subject names
#'
#' @param x Vector of subject names
#' @return Standardized subject names
#' @keywords internal
standardize_assessment_subject <- function(x) {
  x <- toupper(trimws(as.character(x)))

  # Standard CMAS subject mappings
  x <- gsub("^ELA$|^ENGLISH.*LANGUAGE.*ARTS$|^ENGLISH$|^READING$", "ELA", x)
  x <- gsub("^MATH$|^MATHEMATICS$|^MTH$", "Math", x)
  x <- gsub("^SCIENCE$|^SCI$|^SCNC$", "Science", x)
  x <- gsub("^SOCIAL.*STUDIES$|^SS$|^SOC.*STUD$", "Social Studies", x)
  x <- gsub("^CSLA$|^COLORADO.*SPANISH.*|^SPANISH.*LANGUAGE.*ARTS$", "CSLA", x)

  x
}


#' Standardize grade levels
#'
#' @param x Vector of grade values
#' @return Standardized grade levels
#' @keywords internal
standardize_assessment_grade <- function(x) {
  x <- toupper(trimws(as.character(x)))

  # Remove "GRADE" prefix
  x <- gsub("^GRADE\\s*", "", x)

  # Handle ordinal formats
  x <- gsub("^3RD$", "03", x)
  x <- gsub("^4TH$", "04", x)
  x <- gsub("^5TH$", "05", x)
  x <- gsub("^6TH$", "06", x)
  x <- gsub("^7TH$", "07", x)
  x <- gsub("^8TH$", "08", x)
  x <- gsub("^11TH$", "11", x)

  # Pad single digits
  x <- gsub("^([3-9])$", "0\\1", x)

  # Special values
  x <- gsub("^ALL.*GRADES$|^ALL$|^TOTAL$", "All", x)
  x <- gsub("^HS$|^HIGH.*SCHOOL$", "HS", x)

  x
}


#' Standardize subgroup names
#'
#' @param x Vector of subgroup names
#' @return Standardized subgroup names
#' @keywords internal
standardize_assessment_subgroup <- function(x) {
  x <- trimws(as.character(x))

  # Create mapping of common variations to standard names
  subgroup_map <- c(
    # All students
    "All Students" = "All Students",
    "ALL STUDENTS" = "All Students",
    "All" = "All Students",
    "ALL" = "All Students",
    "Total" = "All Students",
    "TOTAL" = "All Students",

    # Race/ethnicity
    "Black or African American" = "Black",
    "BLACK OR AFRICAN AMERICAN" = "Black",
    "Black/African American" = "Black",
    "African American" = "Black",
    "Black" = "Black",

    "White" = "White",
    "WHITE" = "White",

    "Hispanic or Latino" = "Hispanic",
    "HISPANIC OR LATINO" = "Hispanic",
    "Hispanic/Latino" = "Hispanic",
    "Hispanic" = "Hispanic",
    "Latino" = "Hispanic",

    "Asian" = "Asian",
    "ASIAN" = "Asian",

    "American Indian or Alaska Native" = "Native American",
    "AMERICAN INDIAN OR ALASKA NATIVE" = "Native American",
    "American Indian/Alaska Native" = "Native American",
    "Native American" = "Native American",

    "Native Hawaiian or Other Pacific Islander" = "Pacific Islander",
    "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER" = "Pacific Islander",
    "Native Hawaiian/Pacific Islander" = "Pacific Islander",
    "Pacific Islander" = "Pacific Islander",

    "Two or More Races" = "Multiracial",
    "TWO OR MORE RACES" = "Multiracial",
    "Multiracial" = "Multiracial",
    "Multi-Racial" = "Multiracial",

    # Gender
    "Female" = "Female",
    "FEMALE" = "Female",
    "Male" = "Male",
    "MALE" = "Male",

    # Special populations
    "Free/Reduced Lunch Eligible" = "Economically Disadvantaged",
    "FREE/REDUCED LUNCH ELIGIBLE" = "Economically Disadvantaged",
    "Free and Reduced Lunch" = "Economically Disadvantaged",
    "FRL" = "Economically Disadvantaged",
    "Economically Disadvantaged" = "Economically Disadvantaged",

    "Not Economically Disadvantaged" = "Non-Economically Disadvantaged",
    "Not Free/Reduced Lunch Eligible" = "Non-Economically Disadvantaged",

    "Students with Disabilities" = "Students with Disabilities",
    "STUDENTS WITH DISABILITIES" = "Students with Disabilities",
    "IEP" = "Students with Disabilities",
    "Special Education" = "Students with Disabilities",

    "Students without Disabilities" = "Non-SWD",
    "Not IEP" = "Non-SWD",

    "English Learners" = "English Learners",
    "ENGLISH LEARNERS" = "English Learners",
    "English Language Learners" = "English Learners",
    "ELL" = "English Learners",
    "EL" = "English Learners",
    "NEP/LEP" = "English Learners",

    "Not English Learners" = "Non-EL",
    "Non-English Learners" = "Non-EL",

    # Gifted
    "Gifted and Talented" = "Gifted",
    "GIFTED AND TALENTED" = "Gifted",
    "Gifted" = "Gifted",

    # Migrant
    "Migrant" = "Migrant",
    "MIGRANT" = "Migrant"
  )

  # Apply mapping
  result <- subgroup_map[x]

  # Keep original for unmatched values
  result[is.na(result)] <- x[is.na(result)]

  unname(result)
}


#' Safe numeric conversion for assessment data
#'
#' Converts to numeric, handling suppressed values and special characters.
#'
#' @param x Vector to convert
#' @return Numeric vector
#' @keywords internal
safe_assessment_numeric <- function(x) {
  x <- as.character(x)

  # Handle suppression markers
  x <- gsub("^\\*+$", NA_character_, x)  # Asterisks

  x <- gsub("^<\\d+$", NA_character_, x)  # Less than values
  x <- gsub("^>\\d+$", NA_character_, x)  # Greater than values
  x <- gsub("^--$", NA_character_, x)     # Double dash
  x <- gsub("^-$", NA_character_, x)      # Single dash (if not negative)
  x <- gsub("^N/?A$", NA_character_, x, ignore.case = TRUE)
  x <- gsub("^\\.$", NA_character_, x)    # Single dot

  # Remove commas and percent signs
  x <- gsub(",", "", x)
  x <- gsub("%", "", x)

  # Convert to numeric
  suppressWarnings(as.numeric(x))
}


#' Create empty assessment result data frame
#'
#' @param end_year School year end
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_assessment_result <- function(end_year) {
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
    pct_did_not_meet = numeric(0),
    pct_partially_met = numeric(0),
    pct_approached = numeric(0),
    pct_met = numeric(0),
    pct_exceeded = numeric(0),
    pct_proficient = numeric(0),
    is_state = logical(0),
    is_district = logical(0),
    is_school = logical(0),
    aggregation_flag = character(0),
    stringsAsFactors = FALSE
  )
}
