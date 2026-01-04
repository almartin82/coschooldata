# TODO: coschooldata pkgdown build issues

## Issue: Network timeout during vignette build

**Date**: 2026-01-01

**Error**: pkgdown build fails when rendering
`vignettes/enrollment_hooks.Rmd`

**Details**: - The vignette calls `fetch_enr_multi(2018:2025)` which
tries to download enrollment data from the Colorado Department of
Education website - The download times out after 10 seconds with error:
`Download failed: Timeout was reached [www.cde.state.co.us]: Connection timed out after 10002 milliseconds`

**Root cause**: The CDE website (`www.cde.state.co.us`) is either slow
or blocking requests during the pkgdown build process.

## Potential solutions

1.  **Pre-cache data**: Run the vignette locally first to populate the
    cache, then include cache files in the package or use a CI caching
    strategy

2.  **Use pre-built vignettes**: Add `VignetteBuilder: knitr` to
    DESCRIPTION and pre-build the vignette HTML, checking it into the
    repo

3.  **Increase timeout**: Modify the download functions to use a longer
    timeout for CI environments

4.  **Mock data for vignettes**: Create a small sample dataset
    specifically for vignette examples that doesn’t require network
    access

5.  **Skip vignette on CRAN/CI**: Add
    `eval = requireNamespace("coschooldata", quietly = TRUE) && interactive()`
    to chunk options (though this defeats the purpose of showing real
    examples)

## Recommended approach

Option 1 or 2 are likely the best solutions - either pre-cache the data
or pre-build the vignette so the pkgdown build doesn’t require live
network access to the CDE website.
