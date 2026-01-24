# Fetch assessment data for multiple years

Downloads and combines assessment data for multiple school years. Note:
2020 is automatically excluded (COVID-19 testing waiver).

## Usage

``` r
fetch_assessment_multi(
  end_years,
  subject = "all",
  tidy = TRUE,
  use_cache = TRUE
)
```

## Arguments

- end_years:

  Vector of school year ends (e.g., c(2022, 2023, 2024))

- subject:

  Subject to fetch: "all" (default), "ela", "math", "science", or "csla"

- tidy:

  If TRUE (default), returns data in long format.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Combined data frame with assessment data for all requested years

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 3 years of data
assess_multi <- fetch_assessment_multi(2022:2024)

# Get Math data for 5 years
math_trend <- fetch_assessment_multi(2019:2024, subject = "math")
} # }
```
