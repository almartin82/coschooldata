# coschooldata: Fetch and Process Colorado School Data

Downloads and processes school data from the Colorado Department of
Education (CDE). Provides functions for fetching enrollment data from
the Student October Count collection and transforming it into tidy
format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/coschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/coschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`get_available_years`](https://almartin82.github.io/coschooldata/reference/get_available_years.md):

  Get available year range for data

## ID System

Colorado uses a hierarchical ID system:

- District IDs: 4 digits (e.g., 0880 = Denver County 1)

- School IDs: 4 digits (unique within district context)

## Data Sources

Data is sourced from the Colorado Department of Education:

- Pupil Membership: <https://www.cde.state.co.us/cdereval/pupilcurrent>

- Data Archive:
  <https://ed.cde.state.co.us/cdereval/pupilmembership-statistics>

## Data Availability

The package currently supports years 2020-2025. Data comes from the
Student October Count collection published by CDE. Use
[`get_available_years()`](https://almartin82.github.io/coschooldata/reference/get_available_years.md)
to check the current available range.

## See also

Useful links:

- <https://almartin82.github.io/coschooldata>

- <https://github.com/almartin82/coschooldata>

- Report bugs at <https://github.com/almartin82/coschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
