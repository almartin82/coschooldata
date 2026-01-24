"""
Tests for pycoschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pycoschooldata
    assert pycoschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pycoschooldata
    assert hasattr(pycoschooldata, 'fetch_enr')
    assert callable(pycoschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pycoschooldata
    assert hasattr(pycoschooldata, 'get_available_years')
    assert callable(pycoschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pycoschooldata
    assert hasattr(pycoschooldata, '__version__')
    assert isinstance(pycoschooldata.__version__, str)


def test_has_fetch_assessment():
    """fetch_assessment function is available."""
    import pycoschooldata
    assert hasattr(pycoschooldata, 'fetch_assessment')
    assert callable(pycoschooldata.fetch_assessment)


def test_has_fetch_assessment_multi():
    """fetch_assessment_multi function is available."""
    import pycoschooldata
    assert hasattr(pycoschooldata, 'fetch_assessment_multi')
    assert callable(pycoschooldata.fetch_assessment_multi)


def test_has_get_available_assessment_years():
    """get_available_assessment_years function is available."""
    import pycoschooldata
    assert hasattr(pycoschooldata, 'get_available_assessment_years')
    assert callable(pycoschooldata.get_available_assessment_years)
