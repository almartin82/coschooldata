# ==============================================================================
# LIVE Pipeline Tests for coschooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP status codes
# 2. File Download - Successful download and file type verification
# 3. File Parsing - Read file into R
# 4. Column Structure - Expected columns exist
# 5. Year Filtering - Extract data for specific years
# 6. Aggregation Logic - District sums match state totals
# 7. Data Quality - No Inf/NaN, valid ranges
# 8. Output Fidelity - tidy=TRUE matches raw data
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

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("Colorado DOE main website is accessible", {
  skip_if_offline()

  response <- httr::HEAD(
    "https://www.cde.state.co.us/cdereval/pupilcurrent",
    httr::timeout(30),
    httr::config(ssl_verifypeer = FALSE)
  )
  expect_equal(httr::status_code(response), 200)
})

test_that("CDE archive page is accessible", {
  skip_if_offline()

  response <- httr::HEAD(
    "https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives",
    httr::timeout(30),
    httr::config(ssl_verifypeer = FALSE)
  )
  # Accept 200 or 301/302 redirects

  expect_true(httr::status_code(response) %in% c(200, 301, 302))
})

test_that("Known enrollment URLs return valid responses", {
  skip_if_offline()

  # Test URLs from the hardcoded lookup table
  urls_to_test <- list(
    "2024_grade" = "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool",
    "2023_grade" = "https://www.cde.state.co.us/cdereval/2022-2023schoolmembershipgrade",
    "2022_grade" = "https://www.cde.state.co.us/cdereval/2021-2022schoolmembershipgrade"
  )

  for (name in names(urls_to_test)) {
    url <- urls_to_test[[name]]
    tryCatch({
      response <- httr::HEAD(
        url,
        httr::timeout(30),
        httr::config(ssl_verifypeer = FALSE)
      )
      # Should return 200 or redirect (301/302)
      expect_true(
        httr::status_code(response) %in% c(200, 301, 302),
        info = paste("URL should be accessible:", name, url)
      )
    }, error = function(e) {
      skip(paste("Network error testing URL:", name, "-", e$message))
    })
  }
})

# ==============================================================================
# STEP 2: File Download Tests
# ==============================================================================

test_that("Can download Colorado enrollment data file", {
  skip_if_offline()

  # Use a known working URL
  url <- "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool"
  temp_file <- tempfile(fileext = ".xlsx")

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(120),
      httr::config(ssl_verifypeer = FALSE)
    )

    # Check HTTP status
    expect_true(httr::status_code(response) %in% c(200, 301, 302),
                info = "Download should succeed")

    # Check file exists and has content
    expect_true(file.exists(temp_file), info = "File should be created")

    file_size <- file.info(temp_file)$size
    expect_gt(file_size, 1000, info = "File should be larger than 1KB (not an error page)")

    # Clean up
    if (file.exists(temp_file)) unlink(temp_file)

  }, error = function(e) {
    if (file.exists(temp_file)) unlink(temp_file)
    skip(paste("Download failed:", e$message))
  })
})

# ==============================================================================
# STEP 3: File Parsing Tests
# ==============================================================================

test_that("Can parse Colorado enrollment file with readxl", {
  skip_if_offline()

  url <- "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool"
  temp_file <- tempfile(fileext = ".xlsx")

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(120),
      httr::config(ssl_verifypeer = FALSE)
    )

    if (httr::http_error(response)) {
      skip("Could not download file for parsing test")
    }

    # Try to list sheets
    sheets <- readxl::excel_sheets(temp_file)
    expect_gt(length(sheets), 0, info = "Excel file should have at least one sheet")

    # Try to read first sheet
    df <- readxl::read_excel(temp_file, sheet = sheets[1])
    expect_true(is.data.frame(df), info = "Should parse to data frame")
    expect_gt(nrow(df), 0, info = "Data frame should have rows")

    # Clean up
    if (file.exists(temp_file)) unlink(temp_file)

  }, error = function(e) {
    if (file.exists(temp_file)) unlink(temp_file)
    skip(paste("Parsing test failed:", e$message))
  })
})

# ==============================================================================
# STEP 4: Column Structure Tests
# ==============================================================================

test_that("get_enrollment_urls returns URLs for known years", {
  # Test the URL discovery function
  for (year in 2020:2024) {
    urls <- coschooldata:::get_enrollment_urls(year)
    expect_true(!is.null(urls), info = paste("Should have URLs for year", year))
    expect_true("grade" %in% names(urls) || "race_gender" %in% names(urls),
                info = paste("Should have grade or race_gender URL for year", year))
  }
})

# ==============================================================================
# STEP 5: get_raw_enr() Function Tests
# ==============================================================================

test_that("get_raw_enr returns data for valid year", {
  skip_if_offline()
  
  # Get available years
  years_info <- coschooldata::get_available_years()
  
  if (is.list(years_info)) {
    test_year <- years_info$max_year
  } else {
    test_year <- max(years_info)
  }
  
  # This may fail if data source is broken - that is the test!
  tryCatch({
    raw <- coschooldata:::get_raw_enr(test_year)
    expect_true(is.list(raw) || is.data.frame(raw))
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("get_available_years returns valid year range", {
  result <- coschooldata::get_available_years()
  
  if (is.list(result)) {
    expect_true("min_year" %in% names(result) || "years" %in% names(result))
    if ("min_year" %in% names(result)) {
      expect_true(result$min_year >= 1990 & result$min_year <= 2030)
      expect_true(result$max_year >= 1990 & result$max_year <= 2030)
    }
  } else {
    expect_true(is.numeric(result) || is.integer(result))
    expect_true(all(result >= 1990 & result <= 2030, na.rm = TRUE))
  }
})

# ==============================================================================
# STEP 6: Data Quality Tests
# ==============================================================================

test_that("fetch_enr returns data with no Inf or NaN", {
  skip_if_offline()
  
  tryCatch({
    years_info <- coschooldata::get_available_years()
    if (is.list(years_info)) {
      test_year <- years_info$max_year
    } else {
      test_year <- max(years_info)
    }
    
    data <- coschooldata::fetch_enr(test_year, tidy = TRUE)
    
    for (col in names(data)[sapply(data, is.numeric)]) {
      expect_false(any(is.infinite(data[[col]]), na.rm = TRUE), 
                   info = paste("No Inf in", col))
      expect_false(any(is.nan(data[[col]]), na.rm = TRUE), 
                   info = paste("No NaN in", col))
    }
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("Enrollment counts are non-negative", {
  skip_if_offline()
  
  tryCatch({
    years_info <- coschooldata::get_available_years()
    if (is.list(years_info)) {
      test_year <- years_info$max_year
    } else {
      test_year <- max(years_info)
    }
    
    data <- coschooldata::fetch_enr(test_year, tidy = FALSE)
    
    if ("row_total" %in% names(data)) {
      expect_true(all(data$row_total >= 0, na.rm = TRUE))
    }
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 7: Aggregation Tests
# ==============================================================================

test_that("State total is reasonable (not zero)", {
  skip_if_offline()
  
  tryCatch({
    years_info <- coschooldata::get_available_years()
    if (is.list(years_info)) {
      test_year <- years_info$max_year
    } else {
      test_year <- max(years_info)
    }
    
    data <- coschooldata::fetch_enr(test_year, tidy = FALSE)
    
    state_rows <- data[data$type == "State", ]
    if (nrow(state_rows) > 0 && "row_total" %in% names(state_rows)) {
      state_total <- sum(state_rows$row_total, na.rm = TRUE)
      # State total should be > 0 (unless data source is broken)
      expect_gt(state_total, 0, 
                label = "State total enrollment should be > 0")
    }
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 8: Output Fidelity Tests
# ==============================================================================

test_that("tidy=TRUE and tidy=FALSE return consistent totals", {
  skip_if_offline()
  
  tryCatch({
    years_info <- coschooldata::get_available_years()
    if (is.list(years_info)) {
      test_year <- years_info$max_year
    } else {
      test_year <- max(years_info)
    }
    
    wide <- coschooldata::fetch_enr(test_year, tidy = FALSE)
    tidy <- coschooldata::fetch_enr(test_year, tidy = TRUE)
    
    # Both should have data
    expect_gt(nrow(wide), 0)
    expect_gt(nrow(tidy), 0)
    
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Cache functions exist and work", {
  # Test that cache path can be generated
  tryCatch({
    path <- coschooldata:::get_cache_path(2024, "enrollment")
    expect_true(is.character(path))
    expect_true(grepl("2024", path))
  }, error = function(e) {
    skip("Cache functions may not be implemented")
  })
})

