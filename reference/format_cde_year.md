# Get the academic year label for file names

CDE uses various naming conventions for files. This function generates
the appropriate year string for file URLs.

## Usage

``` r
format_cde_year(end_year, format = "dash2")
```

## Arguments

- end_year:

  End year (e.g., 2024)

- format:

  One of "dash2" (2023-24), "dash4" (2023-2024), or "single" (2024)

## Value

Formatted year string
