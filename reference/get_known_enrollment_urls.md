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

## Details

NOTE: As of January 2026, www.cde.state.co.us is DOWN. The new site
ed.cde.state.co.us hosts pages but files still point to the old domain.
This function tries both domains.
