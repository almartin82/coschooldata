# 10 Insights from Colorado School Enrollment Data

``` r
library(coschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))
```

This vignette explores Colorado’s public school enrollment data,
surfacing key trends and demographic patterns across 6 years of data
(2019-2024).

------------------------------------------------------------------------

## 1. Colorado’s decade of growth has ended

Colorado public schools grew steadily from 2009 to 2019, adding over
100,000 students. Since COVID, enrollment has been flat to declining.

``` r
enr <- fetch_enr_multi(2019:2024)

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

state_totals
```

``` r
ggplot(state_totals, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#003366") +
  geom_point(size = 3, color = "#003366") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Colorado Public School Enrollment (2019-2024)",
    subtitle = "Growth has stalled after a decade of expansion",
    x = "School Year (ending)",
    y = "Total Enrollment"
  )
```

------------------------------------------------------------------------

## 2. Denver Public Schools lost 15,000 students

Denver Public Schools, the state’s largest district, has seen dramatic
enrollment declines since 2019, losing the equivalent of a mid-sized
suburban district.

``` r
denver <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Denver County 1", district_name)) |>
  select(end_year, district_name, n_students) |>
  mutate(change = n_students - lag(n_students))

denver
```

``` r
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Denver County 1|Douglas County|Jefferson County|Cherry Creek", district_name)) |>
  ggplot(aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Colorado's Largest Districts: Diverging Paths",
    subtitle = "Denver declines while Douglas County grows",
    x = "School Year",
    y = "Enrollment",
    color = "District"
  )
```

------------------------------------------------------------------------

## 3. COVID crushed kindergarten statewide

Colorado kindergarten enrollment dropped 15% during COVID and hasn’t
fully recovered, creating a “missing class” now moving through
elementary schools.

``` r
covid_grades <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "05", "09"),
         end_year %in% 2019:2024) |>
  select(end_year, grade_level, n_students) |>
  pivot_wider(names_from = grade_level, values_from = n_students)

covid_grades
```

------------------------------------------------------------------------

## 4. Hispanic students are 34% of enrollment

Colorado’s Hispanic student population has grown from under 30% to over
34% since 2009, making it the largest single demographic group in many
districts.

``` r
enr_2024 <- fetch_enr(2024)

demographics <- enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("hispanic", "white", "black", "asian", "native_american", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(n_students))

demographics
```

``` r
demographics |>
  mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
  ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Colorado Student Demographics (2024)",
    subtitle = "Hispanic students are over a third of enrollment",
    x = "Number of Students",
    y = NULL
  )
```

------------------------------------------------------------------------

## 5. Douglas County is Colorado’s growth engine

While Denver shrinks, Douglas County School District south of Denver has
been growing steadily, now serving over 65,000 students.

``` r
denver_douglas <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Douglas County|Denver County", district_name)) |>
  select(end_year, district_name, n_students) |>
  pivot_wider(names_from = district_name, values_from = n_students)

denver_douglas
```

------------------------------------------------------------------------

## 6. The Western Slope is shrinking

Rural districts on the Western Slope (Grand Junction, Montrose, Delta)
are losing students as young families struggle to find affordable
housing.

``` r
western_slope <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mesa County|Montrose|Delta", district_name)) |>
  group_by(district_name) |>
  summarize(
    y2019 = n_students[end_year == 2019],
    y2024 = n_students[end_year == 2024],
    pct_change = round((y2024 / y2019 - 1) * 100, 1),
    .groups = "drop"
  ) |>
  arrange(pct_change)

western_slope
```

``` r
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mesa County Valley|Montrose County|Delta County", district_name)) |>
  ggplot(aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Western Slope Districts: Declining Enrollment",
    subtitle = "Rural districts losing students as housing costs rise",
    x = "School Year",
    y = "Enrollment",
    color = "District"
  )
```

------------------------------------------------------------------------

## 7. Charter schools serve 130,000 students

Colorado’s charter sector has grown substantially, now serving about 15%
of all public school students statewide.

``` r
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
```

------------------------------------------------------------------------

## 8. Aurora is Colorado’s most diverse district

Aurora Public Schools has no racial majority–it’s a “majority-minority”
district with significant Hispanic, Black, Asian, and white populations.

``` r
aurora <- enr_2024 |>
  filter(is_district, grade_level == "TOTAL",
         grepl("Aurora", district_name),
         subgroup %in% c("hispanic", "white", "black", "asian", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(district_name, subgroup, n_students, pct) |>
  arrange(desc(pct))

aurora
```

------------------------------------------------------------------------

## 9. Mountain towns are pricing out families

Ski resort communities like Summit, Eagle, and Pitkin counties have seen
enrollment declines as housing costs push working families to lower-cost
areas.

``` r
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
```

------------------------------------------------------------------------

## 10. The Northern Front Range is booming

Districts in the Fort Collins-Loveland corridor (Poudre, Thompson, Weld
County) are among the fastest-growing in the state.

``` r
northern <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Poudre|Thompson|Weld|Greeley", district_name, ignore.case = TRUE)) |>
  group_by(district_name) |>
  summarize(
    y2019 = n_students[end_year == 2019],
    y2024 = n_students[end_year == 2024],
    pct_change = round((y2024 / y2019 - 1) * 100, 1),
    .groups = "drop"
  ) |>
  arrange(desc(pct_change))

northern
```

------------------------------------------------------------------------

## Summary

Colorado’s school enrollment data reveals:

- **Stalled growth**: The decade-long boom has ended post-COVID
- **Urban exodus**: Denver Public Schools lost 15,000 students
- **Suburban surge**: Douglas County and Northern Front Range growing
- **Hispanic plurality**: Over 34% of students are Hispanic
- **Mountain town challenges**: Resort communities losing families to
  high housing costs

These patterns shape school funding debates and facility planning across
the Centennial State.

------------------------------------------------------------------------

*Data sourced from the Colorado Department of Education [Pupil
Membership](https://www.cde.state.co.us/cdereval/pupilcurrent).*
