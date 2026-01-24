# Add aggregation flags to assessment data

Identifies whether each row is state, district, or school level data.

## Usage

``` r
id_assessment_aggs(df)
```

## Arguments

- df:

  Data frame with district_id and school_id columns

## Value

Data frame with is_state, is_district, is_school flags
