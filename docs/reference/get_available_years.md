# Get available years for Colorado enrollment data

Returns the range of school years for which enrollment data is available
from the Colorado Department of Education. Uses URL discovery to
determine which years have working data files.

## Usage

``` r
get_available_years()
```

## Value

A list with three elements:

- min_year:

  The earliest available school year end (e.g., 2020 for 2019-20)

- max_year:

  The latest available school year end (e.g., 2025 for 2024-25)

- description:

  Human-readable description of data availability

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 2020
#> 
#> $max_year
#> [1] 2025
#> 
#> $description
#> [1] "Colorado enrollment data is available from 2019-20 (end_year 2020) through 2024-25 (end_year 2025). Data comes from the Student October Count collection published by the Colorado Department of Education. Note: Earlier years (2018-2019) may be available but use inconsistent URL patterns."
#> 
# Returns list with min_year, max_year, and description
```
