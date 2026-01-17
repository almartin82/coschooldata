# Colorado School Data Package Expansion Plan

> Last researched: 2026-01-03 Package: coschooldata Current status:
> R-CMD-check FAILING, pkgdown passing, Python tests passing

## Current Capabilities

| Data Type  | Status               | Years     | Function                                                                          |
|------------|----------------------|-----------|-----------------------------------------------------------------------------------|
| Enrollment | implemented (BROKEN) | 2018-2024 | [`fetch_enr()`](https://almartin82.github.io/coschooldata/reference/fetch_enr.md) |

**CRITICAL ISSUE**: R-CMD-check is failing because: - Vignette
`enrollment_hooks.Rmd` calls `fetch_enr_multi(2019:2024)` - Current code
uses WRONG URL patterns - CDE completely reorganized their URL
structure - file naming is inconsistent across years

## State DOE Data Sources

### Data Portal Overview

- **Main data portal**: <https://ed.cde.state.co.us/cdereval>
- **Current year data**: <https://cde.state.co.us/cdereval/pupilcurrent>
- **Previous years archive**:
  <https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives>
- **API availability**: No - Excel downloads only
- **File formats**: Excel (.xlsx)

### URL Structure Discovery

**CRITICAL FINDING**: CDE uses COMPLETELY DIFFERENT URL patterns for
each year. There is NO consistent pattern.

#### 2023-24 URLs (end_year = 2024)

School-level files: -
`https://www.cde.state.co.us/cdereval/pk-12membershipfrlracegenderbyschoolwithflags`
(combined with flags - NEW) -
`https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool` -
`https://www.cde.state.co.us/cdereval/2023-24pk-12raceethnicityandgenderbygradeandschool` -
`https://www.cde.state.co.us/cdereval/2023-24pk-12instructionalprogramsbyschool` -
`https://www.cde.state.co.us/cdereval/2023-24k-12frleligibilitybyschool` -
`https://www.cde.state.co.us/cdereval/2023-24pk-12frleligibilitybyschool`

#### 2022-23 URLs (end_year = 2023)

School-level files: -
`https://www.cde.state.co.us/cdereval/2022-2023schoolmembershipgrade` -
`https://www.cde.state.co.us/cdereval/2022-2023schoolmembershipethnicityracegender` -
`https://www.cde.state.co.us/cdereval/2022-2023schoolipst` -
`https://www.cde.state.co.us/cdereval/2022-2023schoolk-12frl` -
`https://www.cde.state.co.us/cdereval/2022-2023schoolpk-12frl`

#### 2021-22 URLs (end_year = 2022)

School-level files: -
`https://www.cde.state.co.us/cdereval/2021-2022schoolmembershipgrade` -
`https://www.cde.state.co.us/cdereval/2021-2022schoolmembershipethnicityracegender` -
`https://www.cde.state.co.us/cdereval/2021-2022schoolipst` -
`https://www.cde.state.co.us/cdereval/2021-2022schoolk-12frl` -
`https://www.cde.state.co.us/cdereval/2021-2022schoolpk-12frl`

#### 2020-21 URLs (end_year = 2021)

School-level files: -
`https://www.cde.state.co.us/cdereval/2020-21membershipgradelevelbyschool` -
`https://www.cde.state.co.us/cdereval/2020-21raceethnicityandgenderbyschool` -
`https://www.cde.state.co.us/cdereval/2020-21instructionalprogrambyschool` -
`https://www.cde.state.co.us/cdereval/2020-21k-12frleligibilitybyschool` -
`https://www.cde.state.co.us/cdereval/2020-21pk-12frleligibilitybyschool`

#### 2019-20 URLs (end_year = 2020)

School-level files: -
`https://www.cde.state.co.us/cdereval/2019-20pk-12membershipgradelevelbyschool` -
`https://www.cde.state.co.us/cdereval/2019-20pk-12race/ethnicityandgenderbygradeandschool` -
`https://www.cde.state.co.us/cdereval/2019-20pk-12instructionalprogramsbyschool` -
`https://www.cde.state.co.us/cdereval/2019-20k-12freeandreducedluncheligibilitybyschool` -
`https://www.cde.state.co.us/cdereval/2019-20pk-12freeandreducedluncheligibilitybyschool`

#### 2018-19 URLs (end_year = 2019)

Page URL:
`https://www.cde.state.co.us/cdereval/2017-2018pupilmembership` (note:
uses START year in URL!) Known working file URLs (confirmed via
search): -
`https://www.cde.state.co.us/cdereval/2018-19pk-12instructiona-programsbyschool-0`
(note: typo “instructiona” and “-0” suffix) -
`https://www.cde.state.co.us/cdereval/2018-19pk-1-freeandreducedluncheligibilitybydistrict`
(note: “pk-1-” instead of “pk-12-”) - Race/ethnicity and grade level
files exist but exact URLs not discovered via search - Files confirmed
to exist on page: “2018-19 PK-12 Membership Grade Level by School”,
“2018-19 PK-12 Race/Ethnicity and Gender by Grade and School”

#### 2017-18 URLs (end_year = 2018)

Page URL: `http://www.cde.state.co.us/cdereval/2017-18pupilmembership` -
Files confirmed to exist: “2017-18 PK-12 Race/Ethnicity and Gender by
Grade and School”, “2017-18 PK-12 Instructional Programs by School” -
Exact download URLs not discovered via search

#### 2016-17 URLs (end_year = 2017)

Known working URL: -
`https://www.cde.state.co.us/cdereval/2016-17-pm-school-grade-excel`
(direct xlsx download)

### URL Pattern Observations

1.  **Year format varies**: Sometimes `2023-24`, sometimes `2022-2023`,
    sometimes `2020-21`
2.  **File naming varies**:
    - 2024: `pk-12membershipgradelevelbyschool`
    - 2023: `schoolmembershipgrade`
    - 2021: `membershipgradelevelbyschool`
3.  **No `.xlsx` extension in URLs** - these are page URLs that serve
    Excel files
4.  **Special characters**: 2019-20 uses `race/ethnicity` with a slash
    in the URL
5.  **Older years** use completely different page URL patterns

### Recommended Fix Strategy

**Option A: Hardcoded URL lookup table (RECOMMENDED)** Create a lookup
table with verified URLs for each year. This is the most reliable
approach given the inconsistent naming.

``` r
get_enrollment_urls <- function(end_year) {
  urls <- list(
    "2024" = list(
      grade = "https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool",
      race_gender = "https://www.cde.state.co.us/cdereval/2023-24pk-12raceethnicityandgenderbygradeandschool"
    ),
    "2023" = list(
      grade = "https://www.cde.state.co.us/cdereval/2022-2023schoolmembershipgrade",
      race_gender = "https://www.cde.state.co.us/cdereval/2022-2023schoolmembershipethnicityracegender"
    ),
    # ... etc
  )
  urls[[as.character(end_year)]]
}
```

**Option B: Web scraping the archive page** Scrape
`https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives`
to dynamically find current URLs. More robust to future changes but more
complex.

------------------------------------------------------------------------

## Implementation Queue

### Priority 1: FIX R-CMD-CHECK (Enrollment URL Fix)

**Problem:** Current
[`build_cde_url()`](https://almartin82.github.io/coschooldata/reference/build_cde_url.md)
generates URLs like: -
`https://www.cde.state.co.us/cdereval/2018-19pk-12membershipfrlethnicitygenderschoolflags.xlsx`

But actual CDE URLs are like: -
`https://www.cde.state.co.us/cdereval/2019-20pk-12membershipgradelevelbyschool`
(no .xlsx) - And patterns vary by year

**Requirements:** - \[ \] Create lookup table with verified URLs for
years 2020-2025 - \[ \] Update
[`get_raw_enr()`](https://almartin82.github.io/coschooldata/reference/get_raw_enr.md)
to use lookup table - \[ \] Update
[`get_available_years()`](https://almartin82.github.io/coschooldata/reference/get_available_years.md)
to 2020-2025 (drop 2018-2019 until URLs verified) - \[ \] Update
vignette to use years 2020-2024 - \[ \] Add URL availability tests for
all years

**Implementation Notes:** - Focus on 2020+ first (URLs verified) -
2018-2019 needs manual verification from their archive page - Consider
adding fallback URL attempts

**Test Requirements:** - \[ \] URL availability (HTTP 200) for all
claimed years - \[ \] File download (size \> threshold, correct type) -
\[ \] File parsing (sheets exist, columns present) - \[ \] Year
filtering (correct year extracted) - \[ \] Aggregation (state = sum of
districts) - \[ \] Data quality (no Inf/NaN, valid ranges) - \[ \]
Fidelity (tidy output matches raw values)

**Estimated complexity**: Medium

------------------------------------------------------------------------

### Priority 2: Graduation Rates

- URL: <https://www.cde.state.co.us/cdereval/gradratecurrent>
- Status: Available
- Includes 4, 5, 6, 7-year rates and dropout rates

### Priority 3: Assessments (CMAS)

- URL: <https://www.cde.state.co.us/assessment/cmas-data-and-results>
- Status: Available
- ELA, Math, Science, Social Studies

------------------------------------------------------------------------

## Research Log

### 2026-01-03

- Checked R-CMD-check status: FAILING
- Failure is in vignette building - `fetch_enr_multi(2019:2024)` fails
  on 2019
- **KEY FINDING**: CDE has NO consistent URL pattern across years
- URLs vary in:
  - Year format (2023-24 vs 2022-2023 vs 2020-21)
  - File type naming (membershipgradelevelbyschool vs
    schoolmembershipgrade)
  - Path structure
  - Special characters (race/ethnicity with slash)
  - Typos in URLs (e.g., “instructiona” instead of “instructional”)
  - Suffixes (e.g., “-0” appended to some URLs)
- Verified working URLs for 2020-2024 from archive page
- 2018-2019: Files confirmed to exist, but exact URLs not fully
  discoverable via web search
- 2017-2018: Files confirmed to exist on separate page
- 2016-2017: Found direct download URL pattern
  (`2016-17-pm-school-grade-excel`)
- **RECOMMENDATION**:
  1.  Use hardcoded URL lookup table for 2020-2025 (verified)
  2.  For 2018-2019: Either scrape the page to get URLs or temporarily
      exclude until verified
  3.  Consider adding web scraping of archive page for dynamic URL
      discovery

Sources reviewed: - <https://ed.cde.state.co.us/cdereval> (main
portal) -
<https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives>
(archive with all URLs) -
<https://www.cde.state.co.us/cdereval/2023-2024pupilmembership> (2024
data) - <https://www.cde.state.co.us/cdereval/rvprioryearpmdata>
(historical data index) -
<https://www.cde.state.co.us/cdereval/2019-2020pupilmembership> (2020
data) - <https://www.cde.state.co.us/cdereval/2017-2018pupilmembership>
(2019 data - confusing URL) -
<http://www.cde.state.co.us/cdereval/2017-18pupilmembership> (2018 data)

------------------------------------------------------------------------

------------------------------------------------------------------------

# Assessment Data Expansion Research

**Last Updated:** 2026-01-11 **Theme Researched:** Assessment Data
(CMAS, PSAT, School Performance Frameworks)

------------------------------------------------------------------------

## Executive Summary

Colorado assessment data exists but faces **MAJOR ACCESSIBILITY
CHALLENGES**: - **Student-level CMAS data**: Locked behind
PearsonAccessnext (authentication required) - **Aggregate
district/school data**: Available via CDE SchoolView and Performance
Framework pages - **Historical coverage**: 2014-2025 for CMAS, 2009-2025
for Performance Frameworks - **Recommended path**: Focus on Performance
Framework data (publicly accessible)

------------------------------------------------------------------------

## Data Sources Found

### Source 1: CMAS Student Data Files (PearsonAccessnext)

**URL:**
<https://www.cde.state.co.us/assessment/accessing_datafiles_reports_pan>
**HTTP Status:** 200 (accessible) **Format:** CSV files (via
PearsonAccessnext portal) **Years Available:** 2014-2025 **Access
Method:** **REQUIRES AUTHENTICATION** - Not publicly accessible

#### Details:

- **Field Definition Pages:**

  - 2024: <https://www.cde.state.co.us/assessment/cmas_sdf_2024>
  - 2023: <https://www.cde.state.co.us/assessment/cmas_sdf_2023>
  - 2022: <https://www.cde.state.co.us/assessment/cmas_sdf_2022>
  - 2021: <https://www.cde.state.co.us/assessment/cmas_sdf_21>

- **Summary Data File Layout:**
  <https://www.cde.state.co.us/assessment/cmas_coalt_summarydatafile>

- **Key Finding from CDE:** \> “Student Data Files and Summary Data
  Files are available for past administrations of CMAS and CoAlt
  assessments going back to 2014”

#### Access Barrier:

> “Accessing Data Files and Reports in PearsonAccessnext” page indicates
> that: - Files are accessed through PearsonAccessnext
> (<https://co.pearsonaccessnext.com/>) - Requires user account and
> authentication - **NOT publicly downloadable via direct URL**

#### Red Flags:

- ❌ HTTP 403 likely if attempting direct download
- ❌ JavaScript-based portal (no simple API)
- ❌ Auth required (no workaround documented)
- ❌ This is student-level data (FERPA protections apply)

------------------------------------------------------------------------

### Source 2: School Performance Framework (SPF) Data

**URL:**
<https://www.cde.state.co.us/accountability/performanceframeworkresults>
**HTTP Status:** 200 (accessible) **Format:** XLSX spreadsheets
(publicly accessible) **Years Available:** 2009-2025 **Access Method:**
Direct download links

#### Details:

- **Data Tools & Reports Page:**
  <https://www.cde.state.co.us/accountability/Data-Tools-Reports>
  - Quote: “Files include spreadsheets with current and historical
    performance framework results”
- **SchoolView Data Files Page:**
  <https://www.cde.state.co.us/schoolview/datafiles>
  - Dedicated page for downloadable data files
- **Performance Framework Pages:**
  - Achievement:
    <https://www.cde.state.co.us/schoolview/frameworks/achievement/0920>
  - Growth:
    <https://www.cde.state.co.us/schoolview/frameworks/growth/0920>
  - Official Ratings:
    <https://www.cde.state.co.us/schoolview/frameworks/official/1050/2642>

#### Green Flags:

- ✅ Publicly accessible (no authentication)
- ✅ XLSX format (easily parsed)
- ✅ Historical data available (2009-2025)
- ✅ District and school-level aggregations
- ✅ CMAS proficiency data embedded in SPF

#### Data Content:

Performance Frameworks include: - **CMAS Achievement**: %
proficient/distinguished in Math and ELA - **CMAS Growth**: Median
Growth Percentiles (MGP) - **District/School Ratings**: Performance
ratings (Accredited, Priority Improvement, etc.) - **Subgroup Data**:
Disaggregated by race/ethnicity, ELL, SPED, FRPL

------------------------------------------------------------------------

### Source 3: Accountability Data Files

**URL:** Various CDE accountability pages **HTTP Status:** 200
(accessible) **Format:** XLSX files **Years Available:** 2019-2025

#### Example URLs Found:

- 2025 CMAS Growth State Level:
  <https://www.cde.state.co.us/accountability/2025cmasgrowthsummarystatelevel>
- 2024 CMAS Growth State Summary:
  <https://www.cde.state.co.us/accountability/2024cmasgrowthstatesummary>
- 2024 AEC Public Data File:
  <https://www.cde.state.co.us/accountability/2024_aec_final_public_data_file_120924>
- DPF Ratings 2009-2022:
  <https://www.cde.state.co.us/accountability/finaldpfprinterfriendly>
- SPF Ratings 2019-2025:
  <https://www.cde.state.co.us/accountability/2025spfratingsovertime>

#### Green Flags:

- ✅ Publicly accessible
- ✅ XLSX format
- ✅ State, district, and school-level summaries

------------------------------------------------------------------------

## Schema Analysis

### CMAS Student Data File (Not Recommended - Auth Required)

Based on field definition pages: - **Student-level columns:** Student
ID, School Code, District Code, Grade, Content Area, Score Level,
Performance Level - **Assessment types:** Math, ELA, Science, Social
Studies - **Score levels:** Below, Approaching, Met, Exceeded -
**Performance levels:** 1-5 scale

**Issue:** Cannot verify actual schema without PearsonAccessnext access.

### Performance Framework Data (Recommended)

**Expected schema (based on CDE documentation):** - **Identifiers:**
District Code, District Name, School Code, School Name - **Achievement
Metrics:** Pct Proficient/Distinguished (Math, ELA), Science Score -
**Growth Metrics:** Median Growth Percentile (MGP), Growth Gap -
**Rating Metrics:** Performance Rating, Participation Rate -
**Subgroups:** All, Race/Ethnicity, ELL, SPED, FRPL, Gifted

**Need to download sample files to verify exact column names.**

------------------------------------------------------------------------

## ID System

### Colorado District and School IDs

**Format:** - **District Code:** 4 digits (e.g., 0880 = Denver
County 1) - **School Code:** 4 digits unique within district - **State
Code:** 2 digits (08 = Colorado)

**Example:** 0880-1788 - 08 = Colorado - 880 = Denver County 1
(District) - 1788 = Specific school within Denver

**Composite IDs** are hyphenated or concatenated in CDE data files.

------------------------------------------------------------------------

## Time Series Heuristics

### Expected Ranges (to verify with downloaded data):

| Metric                         | Expected Range      | Red Flag If          |
|--------------------------------|---------------------|----------------------|
| State Proficient % (Math)      | 35-45%              | Change \>5% YoY      |
| State Proficient % (ELA)       | 40-50%              | Change \>5% YoY      |
| District Count                 | 175-185 districts   | Sudden drop/spike    |
| School Count                   | 1,800-1,950 schools | Sudden drop/spike    |
| MGP (Median Growth Percentile) | 40-60               | Below 35 or above 65 |

### Known Assessment Schedule:

- **CMAS:** Spring administration (March-April), released August
- **PSAT/SAT:** Spring administration (April), results June-August
- **Science CMAS:** Grades 5, 8, 11
- **Social Studies CMAS:** Grades 4 and 7 (sampled schools)

### COVID Impact:

- **2020:** No CMAS assessments (COVID pandemic)
- **2021:** Reduced participation, optional for districts
- **2022-2025:** Normal administration resumed

------------------------------------------------------------------------

## Recommended Implementation

### Priority: **MEDIUM** (Recommended: Performance Framework data only)

### Complexity: **MEDIUM**

### Estimated Files to Modify: 6-8 files

### Decision: **DO NOT implement CMAS student-level data**

**Rationale:** 1. Authentication required for PearsonAccessnext 2.
Student-level data has FERPA protections 3. No public API or automated
download method 4. Falls back to manual downloads (violates project
rules)

### Alternative: **Implement Performance Framework data**

**Recommended approach:**

#### Implementation Steps:

1.  **Create `R/url_discovery_assessment.R`**
    - Discover SPF data file URLs from CDE accountability pages
    - Parse HTML to find XLSX download links
    - Handle year-based URL patterns (if they exist)
2.  **Create `R/get_raw_assessment.R`**
    - `get_raw_spf()`: Download SPF XLSX files
    - `get_raw_district_spf()`: District-level performance frameworks
    - `get_raw_school_spf()`: School-level performance frameworks
    - Use readxl::read_xlsx() for parsing
3.  **Create `R/process_assessment.R`**
    - `process_spf()`: Standardize column names across years
    - Handle schema changes (2009-2018 vs 2019-2025)
    - Extract CMAS achievement and growth metrics
    - Add proficiency categories (Met/Exceeded = Proficient)
4.  **Create `R/tidy_assessment.R`**
    - `tidy_spf()`: Convert to tidy format
    - Columns: year, district_id, school_id, metric, value, subgroup
    - Metrics: pct_proficient_math, pct_proficient_ela, mgp_math,
      mgp_ela, rating
5.  **Create `R/fetch_assessment.R`**
    - `fetch_spf()`: Main user-facing function
    - `fetch_spf_multi()`: Multi-year fetcher
    - Add use_cache parameter
6.  **Create `tests/testthat/test-pipeline-live-assessment.R`**
    - URL availability tests
    - File download tests
    - Schema verification tests
    - Data quality tests (no negative values, valid percentages)
    - Fidelity tests (verify specific district/year values)
7.  **Update `R/available_years.R`**
    - Add SPF year range (2009-2025)
    - Note 2020 gap (COVID)

------------------------------------------------------------------------

## Test Requirements

### Raw Data Fidelity Tests Needed:

**After downloading sample files, verify:**

``` r
# Example fidelity tests (to be updated with actual values)

test_that("2024: Denver Public Schools Math Proficiency matches SPF", {
  skip_if_offline()

  spf <- fetch_spf(2024)

  denver_math <- spf %>%
    filter(district_id == "0880",
           metric == "pct_proficient_math",
           subgroup == "all")

  # Update this value after downloading actual file
  expect_equal(denver_math$value, XX.X, tolerance = 0.1)
})

test_that("2019: State ELA proficiency is in valid range", {
  skip_if_offline()

  spf <- fetch_spf(2019)

  state_ela <- spf %>%
    filter(is_state,
           metric == "pct_proficient_ela",
           subgroup == "all") %>%
    pull(value)

  expect_gt(state_ela, 40)
  expect_lt(state_ela, 50)
})
```

### Data Quality Checks:

- No negative proficiency percentages
- No percentages \> 100
- State total in expected ranges (35-50% proficient)
- Major districts exist in all years (Denver 0880, Jeffco 0890, Douglas
  0795)
- 2020 gap handled gracefully (no data or NULL)
- CMAS science and social studies included where applicable

------------------------------------------------------------------------

## Implementation Alternatives

### Option 1: Performance Framework Data (RECOMMENDED)

**Pros:** - Publicly accessible (no auth) - XLSX format (easy parsing) -
Historical coverage (2009-2025) - Includes CMAS proficiency data -
District and school-level

**Cons:** - Aggregate data (not student-level) - Limited to SPF
metrics - May need to download multiple files per year

**Effort:** 2-3 days

### Option 2: CMAS Student-Level Data (NOT RECOMMENDED)

**Pros:** - Student-level data - Most detailed assessment data - All
CMAS subjects included

**Cons:** - Authentication required (PearsonAccessnext) - Student-level
data (FERPA concerns) - No public API - Manual download process -
Violates project automation rules

**Effort:** 1-2 weeks (with manual workarounds)

### Option 3: Hybrid Approach (NOT VIABLE)

**Description:** Use `import_local_spf()` fallback function for manual
downloads

**Pros:** - Users can manually download from PearsonAccessnext - Package
provides parsing and tidying

**Cons:** - Still requires manual intervention - Poor user experience -
Violates “find automated alternatives” rule

**Decision:** Do not implement

------------------------------------------------------------------------

## Next Steps

### Immediate Actions:

1.  **Download Sample SPF Files**
    - Download 2024 SPF district and school files
    - Download 2019 SPF files (pre-COVID)
    - Download 2015 SPF files (historical)
2.  **Verify Schema**
    - Document column names for each year
    - Identify schema changes over time
    - Map composite IDs to district/school
3.  **Establish Fidelity Values**
    - Pick 3-5 specific districts and years
    - Record exact proficiency percentages
    - Use for test verification
4.  **Begin Implementation**
    - Follow TDD approach
    - Write tests first
    - Implement URL discovery
    - Implement download and parsing
    - Implement tidying
    - Test thoroughly

### Future Enhancements (Out of Scope):

- **PSAT/SAT Data:** High school assessment data (excluded per user
  request)
- **Colorado Growth Model:** Detailed growth percentiles (complex
  schema)
- **CoAlt Data:** Alternative assessment data (special education)
- **Historical PARCC:** Pre-CMAS assessment (2015-2018, different
  format)

------------------------------------------------------------------------

## Notes

### Server Status Considerations:

The primary enrollment data server (www.cde.state.co.us) is **DOWN** for
enrollment data as of 2026-01-03. However:

- **Assessment pages are ACCESSIBLE:** HTTP 200 on all CDE assessment
  URLs checked
- **SchoolView is operational:** Framework and data file pages are
  accessible
- **PearsonAccessnext is separate:** CMAS data portal is independent of
  www.cde.state.co.us

**Conclusion:** Assessment data access is NOT impacted by the enrollment
server outage.

------------------------------------------------------------------------

## Conclusion

**Colorado assessment data expansion is VIABLE** but with important
caveats:

1.  **Student-level CMAS data is not accessible** without
    PearsonAccessnext authentication
2.  **Performance Framework data IS accessible** and provides CMAS
    proficiency aggregations
3.  **Recommended implementation:** Focus on SPF data (2009-2025)
4.  **Excluded:** PSAT/SAT data (per user request), student-level CMAS
    (access barriers)

**Implementation Priority:** MEDIUM (valuable data, but requires careful
schema analysis)

**Estimated Effort:** 2-3 days for SPF data implementation

**Decision:** Proceed with Performance Framework data implementation,
skip CMAS student-level data due to authentication requirements.

------------------------------------------------------------------------

## Sources

- [CMAS Student Data File Field Definitions - Spring
  2024](https://www.cde.state.co.us/assessment/cmas_sdf_2024)
- [2025 CMAS Student Data File Field
  Definitions](https://www.cde.state.co.us/assessment/cmas_sdf)
- [Accessing Data Files and Reports in
  PearsonAccessnext](https://www.cde.state.co.us/assessment/accessing_datafiles_reports_pan)
- [Data Training \|
  CDE](https://www.cde.state.co.us/assessment/training-data)
- [CDE District and School Performance Framework
  Results](https://www.cde.state.co.us/accountability/performanceframeworkresults)
- [CDE Data Tools &
  Reports](https://www.cde.state.co.us/accountability/Data-Tools-Reports)
- [SchoolView Data
  Files](https://www.cde.state.co.us/schoolview/datafiles)
- [Performance Frameworks - Academic
  Achievement](https://www.cde.state.co.us/schoolview/frameworks/achievement/0920)
- [Performance Frameworks - Academic
  Growth](https://cde.state.co.us/schoolview/frameworks/growth/0920)
- [CMAS Parent Portal - Cherry Creek
  Schools](https://www.cherrycreekschools.org/programs-and-services/assessment-performance-analytics/assessments/parent-resources/cmas-parent-portal)

------------------------------------------------------------------------

## Blocked / Not Available

| Data Type               | Reason                                            | Alternative Source?                      |
|-------------------------|---------------------------------------------------|------------------------------------------|
| CMAS Student-Level Data | PearsonAccessnext requires authentication (FERPA) | Use Performance Framework aggregate data |
| PSAT/SAT Data           | Excluded per user request                         | N/A                                      |
