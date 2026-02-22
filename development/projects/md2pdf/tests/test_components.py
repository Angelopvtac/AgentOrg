"""Tests for the component preprocessor."""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from components import preprocess, build_cover_html, get_warnings


def test_pagebreak():
    result = preprocess("---pagebreak---")
    assert '<div class="page-break"></div>' in result


def test_callout_with_title():
    text = "::: blue Important\nSome content\n:::"
    result = preprocess(text)
    assert 'callout-blue' in result
    assert 'Important' in result
    assert 'Some content' in result


def test_callout_without_title():
    text = "::: green\nGreen content\n:::"
    result = preprocess(text)
    assert 'callout-green' in result
    assert 'Green content' in result


def test_simple_component():
    text = "::: card\nCard content\n:::"
    result = preprocess(text)
    assert '<div class="card"' in result
    assert 'Card content' in result


def test_key_insight():
    text = "::: key-insight\nInsight text\n:::"
    result = preprocess(text)
    assert '<div class="key-insight"' in result


def test_columns():
    text = ":::: columns\n::: col\nLeft\n:::\n::: col\nRight\n:::\n::::"
    result = preprocess(text)
    assert '<div class="columns"' in result
    assert '<div class="col"' in result


def test_metrics():
    text = "::: metrics\nTAM: $1.8B | CAGR: 34%\n:::"
    result = preprocess(text)
    assert 'metric-row' in result
    assert 'TAM' in result
    assert '$1.8B' in result


def test_badge_spans():
    text = "[HIGH]{.badge-high}"
    result = preprocess(text)
    assert 'badge-high' in result
    assert 'HIGH' in result


def test_pill_spans():
    text = "[TAM: $1.8B]{.pill}"
    result = preprocess(text)
    assert 'metric-pill' in result


def test_worksheet_fields():
    text = "::: worksheet\n>> Company Name\n> Acme Corp\n:::"
    result = preprocess(text)
    assert 'field-label' in result
    assert 'Company Name' in result
    assert 'field-input' in result
    assert 'Acme Corp' in result


def test_nested_blocks():
    text = "::: card\n::: blue Note\nNested callout\n:::\n:::"
    result = preprocess(text)
    assert 'class="card"' in result
    assert 'callout-blue' in result


def test_unclosed_block_warns():
    get_warnings()  # clear
    preprocess("::: card\nNo closing")
    warnings = get_warnings()
    assert len(warnings) > 0
    assert "Unclosed" in warnings[0]


def test_cover_html():
    meta = {"cover": True, "title": "Test Report", "subtitle": "A Test"}
    html = build_cover_html(meta)
    assert "cover-page" in html
    assert "Test Report" in html
    assert "A Test" in html


def test_cover_html_no_cover():
    meta = {"title": "Test"}
    html = build_cover_html(meta)
    assert html == ""


def test_cover_with_stats():
    meta = {
        "cover": True,
        "title": "Report",
        "stats": [{"value": "$100M", "label": "Market"}],
    }
    html = build_cover_html(meta)
    assert "$100M" in html
    assert "Market" in html
