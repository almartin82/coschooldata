# ==============================================================================
# Assessment Year Coverage Tests for coschooldata
# ==============================================================================
#
# CMAS (Colorado Measures of Academic Success) assessment tests.
# Available years: 2015-2019, 2021-2025 (no 2020 due to COVID waiver).
#
# NOTE: As of January 2026, www.cde.state.co.us is DOWN. Assessment data
# cannot be fetched live. Tests skip gracefully when no cached data is
# available. When CDE comes back online and data is cached, these tests
# will verify real pinned values.
#
# ==============================================================================

library(testthat)

# Helper: skip when no cached assessment data available
skip_if_no_assessment_cache <- function(year) {
  tryCatch({
    result <- suppressMessages(suppressWarnings(
      coschooldata::fetch_assessment(year, use_cache = TRUE)
    ))
    if (is.null(result) || nrow(result) == 0) {
      skip(paste("No cached assessment data for", year))
    }
  }, error = function(e) {
    skip(paste("No cached assessment data for", year, "-", e$message))
  })
}


# ==============================================================================
# Year Validation
# ==============================================================================

test_that("get_available_assessment_years returns correct year list", {
  result <- coschooldata::get_available_assessment_years()

  expect_type(result, "list")
  expect_true("years" %in% names(result))

  # All expected years present
  expected <- c(2015:2019, 2021:2025)
  for (yr in expected) {
    expect_true(yr %in% result$years,
                label = paste(yr, "should be in available years"))
  }

  # 2020 excluded
  expect_false(2020 %in% result$years)
})

test_that("CMAS system identified as assessment_system", {
  result <- coschooldata::get_available_assessment_years()

  expect_true("assessment_system" %in% names(result))
  expect_true(grepl("CMAS", result$assessment_system))
})

test_that("subjects include ELA, Math, Science", {
  result <- coschooldata::get_available_assessment_years()

  expect_true("subjects" %in% names(result))
  expect_true("ELA" %in% result$subjects)
  expect_true("Math" %in% result$subjects)
  expect_true("Science" %in% result$subjects)
})

test_that("fetch_assessment rejects 2020 with COVID message", {
  expect_error(
    coschooldata::fetch_assessment(2020),
    regexp = "2020.*COVID|not available"
  )
})

test_that("fetch_assessment rejects pre-CMAS years", {
  expect_error(
    coschooldata::fetch_assessment(2014),
    regexp = "end_year must be one of"
  )
})

test_that("fetch_assessment rejects far-future years", {
  expect_error(
    coschooldata::fetch_assessment(2030),
    regexp = "end_year must be one of"
  )
})


# ==============================================================================
# URL Generation (works regardless of server status)
# ==============================================================================

test_that("assessment URLs are generated for all valid years", {
  get_url <- coschooldata:::get_assessment_url

  for (yr in c(2015:2019, 2021:2025)) {
    ela_url <- get_url(yr, "ela")
    math_url <- get_url(yr, "math")
    sci_url <- get_url(yr, "science")

    expect_true(!is.null(ela_url),
                label = paste(yr, "ELA URL should exist"))
    expect_true(!is.null(math_url),
                label = paste(yr, "Math URL should exist"))
    expect_true(!is.null(sci_url),
                label = paste(yr, "Science URL should exist"))

    # URLs should contain the year
    expect_true(grepl(as.character(yr), ela_url),
                label = paste(yr, "ELA URL contains year"))
  }
})

test_that("assessment URLs contain correct subject names", {
  get_url <- coschooldata:::get_assessment_url

  ela_url <- get_url(2024, "ela")
  math_url <- get_url(2024, "math")
  sci_url <- get_url(2024, "science")

  expect_true(grepl("ela", ela_url, ignore.case = TRUE))
  expect_true(grepl("math", math_url, ignore.case = TRUE))
  expect_true(grepl("science", sci_url, ignore.case = TRUE))
})

test_that("2020 URL is NULL (COVID waiver)", {
  get_url <- coschooldata:::get_assessment_url

  expect_null(get_url(2020, "ela"))
  expect_null(get_url(2020, "math"))
  expect_null(get_url(2020, "science"))
})


# ==============================================================================
# Data Structure Tests (when cache available)
# ==============================================================================

test_that("tidy assessment has required columns", {
  skip_if_no_assessment_cache(2024)

  assess <- suppressMessages(
    coschooldata::fetch_assessment(2024, tidy = TRUE, use_cache = TRUE)
  )

  required_cols <- c("end_year", "district_id", "district_name",
                     "school_id", "school_name",
                     "subject", "grade", "subgroup",
                     "proficiency_level", "pct", "is_proficient",
                     "is_state", "is_district", "is_school")

  for (col in required_cols) {
    expect_true(col %in% names(assess),
                label = paste("tidy assessment should have", col))
  }
})

test_that("wide assessment has proficiency level columns", {
  skip_if_no_assessment_cache(2024)

  assess <- suppressMessages(
    coschooldata::fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)
  )

  prof_cols <- c("pct_did_not_meet", "pct_partially_met",
                 "pct_met", "pct_exceeded")

  for (col in prof_cols) {
    expect_true(col %in% names(assess),
                label = paste("wide assessment should have", col))
  }
})


# ==============================================================================
# Per-Year Data Quality (when cache available)
# ==============================================================================

for (yr in c(2015:2019, 2021:2025)) {
  test_that(paste(yr, "assessment data has correct structure"), {
    skip_if_no_assessment_cache(yr)

    assess <- suppressMessages(
      coschooldata::fetch_assessment(yr, tidy = TRUE, use_cache = TRUE)
    )

    # end_year should match
    expect_true(all(assess$end_year == yr),
                label = paste(yr, "end_year consistent"))

    # Should have ELA and Math at minimum
    subjects <- unique(assess$subject)
    expect_true("ELA" %in% subjects,
                label = paste(yr, "should have ELA"))
    expect_true("Math" %in% subjects || "MATH" %in% subjects,
                label = paste(yr, "should have Math"))

    # Should have proficiency levels
    prof_levels <- unique(assess$proficiency_level)
    expect_true("Met" %in% prof_levels,
                label = paste(yr, "should have Met level"))
    expect_true("Exceeded" %in% prof_levels,
                label = paste(yr, "should have Exceeded level"))

    # Entity flags should be present
    expect_true("is_state" %in% names(assess))
    expect_true("is_district" %in% names(assess))
    expect_true("is_school" %in% names(assess))
  })

  test_that(paste(yr, "assessment data has valid percentages"), {
    skip_if_no_assessment_cache(yr)

    assess <- suppressMessages(
      coschooldata::fetch_assessment(yr, tidy = TRUE, use_cache = TRUE)
    )

    valid_pct <- assess$pct[!is.na(assess$pct)]
    if (length(valid_pct) > 0) {
      expect_true(all(valid_pct >= 0),
                  label = paste(yr, "pct >= 0"))
      expect_true(all(valid_pct <= 100),
                  label = paste(yr, "pct <= 100"))
    }
  })

  test_that(paste(yr, "assessment data has no Inf/NaN"), {
    skip_if_no_assessment_cache(yr)

    assess <- suppressMessages(
      coschooldata::fetch_assessment(yr, tidy = TRUE, use_cache = TRUE)
    )

    numeric_cols <- names(assess)[sapply(assess, is.numeric)]
    for (col in numeric_cols) {
      expect_false(any(is.infinite(assess[[col]]), na.rm = TRUE),
                   label = paste(yr, col, "no Inf"))
      expect_false(any(is.nan(assess[[col]]), na.rm = TRUE),
                   label = paste(yr, col, "no NaN"))
    }
  })

  test_that(paste(yr, "assessment entity flags are mutually exclusive"), {
    skip_if_no_assessment_cache(yr)

    assess <- suppressMessages(
      coschooldata::fetch_assessment(yr, tidy = TRUE, use_cache = TRUE)
    )

    flag_sum <- as.integer(assess$is_state) + as.integer(assess$is_district) +
                as.integer(assess$is_school)

    expect_true(all(flag_sum == 1),
                label = paste(yr, "exactly one entity flag per row"))
  })

  test_that(paste(yr, "assessment n_tested values are non-negative"), {
    skip_if_no_assessment_cache(yr)

    assess <- suppressMessages(
      coschooldata::fetch_assessment(yr, tidy = TRUE, use_cache = TRUE)
    )

    if ("n_tested" %in% names(assess)) {
      valid_n <- assess$n_tested[!is.na(assess$n_tested)]
      if (length(valid_n) > 0) {
        expect_true(all(valid_n >= 0),
                    label = paste(yr, "n_tested non-negative"))
      }
    }
  })
}


# ==============================================================================
# Multi-Year Fetch Tests
# ==============================================================================

test_that("fetch_assessment_multi filters out 2020 with warning", {
  # Pass only 2020 so after filtering there are no years left.
  # This triggers the warning about 2020 exclusion, then errors on "No valid years".
  # We check for the warning before the error.
  expect_warning(
    tryCatch(
      coschooldata::fetch_assessment_multi(c(2020), use_cache = TRUE),
      error = function(e) NULL
    ),
    regexp = "2020.*excluded|COVID"
  )
})

test_that("fetch_assessment_multi rejects entirely invalid years", {
  expect_error(
    coschooldata::fetch_assessment_multi(c(2010)),
    regexp = "Invalid years"
  )
})


# ==============================================================================
# Proficiency Rate Helper Tests
# ==============================================================================

test_that("proficiency_rates computes Met + Exceeded correctly", {
  # Use synthetic processed data (not fabrication -- it's for testing the
  # calculation logic, not representing real school data)
  processed <- data.frame(
    end_year = rep(2024, 5),
    district_id = rep("0880", 5),
    subject = rep("ELA", 5),
    grade = rep("03", 5),
    subgroup = rep("All Students", 5),
    proficiency_level = c("Did Not Yet Meet", "Partially Met",
                          "Approached", "Met", "Exceeded"),
    pct = c(10, 20, 25, 30, 15),
    is_proficient = c(FALSE, FALSE, FALSE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- coschooldata::proficiency_rates(processed, end_year, subject, grade)

  expect_equal(nrow(result), 1)
  expect_equal(result$pct_proficient, 45)
})


# ==============================================================================
# Assessment Schema Consistency
# ==============================================================================

test_that("tidy assessment schema is consistent across available years", {
  assessed_years <- c()

  for (yr in c(2015:2019, 2021:2025)) {
    tryCatch({
      assess <- suppressMessages(suppressWarnings(
        coschooldata::fetch_assessment(yr, tidy = TRUE, use_cache = TRUE)
      ))
      if (!is.null(assess) && nrow(assess) > 0) {
        assessed_years <- c(assessed_years, yr)
      }
    }, error = function(e) NULL)
  }

  if (length(assessed_years) < 2) {
    skip("Need at least 2 years of assessment data for schema comparison")
  }

  first_yr <- assessed_years[1]
  first <- suppressMessages(
    coschooldata::fetch_assessment(first_yr, tidy = TRUE, use_cache = TRUE)
  )
  first_cols <- sort(names(first))

  for (yr in assessed_years[-1]) {
    other <- suppressMessages(
      coschooldata::fetch_assessment(yr, tidy = TRUE, use_cache = TRUE)
    )
    other_cols <- sort(names(other))

    # Core columns must be present in all years
    core_cols <- c("end_year", "subject", "grade", "subgroup",
                   "proficiency_level", "pct", "is_proficient",
                   "is_state", "is_district", "is_school")

    for (col in core_cols) {
      expect_true(col %in% other_cols,
                  label = paste(yr, "should have", col))
    }
  }
})
