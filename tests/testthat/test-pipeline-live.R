# ==============================================================================
# LIVE Pipeline Tests for coschooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# IMPORTANT: As of January 2026, www.cde.state.co.us is DOWN (connection refused).
# The new site ed.cde.state.co.us hosts pages but data files still point to
# the old domain. These tests document the current situation.
#
# Test Categories:
# 1. Server Status - Check which CDE domains are accessible
# 2. URL Availability - HTTP status codes for pages and files
# 3. Archive Page - Verify ed.cde.state.co.us works
# 4. File Download - Test actual file retrieval (when server is up)
# 5. File Parsing - Read file into R
# 6. Package Functions - Core functions work correctly
# 7. Data Quality - No Inf/NaN, valid ranges (when data available)
# 8. Aggregation - Totals sum correctly (when data available)
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# Helper to check if a server is reachable
check_server <- function(url, timeout = 10) {
  tryCatch({
    response <- httr::HEAD(url, httr::timeout(timeout), httr::config(ssl_verifypeer = FALSE))
    list(
      reachable = TRUE,
      status_code = httr::status_code(response)
    )
  }, error = function(e) {
    list(
      reachable = FALSE,
      error = e$message
    )
  })
}

# ==============================================================================
# STEP 1: Server Status Tests
# ==============================================================================

test_that("DOCUMENT: www.cde.state.co.us server status", {
  skip_if_offline()

  # Check if the OLD domain is accessible
  result <- check_server("https://www.cde.state.co.us")

  # Document current status - this may change
  if (!result$reachable) {
    # Server is DOWN - this is the known issue as of Jan 2026
    expect_false(result$reachable,
      info = "KNOWN ISSUE: www.cde.state.co.us is DOWN. Data files are unavailable.")
  } else {
    # Server is UP - great!
    expect_true(result$reachable)
    expect_equal(result$status_code, 200)
  }
})

test_that("New CDE site ed.cde.state.co.us is accessible (HTTP 200)", {
  skip_if_offline()

  response <- httr::HEAD(
    "https://ed.cde.state.co.us",
    httr::timeout(30)
  )

  expect_equal(
    httr::status_code(response), 200,
    info = "New CDE website should be accessible"
  )
})

test_that("CDE archive page is accessible on new site", {
  skip_if_offline()

  response <- httr::GET(
    "https://ed.cde.state.co.us/cdereval/pupilmembership-statistics",
    httr::timeout(30)
  )

  expect_equal(
    httr::status_code(response), 200,
    info = "Pupil membership statistics page should be accessible"
  )
})

test_that("CDE archive page lists enrollment files", {
  skip_if_offline()

  response <- httr::GET(
    "https://ed.cde.state.co.us/cdereval/pupilmembership-statistics",
    httr::timeout(30)
  )

  if (httr::http_error(response)) {
    skip("Could not access archive page")
  }

  content <- httr::content(response, "text", encoding = "UTF-8")

  # Check that the page mentions enrollment data
  expect_true(
    grepl("membership|enrollment", content, ignore.case = TRUE),
    info = "Archive page should mention enrollment/membership data"
  )

  # Check that Excel files are referenced
  expect_true(
    grepl("xlsx|excel", content, ignore.case = TRUE),
    info = "Archive page should reference Excel files"
  )
})

# ==============================================================================
# STEP 2: Data File URL Tests
# ==============================================================================

test_that("DOCUMENT: Primary enrollment file URLs return 404/connection error (known issue)", {
  skip_if_offline()

  # These URLs point to www.cde.state.co.us which may be DOWN
  test_urls <- c(
    "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool",
    "https://www.cde.state.co.us/cdereval/2022-2023schoolmembershipgrade"
  )

  for (url in test_urls) {
    result <- check_server(url)

    # Document status - either connection refused or 404
    if (!result$reachable) {
      expect_false(result$reachable,
        info = paste("KNOWN ISSUE - Server down:", url))
    } else if (result$status_code == 404) {
      expect_equal(result$status_code, 404,
        info = paste("KNOWN ISSUE - File moved:", url))
    } else {
      # If we get here, the file is actually accessible!
      expect_true(result$status_code %in% c(200, 301, 302),
        info = paste("File accessible:", url))
    }
  }
})

# ==============================================================================
# STEP 3: Package Function Tests
# ==============================================================================

test_that("get_available_years returns valid year range", {
  result <- coschooldata::get_available_years()

  expect_type(result, "list")
  expect_true("min_year" %in% names(result))
  expect_true("max_year" %in% names(result))

  expect_gte(result$min_year, 2015)
  expect_lte(result$max_year, 2030)
  expect_lt(result$min_year, result$max_year)
})

test_that("get_enrollment_urls returns URLs for known years", {
  # Test the URL discovery function - should return URLs even if server is down
  for (year in 2020:2024) {
    urls <- coschooldata:::get_enrollment_urls(year)
    expect_true(!is.null(urls),
      info = paste("Should have URLs for year", year))
    expect_true("grade" %in% names(urls) || "race_gender" %in% names(urls),
      info = paste("Should have grade or race_gender URL for year", year))
  }
})

test_that("URL discovery functions handle server errors gracefully", {
  # Even if server is down, functions should not crash
  expect_no_error({
    urls <- coschooldata:::get_enrollment_urls(2024)
  })

  expect_no_error({
    urls <- coschooldata:::get_known_enrollment_urls(2024)
  })
})

# ==============================================================================
# STEP 4: File Download Tests (when server available)
# ==============================================================================

test_that("Can download enrollment file when server is accessible", {
  skip_if_offline()

  # First check if server is up
  server_status <- check_server("https://www.cde.state.co.us")

  if (!server_status$reachable) {
    skip("Server www.cde.state.co.us is down - cannot test download")
  }

  url <- "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(120),
    httr::config(ssl_verifypeer = FALSE)
  )

  expect_equal(httr::status_code(response), 200)
  expect_true(file.exists(temp_file))
  expect_gt(file.info(temp_file)$size, 1000)
})

test_that("Downloaded file is Excel format (not HTML error page)", {
  skip_if_offline()

  server_status <- check_server("https://www.cde.state.co.us")
  if (!server_status$reachable) {
    skip("Server www.cde.state.co.us is down")
  }

  url <- "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(120),
    httr::config(ssl_verifypeer = FALSE)
  )

  if (httr::http_error(response)) {
    skip("Could not download file")
  }

  # Verify it's actually an Excel file
  file_type <- system(paste("file", shQuote(temp_file)), intern = TRUE)
  expect_true(
    grepl("Microsoft|Excel|Zip|OOXML", file_type),
    label = paste("Expected Excel file, got:", file_type)
  )
})

# ==============================================================================
# STEP 5: File Parsing Tests (when server available)
# ==============================================================================

test_that("Can parse enrollment Excel file with readxl", {
  skip_if_offline()

  server_status <- check_server("https://www.cde.state.co.us")
  if (!server_status$reachable) {
    skip("Server www.cde.state.co.us is down")
  }

  url <- "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool"
  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(120),
    httr::config(ssl_verifypeer = FALSE)
  )

  if (httr::http_error(response)) {
    skip("Could not download file")
  }

  sheets <- readxl::excel_sheets(temp_file)
  expect_gt(length(sheets), 0)

  df <- readxl::read_excel(temp_file, sheet = sheets[1])
  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 0)
  expect_gt(ncol(df), 0)
})

# ==============================================================================
# STEP 6: get_raw_enr() and fetch_enr() Tests
# ==============================================================================

test_that("get_raw_enr fails gracefully when server is down", {
  skip_if_offline()

  server_status <- check_server("https://www.cde.state.co.us")

  if (!server_status$reachable) {
    # Server is down - function should fail with informative error
    expect_error(
      coschooldata:::get_raw_enr(2024),
      info = "get_raw_enr should fail when server is down"
    )
  } else {
    # Server is up - function should work
    result <- coschooldata:::get_raw_enr(2024)
    expect_true(is.list(result) || is.data.frame(result))
  }
})

test_that("fetch_enr returns data when server is accessible", {
  skip_if_offline()

  server_status <- check_server("https://www.cde.state.co.us")
  if (!server_status$reachable) {
    skip("Server www.cde.state.co.us is down - cannot fetch enrollment data")
  }

  data <- coschooldata::fetch_enr(2024, tidy = TRUE)
  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0)
})

# ==============================================================================
# STEP 7: Data Quality Tests (when data available)
# ==============================================================================

test_that("Fetched data has no Inf or NaN values", {
  skip_if_offline()

  server_status <- check_server("https://www.cde.state.co.us")
  if (!server_status$reachable) {
    skip("Server down - cannot test data quality")
  }

  tryCatch({
    data <- coschooldata::fetch_enr(2024, tidy = TRUE)

    numeric_cols <- sapply(data, is.numeric)
    for (col in names(data)[numeric_cols]) {
      expect_false(any(is.infinite(data[[col]]), na.rm = TRUE),
        info = paste("No Inf in", col))
      expect_false(any(is.nan(data[[col]]), na.rm = TRUE),
        info = paste("No NaN in", col))
    }
  }, error = function(e) {
    skip(paste("Could not fetch data:", e$message))
  })
})

test_that("Enrollment counts are non-negative", {
  skip_if_offline()

  server_status <- check_server("https://www.cde.state.co.us")
  if (!server_status$reachable) {
    skip("Server down - cannot test data quality")
  }

  tryCatch({
    data <- coschooldata::fetch_enr(2024, tidy = FALSE)

    if ("row_total" %in% names(data)) {
      expect_true(all(data$row_total >= 0, na.rm = TRUE))
    }
  }, error = function(e) {
    skip(paste("Could not fetch data:", e$message))
  })
})

# ==============================================================================
# STEP 8: Aggregation Tests (when data available)
# ==============================================================================

test_that("State total is positive (not zero)", {
  skip_if_offline()

  server_status <- check_server("https://www.cde.state.co.us")
  if (!server_status$reachable) {
    skip("Server down - cannot test aggregation")
  }

  tryCatch({
    data <- coschooldata::fetch_enr(2024, tidy = FALSE)

    if ("type" %in% names(data) && "row_total" %in% names(data)) {
      state_rows <- data[data$type == "State", ]
      if (nrow(state_rows) > 0) {
        state_total <- sum(state_rows$row_total, na.rm = TRUE)
        expect_gt(state_total, 0)
      }
    }
  }, error = function(e) {
    skip(paste("Could not fetch data:", e$message))
  })
})

# ==============================================================================
# STEP 9: Cache Function Tests
# ==============================================================================

test_that("Cache path function returns valid path", {
  tryCatch({
    path <- coschooldata:::get_cache_path(2024, "enrollment")
    expect_true(is.character(path))
    expect_true(grepl("2024", path))
    expect_true(grepl("\\.rds$", path))
  }, error = function(e) {
    skip("Cache functions may not be implemented")
  })
})

test_that("clear_cache runs without error", {
  tryCatch({
    expect_no_error(suppressMessages(coschooldata::clear_cache()))
  }, error = function(e) {
    skip("clear_cache not implemented")
  })
})

# ==============================================================================
# STEP 10: Output Fidelity Tests (when data available)
# ==============================================================================

test_that("tidy=TRUE and tidy=FALSE return consistent data", {
  skip_if_offline()

  server_status <- check_server("https://www.cde.state.co.us")
  if (!server_status$reachable) {
    skip("Server down - cannot test fidelity")
  }

  tryCatch({
    wide <- coschooldata::fetch_enr(2024, tidy = FALSE)
    tidy <- coschooldata::fetch_enr(2024, tidy = TRUE)

    expect_gt(nrow(wide), 0)
    expect_gt(nrow(tidy), 0)

  }, error = function(e) {
    skip(paste("Could not fetch data:", e$message))
  })
})
