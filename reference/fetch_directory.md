# Fetch Colorado school directory data

Downloads and processes school and district directory data from the
Colorado Department of Education. This includes all public schools and
districts with contact information, addresses, and grade level
information.

## Usage

``` r
fetch_directory(end_year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  Currently unused. The directory data represents current schools and is
  not year-specific. Included for API consistency with other fetch
  functions.

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from CDE.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from CDE.

## Value

A tibble with school directory data. Columns include:

- `state_school_id`: Combined district + school code (8 digits)

- `state_district_id`: 4-digit district code

- `school_code`: 4-digit school code

- `school_name`: School name

- `district_name`: District name

- `school_type`: Type of school (District, School)

- `grades_served`: Low grade - High grade

- `low_grade`: Lowest grade served

- `high_grade`: Highest grade served

- `address`: Physical street address

- `city`: City

- `state`: State (always "CO")

- `zip`: ZIP code

- `phone`: Phone number

- `charter_status`: Charter indicator (Y/N)

- `agg_level`: Aggregation level ("S" = School, "D" = District)

## Details

The directory data is downloaded as Excel files from the CDE CEDAR
library. School addresses and district addresses are downloaded
separately and combined. This data represents the current state of
Colorado schools and districts and is updated regularly by CDE.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory data
dir_data <- fetch_directory()

# Get raw format (original CDE column names)
dir_raw <- fetch_directory(tidy = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(use_cache = FALSE)

# Filter to schools only
library(dplyr)
schools <- dir_data |>
  filter(agg_level == "S")

# Find all schools in a district
denver_schools <- dir_data |>
  filter(state_district_id == "0880", agg_level == "S")
} # }
```
