# ==============================================================================
# Directory Year Coverage Tests for coschooldata
# ==============================================================================
#
# Tests for the Colorado school directory data from CDE's CEDAR library.
# Directory data is NOT year-specific (current snapshot of schools/districts).
#
# Data source: cedar.cde.state.co.us (separate from www.cde.state.co.us)
# This server is UP even when the main CDE data server is down.
#
# Pinned values were read from actual CDE directory data.
#
# ==============================================================================

library(testthat)

# Helper: skip if directory data unavailable (network issue)
skip_if_no_directory <- function() {
  tryCatch({
    suppressMessages(coschooldata::fetch_directory(use_cache = TRUE))
  }, error = function(e) {
    skip(paste("Directory data unavailable:", e$message))
  })
}


# ==============================================================================
# Required Fields
# ==============================================================================

test_that("directory has all required columns", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  required_cols <- c(
    "state_school_id", "state_district_id", "school_code",
    "agg_level", "school_name", "district_name",
    "school_type", "charter_status",
    "address", "city", "state", "zip", "phone"
  )

  for (col in required_cols) {
    expect_true(col %in% names(dir_data),
                label = paste("directory should have", col, "column"))
  }
})

test_that("directory has grade range columns", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  # Should have low/high grade or grades_served
  has_grade_info <- any(c("low_grade", "high_grade", "grades_served") %in% names(dir_data))
  expect_true(has_grade_info,
              label = "directory should have grade range information")
})

test_that("directory has geographic columns (county)", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  # Districts should have county info
  expect_true("county_name" %in% names(dir_data) || "county_code" %in% names(dir_data),
              label = "directory should have county information")
})


# ==============================================================================
# Entity Counts
# ==============================================================================

test_that("directory has schools and districts", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  n_schools <- sum(dir_data$agg_level == "S")
  n_districts <- sum(dir_data$agg_level == "D")

  # Colorado has ~1800-1900 schools and ~180 districts
  expect_gt(n_schools, 1700, label = "school count floor")
  expect_lt(n_schools, 2100, label = "school count ceiling")
  expect_gt(n_districts, 170, label = "district count floor")
  expect_lt(n_districts, 200, label = "district count ceiling")

  # Schools should vastly outnumber districts
  expect_gt(n_schools, n_districts * 5)
})

test_that("charter schools are identified (200+ in CO)", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  schools <- dir_data[dir_data$agg_level == "S", ]
  n_charters <- sum(schools$charter_status == "Y", na.rm = TRUE)

  # Colorado has 250+ charter schools
  expect_gt(n_charters, 200, label = "charter school count")
  expect_lt(n_charters, 400, label = "charter school count ceiling")
})


# ==============================================================================
# ID Format
# ==============================================================================

test_that("state_district_id is 4-character string for most entities", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  # Most IDs should be exactly 4 characters (there may be edge cases)
  nchar_ids <- nchar(dir_data$state_district_id)
  pct_4char <- sum(nchar_ids == 4) / length(nchar_ids)

  expect_gt(pct_4char, 0.99,
            label = "at least 99% of district IDs should be 4 characters")
  expect_type(dir_data$state_district_id, "character")
})

test_that("school_code is 4-character string for schools", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  schools <- dir_data[dir_data$agg_level == "S", ]

  # Most school codes should be 4 characters
  nchar_codes <- nchar(schools$school_code)
  pct_4char <- sum(nchar_codes == 4) / length(nchar_codes)

  expect_gt(pct_4char, 0.99,
            label = "at least 99% of school codes should be 4 characters")
  expect_type(schools$school_code, "character")
})

test_that("state_school_id = state_district_id + school_code for schools", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  schools <- dir_data[dir_data$agg_level == "S", ]

  # Verify concatenation
  expected_id <- paste0(schools$state_district_id, schools$school_code)
  matches <- schools$state_school_id == expected_id

  # Most should match (edge cases with odd district codes may differ)
  pct_match <- sum(matches) / length(matches)
  expect_gt(pct_match, 0.99,
            label = "state_school_id = district_id + school_code")
})

test_that("district rows have school_code = 0000", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  districts <- dir_data[dir_data$agg_level == "D", ]

  expect_true(all(districts$school_code == "0000"),
              label = "all district rows should have school_code = 0000")
})


# ==============================================================================
# Known Entity Lookups
# ==============================================================================

test_that("Denver Public Schools (0880) exists as a district", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  denver <- dir_data[dir_data$state_district_id == "0880" &
                       dir_data$agg_level == "D", ]

  expect_equal(nrow(denver), 1)
  expect_true(grepl("Denver", denver$district_name, ignore.case = TRUE))
  expect_equal(denver$state, "CO")
})

test_that("Denver has 190+ schools in directory", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  denver_schools <- dir_data[dir_data$state_district_id == "0880" &
                               dir_data$agg_level == "S", ]

  # Denver has ~190-210 schools
  expect_gt(nrow(denver_schools), 180, label = "Denver school count floor")
  expect_lt(nrow(denver_schools), 250, label = "Denver school count ceiling")
})

test_that("Denver East High School exists (school_code 2398)", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  east_high <- dir_data[dir_data$state_district_id == "0880" &
                          dir_data$school_code == "2398" &
                          dir_data$agg_level == "S", ]

  expect_equal(nrow(east_high), 1)
  expect_true(grepl("East", east_high$school_name, ignore.case = TRUE))
  expect_equal(east_high$state_school_id, "08802398")
})

test_that("Jefferson County R-1 (1420) exists as a district", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  jeffco <- dir_data[dir_data$state_district_id == "1420" &
                       dir_data$agg_level == "D", ]

  expect_equal(nrow(jeffco), 1)
  expect_true(grepl("Jefferson", jeffco$district_name, ignore.case = TRUE))
})

test_that("Jefferson County has 130+ schools", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  jeffco_schools <- dir_data[dir_data$state_district_id == "1420" &
                               dir_data$agg_level == "S", ]

  expect_gt(nrow(jeffco_schools), 130, label = "Jeffco school count floor")
  expect_lt(nrow(jeffco_schools), 200, label = "Jeffco school count ceiling")
})

test_that("Colorado Springs district (1010) exists", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  # Colorado Springs D11 or Academy D20 -- look for any Colorado Springs district
  d11 <- dir_data[dir_data$state_district_id == "1010" &
                    dir_data$agg_level == "D", ]

  expect_equal(nrow(d11), 1)
})


# ==============================================================================
# Data Quality
# ==============================================================================

test_that("state is always CO for all entities", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  non_na_state <- dir_data$state[!is.na(dir_data$state)]
  expect_true(all(non_na_state == "CO"),
              label = "all entities should be in Colorado")
})

test_that("most entities have non-empty names", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  # School names
  pct_named <- sum(!is.na(dir_data$school_name) & dir_data$school_name != "") /
               nrow(dir_data)
  expect_gt(pct_named, 0.99, label = "school_name completeness")

  # District names
  pct_dist_named <- sum(!is.na(dir_data$district_name) & dir_data$district_name != "") /
                    nrow(dir_data)
  expect_gt(pct_dist_named, 0.99, label = "district_name completeness")
})

test_that("most entities have addresses", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  pct_with_address <- sum(!is.na(dir_data$address) & dir_data$address != "") /
                      nrow(dir_data)
  expect_gt(pct_with_address, 0.90, label = "address completeness")
})

test_that("most entities have city", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  pct_with_city <- sum(!is.na(dir_data$city) & dir_data$city != "") /
                   nrow(dir_data)
  expect_gt(pct_with_city, 0.95, label = "city completeness")
})

test_that("most entities have ZIP codes", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  pct_with_zip <- sum(!is.na(dir_data$zip) & dir_data$zip != "") /
                  nrow(dir_data)
  expect_gt(pct_with_zip, 0.90, label = "ZIP code completeness")
})

test_that("ZIP codes are valid Colorado format (starts with 80 or 81)", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  valid_zips <- dir_data$zip[!is.na(dir_data$zip) & dir_data$zip != ""]
  # Extract first 2 digits
  zip_prefix <- substr(valid_zips, 1, 2)

  # Colorado ZIPs are 80xxx-81xxx
  pct_co_zip <- sum(zip_prefix %in% c("80", "81")) / length(zip_prefix)
  expect_gt(pct_co_zip, 0.95,
            label = "at least 95% of ZIPs should be Colorado (80xxx/81xxx)")
})

test_that("at most 1 duplicate state_school_id (known edge case: 5-digit district)", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  n_dupes <- sum(duplicated(dir_data$state_school_id))

  # There is 1 known edge case: district code 46080 (5 digits) produces
  # state_school_id "460800000" that collides between school and district rows.
  # This is a CDE data quality issue, not a package bug.
  expect_lte(n_dupes, 1,
             label = "at most 1 duplicate state_school_id (known CDE edge case)")
})

test_that("major cities are represented", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  cities <- unique(toupper(dir_data$city))

  expect_true("DENVER" %in% cities, label = "Denver represented")
  expect_true("COLORADO SPRINGS" %in% cities, label = "Colorado Springs represented")
  expect_true("AURORA" %in% cities, label = "Aurora represented")
  expect_true("FORT COLLINS" %in% cities, label = "Fort Collins represented")
  expect_true("PUEBLO" %in% cities, label = "Pueblo represented")
})


# ==============================================================================
# Directory Cache Tests
# ==============================================================================

test_that("directory cache functions work without error", {
  expect_no_error(
    suppressMessages(coschooldata::clear_directory_cache())
  )
})

test_that("fetch_directory tidy=FALSE returns raw list", {
  skip_if_no_directory()

  raw <- suppressMessages(
    coschooldata::fetch_directory(tidy = FALSE, use_cache = TRUE)
  )

  expect_type(raw, "list")
  expect_true("schools" %in% names(raw))
  expect_true("districts" %in% names(raw))
  expect_s3_class(raw$schools, "data.frame")
  expect_s3_class(raw$districts, "data.frame")
})


# ==============================================================================
# Aggregation Level Consistency
# ==============================================================================

test_that("agg_level only contains S and D values", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  expect_true(all(dir_data$agg_level %in% c("S", "D")),
              label = "agg_level should only be S or D")
})

test_that("charter_status is Y or N for schools", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  schools <- dir_data[dir_data$agg_level == "S", ]
  valid_charter <- schools$charter_status[!is.na(schools$charter_status)]

  # Most should be Y or N
  pct_valid <- sum(valid_charter %in% c("Y", "N")) / length(valid_charter)
  expect_gt(pct_valid, 0.95,
            label = "charter_status should be Y or N for schools")
})

test_that("districts have charter_status = N", {
  skip_if_no_directory()

  dir_data <- suppressMessages(
    coschooldata::fetch_directory(use_cache = TRUE)
  )

  districts <- dir_data[dir_data$agg_level == "D", ]

  expect_true(all(districts$charter_status == "N"),
              label = "districts should have charter_status = N")
})
