# Download modern format enrollment data (2019+)

Downloads enrollment data from CDE's modern Excel files. Uses URL
discovery to find the correct file locations since CDE uses inconsistent
URL patterns.

## Usage

``` r
download_modern_enrollment(end_year)
```

## Arguments

- end_year:

  School year end (2019-2025)

## Value

Data frame with school-level enrollment data
