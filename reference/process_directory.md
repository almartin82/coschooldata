# Process raw school directory data to standard schema

Takes raw school directory data from CDE and standardizes column names,
types, and combines schools and districts into a single data frame.

## Usage

``` r
process_directory(raw_data)
```

## Arguments

- raw_data:

  List with schools and districts data frames from get_raw_directory()

## Value

Processed data frame with standard schema
