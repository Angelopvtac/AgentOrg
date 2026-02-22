"""Tests for the Typst converter."""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from typst_converter import TypstConverter


def make_converter():
    return TypstConverter()


def test_basic_paragraph():
    c = make_converter()
    result = c.convert("Hello world")
    assert "Hello world" in result


def test_heading_levels():
    c = make_converter()
    result = c.convert("## Sub heading\n\n### Third level")
    assert "== Sub heading" in result
    assert "=== Third level" in result


def test_h1_section_banner():
    c = make_converter()
    result = c.convert("# Major Section")
    assert "section-banner" in result
    assert "Major Section" in result


def test_bold_and_italic():
    c = make_converter()
    result = c.convert("**bold** and *italic*")
    assert "*bold*" in result
    assert "_italic_" in result


def test_link():
    c = make_converter()
    result = c.convert("[Click here](https://example.com)")
    assert '#link("https://example.com")' in result


def test_unordered_list():
    c = make_converter()
    result = c.convert("- Item A\n- Item B")
    assert "- Item A" in result
    assert "- Item B" in result


def test_ordered_list():
    c = make_converter()
    result = c.convert("1. First\n2. Second")
    assert "+ First" in result
    assert "+ Second" in result


def test_code_block():
    c = make_converter()
    result = c.convert('```python\nprint("hi")\n```')
    assert "raw" in result
    assert "python" in result


def test_pagebreak():
    c = make_converter()
    result = c.convert("---pagebreak---")
    assert "#pagebreak()" in result


def test_callout():
    c = make_converter()
    result = c.convert("::: blue Note\nContent here\n:::")
    assert '#callout("blue"' in result
    assert "Note" in result


def test_metrics():
    c = make_converter()
    result = c.convert("::: metrics\nTAM: $1.8B | CAGR: 34%\n:::")
    assert "#metric-row" in result


def test_table():
    c = make_converter()
    md = "| Name | Value |\n|------|-------|\n| A | 1 |\n| B | 2 |"
    result = c.convert(md)
    assert "#table(" in result
    assert "Name" in result


def test_badge_span():
    c = make_converter()
    result = c.convert("[HIGH]{.badge-high}")
    assert '#badge("high")' in result


def test_pill_span():
    c = make_converter()
    result = c.convert("[TAM: $1.8B]{.pill}")
    assert "#pill[" in result


def test_blockquote():
    c = make_converter()
    result = c.convert("> A wise quote")
    assert "#quote" in result


def test_columns():
    c = make_converter()
    text = ":::: columns\n::: col\nLeft\n:::\n::: col\nRight\n:::\n::::"
    result = c.convert(text)
    assert "#grid(" in result
    assert "Left" in result
    assert "Right" in result


def test_cover_page():
    c = make_converter()
    meta = {"cover": True, "title": "Test", "subtitle": "Sub"}
    result = c.convert("Content", meta=meta)
    assert "#cover-page(" in result
    assert "Test" in result


def test_imports_present():
    c = make_converter()
    result = c.convert("Hello")
    assert '#import "typst/template.typ"' in result
    assert '#import "typst/components.typ"' in result


def test_escape_special_chars():
    c = make_converter()
    result = c.convert("Price is $100 and email@test")
    assert "\\$" in result
    assert "\\@" in result
