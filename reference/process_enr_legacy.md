# Process legacy format enrollment data (2020-2022)

Legacy format has per-grade rows with Male/Female splits by race.
Includes both school-level and district-level (school code 0000) rows.

## Usage

``` r
process_enr_legacy(data_rows, end_year)
```

## Arguments

- data_rows:

  Data frame with proper column names

- end_year:

  School year end

## Value

Wide format data frame
