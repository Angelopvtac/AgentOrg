"""Tests for YAML front matter extraction."""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from md2pdf import extract_front_matter


def test_no_front_matter():
    meta, body = extract_front_matter("# Hello\n\nWorld")
    assert meta == {}
    assert body == "# Hello\n\nWorld"


def test_basic_front_matter():
    text = "---\ntitle: Test\n---\n\n# Hello"
    meta, body = extract_front_matter(text)
    assert meta["title"] == "Test"
    assert body.strip() == "# Hello"


def test_complex_front_matter():
    text = """---
title: My Report
subtitle: A Subtitle
cover: true
stats:
  - value: "$100M"
    label: Market Size
---

Content here"""
    meta, body = extract_front_matter(text)
    assert meta["title"] == "My Report"
    assert meta["subtitle"] == "A Subtitle"
    assert meta["cover"] is True
    assert len(meta["stats"]) == 1
    assert meta["stats"][0]["value"] == "$100M"
    assert "Content here" in body


def test_invalid_yaml():
    text = "---\n: invalid: yaml: [[\n---\n\nContent"
    meta, body = extract_front_matter(text)
    assert meta == {}
    assert "Content" in body


def test_no_closing_delimiter():
    text = "---\ntitle: Test\nNo closing delimiter"
    meta, body = extract_front_matter(text)
    assert meta == {}
    assert "title: Test" in body


def test_empty_front_matter():
    text = "---\n---\n\nContent"
    meta, body = extract_front_matter(text)
    assert meta == {}
    assert "Content" in body
