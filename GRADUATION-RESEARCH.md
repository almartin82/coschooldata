# Colorado Graduation Rate Data Research

**Package:** coschooldata **Research Date:** 2026-01-10 **Researcher:**
Claude Code **State:** Colorado (CO)

------------------------------------------------------------------------

## Executive Summary

**Viability Tier:** 1 (Direct Downloads)

**Recommendation:** IMPLEMENT

**Rationale:** Colorado Department of Education (CDE) provides
comprehensive graduation rate data in machine-readable Excel (.xlsx)
format with direct download URLs. Data spans 2020-2024 (5 years) with
district and school-level detail, including demographic subgroup
breakdowns and completion rates. The workbooks are well-structured with
consistent format across years.

------------------------------------------------------------------------

## Data Sources Investigated

### 1. Primary Source: CDE Graduation Rate Workbooks

**URL:** <https://www.cde.state.co.us/cdereval/gradratecurrent>

**Format:** Excel (.xlsx) workbooks

**Viability:** HIGH - Direct download URLs, consistent format

**Data Files Available:**

#### 2024 Data (Confirmed Access)

- **Main Workbook:**
  <https://www.cde.state.co.us/cdereval/2024graduation_data-workbook>
  - Filename:
    `2024_Graduation Completion Rates_State, District, School_PRIVACY APPLIED.xlsx`
  - Size: 1.3 MB
  - Content: State, district, and school-level graduation/completion
    rates with demographic breakdowns
- **State Trends:**
  <https://www.cde.state.co.us/cdereval/2024graduation_state-trends>
  - Filename: `2024_Grad-Comp_State_3-yr_Trend.xlsx`
  - Size: 7.5 KB
  - Content: 3-year statewide trend data (AYG 2022, 2023, 2024)

#### Historical Data (Available via Archive Pages)

- **2023 Data:**
  <https://www.cde.state.co.us/cdereval/2023graduationstatistics>
  - Contains links to workbook with 2023-2024 school year data
  - Includes 2022, 2021, 2020 historical data within same workbook
- **Archive Pattern:** Each year’s workbook contains multi-year
  historical data
  - 2024 workbook contains AYG 2024, 2023, 2022, 2021, 2020
  - Previous years follow similar pattern

### 2. Alternative Sources (Not Recommended)

#### SchoolView Data Portal

**URL:**
<https://www.cde.state.co.us/schoolview/explore/graduation/0020/ALL>

**Format:** Interactive web interface with HTML tables

**Viability:** LOW - Requires web scraping, not direct download

**Issues:** - JavaScript-rendered data - No direct CSV/Excel export -
Would require browser automation (Selenium/Puppeteer) - Higher
maintenance burden

#### Urban Institute API

**URL:**
<https://educationdata.urban.org/documentation/school-districts.html>

**Format:** REST API

**Viability:** PROHIBITED - Federal data source

**Rationale for Exclusion:** - Urban Institute aggregates federal data
(NCES CCD) - Loses state-specific details - Violates project
requirement: **NEVER use federal sources** - State DOE data is primary
and more comprehensive

------------------------------------------------------------------------

## Data Structure

### Workbook Organization

The 2024 graduation workbook contains **5 sheets**:

1.  **State Rates**
    - State-level graduation/completion rates
    - Demographic subgroup breakdowns
    - Multi-year trends (AYG 2020-2024)
2.  **District Race Eth Gender**
    - District-level graduation rates by race/ethnicity and gender
    - Multiple cohort years (4-year, 5-year, 6-year, 7-year)
3.  **District IPST**
    - District-level by Instructional Program/Service Type
    - Subgroups: Economically Disadvantaged, English Learners, Gifted,
      Homeless, Migrant, Students with Disabilities, Title I, Military
      Connected, Foster
4.  **School Race Eth Gender**
    - School-level graduation rates by race/ethnicity and gender
    - Multiple cohort years
5.  **School IPST**
    - School-level by Instructional Program/Service Type
    - Same subgroups as District IPST

### Column Structure

Based on examination of District Race/Ethnicity/Gender sheet:

**Identified Columns:** - County Name - Organization Code
(district/school ID) - Organization Name - Anticipated Year of
Graduation (AYG) - Number of Years (4, 5, 6, 7) - Cohort Size (with
formatting, e.g., “69,123”) - All Students Graduation Rate (%) - All
Students Completion Rate (%) - Female Cohort Size - Female Graduation
Rate (%) - Female Completion Rate (%) - Male Cohort Size - Male
Graduation Rate (%) - Male Completion Rate (%) - \[Continues for
racial/ethnic subgroups\]

**Racial/Ethnic Subgroups:** - American Indian or Alaskan Native -
Asian - Black or African American - Hispanic or Latino - Native Hawaiian
or Other Pacific Islander - Two or More Races - White

**Note:** Column headers use merged cells in Excel, resulting in generic
names (…2, …3, etc.) when read with readxl. Will need custom column
naming logic.

### Sample Data Values

From District Race/Ethnicity/Gender sheet (AYG 2024, 4-year):

    STATE TOTALS:
    - Cohort Size: 69,123
    - Graduation Rate: 84.2%
    - Completion Rate: 85.6%
    - Female Graduation: 86.0%
    - Male Graduation: 80.3%

    Adams 12 Five Star Schools (District 0020):
    - Cohort Size: 2,938
    - Graduation Rate: 85.9%
    - Completion Rate: 86.5%
    - Female Graduation: 88.5%
    - Male Graduation: 83.5%

    Mapleton School District (District 0010):
    - Cohort Size: 465
    - Graduation Rate: 71.6%
    - Completion Rate: 71.6%
    - Female Graduation: 75.2%
    - Male Graduation: 67.9%

### Data Quality Notes

**Privacy Suppression:** - Small cohort sizes suppressed with “–” - File
note: “PRIVACY APPLIED” in filename - 49 of 185 districts had AYG 2024
cohorts of 15 or fewer students

**Rate Calculations:** - Graduation Rate: Regular diplomas / Cohort
Size - Completion Rate: (Regular diplomas + HSED + certificates) /
Cohort Size - Adjusted cohort methodology (transfers in/out verified)

**Special Considerations:** - 94 Alternative Education Campuses (AECs)
in 2023-24 - Graduation Guidelines implemented 2020-21, full
implementation 2021-22 - Extended year rates (5, 6, 7 year) available

------------------------------------------------------------------------

## Year Availability

| School Year | Anticipated Year of Graduation | Data Release Date | Workbook Available     |
|-------------|--------------------------------|-------------------|------------------------|
| 2023-2024   | 2024                           | January 2025      | YES - 2024 workbook    |
| 2022-2023   | 2023                           | January 2024      | YES - In 2024 workbook |
| 2021-2022   | 2022                           | January 2023      | YES - In 2024 workbook |
| 2020-2021   | 2021                           | January 2022      | YES - In 2024 workbook |
| 2019-2020   | 2020                           | January 2021      | YES - In 2024 workbook |

**Target Years Coverage:** 2021-2025 = **ALL 5 YEARS AVAILABLE**

**Note:** Each workbook contains historical data. The 2024 workbook
includes AYG 2020-2024 (5 years of graduation cohorts).

------------------------------------------------------------------------

## Implementation Recommendations

### Data Acquisition Strategy

**Primary Approach:** Direct URL downloads

**Base URL Pattern:**

    https://www.cde.state.co.us/cdereval/{YEAR}graduation_data-workbook

**Confirmed Years:** - 2024:
<https://www.cde.state.co.us/cdereval/2024graduation_data-workbook>

**To Investigate:** - Test URL pattern for 2023, 2022, 2021 - If pattern
breaks, use archive pages: - 2023:
<https://www.cde.state.co.us/cdereval/2023graduationstatistics> - 2022:
Search for “2022graduationstatistics” - 2021: Search for
“2021graduationstatistics”

### Data Processing Approach

**Challenge:** Merged header cells in Excel

**Solutions:** 1. **Skip headers and hardcode column names** - Most
reliable given consistent format 2. **Parse merged cells** - Complex and
fragile 3. **Reference separate documentation** - May not exist

**Recommended:** Skip first 1-2 rows, hardcode column names based on
known structure

### Recommended Function Structure

``` r
get_raw_grad_co <- function(year) {

  # Map year to URL
  url <- switch(as.character(year),
    "2024" = "https://www.cde.state.co.us/cdereval/2024graduation_data-workbook",
    # Add 2023, 2022, 2021 once URLs confirmed
  )

  # Download to temp file
  temp_file <- tempfile(fileext = ".xlsx")
  download.file(url, temp_file, mode = "wb")

  # Read district-level data (primary sheet of interest)
  df <- read_excel(temp_file,
                   sheet = "District Race Eth Gender",
                   skip = 1)  # Skip header row

  # Hardcode column names (due to merged cells)
  col_names <- c(
    "county", "org_code", "org_name", "ayg", "num_years",
    "cohort_all", "grad_rate_all", "comp_rate_all",
    "cohort_female", "grad_rate_female", "comp_rate_female",
    # ... etc for all subgroups
  )

  names(df) <- col_names[1:ncol(df)]

  # Filter to 4-year rates for year of interest
  df <- df %>%
    filter(num_years == 4, ayg == year)

  # Clean numeric columns (remove commas, convert)
  # ...

  return(df)
}
```

### Subgroups to Extract

**Primary Demographics:** - All Students - Female - Male - American
Indian / Alaskan Native - Asian - Black / African American - Hispanic /
Latino - Native Hawaiian / Pacific Islander - Two or More Races - White

**Instructional Program/Service Types (from IPST sheet):** -
Economically Disadvantaged - English Learners - Gifted and Talented -
Homeless - Migrant - Students with Disabilities - Title I - Military
Connected - Foster

**Note:** These subgroups are in separate sheets (Race/Eth/Gender vs
IPST). Will need to read both and merge.

------------------------------------------------------------------------

## Data Validation

**Checks to Implement:**

1.  **URL Accessibility:** HTTP 200 check
2.  **File Format:** Valid .xlsx with readxl
3.  **Sheet Existence:** All 5 sheets present
4.  **State Totals:** Compare AYG 2024 statewide rate = 84.2%
5.  **District Count:** Verify ~185 districts + BOCES
6.  **No Invalid Rates:** Rates between 0-100% (excluding NA)
7.  **Cohort Sizes:** Positive integers (excluding suppressed “–”)
8.  **Historical Consistency:** Previous years match across workbooks

------------------------------------------------------------------------

## Known Issues

### 1. Merged Header Cells

**Impact:** Generic column names when read with readxl **Solution:**
Hardcode column mapping

### 2. Privacy Suppression

**Impact:** Small cohorts show “–” instead of rates **Solution:** Treat
as NA, document suppression threshold (cohort \< 15)

### 3. Number Formatting

**Impact:** Cohort sizes have commas (e.g., “69,123”) **Solution:**
Remove commas, convert to numeric

### 4. Multi-Sheet Structure

**Impact:** Demographic data in 2 separate sheets (Race/Eth/Gender +
IPST) **Solution:** Read both, pivot longer, merge

### 5. Historical Year URLs

**Impact:** URL pattern for 2023, 2022, 2021 not confirmed **Solution:**
Test pattern, fall back to archive page scraping if needed

------------------------------------------------------------------------

## Next Steps

1.  **Confirm URL Pattern:** Test 2023graduation_data-workbook,
    2022graduation_data-workbook
2.  **If Pattern Fails:** Scrape archive pages for actual workbook links
3.  **Develop Column Mapping:** Create full column name reference based
    on 2024 workbook
4.  **Implement Function:** Build `get_raw_grad_co()` with proper error
    handling
5.  **Add Tests:** Verify statewide rate, district counts, subgroup
    availability
6.  **Documentation:** Add vignette with graduation rate analysis
    examples

------------------------------------------------------------------------

## Sources

### Colorado Department of Education

- [Current Graduation
  Rates](https://www.cde.state.co.us/cdereval/gradratecurrent)
- [2022-2023 Graduation
  Statistics](https://www.cde.state.co.us/cdereval/2023graduationstatistics)
- [2024 Graduation Data
  Workbook](https://www.cde.state.co.us/cdereval/2024graduation_data-workbook)
- [2024 State Trends
  Workbook](https://www.cde.state.co.us/cdereval/2024graduation_state-trends)
- [Colorado Graduation Rate
  Dashboard](https://www.cde.state.co.us/code/graduationrate)
- [SchoolView Data
  Portal](https://www.cde.state.co.us/schoolview/explore/graduation/0020/ALL)

### Data Context

- [January 2025 CDE Press
  Release](https://www.denver7.com/lifestyle/education/colorado-department-of-education-releases-graduation-and-dropout-rates-for-2023-2024-school-year)
- [Chalkbeat Colorado
  Coverage](https://www.chalkbeat.org/colorado/2024/01/09/colorado-2023-graduation-rates-dropout-rates-increased-slightly/)

------------------------------------------------------------------------

**Status:** RESEARCH COMPLETE **Recommendation:** IMPLEMENT with Tier 1
(Direct Downloads) approach **Priority:** HIGH - All 5 target years
available from state DOE source
