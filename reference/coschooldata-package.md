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

- `tidy_enr`:

  Transform wide data to tidy (long) format

- `id_enr_aggs`:

  Add aggregation level flags

- `enr_grade_aggs`:

  Create grade-level aggregations

## Cache functions

- [`cache_status`](https://almartin82.github.io/coschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/coschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Colorado uses a hierarchical ID system:

- District IDs: 4 digits (e.g., 0880 = Denver County 1)

- School IDs: 4 digits (unique within district context)

## Data Sources

Data is sourced from the Colorado Department of Education:

- Pupil Membership: <https://www.cde.state.co.us/cdereval/pupilcurrent>

- Data Pipeline: <https://www.cde.state.co.us/datapipeline>

## Data Availability

The package supports three format eras:

- 2009-2018: Excel files with older column format

- 2019-2023: Excel files with modern column naming

- 2024+: Current format with enhanced school flags

## See also

Useful links:

- <https://almartin82.github.io/coschooldata>

- <https://github.com/almartin82/coschooldata>

- Report bugs at <https://github.com/almartin82/coschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
