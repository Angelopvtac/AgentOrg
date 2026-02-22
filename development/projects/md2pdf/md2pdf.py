#!/usr/bin/env python3
"""
md2pdf — Markdown to PDF with a design system.

Pipeline: input.md → YAML extract → component preprocess → markdown render → Jinja2 template → WeasyPrint → PDF
"""
import os
import shutil
import subprocess
import sys
import re

import click
import yaml
import markdown
from jinja2 import Environment, FileSystemLoader
from weasyprint import HTML

from components import preprocess, build_cover_html, get_warnings
from typst_converter import TypstConverter

# --- Paths ---
ROOT = os.path.dirname(os.path.abspath(__file__))
CSS_DIR = os.path.join(ROOT, 'css')
THEMES_DIR = os.path.join(CSS_DIR, 'themes')
TEMPLATES_DIR = os.path.join(ROOT, 'templates')

# CSS load order
CSS_FILES = ['variables.css', 'base.css', 'components.css', 'print.css']

# Markdown extensions
MD_EXTENSIONS = ['tables', 'fenced_code', 'toc', 'sane_lists', 'md_in_html', 'attr_list']


def load_css(theme=None):
    """Load all CSS files in order, optionally appending a theme."""
    sheets = []
    for name in CSS_FILES:
        path = os.path.join(CSS_DIR, name)
        if os.path.exists(path):
            with open(path) as f:
                sheets.append(f.read())

    # Theme
    if theme and theme != 'default':
        theme_path = os.path.join(THEMES_DIR, f'{theme}.css')
        if os.path.exists(theme_path):
            with open(theme_path) as f:
                sheets.append(f.read())
        else:
            available = list_available_themes()
            raise click.ClickException(
                f"Theme '{theme}' not found. Available: {', '.join(available)}"
            )
    return sheets


def list_available_themes():
    """Return sorted list of available theme names."""
    themes = []
    if os.path.isdir(THEMES_DIR):
        for f in os.listdir(THEMES_DIR):
            if f.endswith('.css'):
                themes.append(f[:-4])
    return sorted(themes)


def extract_front_matter(text):
    """Extract YAML front matter from markdown text.

    Returns (metadata_dict, remaining_text).
    """
    if not text.startswith('---'):
        return {}, text

    # Find closing ---
    end = text.find('\n---', 3)
    if end == -1:
        return {}, text

    yaml_str = text[3:end].strip()
    remainder = text[end + 4:].lstrip('\n')

    try:
        meta = yaml.safe_load(yaml_str) or {}
    except yaml.YAMLError as e:
        click.echo(f"  Warning: Invalid YAML front matter: {e}", err=True)
        meta = {}

    return meta, remainder


def render_markdown(text):
    """Render markdown text to HTML."""
    return markdown.markdown(text, extensions=MD_EXTENSIONS)


def assemble_html(content_html, meta, css_sheets, extra_css=None):
    """Wrap rendered HTML in the Jinja2 base template."""
    env = Environment(loader=FileSystemLoader(TEMPLATES_DIR))
    template = env.get_template('base.html')

    return template.render(
        title=meta.get('title', ''),
        css_files=css_sheets,
        extra_css=extra_css or '',
        content=content_html,
    )


def convert_file(input_path, output_path=None, theme=None, extra_css=None):
    """Full pipeline: markdown file → PDF file."""
    if not os.path.exists(input_path):
        raise click.ClickException(f"File not found: {input_path}")

    with open(input_path) as f:
        raw = f.read()

    # 1. Extract front matter
    meta, body = extract_front_matter(raw)

    # 2. Build cover page if requested
    cover_html = build_cover_html(meta)

    # 3. Component preprocessing
    processed = preprocess(body)

    # Show any warnings
    warnings = get_warnings()
    if warnings:
        click.echo(f"  Warnings in {os.path.basename(input_path)}:")
        for w in warnings:
            click.echo(w, err=True)

    # 4. Render markdown → HTML
    body_html = render_markdown(processed)

    # Combine cover + body
    content_html = cover_html + '\n' + body_html if cover_html else body_html

    # 5. Load CSS
    css_sheets = load_css(theme)

    # 6. Assemble full HTML
    full_html = assemble_html(content_html, meta, css_sheets, extra_css)

    # 7. Generate PDF
    if output_path is None:
        base = os.path.splitext(input_path)[0]
        output_path = base + '.pdf'

    # Ensure output directory exists
    out_dir = os.path.dirname(output_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    HTML(string=full_html, base_url=os.path.dirname(os.path.abspath(input_path))).write_pdf(output_path)

    size_kb = os.path.getsize(output_path) / 1024
    click.echo(f"  {os.path.basename(output_path)} ({size_kb:.0f} KB)")
    return output_path


def convert_file_typst(input_path, output_path=None):
    """Full pipeline: markdown file → Typst → PDF."""
    if not os.path.exists(input_path):
        raise click.ClickException(f"File not found: {input_path}")

    # Find typst binary
    typst_bin = shutil.which('typst')
    if not typst_bin:
        # Check common locations
        local_bin = os.path.expanduser('~/.local/bin/typst')
        if os.path.exists(local_bin):
            typst_bin = local_bin
        else:
            raise click.ClickException(
                "typst not found. Install from https://github.com/typst/typst/releases"
            )

    with open(input_path) as f:
        raw = f.read()

    # 1. Extract front matter
    meta, body = extract_front_matter(raw)

    # 2. Convert to Typst source
    converter = TypstConverter()
    source_dir = os.path.dirname(os.path.abspath(input_path))
    typ_source = converter.convert(body, meta, source_dir=source_dir, root_dir=ROOT)

    # 3. Write .typ file in the md2pdf project root (so imports resolve)
    input_basename = os.path.splitext(os.path.basename(input_path))[0]
    typ_path = os.path.join(ROOT, input_basename + '.typ')
    with open(typ_path, 'w') as f:
        f.write(typ_source)

    # 4. Determine output path
    if output_path is None:
        output_path = os.path.splitext(input_path)[0] + '.pdf'

    out_dir = os.path.dirname(output_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    # 5. Compile with typst (root = md2pdf project so imports work)
    result = subprocess.run(
        [typst_bin, 'compile', '--root', ROOT, typ_path, output_path],
        capture_output=True, text=True,
    )

    if result.returncode != 0:
        click.echo(f"  Typst errors:\n{result.stderr}", err=True)
        raise click.ClickException("typst compile failed")

    if result.stderr:
        # Show warnings but don't fail
        for line in result.stderr.strip().split('\n'):
            if line.strip():
                click.echo(f"  typst: {line}", err=True)

    size_kb = os.path.getsize(output_path) / 1024
    click.echo(f"  {os.path.basename(output_path)} ({size_kb:.0f} KB)")
    click.echo(f"  .typ source: {typ_path}")
    return output_path


# ===================== CLI =====================

@click.group()
@click.version_option(version='1.0.0', prog_name='md2pdf')
def cli():
    """md2pdf — Markdown to professional PDF with a design system."""
    pass


@cli.command()
@click.argument('input_file', type=click.Path(exists=True))
@click.option('-o', '--output', type=click.Path(), default=None, help='Output PDF path')
@click.option('-t', '--theme', default='default', help='Theme name (default, dark, minimal)')
@click.option('--css', default=None, help='Extra CSS file to include')
@click.option('-e', '--engine', default='weasyprint', type=click.Choice(['weasyprint', 'typst']),
              help='PDF engine (weasyprint or typst)')
def convert(input_file, output, theme, css, engine):
    """Convert a markdown file to PDF."""
    click.echo(f"Converting {os.path.basename(input_file)} (engine: {engine})...")

    if engine == 'typst':
        convert_file_typst(input_file, output)
    else:
        extra_css = None
        if css:
            with open(css) as f:
                extra_css = f.read()
        convert_file(input_file, output, theme, extra_css)

    click.echo("Done.")


@cli.command()
@click.argument('input_dir', type=click.Path(exists=True))
@click.option('-o', '--output-dir', type=click.Path(), default=None, help='Output directory')
@click.option('-t', '--theme', default='default', help='Theme name')
@click.option('--css', default=None, help='Extra CSS file to include')
def batch(input_dir, output_dir, theme, css):
    """Batch convert all .md files in a directory."""
    extra_css = None
    if css:
        with open(css) as f:
            extra_css = f.read()

    md_files = sorted(
        f for f in os.listdir(input_dir)
        if f.endswith('.md') and not f.startswith('.')
    )

    if not md_files:
        click.echo("No .md files found.")
        return

    click.echo(f"Converting {len(md_files)} files...")
    for md_file in md_files:
        input_path = os.path.join(input_dir, md_file)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
            out_name = os.path.splitext(md_file)[0] + '.pdf'
            out_path = os.path.join(output_dir, out_name)
        else:
            out_path = None

        try:
            convert_file(input_path, out_path, theme, extra_css)
        except Exception as e:
            click.echo(f"  ERROR on {md_file}: {e}", err=True)

    click.echo("Done.")


@cli.command('list-themes')
def list_themes():
    """Show available themes."""
    themes = list_available_themes()
    click.echo("Available themes:")
    for t in themes:
        marker = " (active)" if t == 'default' else ""
        click.echo(f"  - {t}{marker}")


@cli.command('list-components')
def list_components():
    """Show available component syntax reference."""
    click.echo("""md2pdf Component Reference
=========================

CALLOUTS (colored boxes with left border):
  ::: blue                    Blue callout
  ::: green                   Green callout
  ::: orange                  Orange callout
  ::: purple                  Purple callout
  ::: red                     Red callout
  ::: blue Title Text         Callout with title
  :::                         Close any block

LAYOUT:
  :::: columns                Start column container
  ::: col                     Column within container
  :::                         Close column
  ::::                        Close column container
  ---pagebreak---             Force page break

CARDS & BOXES:
  ::: card                    Generic card
  ::: key-insight             Dark insight box (auto "KEY INSIGHT" label)
  ::: highlight               Purple gradient highlight box
  ::: section-intro           Gray intro box for sections
  ::: idea-card               Idea card with border
  ::: idea-header             Idea card header section
  ::: idea-body               Idea card body section

DATA:
  ::: metrics                 Metric row from "Key: Value | Key: Value"
  ::: stat-row                Flex row of stat cards
  ::: stat-card               Individual stat card

BADGES & PILLS:
  [TEXT]{.badge-high}         Green badge
  [TEXT]{.badge-med}          Orange badge
  [TEXT]{.badge-blue}         Blue badge
  [TEXT]{.badge-red}          Red badge
  [TEXT]{.badge-gray}         Gray badge
  [TEXT]{.pill}               Metric pill

TEMPLATES & WORKSHEETS:
  ::: worksheet               Dashed worksheet box
  >> Label                    Field label (inside worksheet)
  > value                     Field value (inside worksheet)
  ::: checklist               Green checklist box
  ::: scoring                 Blue scoring guide box
  ::: template-card           Template card with dark header
  ::: template-body           Template card body

OTHER:
  ::: sprint                  Sprint week box (blue left border)
  ::: go-no-go                Dark go/no-go decision box
  ::: back-cover              Back cover page
  ::: footer                  Report footer section

COVER PAGE (YAML front matter):
  ---
  title: My Report
  subtitle: A Subtitle
  cover: true
  edition: "2026 Edition"
  stats:
    - value: "$100M"
      label: "Market Size"
  tagline: "Compelling tagline here"
  ---
""")


if __name__ == '__main__':
    cli()
