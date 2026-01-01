# coschooldata

Fetch and analyze Colorado school enrollment data from the Colorado
Department of Education (CDE) in R or Python.

**[Documentation](https://almartin82.github.io/coschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/coschooldata/articles/quickstart.html)**

## What can you find with coschooldata?

**17 years of enrollment data (2009-2025).** 880,000 students across 180
districts in the Centennial State. Here are ten stories hiding in the
numbers:

------------------------------------------------------------------------

### 1. Colorado’s decade of growth has ended

Colorado public schools grew steadily from 2009 to 2019, adding over
100,000 students. Since COVID, enrollment has been flat to declining.

``` r
library(coschooldata)
library(dplyr)

enr <- fetch_enr_multi(2009:2025)

enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students))
```

------------------------------------------------------------------------

### 2. Denver Public Schools lost 15,000 students

Denver Public Schools, the state’s largest district, has seen dramatic
enrollment declines since 2019, losing the equivalent of a mid-sized
suburban district.

``` r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Denver County 1", district_name)) %>%
  select(end_year, district_name, n_students) %>%
  mutate(change = n_students - lag(n_students))
```

------------------------------------------------------------------------

### 3. COVID crushed kindergarten statewide

Colorado kindergarten enrollment dropped 15% during COVID and hasn’t
fully recovered, creating a “missing class” now moving through
elementary schools.

``` r
enr <- fetch_enr_multi(2019:2025)

enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "05", "09")) %>%
  select(end_year, grade_level, n_students) %>%
  tidyr::pivot_wider(names_from = grade_level, values_from = n_students)
```

------------------------------------------------------------------------

### 4. Douglas County is Colorado’s growth engine

While Denver shrinks, Douglas County School District south of Denver has
been growing steadily, now serving over 65,000 students.

``` r
enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Douglas County|Denver County", district_name)) %>%
  select(end_year, district_name, n_students) %>%
  tidyr::pivot_wider(names_from = district_name, values_from = n_students)
```

------------------------------------------------------------------------

### 5. Hispanic students are 34% of enrollment

Colorado’s Hispanic student population has grown from under 30% to over
34% since 2009, making it the largest single demographic group in many
districts.

``` r
enr_2025 <- fetch_enr(2025)

enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "native_american", "multiracial")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(n_students))
```

------------------------------------------------------------------------

### 6. The Western Slope is shrinking

Rural districts on the Western Slope (Grand Junction, Montrose, Delta)
are losing students as young families struggle to find affordable
housing.

``` r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mesa County|Montrose|Delta", district_name)) %>%
  group_by(district_name) %>%
  summarize(
    y2015 = n_students[end_year == 2015],
    y2025 = n_students[end_year == 2025],
    pct_change = round((y2025 / y2015 - 1) * 100, 1)
  ) %>%
  arrange(pct_change)
```

------------------------------------------------------------------------

### 7. Charter schools serve 130,000 students

Colorado’s charter sector has grown substantially, now serving about 15%
of all public school students statewide.

``` r
enr_2025 %>%
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  summarize(charter_total = sum(n_students, na.rm = TRUE))
```

------------------------------------------------------------------------

### 8. Aurora is Colorado’s most diverse district

Aurora Public Schools has no racial majority–it’s a “majority-minority”
district with significant Hispanic, Black, Asian, and white populations.

``` r
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL",
         grepl("Aurora", district_name),
         subgroup %in% c("hispanic", "white", "black", "asian", "multiracial")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(district_name, subgroup, n_students, pct) %>%
  arrange(desc(pct))
```

------------------------------------------------------------------------

### 9. Mountain towns are pricing out families

Ski resort communities like Summit, Eagle, and Pitkin counties have seen
enrollment declines as housing costs push working families to lower-cost
areas.

``` r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Summit|Eagle County|Aspen|Vail", district_name, ignore.case = TRUE)) %>%
  group_by(district_name) %>%
  filter(n() > 5) %>%
  summarize(
    earliest = n_students[end_year == min(end_year)],
    latest = n_students[end_year == max(end_year)],
    pct_change = round((latest / earliest - 1) * 100, 1)
  ) %>%
  arrange(pct_change)
```

------------------------------------------------------------------------

### 10. The Northern Front Range is booming

Districts in the Fort Collins-Loveland corridor (Poudre, Thompson, Weld
County) are among the fastest-growing in the state.

``` r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Poudre|Thompson|Weld|Greeley", district_name, ignore.case = TRUE)) %>%
  group_by(district_name) %>%
  summarize(
    y2015 = n_students[end_year == 2015],
    y2025 = n_students[end_year == 2025],
    pct_change = round((y2025 / y2015 - 1) * 100, 1)
  ) %>%
  arrange(desc(pct_change))
```

------------------------------------------------------------------------

## Enrollment Visualizations

![Colorado statewide enrollment
trends](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png)

![Top Colorado
districts](https://almartin82.github.io/coschooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png)

See the [full
vignette](https://almartin82.github.io/coschooldata/articles/enrollment_hooks.html)
for more insights.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/coschooldata")
```

## Quick start

### R

``` r
library(coschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian")) %>%
  select(subgroup, n_students, pct)
```

### Python

``` python
import pycoschooldata as co

# Fetch one year
enr_2025 = co.fetch_enr(2025)

# Fetch multiple years
enr_multi = co.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])

# State totals
state_total = enr_2025[
    (enr_2025['is_state'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
]

# District breakdown
districts = enr_2025[
    (enr_2025['is_district'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False)

# Demographics
demographics = enr_2025[
    (enr_2025['is_state'] == True) &
    (enr_2025['grade_level'] == 'TOTAL') &
    (enr_2025['subgroup'].isin(['hispanic', 'white', 'black', 'asian']))
][['subgroup', 'n_students', 'pct']]
```

## Data availability

| Years         | Source               | Notes                              |
|---------------|----------------------|------------------------------------|
| **2009-2018** | CDE Pupil Membership | Older column format                |
| **2019-2023** | CDE Pupil Membership | Modern column naming               |
| **2024-2025** | CDE Pupil Membership | Current format with enhanced flags |

Data is sourced from the Colorado Department of Education Student
October Count.

### What’s included

- **Levels:** State, district (~180), school (~1,900)
- **Demographics:** Hispanic, White, Black, Asian, Native American,
  Pacific Islander, Two or More Races
- **Special populations:** Free/reduced lunch eligible, English learners
- **Grade levels:** K-12

### Colorado ID system

- **District IDs:** 4 digits (e.g., 0880 = Denver County 1)
- **School IDs:** 4 digits unique within district context

## Data source

Colorado Department of Education: [Pupil
Membership](https://www.cde.state.co.us/cdereval/pupilcurrent)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT
