# Calculate proficiency rates from tidy assessment data

Summarizes tidy assessment data to get proficiency rates (Met +
Exceeded).

## Usage

``` r
proficiency_rates(df, ...)
```

## Arguments

- df:

  Tidy assessment data frame from tidy_assessment

- ...:

  Grouping variables (unquoted)

## Value

Data frame with proficiency rates

## Examples

``` r
if (FALSE) { # \dontrun{
assess <- fetch_assessment(2024)
proficiency_rates(assess, end_year, subject, grade)
} # }
```
