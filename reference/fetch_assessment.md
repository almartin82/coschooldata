# Fetch Colorado CMAS assessment data

Downloads and returns CMAS assessment data from the Colorado Department
of Education.

## Usage

``` r
fetch_assessment(end_year, subject = "all", tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024). Valid range: 2015-2025 (except
  2020).

- subject:

  Subject to fetch: "all" (default), "ela", "math", "science", or "csla"

- tidy:

  If TRUE (default), returns data in long format with proficiency_level
  column. If FALSE, returns wide format with separate pct\_\* columns.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with assessment data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 CMAS assessment data
assess_2024 <- fetch_assessment(2024)

# Get only Math results
math_2024 <- fetch_assessment(2024, subject = "math")

# Get wide format (separate columns for each proficiency level)
assess_wide <- fetch_assessment(2024, tidy = FALSE)

# Force fresh download
assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
} # }
```
