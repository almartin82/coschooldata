# coschooldata Package - Colorado School Enrollment Data

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source**
— the entire point of these packages is to provide STATE-LEVEL data
directly from state DOEs. Federal sources aggregate/transform data
differently and lose state-specific details. If a state DOE source is
broken, FIX IT or find an alternative STATE source — do not fall back to
federal data.

------------------------------------------------------------------------

## Current Status: SERVER DOWN (as of January 2026)

The primary data server `www.cde.state.co.us` is **COMPLETELY
UNREACHABLE** (connection refused). A new site `ed.cde.state.co.us`
hosts pages but data files still reference the old domain.

### Data Source Investigation Summary

**Date of Investigation:** 2026-01-03

#### Server Status

| Domain                | Status   | Notes                                                    |
|-----------------------|----------|----------------------------------------------------------|
| `www.cde.state.co.us` | **DOWN** | Connection refused (ICMP 100% loss)                      |
| `ed.cde.state.co.us`  | **UP**   | New site, pages work, but file links point to old domain |
| `data.colorado.gov`   | **UP**   | Has higher education data, NOT K-12 enrollment           |

#### Pages Checked

| URL                                                                                               | Status           | Content                                                 |
|---------------------------------------------------------------------------------------------------|------------------|---------------------------------------------------------|
| <https://ed.cde.state.co.us>                                                                      | HTTP 200         | New CDE homepage                                        |
| <https://ed.cde.state.co.us/cdereval/pupilmembership-statistics>                                  | HTTP 200         | Enrollment data page - lists files but links are broken |
| <https://ed.cde.state.co.us/cdereval/pupilmembership-statistics/data-insights-resources-archives> | HTTP 200         | Archive page - same issue                               |
| <https://www.cde.state.co.us/cdereval/pupilcurrent>                                               | **CONN REFUSED** | Old pupil data page                                     |
| <https://www.cde.state.co.us/schoolview>                                                          | **CONN REFUSED** | SchoolView portal                                       |

#### File URLs (All Broken)

All data file URLs point to `www.cde.state.co.us` which is DOWN:

| File                             | Expected URL                                                        | Status       |
|----------------------------------|---------------------------------------------------------------------|--------------|
| 2024-25 Grade Level by School    | `/cdereval/2024-25pk-12membershipgradelevelbyschool`                | CONN REFUSED |
| 2024-25 Race/Ethnicity by School | `/cdereval/2024-25pk-12membershipraceethnicitygendergradeandschool` | CONN REFUSED |
| 2023-24 Grade Level by School    | `/cdereval/2023-24pk-12membershipgradelevelbyschool`                | CONN REFUSED |
| All historical files             | Various patterns                                                    | CONN REFUSED |

#### Alternative Sources Checked

| Source                          | Status | Notes                                               |
|---------------------------------|--------|-----------------------------------------------------|
| data.colorado.gov               | UP     | Only has higher education data, NOT K-12 enrollment |
| Colorado School Finance Project | UP     | PDF reports only, no raw data                       |
| Wayback Machine                 | Empty  | No archives of enrollment files found               |

------------------------------------------------------------------------

## Impact

- **Package cannot download enrollment data** - all Excel files are on
  the DOWN server
- **[`fetch_enr()`](https://almartin82.github.io/coschooldata/reference/fetch_enr.md)
  will fail** with connection error
- **Cached data (if any) will work** - check with
  [`cache_status()`](https://almartin82.github.io/coschooldata/reference/cache_status.md)
- **Tests skip gracefully** - 8 tests skip when server is down

------------------------------------------------------------------------

## Package Functions

### When Server is Up

``` r
# Download enrollment data
enr <- fetch_enr(2024, tidy = TRUE)

# Get multiple years
enr_multi <- fetch_enr_multi(2022:2024)

# Check available years
get_available_years()
```

### When Server is Down (Current State)

``` r
# Check server status
check_server("https://www.cde.state.co.us")

# Check cache for previously downloaded data
cache_status()

# If you have cached data
enr <- fetch_enr(2024, use_cache = TRUE)
```

------------------------------------------------------------------------

## Required Actions to Fix Data Source

### Option 1: Wait for Colorado to Restore Server (Recommended)

- Monitor: <https://www.cde.state.co.us>
- The server may be temporarily down for maintenance or migration

### Option 2: Contact Colorado CDE

- Phone: 303-866-6600
- Website: <https://ed.cde.state.co.us>
- Ask about:
  - When will `www.cde.state.co.us` be restored?
  - Are files being migrated to `ed.cde.state.co.us`?
  - Is there an API for enrollment data?

### Option 3: Update Package When Files Move

When CDE migrates files to `ed.cde.state.co.us`, update: 1.
`R/url_discovery.R` - Update base URLs 2. `R/get_raw_enrollment.R` -
Update download URLs 3. Test with
`devtools::test(filter = "pipeline-live")`

### DO NOT USE

- Urban Institute Education Data Portal
- NCES CCD data
- Any federal data aggregation

------------------------------------------------------------------------

## LIVE Pipeline Testing

The package includes comprehensive LIVE tests in
`tests/testthat/test-pipeline-live.R`:

### Test Categories

1.  **Server Status Tests** - Document which domains are reachable
2.  **URL Availability Tests** - Check pages and file URLs
3.  **Archive Page Tests** - Verify ed.cde.state.co.us pages work
4.  **File Download Tests** - Test actual downloads (when server up)
5.  **File Parsing Tests** - Read with readxl
6.  **Package Function Tests** - get_raw_enr(), fetch_enr()
7.  **Data Quality Tests** - No Inf/NaN, non-negative counts
8.  **Aggregation Tests** - State totals positive
9.  **Cache Tests** - Cache functions work
10. **Output Fidelity Tests** - tidy=TRUE consistent with tidy=FALSE

### Running Tests

``` r
# All tests
devtools::test()

# Pipeline tests only
devtools::test(filter = "pipeline-live")
```

### Expected Results (When Server Down)

    [ FAIL 0 | WARN 0 | SKIP 8 | PASS 30 ]

The 8 skipped tests are expected when `www.cde.state.co.us` is down.

------------------------------------------------------------------------

## Available Years

**When working:** 2020-2025 (October 1 pupil count data)

------------------------------------------------------------------------

### GIT COMMIT POLICY

- Commits are allowed
- NO Claude Code attribution, NO Co-Authored-By trailers, NO emojis
- Write normal commit messages as if a human wrote them

------------------------------------------------------------------------

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally
BEFORE opening a PR:

``` r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pycoschooldata && pytest tests/test_pycoschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

`devtools::check()` — 0 errors, 0 warnings

`pytest tests/test_pycoschooldata.py` — all tests pass

[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
— builds without errors

Vignettes render (no `eval=FALSE` hacks)

------------------------------------------------------------------------

## Test Results Summary

**As of 2026-01-03:** - 30 tests passing - 0 tests failing - 8 tests
skipped (server down - expected)

------------------------------------------------------------------------

## Git Workflow (REQUIRED)

### Feature Branch + PR + Auto-Merge Policy

**NEVER push directly to main.** All changes must go through PRs with
auto-merge:

``` bash
# 1. Create feature branch
git checkout -b fix/description-of-change

# 2. Make changes, commit
git add -A
git commit -m "Fix: description of change"

# 3. Push and create PR with auto-merge
git push -u origin fix/description-of-change
gh pr create --title "Fix: description" --body "Description of changes"
gh pr merge --auto --squash

# 4. Clean up stale branches after PR merges
git checkout main && git pull && git fetch --prune origin
```

### Branch Cleanup (REQUIRED)

**Clean up stale branches every time you touch this package:**

``` bash
# Delete local branches merged to main
git branch --merged main | grep -v main | xargs -r git branch -d

# Prune remote tracking branches
git fetch --prune origin
```

### Auto-Merge Requirements

PRs auto-merge when ALL CI checks pass: - R-CMD-check (0 errors, 0
warnings) - Python tests (if py{st}schooldata exists) - pkgdown build
(vignettes must render)

If CI fails, fix the issue and push - auto-merge triggers when checks
pass.
