"""
Component preprocessor for md2pdf.

Transforms markdown-friendly conventions into HTML class annotations
BEFORE the markdown engine processes the content.

Supported conventions:
  ::: blue             → <div class="callout callout-blue" markdown="1">
  ::: card             → <div class="card" markdown="1">
  ::: key-insight      → <div class="key-insight" markdown="1">
  ::: highlight        → <div class="highlight-box" markdown="1">
  ::: worksheet        → <div class="worksheet" markdown="1">
  ::: sprint           → <div class="sprint-week" markdown="1">
  ::: metrics          → metric row from "Key: Value | Key: Value"
  ::: checklist        → <div class="checklist" markdown="1">
  ::: scoring          → <div class="scoring-guide" markdown="1">
  ::: go-no-go         → <div class="go-no-go" markdown="1">
  ::: section-intro    → <div class="section-intro" markdown="1">
  ::: section-divider  → <div class="section-divider" markdown="1">
  ::: back-cover       → <div class="back-cover" markdown="1">
  ::: footer           → <div class="report-footer" markdown="1">
  ::: toc              → <div class="toc" markdown="1">
  ::: template-header  → <div class="template-header" markdown="1">
  :::: columns / ::: col  → flex columns
  [TEXT]{.classname}   → <span class="classname">TEXT</span>
  ---pagebreak---      → <div class="page-break"></div>
  >> Label             → field label (inside worksheet)
  > value              → field input value (after >> label)
  Cover page from YAML front matter
"""
import re
import sys

# Callout color names
CALLOUT_COLORS = {'blue', 'green', 'orange', 'purple', 'red'}

# Component types that map directly to a CSS class (all stack-based)
SIMPLE_COMPONENTS = {
    'card': 'card',
    'key-insight': 'key-insight',
    'highlight': 'highlight-box',
    'worksheet': 'worksheet',
    'sprint': 'sprint-week',
    'checklist': 'checklist',
    'scoring': 'scoring-guide',
    'go-no-go': 'go-no-go',
    'section-intro': 'section-intro',
    'section-divider': 'section-divider',
    'back-cover': 'back-cover',
    'footer': 'report-footer',
    'idea-card': 'idea-card',
    'idea-header': 'idea-header',
    'idea-body': 'idea-body',
    'template-card': 'template-card',
    'template-header': 'template-header',
    'template-body': 'template-body',
    'stat-row': 'stat-row',
    'stat-card': 'stat-card',
    'toc': 'toc',
    'comparison-matrix': 'comparison-matrix',
}

# Warnings collected during processing
_warnings = []


def warn(line_num, msg):
    _warnings.append(f"  Line {line_num}: {msg}")


def get_warnings():
    """Return and clear collected warnings."""
    global _warnings
    w = _warnings[:]
    _warnings = []
    return w


def build_cover_html(meta):
    """Generate cover page HTML from YAML front matter."""
    if not meta.get('cover'):
        return ''

    parts = ['<div class="cover-page">']

    if meta.get('edition'):
        parts.append(f'<div class="edition">{meta["edition"]}</div>')

    parts.append(f'<h1>{meta.get("title", "Untitled")}</h1>')

    if meta.get('subtitle'):
        parts.append(f'<div class="subtitle">{meta["subtitle"]}</div>')

    parts.append('<div class="cover-divider"></div>')

    if meta.get('stats'):
        parts.append('<div class="stat-cards">')
        for stat in meta['stats']:
            parts.append('<div class="stat-card">')
            parts.append(f'<span class="number">{stat["value"]}</span>')
            parts.append(f'<span class="label">{stat["label"]}</span>')
            parts.append('</div>')
        parts.append('</div>')

    if meta.get('tagline'):
        parts.append(f'<div class="tagline">{meta["tagline"]}</div>')

    parts.append('</div>')
    return '\n'.join(parts)


def process_metrics_block(lines):
    """Convert 'Key: Value | Key: Value' lines into metric row HTML."""
    html_parts = ['<div class="metric-row">']
    for line in lines:
        line = line.strip()
        if not line:
            continue
        # Split on | for multiple metrics per line
        entries = [e.strip() for e in line.split('|')]
        for entry in entries:
            if ':' in entry:
                label, value = entry.split(':', 1)
                html_parts.append('<div class="metric">')
                html_parts.append(f'<span class="metric-label">{label.strip()}</span>')
                html_parts.append(f'<span class="metric-value">{value.strip()}</span>')
                html_parts.append('</div>')
            elif entry:
                # Plain metric pill
                html_parts.append(f'<span class="metric-pill">{entry}</span>')
    html_parts.append('</div>')
    return '\n'.join(html_parts)


def _replace_span(match):
    """Replace [TEXT]{.classname} with appropriate span."""
    text = match.group(1)
    cls = match.group(2)
    if cls == 'pill':
        return f'<span class="metric-pill">{text}</span>'
    return f'<span class="{cls}">{text}</span>'


def preprocess(text):
    """
    Transform markdown conventions into HTML-annotated markdown.

    Returns the transformed text ready for markdown rendering.
    """
    lines = text.split('\n')
    output = []
    # Stack for tracking nested block openers: (line_num, type)
    block_stack = []
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # --- Page break ---
        if stripped == '---pagebreak---':
            output.append('<div class="page-break"></div>')
            i += 1
            continue

        # --- Field syntax: >> Label / > value (inside worksheet blocks) ---
        if stripped.startswith('>> '):
            in_worksheet = any(t == 'worksheet' for _, t in block_stack)
            if in_worksheet:
                label = stripped[3:].strip()
                field_values = []
                peek = i + 1
                while peek < len(lines):
                    next_stripped = lines[peek].strip()
                    if not next_stripped:
                        break
                    if next_stripped.startswith('> ') and not next_stripped.startswith('>> '):
                        field_values.append(next_stripped[2:].strip())
                        peek += 1
                    else:
                        break
                output.append('<div class="field">')
                output.append(f'<span class="field-label">{label}</span>')
                for v in field_values:
                    output.append(f'<span class="field-input">{v}</span>')
                if not field_values:
                    output.append('<span class="field-input"></span>')
                output.append('</div>')
                i = peek
                continue

        # --- Span class syntax: [TEXT]{.classname} ---
        if '{.' in line:
            line = re.sub(
                r'\[([^\]]+)\]\{\.([a-zA-Z][\w-]*)\}',
                _replace_span,
                line
            )

        # --- Four-colon column container: :::: columns ---
        if stripped.startswith(':::: '):
            comp_type = stripped[5:].strip()
            if comp_type == 'columns':
                output.append('<div class="columns" markdown="1">')
                block_stack.append((i + 1, 'columns-4'))
                i += 1
                continue

        # --- Four-colon close: :::: ---
        if stripped == '::::':
            if block_stack and block_stack[-1][1] == 'columns-4':
                output.append('</div>')
                block_stack.pop()
                i += 1
                continue

        # --- Three-colon block open: ::: type [title] ---
        if stripped.startswith('::: ') and not stripped.startswith(':::: '):
            rest = stripped[4:].strip()
            # Extract optional title after the type
            parts = rest.split(None, 1)
            comp_type = parts[0] if parts else rest
            title_text = parts[1] if len(parts) > 1 else None

            # Callout colors
            if comp_type in CALLOUT_COLORS:
                output.append(f'<div class="callout callout-{comp_type}" markdown="1">')
                if title_text:
                    output.append(f'<span class="callout-title">{title_text}</span>')
                block_stack.append((i + 1, 'callout'))
                i += 1
                continue

            # Metrics block — collect lines until ::: (no nesting expected)
            if comp_type == 'metrics':
                metric_lines = []
                i += 1
                while i < len(lines) and lines[i].strip() != ':::':
                    metric_lines.append(lines[i])
                    i += 1
                output.append(process_metrics_block(metric_lines))
                if i < len(lines):
                    i += 1  # skip closing :::
                else:
                    warn(i, "Unclosed ::: metrics block")
                continue

            # Simple components (all stack-based, support nesting)
            if comp_type in SIMPLE_COMPONENTS:
                css_class = SIMPLE_COMPONENTS[comp_type]
                output.append(f'<div class="{css_class}" markdown="1">')
                if title_text:
                    output.append(f'**{title_text}**\n')
                block_stack.append((i + 1, comp_type))
                i += 1
                continue

            # Column inside columns container
            if comp_type == 'col':
                output.append('<div class="col" markdown="1">')
                block_stack.append((i + 1, 'col'))
                i += 1
                continue

            # Unknown component type — pass through as generic div
            output.append(f'<div class="{comp_type}" markdown="1">')
            if title_text:
                output.append(f'**{title_text}**\n')
            block_stack.append((i + 1, comp_type))
            i += 1
            continue

        # --- Three-colon close: ::: ---
        if stripped == ':::':
            if block_stack:
                output.append('</div>')
                block_stack.pop()
            else:
                warn(i + 1, "Stray ::: closer with no matching opener")
                output.append(line)
            i += 1
            continue

        # Default: pass through
        # Ensure blank line before list items when preceded by a non-blank, non-list line
        # (Python-Markdown requires this to parse lists correctly, especially inside md_in_html)
        is_list_item = (
            stripped.startswith('- ') or
            stripped.startswith('* ') or
            stripped.startswith('+ ') or
            bool(re.match(r'^\d+\.\s', stripped))
        )
        if is_list_item and output:
            prev = output[-1].strip()
            prev_is_list = (
                prev.startswith('- ') or
                prev.startswith('* ') or
                prev.startswith('+ ') or
                bool(re.match(r'^\d+\.\s', prev))
            )
            if prev and not prev_is_list:
                output.append('')
        output.append(line)
        i += 1

    # Warn about unclosed blocks
    for line_num, btype in block_stack:
        warn(line_num, f"Unclosed ::: {btype} block (opened on line {line_num})")

    return '\n'.join(output)
