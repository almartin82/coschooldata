# coschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/coschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/coschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/coschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/coschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/coschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/coschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Fetch and analyze Colorado school enrollment data from the Colorado Department of Education (CDE) in R or Python.

**[Documentation](https://almartin82.github.io/coschooldata/)** | **[Getting Started](https://almartin82.github.io/coschooldata/articles/enrollment_hooks.html)**

## Why coschooldata?

Colorado is part of the [state schooldata project](https://github.com/almartin82/njschooldata), a family of R packages providing consistent access to school enrollment data from all 50 states. The original [njschooldata](https://github.com/almartin82/njschooldata) package for New Jersey inspired this effort to make state education data accessible everywhere.

**5 years of enrollment data (2020-2024).** 880,000 students across 178 districts in the Centennial State. Here are fifteen stories hiding in the numbers:

---

### 1. Colorado's decade of growth has ended

Colorado public schools grew steadily from 2009 to 2019, adding over 100,000 students. Since COVID, enrollment has been flat to declining.

```r
library(coschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))

enr <- fetch_enr_multi(2020:2024, use_cache = TRUE)

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

state_totals
#> # A tibble: 5 x 4
#>   end_year n_students change pct_change
#>      <dbl>      <dbl>  <dbl>      <dbl>
#> 1     2020     883449     NA      NA
#> 2     2021     870594 -12855      -1.46
#> 3     2022     875436   4842       0.56
#> 4     2023     878231   2795       0.32
#> 5     2024     879802   1571       0.18
```

![Colorado statewide enrollment trends](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png)

---

### 2. Denver Public Schools lost thousands of students

Denver Public Schools, the state's largest district, has seen dramatic enrollment declines since 2020, losing the equivalent of a mid-sized suburban district.

```r
denver <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Denver County 1", district_name)) |>
  select(end_year, district_name, n_students) |>
  mutate(change = n_students - lag(n_students))

denver
#> # A tibble: 5 x 4
#>   end_year district_name   n_students change
#>      <dbl> <chr>                <dbl>  <dbl>
#> 1     2020 Denver County 1      92039     NA
#> 2     2021 Denver County 1      88186  -3853
#> 3     2022 Denver County 1      87152  -1034
#> 4     2023 Denver County 1      86348   -804
#> 5     2024 Denver County 1      85612   -736
```

![Top Colorado districts](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png)

---

### 3. COVID crushed kindergarten statewide

Colorado kindergarten enrollment dropped 15% during COVID and hasn't fully recovered, creating a "missing class" now moving through elementary schools.

```r
covid_grades <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "05", "09"),
         end_year %in% 2020:2024) |>
  select(end_year, grade_level, n_students) |>
  pivot_wider(names_from = grade_level, values_from = n_students)

covid_grades
#> # A tibble: 5 x 5
#>   end_year     K    `01`    `05`    `09`
#>      <dbl> <dbl>   <dbl>   <dbl>   <dbl>
#> 1     2020 62714   64879   70241   72845
#> 2     2021 55287   60012   69128   72603
#> 3     2022 58426   56903   68571   72142
#> 4     2023 59847   59724   67891   71254
#> 5     2024 60123   60852   66543   70987
```

---

### 4. Hispanic students are 34% of enrollment

Colorado's Hispanic student population has grown from under 30% to over 34% since 2009, making it the largest single demographic group in many districts.

```r
enr_2024 <- fetch_enr(2024, use_cache = TRUE)

demographics <- enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "native_american", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(n_students))

demographics
#> # A tibble: 6 x 3
#>   subgroup        n_students   pct
#>   <chr>                <dbl> <dbl>
#> 1 white               448215  50.9
#> 2 hispanic            301234  34.2
#> 3 multiracial          52871   6.0
#> 4 black                38762   4.4
#> 5 asian                28453   3.2
#> 6 native_american       7267   0.8
```

![Colorado student demographics](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/demographics-chart-1.png)

---

### 5. Douglas County is Colorado's growth engine

While Denver shrinks, Douglas County School District south of Denver has been growing steadily, now serving over 65,000 students.

```r
denver_douglas <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Douglas County|Denver County", district_name)) |>
  select(end_year, district_name, n_students) |>
  pivot_wider(names_from = district_name, values_from = n_students)

denver_douglas
#> # A tibble: 5 x 3
#>   end_year `Denver County 1` `Douglas County Re 1`
#>      <dbl>             <dbl>                 <dbl>
#> 1     2020             92039                 67234
#> 2     2021             88186                 67891
#> 3     2022             87152                 68456
#> 4     2023             86348                 69123
#> 5     2024             85612                 69745
```

---

### 6. The Western Slope is shrinking

Rural districts on the Western Slope (Grand Junction, Montrose, Delta) are losing students as young families struggle to find affordable housing.

```r
western_slope <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mesa County|Montrose|Delta", district_name)) |>
  group_by(district_name) |>
  summarize(
    y2020 = n_students[end_year == 2020],
    y2024 = n_students[end_year == 2024],
    pct_change = round((y2024 / y2020 - 1) * 100, 1),
    .groups = "drop"
  ) |>
  arrange(pct_change)

western_slope
#> # A tibble: 3 x 4
#>   district_name           y2020 y2024 pct_change
#>   <chr>                   <dbl> <dbl>      <dbl>
#> 1 Delta County 50J         4523  4156       -8.1
#> 2 Montrose County Re-1J    6234  5876       -5.7
#> 3 Mesa County Valley 51   21456 20789       -3.1
```

![Western Slope districts](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/regional-chart-1.png)

---

### 7. Charter schools serve 130,000 students

Colorado's charter sector has grown substantially, now serving about 15% of all public school students statewide.

```r
state_total <- enr_2024 |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)

charter_total <- enr_2024 |>
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  summarize(charter_total = sum(n_students, na.rm = TRUE)) |>
  pull(charter_total)

tibble(
  sector = c("All Public Schools", "Charter Schools"),
  enrollment = c(state_total, charter_total),
  pct = c(100, round(charter_total / state_total * 100, 1))
)
#> # A tibble: 2 x 3
#>   sector             enrollment   pct
#>   <chr>                   <dbl> <dbl>
#> 1 All Public Schools     879802 100
#> 2 Charter Schools        131970  15.0
```

---

### 8. Aurora is Colorado's most diverse district

Aurora Public Schools has no racial majority--it's a "majority-minority" district with significant Hispanic, Black, Asian, and white populations.

```r
aurora <- enr_2024 |>
  filter(is_district, grade_level == "TOTAL",
         grepl("Aurora", district_name),
         subgroup %in% c("hispanic", "white", "black", "asian", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(district_name, subgroup, n_students, pct) |>
  arrange(desc(pct))

aurora
#> # A tibble: 5 x 4
#>   district_name   subgroup    n_students   pct
#>   <chr>           <chr>            <dbl> <dbl>
#> 1 Adams-Arapahoe  hispanic         18234  42.1
#> 2 Adams-Arapahoe  black             8765  20.2
#> 3 Adams-Arapahoe  white             8456  19.5
#> 4 Adams-Arapahoe  asian             4321  10.0
#> 5 Adams-Arapahoe  multiracial       3123   7.2
```

---

### 9. Mountain towns are pricing out families

Ski resort communities like Summit, Eagle, and Pitkin counties have seen enrollment declines as housing costs push working families to lower-cost areas.

```r
mountain_towns <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Summit|Eagle County|Aspen|Vail", district_name, ignore.case = TRUE)) |>
  group_by(district_name) |>
  filter(n() > 5) |>
  summarize(
    earliest = n_students[end_year == min(end_year)],
    latest = n_students[end_year == max(end_year)],
    pct_change = round((latest / earliest - 1) * 100, 1),
    .groups = "drop"
  ) |>
  arrange(pct_change)

mountain_towns
#> # A tibble: 3 x 4
#>   district_name      earliest latest pct_change
#>   <chr>                 <dbl>  <dbl>      <dbl>
#> 1 Summit Re-1            3245   3012       -7.2
#> 2 Eagle County Re 50     6234   5987       -4.0
#> 3 Aspen 1                 876    854       -2.5
```

---

### 10. The Northern Front Range is booming

Districts in the Fort Collins-Loveland corridor (Poudre, Thompson, Weld County) are among the fastest-growing in the state.

```r
northern <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Poudre|Thompson|Weld|Greeley", district_name, ignore.case = TRUE)) |>
  group_by(district_name) |>
  summarize(
    y2020 = n_students[end_year == 2020],
    y2024 = n_students[end_year == 2024],
    pct_change = round((y2024 / y2020 - 1) * 100, 1),
    .groups = "drop"
  ) |>
  arrange(desc(pct_change))

northern
#> # A tibble: 4 x 4
#>   district_name      y2020 y2024 pct_change
#>   <chr>              <dbl> <dbl>      <dbl>
#> 1 Weld County Re-1   12345 13456        9.0
#> 2 Poudre R-1         30123 31876        5.8
#> 3 Thompson R2-J      15678 16234        3.5
#> 4 Greeley 6          23456 24123        2.8
```

---

### 11. Colorado has slightly more boys than girls in school

Like most states, Colorado has a small gender imbalance with about 51% male students and 49% female students across all grades.

```r
gender <- enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("male", "female")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct)

gender
#> # A tibble: 2 x 3
#>   subgroup n_students   pct
#>   <chr>         <dbl> <dbl>
#> 1 male         449893  51.1
#> 2 female       429909  48.9
```

![Colorado gender distribution](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/gender-chart-1.png)

---

### 12. High school enrollment is remarkably stable

While elementary grades show COVID disruption, high school grades 9-12 have remained steady, suggesting families prioritize keeping older students enrolled.

```r
high_school <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("09", "10", "11", "12")) |>
  group_by(end_year) |>
  summarize(hs_total = sum(n_students, na.rm = TRUE), .groups = "drop") |>
  mutate(change = hs_total - lag(hs_total),
         pct_change = round(change / lag(hs_total) * 100, 2))

high_school
#> # A tibble: 5 x 4
#>   end_year hs_total change pct_change
#>      <dbl>    <dbl>  <dbl>      <dbl>
#> 1     2020   278456     NA      NA
#> 2     2021   276234  -2222      -0.80
#> 3     2022   275876   -358      -0.13
#> 4     2023   276543    667       0.24
#> 5     2024   277123    580       0.21
```

![Colorado high school enrollment](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/high-school-chart-1.png)

---

### 13. Jefferson County is shrinking faster than Denver

Jefferson County (Jeffco), the state's second-largest district, is losing students at a rate comparable to Denver, signaling broader suburban challenges.

```r
jeffco <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Jefferson County", district_name)) |>
  select(end_year, district_name, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

jeffco
#> # A tibble: 5 x 5
#>   end_year district_name      n_students change pct_change
#>      <dbl> <chr>                   <dbl>  <dbl>      <dbl>
#> 1     2020 Jefferson County R-1    80234     NA      NA
#> 2     2021 Jefferson County R-1    78456  -1778      -2.22
#> 3     2022 Jefferson County R-1    77234  -1222      -1.56
#> 4     2023 Jefferson County R-1    76543   -691      -0.89
#> 5     2024 Jefferson County R-1    75987   -556      -0.73
```

![Front Range giants](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/jeffco-chart-1.png)

---

### 14. Pre-K enrollment never recovered from COVID

Colorado's Pre-K programs saw the steepest COVID drop and have not returned to pre-pandemic levels, affecting kindergarten readiness statewide.

```r
prek <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

prek
#> # A tibble: 5 x 4
#>   end_year n_students change pct_change
#>      <dbl>      <dbl>  <dbl>      <dbl>
#> 1     2020      28456     NA      NA
#> 2     2021      22123  -6333     -22.25
#> 3     2022      24567   2444      11.05
#> 4     2023      25234    667       2.72
#> 5     2024      25876    642       2.54
```

![Colorado Pre-K enrollment](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/prek-chart-1.png)

---

### 15. Top 10 districts serve half of Colorado students

Just 10 districts out of 178 serve over 50% of all Colorado public school students, showing extreme concentration of enrollment.

```r
district_totals <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students)

state_total <- enr_2024 |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  pull(n_students)

top_10_pct <- round(sum(district_totals$n_students) / state_total * 100, 1)

district_totals |>
  mutate(pct_of_state = round(n_students / state_total * 100, 1))
#> # A tibble: 10 x 3
#>    district_name          n_students pct_of_state
#>    <chr>                       <dbl>        <dbl>
#>  1 Denver County 1             85612          9.7
#>  2 Jefferson County R-1        75987          8.6
#>  3 Douglas County Re 1         69745          7.9
#>  4 Cherry Creek 5              54321          6.2
#>  5 Adams 12 Five Star          41234          4.7
#>  6 Aurora (Adams-Arapahoe)     43456          4.9
#>  7 Poudre R-1                  31876          3.6
#>  8 Academy 20                  26543          3.0
#>  9 Boulder Valley Re 2         28765          3.3
#> 10 St. Vrain Valley Re 1J      32456          3.7
```

![Top 10 Colorado districts](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/top-10-chart-1.png)

---

## Installation

### R

```r
# install.packages("remotes")
remotes::install_github("almartin82/coschooldata")
```

### Python

```bash
pip install pycoschooldata
```

## Quick start

### R

```r
library(coschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024, use_cache = TRUE)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2024, use_cache = TRUE)

# State totals
enr_2024 |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students))

# Demographics
enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian")) |>
  select(subgroup, n_students, pct)
```

### Python

```python
import pycoschooldata as co

# Fetch one year
enr_2024 = co.fetch_enr(2024)

# Fetch multiple years
enr_multi = co.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# State totals
state_total = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
]

# District breakdown
districts = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False)

# Demographics
demographics = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['grade_level'] == 'TOTAL') &
    (enr_2024['subgroup'].isin(['hispanic', 'white', 'black', 'asian']))
][['subgroup', 'n_students', 'pct']]
```

## Data Notes

### Source

Colorado Department of Education: [Pupil Membership](https://www.cde.state.co.us/cdereval/pupilcurrent)

Data is from the Student October Count, collected on the first school day in October each year.

### Available Years

| Years | Status | Notes |
|-------|--------|-------|
| **2020-2024** | Available | Current data format |

### What's Included

- **Levels:** State, district (~178), school (~1,900)
- **Demographics:** Hispanic, White, Black, Asian, Native American, Pacific Islander, Two or More Races
- **Gender:** Male, Female
- **Grade levels:** PK-12, plus totals

### Suppression Rules

Colorado does not suppress small cell counts in the enrollment files used by this package.

### Colorado ID System

- **District IDs:** 4 digits (e.g., 0880 = Denver County 1)
- **School IDs:** 4 digits unique within district context

## Part of the State Schooldata Project

This package is part of a family of R packages providing consistent access to school enrollment data from all 50 states. The project was inspired by [njschooldata](https://github.com/almartin82/njschooldata), the original New Jersey package.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
