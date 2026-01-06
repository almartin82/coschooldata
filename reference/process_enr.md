# Process raw enrollment data to wide format

Transforms the raw Excel data into a standardized wide format with
proper column names and data types. Colorado's data has a 2-row header
structure

## Usage

``` r
process_enr(df, end_year)
```

## Arguments

- df:

  Raw data frame from download_cde_excel

- end_year:

  School year end

## Value

Data frame in wide format with standardized columns
