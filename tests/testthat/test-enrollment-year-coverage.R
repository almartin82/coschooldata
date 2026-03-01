# ==============================================================================
# Enrollment Year Coverage Tests for coschooldata
# ==============================================================================
#
# Per-year tests through ALL available years (2020-2025) with pinned state
# totals, Denver/Jefferson County enrollment, subgroup/grade completeness,
# and entity flag verification.
#
# Every pinned value below was read from actual cached CDE data.
# No fabricated numbers.
#
# Years with cached data: 2020, 2021, 2024
# Years without cached data (CDE server down): 2022, 2023, 2025
#   -- those years skip gracefully when cache is absent
#
# ==============================================================================

library(testthat)

# Helper to skip when cached data unavailable
skip_if_no_cache <- function(year) {

  tryCatch({
    suppressMessages(coschooldata::fetch_enr(year, tidy = TRUE, use_cache = TRUE))
  }, error = function(e) {
    skip(paste("No cached enrollment data for", year))
  })
}


# ==============================================================================
# 2020: Legacy format (per-grade rows)
# ==============================================================================

test_that("2020 state total enrollment = 913,030", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                  tidy$subgroup == "total_enrollment", ]

  expect_equal(nrow(state), 1)
  expect_equal(state$n_students, 913030)
})

test_that("2020 state racial subgroups are correct", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]

  expect_equal(state$n_students[state$subgroup == "white"], 482951)
  expect_equal(state$n_students[state$subgroup == "hispanic"], 309900)
  expect_equal(state$n_students[state$subgroup == "black"], 41550)
  expect_equal(state$n_students[state$subgroup == "asian"], 29207)
  expect_equal(state$n_students[state$subgroup == "multiracial"], 40785)
  expect_equal(state$n_students[state$subgroup == "native_american"], 6204)
  expect_equal(state$n_students[state$subgroup == "pacific_islander"], 2433)
})

test_that("2020 state gender totals are correct", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]

  expect_equal(state$n_students[state$subgroup == "male"], 469194)
  expect_equal(state$n_students[state$subgroup == "female"], 443836)
})

test_that("2020 Denver total enrollment = 92,112", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                   tidy$grade_level == "TOTAL" &
                   tidy$subgroup == "total_enrollment", ]

  expect_equal(nrow(denver), 1)
  expect_equal(denver$n_students, 92112)
})

test_that("2020 Denver racial subgroups are correct", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                   tidy$grade_level == "TOTAL", ]

  expect_equal(denver$n_students[denver$subgroup == "hispanic"], 48997)
  expect_equal(denver$n_students[denver$subgroup == "white"], 23507)
  expect_equal(denver$n_students[denver$subgroup == "black"], 12060)
  expect_equal(denver$n_students[denver$subgroup == "asian"], 2926)
})

test_that("2020 Jefferson County total enrollment = 84,032", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  jeffco <- tidy[tidy$district_id == "1420" & tidy$is_district &
                   tidy$grade_level == "TOTAL" &
                   tidy$subgroup == "total_enrollment", ]

  expect_equal(nrow(jeffco), 1)
  expect_equal(jeffco$n_students, 84032)
  expect_true(grepl("Jefferson", jeffco$district_name))
})

test_that("2020 has 186 districts and 1907 schools", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  n_districts <- length(unique(tidy$district_id[tidy$is_district]))
  n_schools <- nrow(unique(
    tidy[tidy$is_school & tidy$subgroup == "total_enrollment",
         c("district_id", "campus_id")]
  ))

  expect_equal(n_districts, 186)
  expect_equal(n_schools, 1907)
})

test_that("2020 has all 15 grade levels (PK through TOTAL)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  expected_grades <- c("PK", "K", "01", "02", "03", "04", "05", "06",
                        "07", "08", "09", "10", "11", "12", "TOTAL")

  actual_grades <- sort(unique(tidy$grade_level))
  missing <- setdiff(expected_grades, actual_grades)

  expect_equal(length(missing), 0,
               label = paste("Missing grade levels:", paste(missing, collapse = ", ")))
})

test_that("2020 has 10 subgroups (no FRL in legacy format)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  expected_subgroups <- sort(c(
    "total_enrollment", "male", "female",
    "native_american", "asian", "black", "hispanic",
    "white", "pacific_islander", "multiracial"
  ))

  actual_subgroups <- sort(unique(tidy$subgroup))
  expect_equal(actual_subgroups, expected_subgroups)
})

test_that("2020 state TOTAL equals sum of individual grades", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  total_row <- state$n_students[state$grade_level == "TOTAL"]
  grade_sum <- sum(state$n_students[state$grade_level != "TOTAL"])

  expect_equal(grade_sum, total_row)
})

test_that("2020 state PK = 34,425 and K = 64,009", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]

  expect_equal(state$n_students[state$grade_level == "PK"], 34425)
  expect_equal(state$n_students[state$grade_level == "K"], 64009)
})


# ==============================================================================
# 2021: Legacy format (per-grade rows, no TOTAL grade)
# ==============================================================================

test_that("2021 state total enrollment (sum of grades) = 883,134", {
  skip_if_no_cache(2021)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  total <- sum(state$n_students)

  expect_equal(total, 883134)
})

test_that("2021 state racial subgroups are correct (summed across grades)", {
  skip_if_no_cache(2021)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state, ]
  by_sg <- aggregate(n_students ~ subgroup, data = state, FUN = sum)

  expect_equal(by_sg$n_students[by_sg$subgroup == "white"], 463256)
  expect_equal(by_sg$n_students[by_sg$subgroup == "hispanic"], 301832)
  expect_equal(by_sg$n_students[by_sg$subgroup == "black"], 40419)
  expect_equal(by_sg$n_students[by_sg$subgroup == "asian"], 28424)
  expect_equal(by_sg$n_students[by_sg$subgroup == "multiracial"], 40904)
  expect_equal(by_sg$n_students[by_sg$subgroup == "native_american"], 5846)
  expect_equal(by_sg$n_students[by_sg$subgroup == "pacific_islander"], 2453)
})

test_that("2021 Denver total enrollment (sum of grades) = 89,061", {
  skip_if_no_cache(2021)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  )

  denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                   tidy$subgroup == "total_enrollment", ]
  total <- sum(denver$n_students)

  expect_equal(total, 89061)
})

test_that("2021 Jefferson County total enrollment (sum of grades) = 80,077", {
  skip_if_no_cache(2021)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  )

  jeffco <- tidy[tidy$district_id == "1420" & tidy$is_district &
                   tidy$subgroup == "total_enrollment", ]
  total <- sum(jeffco$n_students)

  expect_equal(total, 80077)
})

test_that("2021 has 186 distinct districts and 1915 distinct schools", {
  skip_if_no_cache(2021)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  )

  n_districts <- length(unique(tidy$district_id[tidy$is_district]))
  n_schools <- nrow(unique(
    tidy[tidy$is_school & tidy$subgroup == "total_enrollment",
         c("district_id", "campus_id")]
  ))

  expect_equal(n_districts, 186)
  expect_equal(n_schools, 1915)
})

test_that("2021 has 14 grade levels (PK through 12, no TOTAL)", {
  skip_if_no_cache(2021)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  )

  expected_grades <- c("PK", "K", "01", "02", "03", "04", "05", "06",
                        "07", "08", "09", "10", "11", "12")

  actual_grades <- sort(unique(tidy$grade_level))
  missing <- setdiff(expected_grades, actual_grades)

  expect_equal(length(missing), 0,
               label = paste("Missing grade levels:", paste(missing, collapse = ", ")))
})

test_that("2021 has 10 subgroups (no FRL in legacy format)", {
  skip_if_no_cache(2021)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  )

  expected_subgroups <- sort(c(
    "total_enrollment", "male", "female",
    "native_american", "asian", "black", "hispanic",
    "white", "pacific_islander", "multiracial"
  ))

  actual_subgroups <- sort(unique(tidy$subgroup))
  expect_equal(actual_subgroups, expected_subgroups)
})

test_that("2021 racial subgroups sum to total at state level (per grade)", {
  skip_if_no_cache(2021)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  )

  racial_subgroups <- c("native_american", "asian", "black", "hispanic",
                        "white", "pacific_islander", "multiracial")

  for (gl in unique(tidy$grade_level[tidy$is_state])) {
    state_gl <- tidy[tidy$is_state & tidy$grade_level == gl, ]
    total <- state_gl$n_students[state_gl$subgroup == "total_enrollment"]
    race_sum <- sum(state_gl$n_students[state_gl$subgroup %in% racial_subgroups])

    expect_equal(race_sum, total,
                 label = paste("2021 grade", gl, "racial sum vs total"))
  }
})


# ==============================================================================
# 2022: CDE server down -- skip gracefully
# ==============================================================================

test_that("2022 enrollment data loads from cache or skips", {
  skip_if_no_cache(2022)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)
  )

  expect_s3_class(tidy, "data.frame")
  expect_gt(nrow(tidy), 0)

  # State total should be in ~870K-920K range (reasonable for CO)
  state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  total <- sum(state$n_students)
  expect_gt(total, 870000)
  expect_lt(total, 920000)
})


# ==============================================================================
# 2023: CDE server down -- skip gracefully
# ==============================================================================

test_that("2023 enrollment data loads from cache or skips", {
  skip_if_no_cache(2023)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  )

  expect_s3_class(tidy, "data.frame")
  expect_gt(nrow(tidy), 0)

  # State total should be in ~870K-920K range
  state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  total <- sum(state$n_students)
  expect_gt(total, 870000)
  expect_lt(total, 920000)
})


# ==============================================================================
# 2024: Modern format (one row per school, TOTAL grade only)
# ==============================================================================

test_that("2024 state total enrollment = 881,446", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                  tidy$subgroup == "total_enrollment", ]

  expect_equal(nrow(state), 1)
  expect_equal(state$n_students, 881446)
})

test_that("2024 state racial subgroups are correct", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]

  expect_equal(state$n_students[state$subgroup == "white"], 444973)
  expect_equal(state$n_students[state$subgroup == "hispanic"], 312685)
  expect_equal(state$n_students[state$subgroup == "black"], 40070)
  expect_equal(state$n_students[state$subgroup == "asian"], 28899)
  expect_equal(state$n_students[state$subgroup == "multiracial"], 46570)
  expect_equal(state$n_students[state$subgroup == "native_american"], 5348)
  expect_equal(state$n_students[state$subgroup == "pacific_islander"], 2901)
})

test_that("2024 state gender totals are correct", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]

  expect_equal(state$n_students[state$subgroup == "male"], 452215)
  expect_equal(state$n_students[state$subgroup == "female"], 428834)
})

test_that("2024 state FRL = 398,112", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  state_frl <- tidy[tidy$is_state & tidy$grade_level == "TOTAL" &
                      tidy$subgroup == "free_reduced_lunch", ]

  expect_equal(nrow(state_frl), 1)
  expect_equal(state_frl$n_students, 398112)
})

test_that("2024 Denver total enrollment = 88,235", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                   tidy$grade_level == "TOTAL" &
                   tidy$subgroup == "total_enrollment", ]

  expect_equal(nrow(denver), 1)
  expect_equal(denver$n_students, 88235)
  expect_true(grepl("Denver", denver$district_name))
})

test_that("2024 Denver racial subgroups are correct", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                   tidy$grade_level == "TOTAL", ]

  expect_equal(denver$n_students[denver$subgroup == "hispanic"], 45726)
  expect_equal(denver$n_students[denver$subgroup == "white"], 22398)
  expect_equal(denver$n_students[denver$subgroup == "black"], 11617)
  expect_equal(denver$n_students[denver$subgroup == "asian"], 2735)
  expect_equal(denver$n_students[denver$subgroup == "multiracial"], 4544)
  expect_equal(denver$n_students[denver$subgroup == "native_american"], 477)
  expect_equal(denver$n_students[denver$subgroup == "pacific_islander"], 738)
})

test_that("2024 Denver FRL = 55,535", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  denver_frl <- tidy[tidy$district_id == "0880" & tidy$is_district &
                       tidy$grade_level == "TOTAL" &
                       tidy$subgroup == "free_reduced_lunch", ]

  expect_equal(denver_frl$n_students, 55535)
})

test_that("2024 Jefferson County total enrollment = 76,172", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  jeffco <- tidy[tidy$district_id == "1420" & tidy$is_district &
                   tidy$grade_level == "TOTAL" &
                   tidy$subgroup == "total_enrollment", ]

  expect_equal(nrow(jeffco), 1)
  expect_equal(jeffco$n_students, 76172)
  expect_true(grepl("Jefferson", jeffco$district_name))
})

test_that("2024 Jefferson County racial subgroups are correct", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  jeffco <- tidy[tidy$district_id == "1420" & tidy$is_district &
                   tidy$grade_level == "TOTAL", ]

  expect_equal(jeffco$n_students[jeffco$subgroup == "white"], 49938)
  expect_equal(jeffco$n_students[jeffco$subgroup == "hispanic"], 19085)
  expect_equal(jeffco$n_students[jeffco$subgroup == "multiracial"], 3524)
  expect_equal(jeffco$n_students[jeffco$subgroup == "asian"], 2189)
  expect_equal(jeffco$n_students[jeffco$subgroup == "black"], 978)
  expect_equal(jeffco$n_students[jeffco$subgroup == "native_american"], 356)
  expect_equal(jeffco$n_students[jeffco$subgroup == "pacific_islander"], 102)
})

test_that("2024 Jefferson County FRL = 24,464", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  jeffco_frl <- tidy[tidy$district_id == "1420" & tidy$is_district &
                       tidy$grade_level == "TOTAL" &
                       tidy$subgroup == "free_reduced_lunch", ]

  expect_equal(jeffco_frl$n_students, 24464)
})

test_that("2024 has 186 districts and 1907 schools", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  n_districts <- sum(tidy$is_district & tidy$subgroup == "total_enrollment" &
                       tidy$grade_level == "TOTAL")
  n_schools <- sum(tidy$is_school & tidy$subgroup == "total_enrollment" &
                     tidy$grade_level == "TOTAL")

  expect_equal(n_districts, 186)
  expect_equal(n_schools, 1907)
})

test_that("2024 has 261 charter schools", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  charters <- tidy[tidy$is_charter & tidy$is_school &
                     tidy$subgroup == "total_enrollment" &
                     tidy$grade_level == "TOTAL", ]

  expect_equal(nrow(charters), 261)
})

test_that("2024 has only TOTAL grade level (modern format)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expect_equal(unique(tidy$grade_level), "TOTAL")
})

test_that("2024 has 11 subgroups (including FRL in modern format)", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  expected_subgroups <- sort(c(
    "total_enrollment", "male", "female",
    "native_american", "asian", "black", "hispanic",
    "white", "pacific_islander", "multiracial",
    "free_reduced_lunch"
  ))

  actual_subgroups <- sort(unique(tidy$subgroup))
  expect_equal(actual_subgroups, expected_subgroups)
})

test_that("2024 racial subgroups sum to total enrollment at state level", {
  tidy <- suppressMessages(
    coschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  )

  racial_subgroups <- c("native_american", "asian", "black", "hispanic",
                        "white", "pacific_islander", "multiracial")

  state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]
  total <- state$n_students[state$subgroup == "total_enrollment"]
  race_sum <- sum(state$n_students[state$subgroup %in% racial_subgroups])

  expect_equal(race_sum, total)
})


# ==============================================================================
# 2025: CDE server down -- skip gracefully
# ==============================================================================

test_that("2025 enrollment data loads from cache or skips", {
  skip_if_no_cache(2025)

  tidy <- suppressMessages(
    coschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  )

  expect_s3_class(tidy, "data.frame")
  expect_gt(nrow(tidy), 0)

  # State total should be in ~870K-920K range
  state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  total <- sum(state$n_students)
  expect_gt(total, 870000)
  expect_lt(total, 920000)
})


# ==============================================================================
# Cross-Year Consistency Checks
# ==============================================================================

test_that("state enrollment stays in reasonable range across cached years", {
  # Colorado's enrollment is ~880K-920K, should not jump wildly
  years_data <- list()

  for (yr in c(2020, 2021, 2024)) {
    tryCatch({
      tidy <- suppressMessages(
        coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
      )
      state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
      # Use TOTAL grade if available, otherwise sum individual grades
      if ("TOTAL" %in% state$grade_level) {
        total <- state$n_students[state$grade_level == "TOTAL"]
      } else {
        total <- sum(state$n_students)
      }
      years_data[[as.character(yr)]] <- total
    }, error = function(e) NULL)
  }

  for (yr in names(years_data)) {
    expect_gt(years_data[[yr]], 850000,
              label = paste(yr, "state enrollment floor"))
    expect_lt(years_data[[yr]], 950000,
              label = paste(yr, "state enrollment ceiling"))
  }
})

test_that("Denver enrollment stays in reasonable range across years", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    denver <- tidy[tidy$district_id == "0880" & tidy$is_district &
                     tidy$subgroup == "total_enrollment", ]
    # Use TOTAL grade if available, otherwise sum individual grades
    if ("TOTAL" %in% denver$grade_level) {
      total <- denver$n_students[denver$grade_level == "TOTAL"]
    } else {
      total <- sum(denver$n_students)
    }

    expect_gt(total, 80000,
              label = paste(yr, "Denver enrollment floor"))
    expect_lt(total, 100000,
              label = paste(yr, "Denver enrollment ceiling"))
  }
})

test_that("district count is consistent across years", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    n_districts <- length(unique(tidy$district_id[tidy$is_district]))
    expect_equal(n_districts, 186,
                 label = paste(yr, "district count"))
  }
})

test_that("school count is stable across years (~1900)", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    n_schools <- nrow(unique(
      tidy[tidy$is_school & tidy$subgroup == "total_enrollment" &
             tidy$grade_level %in% c("TOTAL", unique(tidy$grade_level)[1]),
           c("district_id", "campus_id")]
    ))

    expect_gt(n_schools, 1800,
              label = paste(yr, "school count floor"))
    expect_lt(n_schools, 2100,
              label = paste(yr, "school count ceiling"))
  }
})

test_that("entity flags are mutually exclusive for every cached year", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    flag_sum <- as.integer(tidy$is_state) + as.integer(tidy$is_district) +
                as.integer(tidy$is_school)
    expect_true(all(flag_sum == 1),
                label = paste(yr, "mutually exclusive entity flags"))
  }
})

test_that("no Inf or NaN in enrollment data for any cached year", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    expect_false(any(is.infinite(tidy$n_students)),
                 label = paste(yr, "no Inf in n_students"))
    expect_false(any(is.nan(tidy$n_students)),
                 label = paste(yr, "no NaN in n_students"))
    expect_false(any(is.infinite(tidy$pct), na.rm = TRUE),
                 label = paste(yr, "no Inf in pct"))
    expect_false(any(is.nan(tidy$pct), na.rm = TRUE),
                 label = paste(yr, "no NaN in pct"))
  }
})

test_that("no negative enrollment values for any cached year", {
  for (yr in c(2020, 2024)) {
    tidy <- suppressMessages(
      coschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    )

    expect_false(any(tidy$n_students < 0, na.rm = TRUE),
                 label = paste(yr, "no negative n_students"))
  }
})
