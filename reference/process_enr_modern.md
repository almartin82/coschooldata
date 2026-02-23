# Process modern format enrollment data (2023+)

Modern format has one row per school with combined race totals. No
per-grade breakdown; each row is a school-level TOTAL.

## Usage

``` r
process_enr_modern(data_rows, end_year)
```

## Arguments

- data_rows:

  Data frame with proper column names

- end_year:

  School year end

## Value

Wide format data frame
