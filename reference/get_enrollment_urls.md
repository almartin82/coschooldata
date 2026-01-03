# Get enrollment data URLs for a specific year

Discovers the correct URLs for enrollment data files by scraping CDE's
archive pages. CDE uses inconsistent URL patterns, so this function
provides a reliable way to find current file locations.

## Usage

``` r
get_enrollment_urls(end_year)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24)

## Value

Named list with URLs for grade and race_gender files, or NULL if not
found
