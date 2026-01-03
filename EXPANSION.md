# Colorado School Data Package Expansion Plan

> Last researched: 2026-01-03
> Package: coschooldata
> Current status: R-CMD-check FAILING, pkgdown passing, Python tests passing

## Current Capabilities

| Data Type | Status | Years | Function |
|-----------|--------|-------|----------|
| Enrollment | implemented (BROKEN) | 2018-2024 | `fetch_enr()` |

**CRITICAL ISSUE**: R-CMD-check is failing because:
- Vignette `enrollment_hooks.Rmd` calls `fetch_enr_multi(2019:2024)`
- Current code uses WRONG URL patterns
- CDE completely reorganized their URL structure - file naming is inconsistent across years

## State DOE Data Sources

### Data Portal Overview
- **Main data portal**: https://ed.cde.state.co.us/cdereval
- **Current year data**: https://cde.state.co.us/cdereval/pupilcurrent
- **Previous years archive**: https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives
- **API availability**: No - Excel downloads only
- **File formats**: Excel (.xlsx)

### URL Structure Discovery

**CRITICAL FINDING**: CDE uses COMPLETELY DIFFERENT URL patterns for each year. There is NO consistent pattern.

#### 2023-24 URLs (end_year = 2024)
School-level files:
- `https://www.cde.state.co.us/cdereval/pk-12membershipfrlracegenderbyschoolwithflags` (combined with flags - NEW)
- `https://www.cde.state.co.us/cdereval/2023-24pk-12membershipgradelevelbyschool`
- `https://www.cde.state.co.us/cdereval/2023-24pk-12raceethnicityandgenderbygradeandschool`
- `https://www.cde.state.co.us/cdereval/2023-24pk-12instructionalprogramsbyschool`
- `https://www.cde.state.co.us/cdereval/2023-24k-12frleligibilitybyschool`
- `https://www.cde.state.co.us/cdereval/2023-24pk-12frleligibilitybyschool`

#### 2022-23 URLs (end_year = 2023)
School-level files:
- `https://www.cde.state.co.us/cdereval/2022-2023schoolmembershipgrade`
- `https://www.cde.state.co.us/cdereval/2022-2023schoolmembershipethnicityracegender`
- `https://www.cde.state.co.us/cdereval/2022-2023schoolipst`
- `https://www.cde.state.co.us/cdereval/2022-2023schoolk-12frl`
- `https://www.cde.state.co.us/cdereval/2022-2023schoolpk-12frl`

#### 2021-22 URLs (end_year = 2022)
School-level files:
- `https://www.cde.state.co.us/cdereval/2021-2022schoolmembershipgrade`
- `https://www.cde.state.co.us/cdereval/2021-2022schoolmembershipethnicityracegender`
- `https://www.cde.state.co.us/cdereval/2021-2022schoolipst`
- `https://www.cde.state.co.us/cdereval/2021-2022schoolk-12frl`
- `https://www.cde.state.co.us/cdereval/2021-2022schoolpk-12frl`

#### 2020-21 URLs (end_year = 2021)
School-level files:
- `https://www.cde.state.co.us/cdereval/2020-21membershipgradelevelbyschool`
- `https://www.cde.state.co.us/cdereval/2020-21raceethnicityandgenderbyschool`
- `https://www.cde.state.co.us/cdereval/2020-21instructionalprogrambyschool`
- `https://www.cde.state.co.us/cdereval/2020-21k-12frleligibilitybyschool`
- `https://www.cde.state.co.us/cdereval/2020-21pk-12frleligibilitybyschool`

#### 2019-20 URLs (end_year = 2020)
School-level files:
- `https://www.cde.state.co.us/cdereval/2019-20pk-12membershipgradelevelbyschool`
- `https://www.cde.state.co.us/cdereval/2019-20pk-12race/ethnicityandgenderbygradeandschool`
- `https://www.cde.state.co.us/cdereval/2019-20pk-12instructionalprogramsbyschool`
- `https://www.cde.state.co.us/cdereval/2019-20k-12freeandreducedluncheligibilitybyschool`
- `https://www.cde.state.co.us/cdereval/2019-20pk-12freeandreducedluncheligibilitybyschool`

#### 2018-19 URLs (end_year = 2019)
Page URL: `https://www.cde.state.co.us/cdereval/2017-2018pupilmembership` (note: uses START year in URL!)
Known working file URLs (confirmed via search):
- `https://www.cde.state.co.us/cdereval/2018-19pk-12instructiona-programsbyschool-0` (note: typo "instructiona" and "-0" suffix)
- `https://www.cde.state.co.us/cdereval/2018-19pk-1-freeandreducedluncheligibilitybydistrict` (note: "pk-1-" instead of "pk-12-")
- Race/ethnicity and grade level files exist but exact URLs not discovered via search
- Files confirmed to exist on page: "2018-19 PK-12 Membership Grade Level by School", "2018-19 PK-12 Race/Ethnicity and Gender by Grade and School"

#### 2017-18 URLs (end_year = 2018)
Page URL: `http://www.cde.state.co.us/cdereval/2017-18pupilmembership`
- Files confirmed to exist: "2017-18 PK-12 Race/Ethnicity and Gender by Grade and School", "2017-18 PK-12 Instructional Programs by School"
- Exact download URLs not discovered via search

#### 2016-17 URLs (end_year = 2017)
Known working URL:
- `https://www.cde.state.co.us/cdereval/2016-17-pm-school-grade-excel` (direct xlsx download)

### URL Pattern Observations

1. **Year format varies**: Sometimes `2023-24`, sometimes `2022-2023`, sometimes `2020-21`
2. **File naming varies**:
   - 2024: `pk-12membershipgradelevelbyschool`
   - 2023: `schoolmembershipgrade`
   - 2021: `membershipgradelevelbyschool`
3. **No `.xlsx` extension in URLs** - these are page URLs that serve Excel files
4. **Special characters**: 2019-20 uses `race/ethnicity` with a slash in the URL
5. **Older years** use completely different page URL patterns

### Recommended Fix Strategy

**Option A: Hardcoded URL lookup table (RECOMMENDED)**
Create a lookup table with verified URLs for each year. This is the most reliable approach given the inconsistent naming.

```r
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

**Option B: Web scraping the archive page**
Scrape `https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives` to dynamically find current URLs. More robust to future changes but more complex.

---

## Implementation Queue

### Priority 1: FIX R-CMD-CHECK (Enrollment URL Fix)

**Problem:**
Current `build_cde_url()` generates URLs like:
- `https://www.cde.state.co.us/cdereval/2018-19pk-12membershipfrlethnicitygenderschoolflags.xlsx`

But actual CDE URLs are like:
- `https://www.cde.state.co.us/cdereval/2019-20pk-12membershipgradelevelbyschool` (no .xlsx)
- And patterns vary by year

**Requirements:**
- [ ] Create lookup table with verified URLs for years 2020-2025
- [ ] Update `get_raw_enr()` to use lookup table
- [ ] Update `get_available_years()` to 2020-2025 (drop 2018-2019 until URLs verified)
- [ ] Update vignette to use years 2020-2024
- [ ] Add URL availability tests for all years

**Implementation Notes:**
- Focus on 2020+ first (URLs verified)
- 2018-2019 needs manual verification from their archive page
- Consider adding fallback URL attempts

**Test Requirements:**
- [ ] URL availability (HTTP 200) for all claimed years
- [ ] File download (size > threshold, correct type)
- [ ] File parsing (sheets exist, columns present)
- [ ] Year filtering (correct year extracted)
- [ ] Aggregation (state = sum of districts)
- [ ] Data quality (no Inf/NaN, valid ranges)
- [ ] Fidelity (tidy output matches raw values)

**Estimated complexity**: Medium

---

### Priority 2: Graduation Rates
- URL: https://www.cde.state.co.us/cdereval/gradratecurrent
- Status: Available
- Includes 4, 5, 6, 7-year rates and dropout rates

### Priority 3: Assessments (CMAS)
- URL: https://www.cde.state.co.us/assessment/cmas-data-and-results
- Status: Available
- ELA, Math, Science, Social Studies

---

## Research Log

### 2026-01-03
- Checked R-CMD-check status: FAILING
- Failure is in vignette building - `fetch_enr_multi(2019:2024)` fails on 2019
- **KEY FINDING**: CDE has NO consistent URL pattern across years
- URLs vary in:
  - Year format (2023-24 vs 2022-2023 vs 2020-21)
  - File type naming (membershipgradelevelbyschool vs schoolmembershipgrade)
  - Path structure
  - Special characters (race/ethnicity with slash)
  - Typos in URLs (e.g., "instructiona" instead of "instructional")
  - Suffixes (e.g., "-0" appended to some URLs)
- Verified working URLs for 2020-2024 from archive page
- 2018-2019: Files confirmed to exist, but exact URLs not fully discoverable via web search
- 2017-2018: Files confirmed to exist on separate page
- 2016-2017: Found direct download URL pattern (`2016-17-pm-school-grade-excel`)
- **RECOMMENDATION**:
  1. Use hardcoded URL lookup table for 2020-2025 (verified)
  2. For 2018-2019: Either scrape the page to get URLs or temporarily exclude until verified
  3. Consider adding web scraping of archive page for dynamic URL discovery

Sources reviewed:
- https://ed.cde.state.co.us/cdereval (main portal)
- https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives (archive with all URLs)
- https://www.cde.state.co.us/cdereval/2023-2024pupilmembership (2024 data)
- https://www.cde.state.co.us/cdereval/rvprioryearpmdata (historical data index)
- https://www.cde.state.co.us/cdereval/2019-2020pupilmembership (2020 data)
- https://www.cde.state.co.us/cdereval/2017-2018pupilmembership (2019 data - confusing URL)
- http://www.cde.state.co.us/cdereval/2017-18pupilmembership (2018 data)

---

## Blocked / Not Available

| Data Type | Reason | Alternative Source? |
|-----------|--------|---------------------|
| N/A | N/A | N/A |
