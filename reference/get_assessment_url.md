# Get assessment URL for a given year and file type

Constructs the URL for downloading CMAS assessment data from CDE.

## Usage

``` r
get_assessment_url(end_year, file_type)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24)

- file_type:

  One of "ela", "math", "science", "csla", "ela_math_state",
  "ela_math_district_school", "science_state", "science_district_school"

## Value

URL string or NULL if not found
