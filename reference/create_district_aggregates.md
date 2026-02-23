# Create district-level aggregates from school-level data

Sums school-level data within each district to create district totals.
Always aggregates from school-level data to ensure all districts are
covered (legacy format only has sparse district-level rows for ~9
districts).

## Usage

``` r
create_district_aggregates(school_tidy, wide_df)
```

## Arguments

- school_tidy:

  Long format data (may include sparse district rows)

- wide_df:

  Original wide data (unused, kept for API compatibility)

## Value

Data frame of district-level tidy rows
