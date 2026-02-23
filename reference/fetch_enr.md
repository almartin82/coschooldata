# Fetch Colorado enrollment data

Downloads and returns enrollment data from the Colorado Department of
Education. When tidy=TRUE (default), returns data in long format with
standard columns: end_year, district_id, district_name, campus_id,
campus_name, grade_level, subgroup, n_students, pct, is_state,
is_district, is_school, is_charter.

## Usage

``` r
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024).

- tidy:

  If TRUE (default), returns data in tidy long format. If FALSE, returns
  processed wide format.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 enrollment data (tidy format)
enr_2024 <- fetch_enr(2024)

# Get wide format
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Force fresh download
enr_fresh <- fetch_enr(2024, use_cache = FALSE)
} # }
```
