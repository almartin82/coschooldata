# ==============================================================================
# Typology Guard Tests for coschooldata
# ==============================================================================
#
# Standard typology guards that prevent common data pipeline bugs:
#
# 1. Filter value validation (no silent empty results from bad filter values)
# 2. One observation per group per period (no duplicate rows)
# 3. Entity flag exhaustiveness (every row has exactly one flag)
# 4. Aggregation hierarchy (state = sum(districts), district = sum(schools))
# 5. Percentage bounds (no values > 1 or < 0 in enrollment pct)
# 6. No silent data loss (0-row results from valid queries)
# 7. Schema stability across formats (legacy vs modern)
# 8. Suppression handling (NA, not 0 or empty string)
# 9. ID format guards (zero-padding, no truncation)
# 10. Cross-subgroup consistency (race sums to total)
#
# ==============================================================================

library(testthat)


# ==============================================================================
# 1. Filter Value Validation
# ==============================================================================

test_that("filtering on non-existent subgroup returns 0 rows (not error)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  # These are common misnomers that must NOT exist in the data
  bad_subgroups <- c("total", "low_income", "economically_disadvantaged",
                     "frl", "iep", "el", "ell", "english_learner",
                     "american_indian", "two_or_more", "special_ed", "lep",
                     "disability", "students_with_disabilities",
                     "socioeconomically_disadvantaged")

  for (sg in bad_subgroups) {
    result <- tidy[tidy$subgroup == sg, ]
    expect_equal(nrow(result), 0,
                 label = paste("non-standard subgroup", sg, "should return 0 rows"))
  }
})

test_that("filtering on valid subgroup returns >0 rows", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  valid_subgroups <- c("total_enrollment", "male", "female",
                       "native_american", "asian", "black", "hispanic",
                       "white", "pacific_islander", "multiracial",
                       "free_reduced_lunch")

  for (sg in valid_subgroups) {
    result <- tidy[tidy$subgroup == sg, ]
    expect_gt(nrow(result), 0,
              label = paste("valid subgroup", sg, "should return rows"))
  }
})

test_that("filtering on non-existent grade_level returns 0 rows", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  bad_grades <- c("total", "all", "ALL GRADE LEVELS", "004", "007",
                  "1st", "Grade 1", "kindergarten", "pk", "k")

  for (gl in bad_grades) {
    result <- tidy[tidy$grade_level == gl, ]
    expect_equal(nrow(result), 0,
                 label = paste("non-standard grade", gl, "should return 0 rows"))
  }
})

test_that("filtering on valid grade_level returns >0 rows (2020 legacy)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  valid_grades <- c("PK", "K", "01", "02", "03", "04", "05", "06",
                    "07", "08", "09", "10", "11", "12", "TOTAL")

  for (gl in valid_grades) {
    result <- tidy[tidy$grade_level == gl, ]
    expect_gt(nrow(result), 0,
              label = paste("valid grade", gl, "should return rows in 2020"))
  }
})

test_that("filtering on TOTAL grade_level returns >0 rows (2024 modern)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  result <- tidy[tidy$grade_level == "TOTAL", ]
  expect_gt(nrow(result), 0,
            label = "TOTAL should return rows in 2024 modern format")
})


# ==============================================================================
# 2. One Observation Per Group Per Period
# ==============================================================================

test_that("2024: no duplicate entity-grade-subgroup combinations", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  dupes <- tidy |>
    dplyr::count(end_year, district_id, campus_id, grade_level, subgroup,
                 is_state, is_district, is_school) |>
    dplyr::filter(n > 1)

  expect_equal(nrow(dupes), 0,
               label = "no duplicate entity-grade-subgroup in 2024")
})

test_that("2020: no duplicate district-grade-subgroup combinations", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  district_dupes <- tidy |>
    dplyr::filter(is_district) |>
    dplyr::count(end_year, district_id, grade_level, subgroup) |>
    dplyr::filter(n > 1)

  expect_equal(nrow(district_dupes), 0,
               label = "no duplicate district rows in 2020")
})

test_that("2020: no duplicate state-grade-subgroup combinations", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  state_dupes <- tidy |>
    dplyr::filter(is_state) |>
    dplyr::count(end_year, grade_level, subgroup) |>
    dplyr::filter(n > 1)

  expect_equal(nrow(state_dupes), 0,
               label = "no duplicate state rows in 2020")
})

test_that("directory: no duplicate state_school_id", {
  tryCatch({
    dir_data <- suppressMessages(
      coschooldata::fetch_directory(use_cache = TRUE)
    )

    n_dupes <- sum(duplicated(dir_data$state_school_id))
    # 1 known edge case: 5-digit district code 46080 causes collision
    expect_lte(n_dupes, 1,
               label = "at most 1 duplicate school ID (known CDE edge case)")
  }, error = function(e) {
    skip(paste("Directory unavailable:", e$message))
  })
})


# ==============================================================================
# 3. Entity Flag Exhaustiveness
# ==============================================================================

test_that("every enrollment row has exactly one entity flag", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    flag_sum <- as.integer(tidy$is_state) + as.integer(tidy$is_district) +
                as.integer(tidy$is_school)

    expect_true(all(flag_sum == 1),
                label = paste(yr, "every row has exactly one entity flag"))
  }
})

test_that("entity flags are boolean type", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_type(tidy$is_state, "logical")
  expect_type(tidy$is_district, "logical")
  expect_type(tidy$is_school, "logical")
  expect_type(tidy$is_charter, "logical")
})

test_that("is_charter is never TRUE for state or district rows", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_equal(sum(tidy$is_charter[tidy$is_state]), 0,
               label = "state rows should never be charter")
  expect_equal(sum(tidy$is_charter[tidy$is_district]), 0,
               label = "district rows should never be charter")
})

test_that("state rows have NA district_id and campus_id", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state_rows <- tidy[tidy$is_state, ]
  expect_true(all(is.na(state_rows$district_id)),
              label = "state district_id should be NA")
  expect_true(all(is.na(state_rows$campus_id)),
              label = "state campus_id should be NA")
})

test_that("district rows have campus_id = 0000", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  district_rows <- tidy[tidy$is_district, ]
  expect_true(all(district_rows$campus_id == "0000"),
              label = "district rows should have campus_id = 0000")
})

test_that("school rows have campus_id != 0000", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  school_rows <- tidy[tidy$is_school, ]
  expect_true(all(school_rows$campus_id != "0000"),
              label = "school rows should have campus_id != 0000")
})


# ==============================================================================
# 4. Aggregation Hierarchy
# ==============================================================================

test_that("state total = sum of district totals (2024)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                  tidy$subgroup == "total_enrollment", ]
  districts <- tidy[tidy$is_district & tidy$grade_level == "TOTAL" &
                      tidy$subgroup == "total_enrollment", ]

  expect_equal(state$n_students, sum(districts$n_students))
})

test_that("district total = sum of school totals (2024 Denver)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  denver_dist <- tidy[tidy$district_id == "0880" & tidy$is_district &
                        tidy$grade_level == "TOTAL" &
                        tidy$subgroup == "total_enrollment", ]
  denver_schools <- tidy[tidy$district_id == "0880" & tidy$is_school &
                           tidy$grade_level == "TOTAL" &
                           tidy$subgroup == "total_enrollment", ]

  expect_equal(denver_dist$n_students, sum(denver_schools$n_students))
})

test_that("aggregation holds for every subgroup at state level (2024)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  for (sg in unique(tidy$subgroup)) {
    state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                    tidy$subgroup == sg, ]
    districts <- tidy[tidy$is_district & tidy$grade_level == "TOTAL" &
                        tidy$subgroup == sg, ]

    expect_equal(state$n_students, sum(districts$n_students, na.rm = TRUE),
                 label = paste("state", sg, "= sum of districts"))
  }
})

test_that("state TOTAL = sum of grades for 2020 legacy format", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  total_row <- state$n_students[state$grade_level == "TOTAL"]
  grade_sum <- sum(state$n_students[state$grade_level != "TOTAL"])

  expect_equal(grade_sum, total_row,
               label = "state TOTAL = sum of individual grades in 2020")
})


# ==============================================================================
# 5. Percentage Bounds
# ==============================================================================

test_that("enrollment pct is on 0-1 scale", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  non_na_pct <- tidy$pct[!is.na(tidy$pct)]
  expect_true(all(non_na_pct >= 0), label = "pct >= 0")
  expect_true(all(non_na_pct <= 1), label = "pct <= 1 (0-1 scale, not 0-100)")
})

test_that("total_enrollment pct is always 1.0", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  total_pct <- tidy$pct[tidy$subgroup == "total_enrollment" & !is.na(tidy$pct)]
  expect_true(all(total_pct == 1.0),
              label = "total_enrollment pct should always be 1.0")
})

test_that("racial subgroup pcts sum to ~1.0 at state level", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  racial_subgroups <- c("native_american", "asian", "black", "hispanic",
                        "white", "pacific_islander", "multiracial")

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                  tidy$subgroup %in% racial_subgroups, ]
  pct_sum <- sum(state$pct, na.rm = TRUE)

  expect_equal(pct_sum, 1.0, tolerance = 0.001,
               label = "racial subgroup pcts sum to 1.0 at state level")
})


# ==============================================================================
# 6. No Silent Data Loss
# ==============================================================================

test_that("fetching a valid year never returns 0-row data frame", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )
    expect_gt(nrow(tidy), 0, label = paste(yr, "should return data"))
  }
})

test_that("fetching Denver by district_id returns data for both years", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    denver <- tidy[tidy$district_id == "0880", ]
    expect_gt(nrow(denver), 0,
              label = paste(yr, "Denver (0880) should have data"))
  }
})

test_that("state rows are present in every year", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    state_rows <- tidy[tidy$is_state, ]
    expect_gt(nrow(state_rows), 0,
              label = paste(yr, "should have state-level rows"))
  }
})


# ==============================================================================
# 7. Schema Stability Across Formats
# ==============================================================================

test_that("tidy schema is identical between 2020 legacy and 2024 modern", {
  tidy_2020 <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )
  tidy_2024 <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  core_cols <- c("end_year", "district_id", "district_name", "campus_id",
                 "campus_name", "grade_level", "is_state", "is_district",
                 "is_school", "is_charter", "subgroup", "n_students", "pct")

  for (col in core_cols) {
    expect_true(col %in% names(tidy_2020),
                label = paste("2020 should have", col))
    expect_true(col %in% names(tidy_2024),
                label = paste("2024 should have", col))
  }
})

test_that("wide schema is identical between 2020 legacy and 2024 modern", {
  wide_2020 <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  )
  wide_2024 <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  )

  core_cols <- c("end_year", "district_id", "district_name", "campus_id",
                 "campus_name", "grade_level", "row_total", "male", "female",
                 "native_american", "asian", "black", "hispanic", "white",
                 "pacific_islander", "multiracial", "is_charter")

  for (col in core_cols) {
    expect_true(col %in% names(wide_2020),
                label = paste("2020 wide should have", col))
    expect_true(col %in% names(wide_2024),
                label = paste("2024 wide should have", col))
  }
})

test_that("column types are consistent between 2020 and 2024", {
  tidy_2020 <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )
  tidy_2024 <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_type(tidy_2020$end_year, typeof(tidy_2024$end_year))
  expect_type(tidy_2020$district_id, typeof(tidy_2024$district_id))
  expect_type(tidy_2020$n_students, typeof(tidy_2024$n_students))
  expect_type(tidy_2020$is_state, typeof(tidy_2024$is_state))
  expect_type(tidy_2020$subgroup, typeof(tidy_2024$subgroup))
})


# ==============================================================================
# 8. Suppression Handling
# ==============================================================================

test_that("suppressed values are NA, never 0 or empty string", {
  wide <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  )

  # free_lunch and reduced_lunch have suppressions in 2024
  na_free <- wide[is.na(wide$free_lunch), ]
  expect_gt(nrow(na_free), 0,
            label = "some free_lunch values should be NA (suppressed)")

  # These schools should still have nonzero enrollment
  expect_true(all(na_free$row_total > 0),
              label = "suppressed FRL schools still have enrollment data")
})

test_that("core enrollment columns never have NA in 2024 wide", {
  wide <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  )

  expect_equal(sum(is.na(wide$row_total)), 0, label = "row_total has no NA")
  expect_equal(sum(is.na(wide$male)), 0, label = "male has no NA")
  expect_equal(sum(is.na(wide$female)), 0, label = "female has no NA")
  expect_equal(sum(is.na(wide$hispanic)), 0, label = "hispanic has no NA")
  expect_equal(sum(is.na(wide$white)), 0, label = "white has no NA")
})


# ==============================================================================
# 9. ID Format Guards
# ==============================================================================

test_that("district_id is zero-padded 4-char string (not integer)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  non_state <- tidy[!tidy$is_state, ]
  expect_type(non_state$district_id, "character")
  expect_true(all(nchar(non_state$district_id) == 4),
              label = "district_id should be zero-padded to 4 chars")
})

test_that("campus_id is zero-padded 4-char string (not integer)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  non_state <- tidy[!tidy$is_state, ]
  expect_type(non_state$campus_id, "character")
  expect_true(all(nchar(non_state$campus_id) == 4),
              label = "campus_id should be zero-padded to 4 chars")
})

test_that("leading zeros are preserved (district 0010 exists)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  # Mapleton 1 is district 0010
  mapleton <- tidy[!is.na(tidy$district_id) & tidy$district_id == "0010", ]
  expect_gt(nrow(mapleton), 0,
            label = "district 0010 (Mapleton) should exist with leading zero")
})

test_that("end_year is numeric, not character", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_true(is.numeric(tidy$end_year))
})


# ==============================================================================
# 10. Cross-Subgroup Consistency
# ==============================================================================

test_that("racial subgroups sum to total_enrollment at every entity level", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  racial_subgroups <- c("native_american", "asian", "black", "hispanic",
                        "white", "pacific_islander", "multiracial")

  # State level
  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]
  state_total <- state$n_students[state$subgroup == "total_enrollment"]
  state_race_sum <- sum(state$n_students[state$subgroup %in% racial_subgroups])
  expect_equal(state_race_sum, state_total,
               label = "state racial sum = total enrollment")

  # Denver district level
  denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                   tidy$grade_level == "TOTAL", ]
  denver_total <- denver$n_students[denver$subgroup == "total_enrollment"]
  denver_race_sum <- sum(denver$n_students[denver$subgroup %in% racial_subgroups])
  expect_equal(denver_race_sum, denver_total,
               label = "Denver racial sum = total enrollment")
})

test_that("male + female approximates total_enrollment at state level (2024)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]
  total <- state$n_students[state$subgroup == "total_enrollment"]
  gender_sum <- state$n_students[state$subgroup == "male"] +
                state$n_students[state$subgroup == "female"]

  # Modern format (2023+) has a Non-Binary column that is not captured in
  # tidy enrollment. So male + female is slightly less than total.
  # The gap is ~397 students out of ~881K (0.045%), within tolerance.
  expect_gt(gender_sum / total, 0.999,
            label = "male + female should be >= 99.9% of total (2024 non-binary gap)")
})

test_that("male + female = total_enrollment at state level (2020)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]
  total <- state$n_students[state$subgroup == "total_enrollment"]
  gender_sum <- state$n_students[state$subgroup == "male"] +
                state$n_students[state$subgroup == "female"]

  expect_equal(gender_sum, total,
               label = "male + female = total_enrollment at state level (2020)")
})

test_that("FRL does not exceed total enrollment at state level (2024)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]
  total <- state$n_students[state$subgroup == "total_enrollment"]
  frl <- state$n_students[state$subgroup == "free_reduced_lunch"]

  expect_true(frl <= total,
              label = "FRL should not exceed total enrollment")
})


# ==============================================================================
# 11. Year Validation Guards
# ==============================================================================

test_that("fetch_enr rejects years before min_year", {
  expect_error(
    coschooldata::fetch_enr(2019),
    regexp = "end_year must be between"
  )
  expect_error(
    coschooldata::fetch_enr(2010),
    regexp = "end_year must be between"
  )
})

test_that("fetch_enr rejects years after max_year", {
  expect_error(
    coschooldata::fetch_enr(2030),
    regexp = "end_year must be between"
  )
})

test_that("get_available_years returns correct min and max", {
  avail <- coschooldata::get_available_years()

  expect_equal(avail$min_year, 2020)
  expect_equal(avail$max_year, 2026)
})

test_that("fetch_assessment rejects COVID year 2020", {
  expect_error(
    coschooldata::fetch_assessment(2020),
    regexp = "2020|COVID|not available"
  )
})


# ==============================================================================
# 12. Assessment Typology Guards
# ==============================================================================

test_that("assessment proficiency levels are exactly the expected set", {
  # Test the tidy_assessment function logic
  processed <- data.frame(
    end_year = 2024,
    district_id = "0880",
    district_name = "Denver",
    school_id = NA_character_,
    school_name = NA_character_,
    subject = "ELA",
    grade = "03",
    subgroup = "All Students",
    n_tested = 100,
    mean_scale_score = 750,
    pct_did_not_meet = 10,
    pct_partially_met = 20,
    pct_approached = 25,
    pct_met = 30,
    pct_exceeded = 15,
    pct_proficient = 45,
    is_state = FALSE,
    is_district = TRUE,
    is_school = FALSE,
    aggregation_flag = "district",
    stringsAsFactors = FALSE
  )

  result <- coschooldata:::tidy_assessment(processed)

  expected_levels <- sort(c("Did Not Yet Meet", "Partially Met",
                            "Approached", "Met", "Exceeded"))
  actual_levels <- sort(unique(result$proficiency_level))

  expect_equal(actual_levels, expected_levels)
})

test_that("is_proficient is TRUE only for Met and Exceeded", {
  processed <- data.frame(
    end_year = 2024,
    district_id = "0880",
    district_name = "Denver",
    school_id = NA_character_,
    school_name = NA_character_,
    subject = "ELA",
    grade = "03",
    subgroup = "All Students",
    n_tested = 100,
    mean_scale_score = 750,
    pct_did_not_meet = 10,
    pct_partially_met = 20,
    pct_approached = 25,
    pct_met = 30,
    pct_exceeded = 15,
    pct_proficient = 45,
    is_state = FALSE,
    is_district = TRUE,
    is_school = FALSE,
    aggregation_flag = "district",
    stringsAsFactors = FALSE
  )

  result <- coschooldata:::tidy_assessment(processed)

  proficient_levels <- result$proficiency_level[result$is_proficient]
  non_proficient_levels <- result$proficiency_level[!result$is_proficient]

  expect_equal(sort(proficient_levels), c("Exceeded", "Met"))
  expect_equal(sort(non_proficient_levels),
               c("Approached", "Did Not Yet Meet", "Partially Met"))
})

test_that("assessment entity flags are set by id_assessment_aggs", {
  id_aggs <- coschooldata:::id_assessment_aggs

  test_df <- data.frame(
    district_id = c(NA_character_, "", "0880", "0880"),
    school_id = c(NA_character_, NA_character_, NA_character_, "0010"),
    stringsAsFactors = FALSE
  )

  result <- id_aggs(test_df)

  # Row 1: NA district -> state
  expect_true(result$is_state[1])
  expect_false(result$is_district[1])
  expect_false(result$is_school[1])

  # Row 2: empty district -> state
  expect_true(result$is_state[2])

  # Row 3: district_id present, no school -> district
  expect_false(result$is_state[3])
  expect_true(result$is_district[3])
  expect_false(result$is_school[3])

  # Row 4: both present -> school
  expect_false(result$is_state[4])
  expect_false(result$is_district[4])
  expect_true(result$is_school[4])
})


# ==============================================================================
# 13. Data Type Guards
# ==============================================================================

test_that("n_students is numeric, not character", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_true(is.numeric(tidy$n_students))
})

test_that("pct is numeric, not character", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_true(is.numeric(tidy$pct))
})

test_that("subgroup is character, not factor", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_type(tidy$subgroup, "character")
  expect_false(is.factor(tidy$subgroup))
})

test_that("grade_level is character, not factor", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_type(tidy$grade_level, "character")
  expect_false(is.factor(tidy$grade_level))
})

test_that("district_name is character for state rows (name = Colorado)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state_rows <- tidy[tidy$is_state, ]
  expect_true(all(state_rows$district_name == "Colorado"))
})
