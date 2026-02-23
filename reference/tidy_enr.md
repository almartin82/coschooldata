# Tidy enrollment data

Transforms wide enrollment data to long format with subgroup column.
Creates district-level and state-level aggregates from school-level
data. Adds standard entity flags: is_state, is_district, is_school,
is_charter.

## Usage

``` r
tidy_enr(df)
```

## Arguments

- df:

  A wide data.frame of processed enrollment data

## Value

A long data.frame of tidied enrollment data with standard columns:
end_year, district_id, district_name, campus_id, campus_name,
grade_level, subgroup, n_students, pct, is_state, is_district,
is_school, is_charter
