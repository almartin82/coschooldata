# Hardcoded lookup table for known-good enrollment URLs

CDE URLs are inconsistent across years. This lookup table contains
verified URLs that have been tested and confirmed working.

## Usage

``` r
get_known_enrollment_urls(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Named list with URLs, or NULL if year not in lookup
