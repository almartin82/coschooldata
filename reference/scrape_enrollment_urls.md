# Scrape CDE archive page to find enrollment URLs

Scrapes the CDE data archive page to find URLs for enrollment data
files. This is used as a fallback when URLs aren't in the hardcoded
lookup table.

## Usage

``` r
scrape_enrollment_urls(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Named list with URLs, or NULL if not found
