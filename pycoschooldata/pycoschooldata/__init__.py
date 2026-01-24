"""
pycoschooldata - Python wrapper for Colorado school data.

Thin rpy2 wrapper around the coschooldata R package.
Returns pandas DataFrames.
"""

from .core import (
    fetch_enr,
    fetch_enr_multi,
    tidy_enr,
    get_available_years,
    fetch_assessment,
    fetch_assessment_multi,
    get_available_assessment_years,
)

__version__ = "0.1.0"
__all__ = [
    "fetch_enr",
    "fetch_enr_multi",
    "tidy_enr",
    "get_available_years",
    "fetch_assessment",
    "fetch_assessment_multi",
    "get_available_assessment_years",
]
