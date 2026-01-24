# Download raw CMAS assessment data

Downloads assessment data from the Colorado Department of Education.
Returns the raw data as-is from the Excel file.

## Usage

``` r
get_raw_assessment(end_year, subject = "all")
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24)

- subject:

  One of "ela", "math", "science", "csla", or "all" (default)

## Value

Data frame with raw assessment data, or list of data frames if
subject="all"
