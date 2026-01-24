# Get available assessment years

Returns information about which school years have assessment data
available.

## Usage

``` r
get_available_assessment_years()
```

## Value

A list with:

- years:

  Vector of available end years (e.g., 2024 for 2023-24)

- note:

  Information about data gaps (e.g., 2020)

- assessment_system:

  Current assessment system name

## Examples

``` r
get_available_assessment_years()
#> $years
#>  [1] 2015 2016 2017 2018 2019 2021 2022 2023 2024 2025
#> 
#> $note
#> [1] "2020 data not available due to COVID-19 testing waiver"
#> 
#> $assessment_system
#> [1] "CMAS (Colorado Measures of Academic Success)"
#> 
#> $subjects
#> [1] "ELA"            "Math"           "Science"        "Social Studies"
#> [5] "CSLA"          
#> 
```
