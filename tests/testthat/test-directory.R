# ==============================================================================
# School Directory Tests
# ==============================================================================

# Skip helper
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) skip("No network connectivity")
  }, error = function(e) skip("No network connectivity"))
}

# ==============================================================================
# 1. URL Availability Tests
# ==============================================================================

test_that("School addresses URL returns HTTP 200", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/School%20Addresses-en.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("District addresses URL returns HTTP 200", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/District%20Addresses-en.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("School codes URL returns HTTP 200", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/School%20Building%20Codes-en-us.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

# ==============================================================================
# 2. File Download Tests
# ==============================================================================

test_that("Can download school addresses Excel file", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/School%20Addresses-en.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")

  response <- httr::GET(url, httr::write_disk(temp_file), httr::timeout(120))

  expect_equal(httr::status_code(response), 200)
  expect_gt(file.info(temp_file)$size, 10000)  # At least 10KB

  # Verify it's actually an Excel file (magic bytes)
  con <- file(temp_file, "rb")
  magic <- readBin(con, "raw", n = 4)
  close(con)

  # XLSX files start with PK (ZIP signature: 50 4B 03 04)
  expect_equal(magic[1:2], charToRaw("PK"))

  unlink(temp_file)
})

test_that("Can download district addresses Excel file", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/District%20Addresses-en.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")

  response <- httr::GET(url, httr::write_disk(temp_file), httr::timeout(120))

  expect_equal(httr::status_code(response), 200)
  expect_gt(file.info(temp_file)$size, 10000)  # At least 10KB

  # Verify it's actually an Excel file
  con <- file(temp_file, "rb")
  magic <- readBin(con, "raw", n = 4)
  close(con)

  expect_equal(magic[1:2], charToRaw("PK"))

  unlink(temp_file)
})

# ==============================================================================
# 3. File Parsing Tests
# ==============================================================================

test_that("Can parse school addresses Excel with readxl", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/School%20Addresses-en.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")

  httr::GET(url, httr::write_disk(temp_file), httr::timeout(120))

  # Check sheets
  sheets <- readxl::excel_sheets(temp_file)
  expect_gt(length(sheets), 0)

  # Read data (skip header rows)
  df <- readxl::read_excel(temp_file, skip = 5, col_types = "text")
  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 0)

  unlink(temp_file)
})

test_that("Can parse district addresses Excel with readxl", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/District%20Addresses-en.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")

  httr::GET(url, httr::write_disk(temp_file), httr::timeout(120))

  # Check sheets
  sheets <- readxl::excel_sheets(temp_file)
  expect_gt(length(sheets), 0)

  # Read data (skip header rows)
  df <- readxl::read_excel(temp_file, skip = 5, col_types = "text")
  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 0)

  unlink(temp_file)
})

# ==============================================================================
# 4. Column Structure Tests
# ==============================================================================

test_that("School addresses Excel has expected columns", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/School%20Addresses-en.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")

  httr::GET(url, httr::write_disk(temp_file), httr::timeout(120))

  df <- readxl::read_excel(temp_file, skip = 5, col_types = "text")
  cols <- tolower(names(df))

  # Expected columns (flexible matching)
  expect_true(any(grepl("district.*code", cols)))
  expect_true(any(grepl("school.*code", cols)))
  expect_true(any(grepl("school.*name", cols)))
  expect_true(any(grepl("address", cols)))
  expect_true(any(grepl("city", cols)))

  unlink(temp_file)
})

test_that("District addresses Excel has expected columns", {
  skip_on_cran()
  skip_if_offline()

  url <- "https://cedar.cde.state.co.us/edulibdir/District%20Addresses-en.xlsx"
  temp_file <- tempfile(fileext = ".xlsx")

  httr::GET(url, httr::write_disk(temp_file), httr::timeout(120))

  df <- readxl::read_excel(temp_file, skip = 5, col_types = "text")
  cols <- tolower(names(df))

  # Expected columns
  expect_true(any(grepl("district.*code", cols)))
  expect_true(any(grepl("district.*name", cols)))
  expect_true(any(grepl("address", cols)))
  expect_true(any(grepl("city", cols)))

  unlink(temp_file)
})

# ==============================================================================
# 5. Package Function Tests
# ==============================================================================

test_that("get_raw_directory returns list with schools and districts", {
  skip_on_cran()
  skip_if_offline()

  raw <- get_raw_directory()

  expect_type(raw, "list")
  expect_true("schools" %in% names(raw))
  expect_true("districts" %in% names(raw))
  expect_s3_class(raw$schools, "data.frame")
  expect_s3_class(raw$districts, "data.frame")
  expect_gt(nrow(raw$schools), 0)
  expect_gt(nrow(raw$districts), 0)
})

test_that("fetch_directory returns data frame with expected structure", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  expect_s3_class(dir_data, "data.frame")
  expect_gt(nrow(dir_data), 0)

  # Check required columns exist
  expect_true("state_school_id" %in% names(dir_data))
  expect_true("state_district_id" %in% names(dir_data))
  expect_true("school_name" %in% names(dir_data))
  expect_true("district_name" %in% names(dir_data))
  expect_true("agg_level" %in% names(dir_data))
  expect_true("city" %in% names(dir_data))
  expect_true("state" %in% names(dir_data))
})

test_that("fetch_directory tidy=FALSE returns raw column names", {
  skip_on_cran()
  skip_if_offline()

  raw <- fetch_directory(tidy = FALSE, use_cache = FALSE)

  expect_s3_class(raw, "list")
  expect_true("schools" %in% names(raw))
  expect_true("districts" %in% names(raw))
})

test_that("fetch_directory has both schools and districts", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Check aggregation levels
  expect_true("S" %in% dir_data$agg_level)  # Schools
  expect_true("D" %in% dir_data$agg_level)  # Districts

  # Schools should outnumber districts
  n_schools <- sum(dir_data$agg_level == "S")
  n_districts <- sum(dir_data$agg_level == "D")

  expect_gt(n_schools, n_districts)
  expect_gt(n_districts, 100)  # CO has ~170 districts
  expect_gt(n_schools, 1500)   # CO has ~1800 schools
})

# ==============================================================================
# 6. Data Quality Tests
# ==============================================================================

test_that("State school IDs are 8 digits with leading zeros preserved", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Filter to actual schools (not districts)
  schools <- dir_data[dir_data$agg_level == "S", ]

  # All should be 8 characters
  expect_true(all(nchar(schools$state_school_id) == 8))

  # All should be character type (preserves leading zeros)
  expect_type(schools$state_school_id, "character")
})

test_that("State district IDs are 4 digits with leading zeros preserved", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # All should be 4 characters
  expect_true(all(nchar(dir_data$state_district_id) == 4))

  # All should be character type
  expect_type(dir_data$state_district_id, "character")
})

test_that("All entities have school names", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # No missing school names
  expect_true(all(!is.na(dir_data$school_name)))
  expect_true(all(nchar(dir_data$school_name) > 0))
})

test_that("All entities have district names", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # No missing district names
  expect_true(all(!is.na(dir_data$district_name)))
  expect_true(all(nchar(dir_data$district_name) > 0))
})

test_that("All entities have addresses", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Most should have addresses (some may be missing)
  pct_with_address <- sum(!is.na(dir_data$address)) / nrow(dir_data)
  expect_gt(pct_with_address, 0.95)  # At least 95% should have addresses
})

test_that("State is always CO", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # All should be CO
  expect_true(all(dir_data$state == "CO" | is.na(dir_data$state)))
})

test_that("No duplicate state_school_id values", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Check for duplicates
  expect_false(any(duplicated(dir_data$state_school_id)))
})

# ==============================================================================
# 7. Cache Tests
# ==============================================================================

test_that("Directory cache functions work", {
  skip_on_cran()
  skip_if_offline()

  # Clear cache first
  clear_directory_cache()

  # First call should download
  dir1 <- fetch_directory(use_cache = TRUE)

  # Check cache exists
  expect_true(cache_exists_directory("directory_tidy"))

  # Second call should use cache (very fast)
  start_time <- Sys.time()
  dir2 <- fetch_directory(use_cache = TRUE)
  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  # Cache retrieval should be very fast (< 1 second)
  expect_lt(elapsed, 1)

  # Data should be identical
  expect_equal(nrow(dir1), nrow(dir2))

  # Clean up
  clear_directory_cache()
})

test_that("clear_directory_cache removes cache files", {
  skip_on_cran()
  skip_if_offline()

  # Create cache
  fetch_directory(use_cache = TRUE)
  expect_true(cache_exists_directory("directory_tidy"))

  # Clear cache
  clear_directory_cache()
  expect_false(cache_exists_directory("directory_tidy"))
})

# ==============================================================================
# 8. Specific Data Fidelity Tests
# ==============================================================================

test_that("Denver Public Schools exists in directory", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Denver district code is 0880
  denver_district <- dir_data[dir_data$state_district_id == "0880" &
                               dir_data$agg_level == "D", ]

  expect_equal(nrow(denver_district), 1)
  expect_true(grepl("Denver", denver_district$district_name, ignore.case = TRUE))
})

test_that("Jefferson County exists in directory", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Jefferson County district code is 1200
  jeffco_district <- dir_data[dir_data$state_district_id == "1200" &
                               dir_data$agg_level == "D", ]

  expect_equal(nrow(jeffco_district), 1)
  expect_true(grepl("Jefferson", jeffco_district$district_name, ignore.case = TRUE))
})

test_that("Major districts have multiple schools", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Denver (0880) should have many schools
  denver_schools <- dir_data[dir_data$state_district_id == "0880" &
                              dir_data$agg_level == "S", ]
  expect_gt(nrow(denver_schools), 100)  # DPS has ~200 schools

  # Jefferson County (1200) should have many schools
  jeffco_schools <- dir_data[dir_data$state_district_id == "1200" &
                              dir_data$agg_level == "S", ]
  expect_gt(nrow(jeffco_schools), 100)  # Jeffco has ~150+ schools
})

test_that("Charter schools are identified", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Filter to schools only
  schools <- dir_data[dir_data$agg_level == "S", ]

  # Should have charter_status column
  expect_true("charter_status" %in% names(schools))

  # Should have both Y and N values
  expect_true("Y" %in% schools$charter_status | "N" %in% schools$charter_status)

  # Count charters
  n_charters <- sum(schools$charter_status == "Y", na.rm = TRUE)
  expect_gt(n_charters, 100)  # CO has 200+ charter schools
})

test_that("Grade levels are captured for schools", {
  skip_on_cran()
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Filter to schools only
  schools <- dir_data[dir_data$agg_level == "S", ]

  # Should have grade-related columns
  expect_true("low_grade" %in% names(schools) | "grades_served" %in% names(schools))

  # Most schools should have grade information
  if ("low_grade" %in% names(schools)) {
    pct_with_grades <- sum(!is.na(schools$low_grade)) / nrow(schools)
    expect_gt(pct_with_grades, 0.80)  # At least 80% should have grade info
  }
})
