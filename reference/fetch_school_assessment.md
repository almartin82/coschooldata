# Fetch assessment data for a specific school

Convenience function to fetch assessment data for a single school.

## Usage

``` r
fetch_school_assessment(
  end_year,
  district_id,
  school_id,
  subject = "all",
  tidy = TRUE,
  use_cache = TRUE
)
```

## Arguments

- end_year:

  School year end

- district_id:

  4-digit district code

- school_id:

  4-digit school code

- subject:

  Subject to fetch: "all" (default), "ela", "math", "science", or "csla"

- tidy:

  If TRUE (default), returns tidy format

- use_cache:

  If TRUE (default), uses cached data

## Value

Data frame filtered to specified school

## Examples

``` r
if (FALSE) { # \dontrun{
# Get a specific school's assessment data
school_assess <- fetch_school_assessment(2024, "0880", "0001")
} # }
```
