# md2pdf

Markdown to professional PDF with a design system. Write in markdown using simple conventions — get polished, presentation-quality PDFs.

**Dual-engine**: Choose between [WeasyPrint](https://weasyprint.org/) (HTML/CSS) or [Typst](https://typst.app/) (native typesetting) depending on your needs.

## Features

- **25+ components** — callouts, cards, columns, worksheets, metrics, stat cards, badges, charts, and more
- **Cover pages** — generated from YAML front matter with stats, taglines, and edition labels
- **3 built-in themes** — default, dark, minimal (WeasyPrint engine)
- **Typst engine** — presentation-style 16:9 layout with section banners, table of contents, and chart support
- **Batch conversion** — convert entire directories of markdown files
- **Zero raw HTML** — all components use markdown-friendly `::: block` syntax

## Quick Start

### Prerequisites

- Python 3.10+
- [Typst](https://github.com/typst/typst/releases) (optional, for the Typst engine)

### Installation

```bash
pip install click pyyaml markdown jinja2 weasyprint
```

Or with the project's `pyproject.toml`:

```bash
pip install -e .
```

For the Typst engine, install the `typst` binary:

```bash
# Download from https://github.com/typst/typst/releases
# Or via package manager:
brew install typst        # macOS
cargo install typst-cli   # Rust
```

### Usage

```bash
# Convert with WeasyPrint (default)
python md2pdf.py convert input.md -o output.pdf

# Convert with Typst engine
python md2pdf.py convert input.md -o output.pdf --engine typst

# Use a theme (WeasyPrint only)
python md2pdf.py convert input.md --theme dark

# Batch convert a directory
python md2pdf.py batch ./docs/ -o ./output/

# List available themes
python md2pdf.py list-themes

# Show component reference
python md2pdf.py list-components
```

## Component Syntax

All components use markdown-friendly conventions — no raw HTML needed.

### Callouts

```markdown
::: blue Important Note
This is a blue callout with a title.
:::

::: green
Green callout without a title.
:::
```

Available colors: `blue`, `green`, `orange`, `purple`, `red`

### Columns

```markdown
:::: columns
::: col
Left column content
:::
::: col
Right column content
:::
::::
```

### Cards & Boxes

```markdown
::: card
Card content here.
:::

::: key-insight
The most important takeaway.
:::

::: highlight
High-impact content with gradient background.
:::
```

### Badges & Pills

```markdown
[HIGH]{.badge-high} [MEDIUM]{.badge-med} [LOW]{.badge-gray}
[TAM: $1.8B]{.pill} [CAGR: 34%]{.pill}
```

### Metrics

```markdown
::: metrics
TAM: $1.8B | CAGR: 34% | Funding: $450M
:::
```

### Worksheets

```markdown
::: worksheet
>> Company Name
> (enter value)

>> Target Market
> (describe your market)
:::
```

### Cover Page

```yaml
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
```

### Other Components

- `::: section-intro` — section introduction box
- `::: sprint` — sprint planning box
- `::: checklist` — checklist box
- `::: scoring` — scoring guide box
- `::: go-no-go` — decision box
- `::: template-card` / `::: template-header` / `::: template-body` — template cards
- `::: stat-row` / `::: stat-card` — stat card rows
- `::: back-cover` — back cover page
- `::: footer` — report footer
- `---pagebreak---` — force page break

Run `python md2pdf.py list-components` for the full reference.

## Engine Comparison

| Feature | WeasyPrint | Typst |
|---------|-----------|-------|
| Layout | Standard A4/Letter | 16:9 presentation-style |
| Themes | 3 built-in CSS themes | Design-system defaults |
| Section banners | No | Auto-generated from H1 |
| Table of contents | No | `::: toc` block |
| Charts | No | Bar, funnel, quadrant, timeline |
| Cover page | HTML/CSS | Typst native |
| Speed | Moderate | Fast |

## Examples

See the [`examples/`](examples/) directory for sample markdown and generated PDFs:

- `sample.md` — component showcase demonstrating all features
- `charts-test.md` — chart component examples (Typst engine)

## Development

```bash
pip install -e ".[dev]"
pytest
ruff check .
```

## License

[MIT](LICENSE)
