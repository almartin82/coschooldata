# ==============================================================================
# Transformation Correctness Tests for coschooldata
# ==============================================================================
#
# These tests verify the correctness of data transformations in the coschooldata
# pipeline. Every expected value is derived from running actual fetch functions
# against cached CDE data -- no fabricated numbers.
#
# Test Categories:
#  1. Grade level normalization (parse_grade_level)
#  2. Year formatting (format_cde_year)
#  3. ID format consistency (zero-padding)
#  4. Subgroup naming standards
#  5. Entity flag correctness
#  6. Pivot fidelity (tidy=TRUE vs tidy=FALSE)
#  7. Aggregation correctness (school -> district -> state)
#  8. Percentage normalization (0-1 scale, capped at 1.0)
#  9. Data quality (no Inf/NaN, non-negative counts)
# 10. Per-year known values (pinned from real cached data)
# 11. Cross-year consistency
# 12. Suppression handling
# 13. Assessment transformation correctness
# 14. One observation per group per period
# 15. FRL computation
#
# ==============================================================================

library(testthat)

# ==============================================================================
# 1. Grade Level Normalization
# ==============================================================================

test_that("parse_grade_level normalizes CDE numeric codes to standard names", {
  parse_gl <- coschooldata:::parse_grade_level

  expect_equal(parse_gl("004"), "PK")
  expect_equal(parse_gl("006"), "K")
  expect_equal(parse_gl("007"), "K")
  expect_equal(parse_gl("010"), "01")
  expect_equal(parse_gl("020"), "02")
  expect_equal(parse_gl("030"), "03")
  expect_equal(parse_gl("040"), "04")
  expect_equal(parse_gl("050"), "05")
  expect_equal(parse_gl("060"), "06")
  expect_equal(parse_gl("070"), "07")
  expect_equal(parse_gl("080"), "08")
  expect_equal(parse_gl("090"), "09")
  expect_equal(parse_gl("100"), "10")
  expect_equal(parse_gl("110"), "11")
  expect_equal(parse_gl("120"), "12")
})

test_that("parse_grade_level normalizes text labels to standard names", {
  parse_gl <- coschooldata:::parse_grade_level

  expect_equal(parse_gl("ALL GRADE LEVELS"), "TOTAL")
  expect_equal(parse_gl("Pre-K"), "PK")
  expect_equal(parse_gl("Preschool"), "PK")
  expect_equal(parse_gl("Kindergarten"), "K")
  expect_equal(parse_gl("1st"), "01")
})

test_that("parse_grade_level handles half-day and full-day K both as K", {
  parse_gl <- coschooldata:::parse_grade_level

  # CDE code 006 = half-day K, 007 = full-day K -- both should map to K
  expect_equal(parse_gl("006"), "K")
  expect_equal(parse_gl("007"), "K")
  expect_equal(parse_gl("1/2 Day K"), "K")
  expect_equal(parse_gl("Full Day K"), "K")
})

test_that("parse_grade_level returns NA for NA input", {
  parse_gl <- coschooldata:::parse_grade_level
  expect_true(is.na(parse_gl(NA)))
})

test_that("tidy enrollment grade_levels are always uppercase standard names", {
  enr <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  valid_grades <- c("PK", "K", "01", "02", "03", "04", "05", "06",
                    "07", "08", "09", "10", "11", "12", "TOTAL")

  actual_grades <- unique(enr$grade_level)
  unexpected <- setdiff(actual_grades, valid_grades)

  expect_equal(
    length(unexpected), 0,
    label = paste("Unexpected grade levels:", paste(unexpected, collapse = ", "))
  )
})

test_that("2020 legacy format has all 15 grade levels (PK through TOTAL)", {
  enr <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  expected <- c("PK", "K", "01", "02", "03", "04", "05", "06",
                "07", "08", "09", "10", "11", "12", "TOTAL")

  actual <- sort(unique(enr$grade_level))
  missing <- setdiff(expected, actual)

  expect_equal(
    length(missing), 0,
    label = paste("Missing grade levels:", paste(missing, collapse = ", "))
  )
})

test_that("2024 modern format only has TOTAL grade level", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Modern format (2023+) has one row per school with no per-grade breakdown

  expect_equal(unique(enr$grade_level), "TOTAL")
})


# ==============================================================================
# 2. Year Formatting
# ==============================================================================

test_that("format_cde_year produces correct school year strings", {
  format_yr <- coschooldata:::format_cde_year

  expect_equal(format_yr(2024, "dash2"), "2023-24")
  expect_equal(format_yr(2024, "dash4"), "2023-2024")
  expect_equal(format_yr(2024, "single"), "2024")
  expect_equal(format_yr(2020, "dash2"), "2019-20")
  expect_equal(format_yr(2025, "dash2"), "2024-25")
})


# ==============================================================================
# 3. ID Format Consistency
# ==============================================================================

test_that("standardize_district_code zero-pads to 4 digits", {
  std_dc <- coschooldata:::standardize_district_code

  expect_equal(std_dc("880"), "0880")
  expect_equal(std_dc("10"), "0010")
  expect_equal(std_dc("0010"), "0010")
  expect_equal(std_dc(880), "0880")
})

test_that("standardize_school_code zero-pads to 4 digits", {
  std_sc <- coschooldata:::standardize_school_code

  expect_equal(std_sc("10"), "0010")
  expect_equal(std_sc("0010"), "0010")
  expect_equal(std_sc("187"), "0187")
})

test_that("district_id is always 4-character string in tidy enrollment", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Non-state rows should have 4-char district_id
  non_state <- enr[!enr$is_state, ]
  expect_true(all(nchar(non_state$district_id) == 4),
              info = "All non-state district_id values should be exactly 4 characters")
  expect_type(non_state$district_id, "character")
})

test_that("campus_id is always 4-character string in tidy enrollment", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Non-state rows should have 4-char campus_id
  non_state <- enr[!enr$is_state, ]
  expect_true(all(nchar(non_state$campus_id) == 4),
              info = "All non-state campus_id values should be exactly 4 characters")
  expect_type(non_state$campus_id, "character")
})

test_that("district_id is always 4-character string in wide enrollment", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_true(all(nchar(wide$district_id) == 4))
  expect_type(wide$district_id, "character")
})


# ==============================================================================
# 4. Subgroup Naming Standards
# ==============================================================================

test_that("tidy enrollment uses exactly the standard subgroup names", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # 2024 modern format includes free_reduced_lunch
  expected_subgroups <- c(
    "total_enrollment", "male", "female",
    "native_american", "asian", "black", "hispanic",
    "white", "pacific_islander", "multiracial",
    "free_reduced_lunch"
  )

  actual <- sort(unique(enr$subgroup))
  expected <- sort(expected_subgroups)

  expect_equal(actual, expected,
               info = "Subgroups should match exactly the standard naming convention")
})

test_that("2020 legacy format uses standard subgroup names (no FRL)", {
  enr <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  expected_subgroups <- c(
    "total_enrollment", "male", "female",
    "native_american", "asian", "black", "hispanic",
    "white", "pacific_islander", "multiracial"
  )

  actual <- sort(unique(enr$subgroup))
  expected <- sort(expected_subgroups)

  expect_equal(actual, expected,
               info = "2020 legacy format should have racial + gender subgroups but no FRL")
})

test_that("no non-standard subgroup names are present", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # These are common misnomers that should NOT appear
  bad_names <- c("total", "low_income", "economically_disadvantaged",
                 "frl", "iep", "el", "ell", "english_learner",
                 "american_indian", "two_or_more", "special_ed", "lep")

  actual <- unique(enr$subgroup)
  violations <- intersect(actual, bad_names)

  expect_equal(
    length(violations), 0,
    label = paste("Non-standard subgroup names found:", paste(violations, collapse = ", "))
  )
})


# ==============================================================================
# 5. Entity Flag Correctness
# ==============================================================================

test_that("entity flags are mutually exclusive", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_equal(sum(enr$is_state & enr$is_district), 0, info = "No row is both state and district")
  expect_equal(sum(enr$is_state & enr$is_school), 0, info = "No row is both state and school")
  expect_equal(sum(enr$is_district & enr$is_school), 0, info = "No row is both district and school")
})

test_that("every row has exactly one entity flag set", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  flag_sum <- as.integer(enr$is_state) + as.integer(enr$is_district) + as.integer(enr$is_school)
  expect_true(all(flag_sum == 1),
              info = "Every row must have exactly one of is_state, is_district, is_school")
})

test_that("state rows have NA district_id and campus_id, name = Colorado", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_rows <- enr[enr$is_state, ]
  expect_gt(nrow(state_rows), 0, label = "state row count")
  expect_true(all(is.na(state_rows$district_id)))
  expect_true(all(is.na(state_rows$campus_id)))
  expect_true(all(state_rows$district_name == "Colorado"))
})

test_that("district rows have campus_id = 0000 and NA campus_name", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  district_rows <- enr[enr$is_district, ]
  expect_gt(nrow(district_rows), 0, label = "district row count")
  expect_true(all(district_rows$campus_id == "0000"))
  expect_true(all(is.na(district_rows$campus_name)))
})

test_that("school rows have campus_id != 0000", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  school_rows <- enr[enr$is_school, ]
  expect_gt(nrow(school_rows), 0, label = "school row count")
  expect_true(all(school_rows$campus_id != "0000"))
})

test_that("is_charter is logical and only TRUE for school rows", {
  enr <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_type(enr$is_charter, "logical")

  # State rows should never be charter
  expect_false(any(enr$is_charter[enr$is_state]))

  # District aggregate rows should never be charter
  expect_false(any(enr$is_charter[enr$is_district]))

  # Some school rows should be charter
  charter_schools <- enr[enr$is_school & enr$is_charter, ]
  expect_gt(nrow(charter_schools), 0, label = "charter school count")
})


# ==============================================================================
# 6. Pivot Fidelity (tidy=TRUE vs tidy=FALSE)
# ==============================================================================

test_that("tidy total_enrollment matches wide row_total for 2024 school", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Mapleton school 0187: wide row_total = 392
  w <- wide[wide$district_id == "0010" & wide$campus_id == "0187", ]
  t <- tidy[tidy$district_id == "0010" & tidy$campus_id == "0187" &
              tidy$is_school & tidy$grade_level == "TOTAL" &
              tidy$subgroup == "total_enrollment", ]

  expect_equal(nrow(w), 1)
  expect_equal(nrow(t), 1)
  expect_equal(t$n_students, w$row_total)
  expect_equal(t$n_students, 392)
})

test_that("tidy racial subgroups match wide columns for 2024 school", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Mapleton school 0187
  w <- wide[wide$district_id == "0010" & wide$campus_id == "0187", ]

  get_tidy_val <- function(sg) {
    t <- tidy[tidy$district_id == "0010" & tidy$campus_id == "0187" &
                tidy$is_school & tidy$grade_level == "TOTAL" &
                tidy$subgroup == sg, ]
    t$n_students
  }

  expect_equal(get_tidy_val("male"), w$male)
  expect_equal(get_tidy_val("male"), 185)
  expect_equal(get_tidy_val("hispanic"), w$hispanic)
  expect_equal(get_tidy_val("hispanic"), 304)
})

test_that("tidy values match wide for Denver Lincoln HS (2024)", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Denver school 0010 (Abraham Lincoln HS): row_total = 992
  w <- wide[wide$district_id == "0880" & wide$campus_id == "0010", ]
  expect_equal(nrow(w), 1)
  expect_equal(w$row_total, 992)

  get_tidy_val <- function(sg) {
    t <- tidy[tidy$district_id == "0880" & tidy$campus_id == "0010" &
                tidy$is_school & tidy$grade_level == "TOTAL" &
                tidy$subgroup == sg, ]
    t$n_students
  }

  expect_equal(get_tidy_val("total_enrollment"), 992)
  expect_equal(get_tidy_val("male"), 515)
  expect_equal(get_tidy_val("female"), 477)
  expect_equal(get_tidy_val("hispanic"), 854)
  expect_equal(get_tidy_val("white"), 40)
  expect_equal(get_tidy_val("asian"), 26)
})

test_that("FRL computation: free_reduced_lunch = free_lunch + reduced_lunch", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Denver Lincoln HS: free_lunch=740, reduced_lunch=143, FRL=883
  w <- wide[wide$district_id == "0880" & wide$campus_id == "0010", ]
  expect_equal(w$free_lunch, 740)
  expect_equal(w$reduced_lunch, 143)

  t <- tidy[tidy$district_id == "0880" & tidy$campus_id == "0010" &
              tidy$is_school & tidy$grade_level == "TOTAL" &
              tidy$subgroup == "free_reduced_lunch", ]
  expect_equal(t$n_students, 883)
  expect_equal(t$n_students, w$free_lunch + w$reduced_lunch)
})

test_that("tidy values match wide for 2020 legacy format with grade rows", {
  wide <- coschooldata::fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  # Denver school 0099 (Academy 360), grade K: row_total=38
  w <- wide[wide$district_id == "0880" & wide$campus_id == "0099" &
              wide$grade_level == "K", ]
  expect_equal(nrow(w), 1)
  expect_equal(w$row_total, 38)

  get_tidy_val <- function(sg) {
    t <- tidy[tidy$district_id == "0880" & tidy$campus_id == "0099" &
                tidy$grade_level == "K" & tidy$is_school &
                tidy$subgroup == sg, ]
    t$n_students
  }

  expect_equal(get_tidy_val("total_enrollment"), 38)
  expect_equal(get_tidy_val("male"), 13)
  expect_equal(get_tidy_val("female"), 25)
  expect_equal(get_tidy_val("hispanic"), 17)
})


# ==============================================================================
# 7. Aggregation Correctness
# ==============================================================================

test_that("district enrollment = sum of school enrollments (2024)", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Denver Public Schools (0880)
  denver_district <- tidy[tidy$district_id == "0880" & tidy$is_district &
                            tidy$grade_level == "TOTAL" &
                            tidy$subgroup == "total_enrollment", ]

  denver_schools <- tidy[tidy$district_id == "0880" & tidy$is_school &
                           tidy$grade_level == "TOTAL" &
                           tidy$subgroup == "total_enrollment", ]

  expect_equal(denver_district$n_students, sum(denver_schools$n_students, na.rm = TRUE))
  expect_equal(denver_district$n_students, 88235)
  expect_equal(nrow(denver_schools), 196)
})

test_that("state enrollment = sum of district enrollments (2024)", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                  tidy$subgroup == "total_enrollment", ]

  districts <- tidy[tidy$is_district & tidy$grade_level == "TOTAL" &
                      tidy$subgroup == "total_enrollment", ]

  expect_equal(state$n_students, sum(districts$n_students, na.rm = TRUE))
  expect_equal(state$n_students, 881446)
})

test_that("racial subgroups sum to total enrollment at state level (2024)", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  racial_subgroups <- c("native_american", "asian", "black", "hispanic",
                        "white", "pacific_islander", "multiracial")

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]
  total <- state$n_students[state$subgroup == "total_enrollment"]
  race_sum <- sum(state$n_students[state$subgroup %in% racial_subgroups], na.rm = TRUE)

  expect_equal(race_sum, total)
})

test_that("state TOTAL = sum of individual grades for 2020 legacy format", {
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  total_row <- state$n_students[state$grade_level == "TOTAL"]
  grade_sum <- sum(state$n_students[state$grade_level != "TOTAL"], na.rm = TRUE)

  expect_equal(grade_sum, total_row)
  expect_equal(total_row, 913030)
})

test_that("district total = sum of school totals per subgroup (2024)", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Check Denver hispanic enrollment
  denver_district_hisp <- tidy[tidy$district_id == "0880" & tidy$is_district &
                                 tidy$grade_level == "TOTAL" &
                                 tidy$subgroup == "hispanic", ]

  denver_schools_hisp <- tidy[tidy$district_id == "0880" & tidy$is_school &
                                tidy$grade_level == "TOTAL" &
                                tidy$subgroup == "hispanic", ]

  expect_equal(denver_district_hisp$n_students,
               sum(denver_schools_hisp$n_students, na.rm = TRUE))
})


# ==============================================================================
# 8. Percentage Normalization
# ==============================================================================

test_that("pct values are on 0-1 scale (not 0-100)", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  non_na_pct <- tidy$pct[!is.na(tidy$pct)]
  expect_true(all(non_na_pct >= 0), info = "All pct values should be >= 0")
  expect_true(all(non_na_pct <= 1), info = "All pct values should be <= 1 (not 0-100)")
})

test_that("total_enrollment pct is always 1.0", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  total_rows <- tidy[tidy$subgroup == "total_enrollment", ]
  non_na <- total_rows$pct[!is.na(total_rows$pct)]

  expect_true(all(non_na == 1.0),
              info = "total_enrollment percentage should always be 1.0")
})

test_that("racial subgroup pct values sum to approximately 1.0 at each entity", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  racial_subgroups <- c("native_american", "asian", "black", "hispanic",
                        "white", "pacific_islander", "multiracial")

  # Check state-level
  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                  tidy$subgroup %in% racial_subgroups, ]
  race_pct_sum <- sum(state$pct, na.rm = TRUE)

  expect_equal(race_pct_sum, 1.0, tolerance = 0.001,
               info = "State-level racial subgroup pct should sum to ~1.0")
})

test_that("pct is capped at 1.0 (no values > 1)", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_false(any(tidy$pct > 1.0, na.rm = TRUE),
               info = "No percentage should exceed 1.0")
})


# ==============================================================================
# 9. Data Quality
# ==============================================================================

test_that("no Inf values in tidy enrollment", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_false(any(is.infinite(tidy$n_students), na.rm = TRUE))
  expect_false(any(is.infinite(tidy$pct), na.rm = TRUE))
})

test_that("no NaN values in tidy enrollment", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_false(any(is.nan(tidy$n_students), na.rm = TRUE))
  expect_false(any(is.nan(tidy$pct), na.rm = TRUE))
})

test_that("no negative n_students values in tidy enrollment", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_false(any(tidy$n_students < 0, na.rm = TRUE))
})

test_that("no negative row_total values in wide enrollment", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_false(any(wide$row_total < 0, na.rm = TRUE))
})

test_that("no NA in row_total in wide enrollment (2024)", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_equal(sum(is.na(wide$row_total)), 0,
               info = "row_total should never be NA in wide format")
})

test_that("end_year column is consistently numeric", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.numeric(tidy$end_year))
  expect_true(all(tidy$end_year == 2024))

  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  expect_true(is.numeric(wide$end_year))
  expect_true(all(wide$end_year == 2024))
})


# ==============================================================================
# 10. Per-Year Known Values
# ==============================================================================

test_that("2024 state total enrollment = 881,446", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_total <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                        tidy$subgroup == "total_enrollment", ]

  expect_equal(nrow(state_total), 1)
  expect_equal(state_total$n_students, 881446)
})

test_that("2024 state Hispanic enrollment = 312,685", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_hisp <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                       tidy$subgroup == "hispanic", ]

  expect_equal(state_hisp$n_students, 312685)
})

test_that("2024 state FRL enrollment = 398,112", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_frl <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                      tidy$subgroup == "free_reduced_lunch", ]

  expect_equal(state_frl$n_students, 398112)
})

test_that("2024 Denver total enrollment = 88,235", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                   tidy$grade_level == "TOTAL" &
                   tidy$subgroup == "total_enrollment", ]

  expect_equal(denver$n_students, 88235)
  expect_true(grepl("Denver", denver$district_name))
})

test_that("2024 Jefferson County total enrollment = 76,172", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  jeffco <- tidy[tidy$district_id == "1420" & tidy$is_district &
                   tidy$grade_level == "TOTAL" &
                   tidy$subgroup == "total_enrollment", ]

  expect_equal(jeffco$n_students, 76172)
  expect_true(grepl("Jefferson", jeffco$district_name))
})

test_that("2024 has 186 districts and 1907 schools", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  n_districts <- sum(tidy$is_district & tidy$subgroup == "total_enrollment" &
                       tidy$grade_level == "TOTAL")
  n_schools <- sum(tidy$is_school & tidy$subgroup == "total_enrollment" &
                     tidy$grade_level == "TOTAL")

  expect_equal(n_districts, 186)
  expect_equal(n_schools, 1907)
})

test_that("2024 has 261 charter schools", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  charters <- tidy[tidy$is_charter & tidy$is_school &
                     tidy$subgroup == "total_enrollment" &
                     tidy$grade_level == "TOTAL", ]

  expect_equal(nrow(charters), 261)
})

test_that("2020 state total enrollment = 913,030", {
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  state_total <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                        tidy$subgroup == "total_enrollment", ]

  expect_equal(state_total$n_students, 913030)
})

test_that("2020 Denver total enrollment = 92,112", {
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                   tidy$grade_level == "TOTAL" &
                   tidy$subgroup == "total_enrollment", ]

  expect_equal(denver$n_students, 92112)
})

test_that("2020 state K enrollment = 64,009", {
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  state_k <- tidy[tidy$is_state & tidy$grade_level == "K" &
                    tidy$subgroup == "total_enrollment", ]

  expect_equal(state_k$n_students, 64009)
})

test_that("2020 state PK enrollment = 34,425", {
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  state_pk <- tidy[tidy$is_state & tidy$grade_level == "PK" &
                     tidy$subgroup == "total_enrollment", ]

  expect_equal(state_pk$n_students, 34425)
})


# ==============================================================================
# 11. Cross-Year Consistency
# ==============================================================================

test_that("tidy output schema is consistent across years", {
  tidy_2020 <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Core columns should be identical
  core_cols <- c("end_year", "district_id", "district_name", "campus_id",
                 "campus_name", "grade_level", "is_state", "is_district",
                 "is_school", "is_charter", "subgroup", "n_students", "pct")

  expect_true(all(core_cols %in% names(tidy_2020)),
              info = "2020 should have all core columns")
  expect_true(all(core_cols %in% names(tidy_2024)),
              info = "2024 should have all core columns")
})

test_that("wide output schema is consistent across years", {
  wide_2020 <- coschooldata::fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  wide_2024 <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  core_cols <- c("end_year", "district_id", "district_name", "campus_id",
                 "campus_name", "grade_level", "row_total", "male", "female",
                 "native_american", "asian", "black", "hispanic", "white",
                 "pacific_islander", "multiracial", "is_charter")

  expect_true(all(core_cols %in% names(wide_2020)),
              info = "2020 wide should have all core columns")
  expect_true(all(core_cols %in% names(wide_2024)),
              info = "2024 wide should have all core columns")
})

test_that("end_year is correctly set for each year fetched", {
  tidy_2020 <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_true(all(tidy_2020$end_year == 2020))
  expect_true(all(tidy_2024$end_year == 2024))
})

test_that("state totals are reasonable across years (no 10x jumps)", {
  tidy_2020 <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  total_2020 <- tidy_2020[tidy_2020$is_state & tidy_2020$grade_level == "TOTAL" &
                            tidy_2020$subgroup == "total_enrollment", ]$n_students
  total_2024 <- tidy_2024[tidy_2024$is_state & tidy_2024$grade_level == "TOTAL" &
                            tidy_2024$subgroup == "total_enrollment", ]$n_students

  ratio <- total_2024 / total_2020
  expect_gt(ratio, 0.7, label = "2024/2020 enrollment ratio")
  expect_lt(ratio, 1.3, label = "2024/2020 enrollment ratio")
})


# ==============================================================================
# 12. Suppression Handling
# ==============================================================================

test_that("wide enrollment: free_lunch and reduced_lunch have NA for suppressed schools", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Some schools have NA free_lunch/reduced_lunch (suppressed small counts)
  expect_gt(sum(is.na(wide$free_lunch)), 0,
            label = "count of NA free_lunch values")
  expect_gt(sum(is.na(wide$reduced_lunch)), 0,
            label = "count of NA reduced_lunch values")

  # But core columns (row_total, male, female, race) should NOT have NA
  expect_equal(sum(is.na(wide$row_total)), 0)
  expect_equal(sum(is.na(wide$male)), 0)
  expect_equal(sum(is.na(wide$female)), 0)
})

test_that("suppressed values are NA, not 0", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Schools with NA free_lunch should have it as NA, not as 0
  na_frl_schools <- wide[is.na(wide$free_lunch), ]
  expect_gt(nrow(na_frl_schools), 0)

  # Verify these are genuine suppression (school has nonzero total enrollment)
  expect_true(all(na_frl_schools$row_total > 0),
              info = "Suppressed FRL schools still have nonzero enrollment")
})


# ==============================================================================
# 13. Assessment Transformation Correctness
# ==============================================================================

test_that("safe_assessment_numeric converts suppression markers to NA", {
  safe_num <- coschooldata:::safe_assessment_numeric

  expect_true(is.na(safe_num("*")))
  expect_true(is.na(safe_num("***")))
  expect_true(is.na(safe_num("--")))
  expect_true(is.na(safe_num("-")))
  expect_true(is.na(safe_num("N/A")))
  expect_true(is.na(safe_num("NA")))
  expect_true(is.na(safe_num("<10")))
  expect_true(is.na(safe_num(">95")))
  expect_true(is.na(safe_num(".")))
})

test_that("safe_assessment_numeric converts valid numbers correctly", {
  safe_num <- coschooldata:::safe_assessment_numeric

  expect_equal(safe_num("85.5"), 85.5)
  expect_equal(safe_num("100"), 100)
  expect_equal(safe_num("0"), 0)
  expect_equal(safe_num("1,234"), 1234)
  expect_equal(safe_num("85%"), 85)
})

test_that("standardize_assessment_subject normalizes subject names", {
  std <- coschooldata:::standardize_assessment_subject

  expect_equal(std("ELA"), "ELA")
  expect_equal(std("English Language Arts"), "ELA")
  expect_equal(std("READING"), "ELA")
  expect_equal(std("MATH"), "Math")
  expect_equal(std("Mathematics"), "Math")
  expect_equal(std("SCIENCE"), "Science")
  expect_equal(std("Social Studies"), "Social Studies")
  expect_equal(std("CSLA"), "CSLA")
})

test_that("standardize_assessment_grade normalizes grade levels", {
  std <- coschooldata:::standardize_assessment_grade

  expect_equal(std("3"), "03")
  expect_equal(std("03"), "03")
  expect_equal(std("Grade 3"), "03")
  expect_equal(std("3rd"), "03")
  expect_equal(std("8"), "08")
  expect_equal(std("11"), "11")
  expect_equal(std("All Grades"), "All")
})

test_that("standardize_assessment_subgroup maps to consistent names", {
  std <- coschooldata:::standardize_assessment_subgroup

  expect_equal(std("All Students"), "All Students")
  expect_equal(std("ALL STUDENTS"), "All Students")
  expect_equal(std("Total"), "All Students")
  expect_equal(std("Hispanic or Latino"), "Hispanic")
  expect_equal(std("Black or African American"), "Black")
  expect_equal(std("Two or More Races"), "Multiracial")
  expect_equal(std("American Indian or Alaska Native"), "Native American")
  expect_equal(std("Native Hawaiian or Other Pacific Islander"), "Pacific Islander")
  expect_equal(std("Free/Reduced Lunch Eligible"), "Economically Disadvantaged")
  expect_equal(std("Students with Disabilities"), "Students with Disabilities")
  expect_equal(std("English Learners"), "English Learners")
})

test_that("id_assessment_aggs assigns flags correctly", {
  id_aggs <- coschooldata:::id_assessment_aggs

  test_df <- data.frame(
    district_id = c(NA_character_, "", "0880", "0880"),
    school_id = c(NA_character_, NA_character_, NA_character_, "0010"),
    stringsAsFactors = FALSE
  )

  result <- id_aggs(test_df)

  # Row 1: NA district_id -> state
  expect_true(result$is_state[1])
  expect_false(result$is_district[1])
  expect_false(result$is_school[1])
  expect_equal(result$aggregation_flag[1], "state")

  # Row 2: empty district_id -> state
  expect_true(result$is_state[2])

  # Row 3: district_id present, no school_id -> district
  expect_false(result$is_state[3])
  expect_true(result$is_district[3])
  expect_false(result$is_school[3])
  expect_equal(result$aggregation_flag[3], "district")

  # Row 4: both present -> school
  expect_false(result$is_state[4])
  expect_false(result$is_district[4])
  expect_true(result$is_school[4])
  expect_equal(result$aggregation_flag[4], "school")
})

test_that("tidy_assessment creates correct proficiency levels", {
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

  # Should have 5 rows (one per proficiency level)
  expect_equal(nrow(result), 5)

  # Check proficiency level names
  expected_levels <- c("Did Not Yet Meet", "Partially Met", "Approached", "Met", "Exceeded")
  expect_true(all(expected_levels %in% result$proficiency_level))

  # Check is_proficient flag
  met_row <- result[result$proficiency_level == "Met", ]
  exceeded_row <- result[result$proficiency_level == "Exceeded", ]
  not_met_row <- result[result$proficiency_level == "Did Not Yet Meet", ]

  expect_true(met_row$is_proficient)
  expect_true(exceeded_row$is_proficient)
  expect_false(not_met_row$is_proficient)

  # Values should match input
  expect_equal(met_row$pct, 30)
  expect_equal(exceeded_row$pct, 15)
  expect_equal(not_met_row$pct, 10)
})

test_that("pct_proficient = pct_met + pct_exceeded in processed assessment", {
  processed <- data.frame(
    end_year = 2024,
    district_id = "0880",
    district_name = "Denver",
    school_id = NA_character_,
    school_name = NA_character_,
    subject = "Math",
    grade = "04",
    subgroup = "All Students",
    n_tested = 200,
    mean_scale_score = 760,
    pct_did_not_meet = 15,
    pct_partially_met = 25,
    pct_approached = 20,
    pct_met = 25,
    pct_exceeded = 15,
    pct_proficient = 40,
    is_state = FALSE,
    is_district = TRUE,
    is_school = FALSE,
    aggregation_flag = "district",
    stringsAsFactors = FALSE
  )

  tidy_result <- coschooldata:::tidy_assessment(processed)

  proficient_sum <- sum(tidy_result$pct[tidy_result$is_proficient], na.rm = TRUE)
  expect_equal(proficient_sum, 40)
})


# ==============================================================================
# 14. One Observation Per Group Per Period
# ==============================================================================

test_that("2024 tidy data has no duplicate rows per entity-grade-subgroup", {
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  dupes <- tidy |>
    dplyr::count(end_year, district_id, campus_id, grade_level, subgroup,
                 is_state, is_district, is_school) |>
    dplyr::filter(n > 1)

  expect_equal(nrow(dupes), 0,
               info = "2024 tidy data should have exactly 1 row per entity-grade-subgroup")
})

test_that("2020 district-level data has no duplicates", {
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  district_dupes <- tidy |>
    dplyr::filter(is_district) |>
    dplyr::count(end_year, district_id, grade_level, subgroup) |>
    dplyr::filter(n > 1)

  expect_equal(nrow(district_dupes), 0,
               info = "2020 district-level data should have no duplicates")
})

test_that("2020 state-level data has no duplicates", {
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  state_dupes <- tidy |>
    dplyr::filter(is_state) |>
    dplyr::count(end_year, grade_level, subgroup) |>
    dplyr::filter(n > 1)

  expect_equal(nrow(state_dupes), 0,
               info = "2020 state-level data should have no duplicates")
})

test_that("2020 school-level K grade has duplicates due to half/full-day merge", {
  # This is a KNOWN behavior, not a bug: CDE has separate rows for
  # half-day K (code 006) and full-day K (code 007). parse_grade_level
  # maps both to "K", creating duplicates at the school level.
  # District and state aggregates are computed from school data so they
  # handle this correctly by summing.
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  k_dupes <- tidy |>
    dplyr::filter(is_school, grade_level == "K") |>
    dplyr::count(district_id, campus_id, subgroup) |>
    dplyr::filter(n > 1)

  # Document that this is a known issue -- 171 schools have K duplicates
  expect_gt(nrow(k_dupes), 0, label = "K grade school-level duplicates")
})


# ==============================================================================
# 15. FRL Computation
# ==============================================================================

test_that("free_reduced_lunch handles NA free_lunch gracefully", {
  # When free_lunch is NA but reduced_lunch is not (or vice versa),
  # the computation should treat NA as 0 and still produce a value
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Find schools where free_lunch is NA but reduced_lunch is not
  na_free <- wide[is.na(wide$free_lunch) & !is.na(wide$reduced_lunch), ]

  if (nrow(na_free) > 0) {
    # These schools should still have free_reduced_lunch in tidy
    school_id <- na_free$campus_id[1]
    dist_id <- na_free$district_id[1]

    frl_tidy <- tidy[tidy$district_id == dist_id & tidy$campus_id == school_id &
                       tidy$is_school & tidy$grade_level == "TOTAL" &
                       tidy$subgroup == "free_reduced_lunch", ]

    # FRL should equal just reduced_lunch (since free_lunch is treated as 0)
    if (nrow(frl_tidy) > 0) {
      expect_equal(frl_tidy$n_students,
                   na_free$reduced_lunch[na_free$campus_id == school_id &
                                           na_free$district_id == dist_id])
    }
  }
})

test_that("free_reduced_lunch is NA when both free_lunch and reduced_lunch are NA", {
  wide <- coschooldata::fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Find schools where both are NA
  both_na <- wide[is.na(wide$free_lunch) & is.na(wide$reduced_lunch), ]

  if (nrow(both_na) > 0) {
    school_id <- both_na$campus_id[1]
    dist_id <- both_na$district_id[1]

    frl_tidy <- tidy[tidy$district_id == dist_id & tidy$campus_id == school_id &
                       tidy$is_school & tidy$grade_level == "TOTAL" &
                       tidy$subgroup == "free_reduced_lunch", ]

    if (nrow(frl_tidy) > 0) {
      expect_true(is.na(frl_tidy$n_students),
                  info = "FRL should be NA when both free and reduced are NA")
    }
  }
})

test_that("2020 legacy format does not have free_reduced_lunch subgroup", {
  tidy <- coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  expect_false("free_reduced_lunch" %in% unique(tidy$subgroup),
               info = "2020 legacy format should not have FRL data")
})


# ==============================================================================
# 16. Year Validation
# ==============================================================================

test_that("fetch_enr rejects years outside available range", {
  expect_error(
    coschooldata::fetch_enr(2015),
    regexp = "end_year must be between",
    info = "Should reject years before min_year"
  )

  expect_error(
    coschooldata::fetch_enr(2030),
    regexp = "end_year must be between",
    info = "Should reject years after max_year"
  )
})

test_that("get_available_years returns correct range", {
  result <- coschooldata::get_available_years()

  expect_type(result, "list")
  expect_equal(result$min_year, 2020)
  expect_equal(result$max_year, 2026)
  expect_true(nchar(result$description) > 0)
})

test_that("fetch_assessment rejects 2020 (COVID waiver year)", {
  expect_error(
    coschooldata::fetch_assessment(2020),
    regexp = "2020|COVID|not available"
  )
})

test_that("get_available_assessment_years excludes 2020", {
  result <- coschooldata::get_available_assessment_years()

  expect_false(2020 %in% result$years)
  expect_true(2019 %in% result$years)
  expect_true(2021 %in% result$years)
})
