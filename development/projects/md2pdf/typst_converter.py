"""
Typst converter for md2pdf.

Converts markdown with md2pdf conventions into Typst source code.
Pipeline: markdown text → TypstConverter.convert() → .typ source string
"""
import os
import re

CALLOUT_COLORS = {'blue', 'green', 'orange', 'purple', 'red'}

# Badge class → Typst badge variant
BADGE_MAP = {
    'badge-high': 'high',
    'badge-med-high': 'med-high',
    'badge-med': 'med',
    'badge-low': 'low',
    'badge-green': 'green',
    'badge-blue': 'blue',
    'badge-orange': 'orange',
    'badge-red': 'red',
    'badge-gray': 'gray',
    'badge-competition': 'competition',
}

# Span class → Typst function (for non-badge, non-pill spans)
SPAN_MAP = {
    'market-size-label': 'market-size-label',
    'market-size-value': 'market-size-value',
    'market-cagr': 'market-cagr',
    'template-number': 'template-number',
}

# Chart span classes — handled in _replace_span
CHART_SPAN_CLASSES = {
    'score-bar', 'progress-bar', 'harvey',
    'rag-green', 'rag-amber', 'rag-red',
    'heat-critical', 'heat-high', 'heat-med', 'heat-low',
    'indicator-pass', 'indicator-fail',
}

# Block-level chart types — parsed specially
CHART_BLOCK_TYPES = {'bar-chart', 'funnel', 'quadrant', 'timeline'}

# Simple ::: components → Typst function name
SIMPLE_COMPONENTS = {
    'key-insight': 'key-insight',
    'highlight': 'highlight-box',
    'card': 'card',
    'section-intro': 'section-intro',
    'section-divider': 'section-divider',
    'worksheet': 'worksheet',
    'sprint': 'sprint',
    'checklist': 'checklist-box',
    'scoring': 'scoring-guide',
    'go-no-go': 'go-no-go',
    'back-cover': 'back-cover',
    'footer': 'report-footer',
    'toc': None,  # special handling — emits outline()
    'comparison-matrix': 'comparison-matrix',
    'idea-card': None,  # handled specially
    'idea-header': None,
    'idea-body': None,
    'template-card': None,
    'template-header': None,
    'template-body': None,
    'stat-row': None,
    'stat-card': None,
}


class TypstConverter:
    """Convert md2pdf-flavored markdown to Typst source."""

    def __init__(self):
        self.output = []
        self.block_stack = []  # stack of (type, title, content_lines)
        self.in_code_fence = False
        self.table_rows = []
        self.table_alignments = []
        self.in_list = False
        self.list_type = None  # 'ul' or 'ol'
        self._section_counter = 0

    def convert(self, text, meta=None, source_dir=None, root_dir=None):
        """Convert full markdown text to Typst source.

        Args:
            text: Markdown body (after front matter extraction)
            meta: Parsed YAML front matter dict
            source_dir: Directory containing the source markdown file
            root_dir: Typst --root directory for resolving image paths

        Returns:
            Complete .typ source string
        """
        meta = meta or {}
        self._source_dir = source_dir
        self._root_dir = root_dir
        self.output = []
        self.block_stack = []
        self.in_code_fence = False
        self.table_rows = []
        self.table_alignments = []
        self._section_counter = 0

        # File header
        self.output.append('#import "typst/template.typ": *')
        self.output.append('#import "typst/cover.typ": *')
        self.output.append('#import "typst/components.typ": *')
        self.output.append('#import "typst/charts.typ": *')
        self.output.append('')

        # PDF metadata
        self._emit_metadata(meta)

        # Cover page
        if meta.get('cover'):
            self._emit_cover(meta)

        # Document wrapper
        if meta.get('title'):
            self.output.append(f'#show: md2pdf-doc.with(doc-title: "{self._escape_string(meta["title"])}")')
        else:
            self.output.append('#show: md2pdf-doc')
        self.output.append('')

        # Process body
        lines = text.split('\n')
        i = 0
        while i < len(lines):
            i = self._process_line(lines, i)

        # Flush any remaining table
        self._flush_table()

        return '\n'.join(self.output)

    def _emit_cover(self, meta):
        """Emit cover page function call from front matter."""
        self.output.append('#cover-page(')
        self.output.append(f'  title: "{self._escape_string(meta.get("title", "Untitled"))}",')
        if meta.get('subtitle'):
            self.output.append(f'  subtitle: "{self._escape_string(meta["subtitle"])}",')
        if meta.get('edition'):
            self.output.append(f'  edition: "{self._escape_string(meta["edition"])}",')
        if meta.get('stats'):
            self.output.append('  stats: (')
            for stat in meta['stats']:
                self.output.append(f'    (value: "{self._escape_string(str(stat["value"]))}", label: "{self._escape_string(stat["label"])}"),')
            self.output.append('  ),')
        if meta.get('tagline'):
            self.output.append(f'  tagline: "{self._escape_string(meta["tagline"])}",')
        if meta.get('author'):
            author = meta['author']
            if isinstance(author, list):
                author = ', '.join(str(a) for a in author)
            self.output.append(f'  author: "{self._escape_string(str(author))}",')
        self.output.append(')')
        self.output.append('')

    def _emit_metadata(self, meta):
        """Emit #set document(...) for PDF metadata from front matter."""
        parts = []
        if meta.get('title'):
            parts.append(f'title: "{self._escape_string(meta["title"])}"')
        if meta.get('author'):
            author = meta['author']
            if isinstance(author, list):
                author_strs = ', '.join(f'"{self._escape_string(a)}"' for a in author)
                parts.append(f'author: ({author_strs})')
            else:
                parts.append(f'author: "{self._escape_string(str(author))}"')
        if meta.get('keywords'):
            keywords = meta['keywords']
            if isinstance(keywords, str):
                keywords = [k.strip() for k in keywords.split(',')]
            kw_strs = ', '.join(f'"{self._escape_string(k)}"' for k in keywords)
            parts.append(f'keywords: ({kw_strs})')
        if parts:
            self.output.append(f'#set document({", ".join(parts)})')
            self.output.append('')

    def _resolve_image_path(self, path):
        """Resolve an image path relative to the Typst --root directory.

        If source_dir is set, resolves the path relative to the markdown source,
        then makes it relative to root_dir for Typst compilation.
        """
        if path.startswith(('http://', 'https://')):
            return path
        if self._source_dir and not os.path.isabs(path):
            abs_path = os.path.normpath(os.path.join(self._source_dir, path))
        else:
            abs_path = os.path.abspath(path)
        if self._root_dir:
            try:
                return os.path.relpath(abs_path, self._root_dir)
            except ValueError:
                return abs_path
        return abs_path

    def _process_line(self, lines, i):
        """Process a single line, return next line index."""
        line = lines[i]
        stripped = line.strip()

        # --- Code fences ---
        if stripped.startswith('```'):
            if self.in_code_fence:
                self.in_code_fence = False
                self._emit(']\n')
                return i + 1
            else:
                self._flush_table()
                self.in_code_fence = True
                lang = stripped[3:].strip()
                if lang:
                    self._emit(f'#block(width: 100%, inset: space-lg, radius: radius-lg, fill: gradient.linear(dark-bg-start, dark-bg-end, angle: 135deg), stroke: border-width + rgb("#334155"), breakable: false)[#text(font-size-xs, fill: dark-text, font: font-mono)[#raw(block: true, lang: "{lang}",')
                else:
                    self._emit(f'#block(width: 100%, inset: space-lg, radius: radius-lg, fill: gradient.linear(dark-bg-start, dark-bg-end, angle: 135deg), stroke: border-width + rgb("#334155"), breakable: false)[#text(font-size-xs, fill: dark-text, font: font-mono)[#raw(block: true,')
                # Collect code content
                code_lines = []
                j = i + 1
                while j < len(lines) and not lines[j].strip().startswith('```'):
                    code_lines.append(lines[j])
                    j += 1
                code_content = '\n'.join(code_lines)
                # Escape for Typst raw
                self._emit(f'"{self._escape_raw(code_content)}"')
                self._emit(')]]')
                self.in_code_fence = False
                if j < len(lines):
                    j += 1  # skip closing ```
                return j

        if self.in_code_fence:
            self._emit(line)
            return i + 1

        # --- Page break ---
        if stripped == '---pagebreak---':
            self._flush_table()
            self._emit('#pagebreak()')
            return i + 1

        # --- Horizontal rule ---
        # Skip if inside a chart block (--- is used as separator in quadrant charts)
        if stripped == '---' and not stripped.startswith('---\n'):
            in_chart = any(t in CHART_BLOCK_TYPES for t, _, _ in self.block_stack)
            if not in_chart:
                self._flush_table()
                self._emit('#line(length: 100%, stroke: color-border)')
                return i + 1

        # --- Four-colon column container ---
        if stripped.startswith(':::: '):
            comp_type = stripped[5:].strip()
            if comp_type == 'columns':
                self._flush_table()
                self.block_stack.append(('columns-4', None, []))
                return i + 1

        if stripped == '::::':
            if self.block_stack and self.block_stack[-1][0] == 'columns-4':
                self._flush_columns()
                return i + 1

        # --- Three-colon block open ---
        if stripped.startswith('::: ') and not stripped.startswith(':::: '):
            self._flush_table()
            rest = stripped[4:].strip()
            parts = rest.split(None, 1)
            comp_type = parts[0] if parts else rest
            title_text = parts[1] if len(parts) > 1 else None

            # Column inside columns container
            if comp_type == 'col':
                self.block_stack.append(('col', None, []))
                return i + 1

            # Callout
            if comp_type in CALLOUT_COLORS:
                self.block_stack.append(('callout', (comp_type, title_text), []))
                return i + 1

            # Metrics block
            if comp_type == 'metrics':
                metric_lines = []
                i += 1
                while i < len(lines) and lines[i].strip() != ':::':
                    metric_lines.append(lines[i])
                    i += 1
                self._emit_metrics(metric_lines)
                if i < len(lines):
                    i += 1
                return i

            # Chart block types (bar-chart, funnel, quadrant, timeline)
            if comp_type in CHART_BLOCK_TYPES:
                # Parse attributes from the rest line (e.g. bar-chart max=5, quadrant x-axis="..." y-axis="...")
                self.block_stack.append((comp_type, rest, []))
                return i + 1

            # Simple components
            if comp_type in SIMPLE_COMPONENTS:
                self.block_stack.append((comp_type, title_text, []))
                return i + 1

            # Unknown — treat as generic block
            self.block_stack.append((comp_type, title_text, []))
            return i + 1

        # --- Three-colon close ---
        if stripped == ':::':
            if self.block_stack:
                self._close_block()
            return i + 1

        # --- Field syntax >> / > ---
        if stripped.startswith('>> '):
            in_worksheet = any(t == 'worksheet' for t, _, _ in self.block_stack)
            if in_worksheet:
                label = stripped[3:].strip()
                values = []
                j = i + 1
                while j < len(lines):
                    ns = lines[j].strip()
                    if not ns:
                        break
                    if ns.startswith('> ') and not ns.startswith('>> '):
                        values.append(ns[2:].strip())
                        j += 1
                    else:
                        break
                value_text = values[0] if values else ''
                self._append_to_block(f'#field[{self._convert_inline(label)}][{self._convert_inline(value_text)}]')
                return j

        # --- Table rows ---
        if stripped.startswith('|') and stripped.endswith('|'):
            # Check if this is a separator row
            cells = [c.strip() for c in stripped[1:-1].split('|')]
            if all(re.match(r'^:?-+:?$', c) for c in cells if c):
                # Separator row — extract alignment
                self.table_alignments = []
                for c in cells:
                    if c.startswith(':') and c.endswith(':'):
                        self.table_alignments.append('center')
                    elif c.endswith(':'):
                        self.table_alignments.append('right')
                    else:
                        self.table_alignments.append('left')
                return i + 1
            else:
                self.table_rows.append(cells)
                return i + 1
        else:
            # Not a table row — flush any accumulated table
            self._flush_table()

        # --- Block-level images: ![alt](path) or ![alt](path){width=50%} on its own line ---
        img_match = re.match(r'^!\[([^\]]*)\]\(([^)]+)\)(?:\{([^}]*)\})?\s*$', stripped)
        if img_match:
            self._flush_table()
            alt = img_match.group(1)
            img_path = self._resolve_image_path(img_match.group(2))
            attrs = img_match.group(3) or ''
            width_arg = ''
            if attrs:
                w_match = re.search(r'width=(\S+)', attrs)
                if w_match:
                    width_arg = f', width: {w_match.group(1)}'
            if alt:
                self._append_to_block(f'#figure(image("{self._escape_string(img_path)}"{width_arg}), caption: [{self._convert_inline(alt)}])')
            else:
                self._append_to_block(f'#image("{self._escape_string(img_path)}"{width_arg})')
            self._append_to_block('')
            return i + 1

        # --- Headings ---
        heading_match = re.match(r'^(#{1,4})\s+(.+)$', stripped)
        if heading_match:
            level = len(heading_match.group(1))
            text_content = heading_match.group(2)

            # Presentation-style: auto section banners for numbered sections
            if not self.block_stack:
                # H1 always gets a full-bleed section banner
                if level == 1:
                    self._section_counter += 1
                    num = f'{self._section_counter:02d}'
                    self._emit(f'#section-banner(number: "{num}", title: "{self._escape_string(text_content)}")')
                    self._emit('')
                    # Hidden heading for TOC/bookmarks only (zero-height, clipped, show-rule stripped)
                    self._emit(f'#block(height: 0pt, clip: true, above: 0pt, below: 0pt)[#show heading: it => box(width: 0pt, height: 0pt); = {self._convert_inline(text_content)}]')
                    self._emit('')
                    return i + 1

                # H2 with "Domain N:", "Category N:", "Part N:", "Section N:" → section banner
                numbered = re.match(r'^(?:Domain|Category|Part|Section|Chapter|Template)\s+(\d+)\s*[:.]\s*(.+)$', text_content, re.IGNORECASE)
                if level == 2 and numbered:
                    num = f'{int(numbered.group(1)):02d}'
                    title = numbered.group(2).strip()
                    self._emit(f'#section-banner(number: "{num}", title: "{self._escape_string(title)}")')
                    self._emit('')
                    # Hidden heading for TOC/bookmarks only (zero-height, clipped, show-rule stripped)
                    self._emit(f'#block(height: 0pt, clip: true, above: 0pt, below: 0pt)[#show heading: it => box(width: 0pt, height: 0pt); == {self._convert_inline(text_content)}]')
                    self._emit('')
                    return i + 1

                # Other H2 headings: pagebreak before them
                if level == 2:
                    self._emit('#pagebreak(weak: true)')

            typst_marker = '=' * level
            self._append_to_block(f'{typst_marker} {self._convert_inline(text_content)}')
            self._append_to_block('')
            return i + 1

        # --- Ordered list ---
        ol_match = re.match(r'^(\d+)\.\s+(.+)$', stripped)
        if ol_match:
            content = ol_match.group(2)
            self._append_to_block(f'+ {self._convert_inline(content)}')
            return i + 1

        # --- Unordered list ---
        ul_match = re.match(r'^(\s*)-\s+(.+)$', line)
        if ul_match:
            indent = len(ul_match.group(1))
            content = ul_match.group(2)
            typst_indent = '  ' * (indent // 2) if indent > 0 else ''
            self._append_to_block(f'{typst_indent}- {self._convert_inline(content)}')
            return i + 1

        # --- Blockquote ---
        if stripped.startswith('> '):
            quote_lines = []
            j = i
            while j < len(lines) and lines[j].strip().startswith('> '):
                quote_lines.append(lines[j].strip()[2:])
                j += 1
            quote_content = ' '.join(quote_lines)
            self._append_to_block(f'#quote(block: true)[{self._convert_inline(quote_content)}]')
            return j

        # --- Blank line ---
        if not stripped:
            self._append_to_block('')
            return i + 1

        # --- Regular paragraph text ---
        self._append_to_block(self._convert_inline(stripped))
        return i + 1

    def _append_to_block(self, text):
        """Append text to current block or top-level output."""
        if self.block_stack:
            self.block_stack[-1][2].append(text)
        else:
            self.output.append(text)

    def _emit(self, text):
        """Emit text to top-level output (bypasses block stack)."""
        self.output.append(text)

    def _close_block(self):
        """Close the top block on the stack and emit its Typst representation."""
        block_type, block_data, content = self.block_stack.pop()

        # Special blocks with mixed content types (tuples + strings)
        if block_type in SIMPLE_COMPONENTS and SIMPLE_COMPONENTS[block_type] is None:
            self._close_special_block(block_type, block_data, content)
            return

        # Chart block types
        if block_type in CHART_BLOCK_TYPES:
            self._close_chart_block(block_type, block_data, content)
            return

        # Filter to strings only for joining (skip any tuple markers)
        str_content = [c for c in content if isinstance(c, str)]
        converted_content = '\n'.join(str_content).strip()

        if block_type == 'callout':
            color, title = block_data
            if title:
                result = f'#callout("{color}", title: "{self._escape_string(title)}")[{converted_content}]'
            else:
                result = f'#callout("{color}")[{converted_content}]'
            self._append_to_block(result)
            self._append_to_block('')

        elif block_type == 'col':
            # Columns are collected by the parent columns-4 block
            if self.block_stack and self.block_stack[-1][0] == 'columns-4':
                self.block_stack[-1][2].append(('__col__', converted_content))
            return

        elif block_type in SIMPLE_COMPONENTS:
            func_name = SIMPLE_COMPONENTS[block_type]
            if block_data:  # has title
                converted_content = f'*{self._convert_inline(block_data)}*\n\n{converted_content}'
            result = f'#{func_name}[{converted_content}]'
            self._append_to_block(result)
            self._append_to_block('')

        else:
            # Unknown block — wrap in a generic block
            if block_data:
                converted_content = f'*{self._convert_inline(block_data)}*\n\n{converted_content}'
            result = f'#block(width: 100%, above: space-md, below: space-md)[{converted_content}]'
            self._append_to_block(result)
            self._append_to_block('')

    def _close_special_block(self, block_type, block_data, content):
        """Handle special block types that need custom logic."""
        str_content = [c for c in content if isinstance(c, str)]
        raw = '\n'.join(str_content)
        converted = raw.strip()

        if block_type == 'stat-card':
            # Parse stat-card content for number and label spans
            # Content has HTML spans: <span class="number">$202B</span>
            num_match = re.search(r'<span\s+class="number">([^<]+)</span>', raw)
            label_match = re.search(r'<span\s+class="label">([^<]+)</span>', raw)
            if num_match and label_match:
                num_val = self._escape_typst(num_match.group(1))
                label_val = self._escape_typst(label_match.group(1))
                result = f'stat-card[{num_val}][{label_val}]'
            else:
                result = f'card[{converted}]'
            # If inside stat-row, store as raw call (no # prefix — parent adds it)
            if self.block_stack and self.block_stack[-1][0] == 'stat-row':
                self.block_stack[-1][2].append(('__stat_card__', result))
            else:
                self._append_to_block(f'#{result}')

        elif block_type == 'stat-row':
            # Collect stat-card children and emit as stat-row
            cards = []
            for item in content:
                if isinstance(item, tuple) and item[0] == '__stat_card__':
                    cards.append(item[1])
            if cards:
                card_args = ', '.join(cards)  # no # prefix inside function args
                result = f'#stat-row({card_args})'
            else:
                result = f'#block[{converted}]'
            self._append_to_block(result)

        elif block_type in ('idea-header', 'idea-body'):
            # Store as tuple in parent idea-card
            if self.block_stack and self.block_stack[-1][0] == 'idea-card':
                self.block_stack[-1][2].append((f'__{block_type}__', converted))
            else:
                self._append_to_block(converted)

        elif block_type == 'idea-card':
            header = ''
            body_parts = []
            for item in content:
                if isinstance(item, tuple) and item[0] == '__idea-header__':
                    header = item[1]
                elif isinstance(item, tuple) and item[0] == '__idea-body__':
                    body_parts.append(item[1])
                elif isinstance(item, str):
                    body_parts.append(item)
            body = '\n'.join(body_parts).strip()
            # Use card with header styling instead of nesting content blocks
            self._append_to_block(f'#block(width: 100%, breakable: true, above: space-lg, below: space-lg, radius: radius-lg, stroke: border-width + color-border, clip: true)[')
            if header:
                self._append_to_block(f'  #block(width: 100%, inset: (x: space-lg, y: space-md), fill: color-bg-subtle)[{header}]')
            self._append_to_block(f'  #block(width: 100%, inset: (x: space-lg, y: space-md))[{body}]')
            self._append_to_block(']')

        elif block_type == 'toc':
            # Emit preamble content + auto-generated outline with page numbers
            self._append_to_block('#toc-block[')
            if converted:
                self._append_to_block(converted)
            self._append_to_block('#outline(title: none, indent: auto)')
            self._append_to_block(']')

        elif block_type in ('template-header', 'template-body'):
            # Store as tuple in parent template-card
            if self.block_stack and self.block_stack[-1][0] == 'template-card':
                self.block_stack[-1][2].append((f'__{block_type}__', converted))
            else:
                self._append_to_block(converted)

        elif block_type == 'template-card':
            header = ''
            body_parts = []
            for item in content:
                if isinstance(item, tuple) and item[0] == '__template-header__':
                    header = item[1]
                elif isinstance(item, tuple) and item[0] == '__template-body__':
                    body_parts.append(item[1])
                elif isinstance(item, str):
                    body_parts.append(item)
            body = '\n'.join(body_parts).strip()
            self._append_to_block('#block(width: 100%, above: space-xl, below: space-xl, stroke: (left: 3pt + color-primary))[')
            if header:
                self._append_to_block(f'  #block(width: 100%, inset: (x: space-xl, y: space-lg), radius: radius-md, fill: gradient.linear(dark-bg-start, rgb("#334155"), angle: 135deg))[#set text(fill: white)\n#show heading: it => text(13pt, fill: white, weight: 700)[#it.body]\n{header}]')
            self._append_to_block(f'  #block(width: 100%, inset: (x: space-xl, y: space-lg))[{body}]')
            self._append_to_block(']')

        self._append_to_block('')

    def _close_chart_block(self, block_type, block_data, content):
        """Handle chart block types: bar-chart, funnel, quadrant, timeline."""
        str_content = [c for c in content if isinstance(c, str)]
        lines = [l.strip() for l in str_content if l.strip()]

        if block_type == 'bar-chart':
            # Parse "max=N" from block_data (e.g. "bar-chart max=5")
            max_val = 5
            if block_data:
                m = re.search(r'max=(\d+)', block_data)
                if m:
                    max_val = int(m.group(1))
            items = []
            for line in lines:
                if ':' in line:
                    label, val = line.rsplit(':', 1)
                    label = label.strip()
                    val = val.strip()
                    # Strip Typst escaping from label for clean output
                    label = label.replace('\\#', '#').replace('\\$', '$').replace('\\@', '@')
                    try:
                        items.append((label, float(val)))
                    except ValueError:
                        continue
            if items:
                item_strs = ', '.join(
                    f'(label: "{self._escape_string(label)}", value: {val})'
                    for label, val in items
                )
                self._append_to_block(f'#bar-chart(({item_strs}), max: {max_val})')
                self._append_to_block('')

        elif block_type == 'funnel':
            # Parse "Label: Value | Percent" lines
            stages = []
            for line in lines:
                if ':' in line:
                    label, rest = line.split(':', 1)
                    label = label.strip().replace('\\$', '$').replace('\\#', '#')
                    parts = rest.split('|')
                    value = parts[0].strip().replace('\\$', '$') if parts else ''
                    pct = parts[1].strip() if len(parts) > 1 else ''
                    stages.append((label, value, pct))
            if stages:
                stage_strs = ', '.join(
                    f'(label: "{self._escape_string(label)}", value: "{self._escape_string(val)}", percent: "{self._escape_string(pct)}")'
                    for label, val, pct in stages
                )
                self._append_to_block(f'#funnel-chart(({stage_strs}))')
                self._append_to_block('')

        elif block_type == 'quadrant':
            # Parse attributes: x-axis="..." y-axis="..."
            x_label = 'X Axis'
            y_label = 'Y Axis'
            if block_data:
                m = re.search(r'x-axis="([^"]+)"', block_data)
                if m:
                    x_label = m.group(1)
                m = re.search(r'y-axis="([^"]+)"', block_data)
                if m:
                    y_label = m.group(1)

            quadrants = []
            points = []
            in_points = False
            for line in lines:
                line_clean = line.replace('\\#', '#').replace('\\$', '$').replace('\\@', '@')
                if line_clean.strip() == '---' or line_clean.strip() == '\\-\\-\\-':
                    in_points = True
                    continue
                if line_clean.startswith('---'):
                    in_points = True
                    continue
                if not in_points:
                    # Q-lines: "Q1 Label: Description"
                    qm = re.match(r'Q(\d)\s+([^:]+):\s*(.*)', line_clean)
                    if qm:
                        quadrants.append((qm.group(2).strip(), qm.group(3).strip()))
                else:
                    # Data points: "Label: x, y"
                    if ':' in line_clean:
                        plabel, coords = line_clean.split(':', 1)
                        coord_parts = coords.split(',')
                        if len(coord_parts) == 2:
                            try:
                                x = float(coord_parts[0].strip())
                                y = float(coord_parts[1].strip())
                                points.append((plabel.strip(), x, y))
                            except ValueError:
                                continue

            quad_strs = ', '.join(
                f'(label: "{self._escape_string(q[0])}", desc: "{self._escape_string(q[1])}")'
                for q in quadrants
            )
            point_strs = ', '.join(
                f'(label: "{self._escape_string(p[0])}", x: {p[1]}, y: {p[2]})'
                for p in points
            )
            self._append_to_block(
                f'#quadrant-chart(x-label: "{self._escape_string(x_label)}", '
                f'y-label: "{self._escape_string(y_label)}", '
                f'quadrants: ({quad_strs}), '
                f'points: ({point_strs}))'
            )
            self._append_to_block('')

        elif block_type == 'timeline':
            # Parse "Period: Title | Description" lines
            items = []
            for line in lines:
                if ':' in line:
                    period, rest = line.split(':', 1)
                    period = period.strip().replace('\\#', '#').replace('\\$', '$')
                    parts = rest.split('|')
                    title = parts[0].strip()
                    desc = parts[1].strip() if len(parts) > 1 else ''
                    items.append((period, title, desc))
            if items:
                item_strs = ', '.join(
                    f'(period: "{self._escape_string(p)}", title: "{self._escape_string(t)}", desc: "{self._escape_string(d)}")'
                    for p, t, d in items
                )
                self._append_to_block(f'#timeline-chart(({item_strs}))')
                self._append_to_block('')

    def _flush_columns(self):
        """Flush a columns-4 block, arranging cols in a grid."""
        if not self.block_stack:
            return
        block_type, _, content = self.block_stack.pop()
        if block_type != 'columns-4':
            return

        # Separate column content from non-column content
        cols = []
        other = []
        for item in content:
            if isinstance(item, tuple) and item[0] == '__col__':
                cols.append(item[1])
            else:
                other.append(item)

        if not cols:
            # No columns found, just emit content
            for item in content:
                if isinstance(item, tuple):
                    self._append_to_block(item[1])
                else:
                    self._append_to_block(item)
            return

        col_fracs = ', '.join(['1fr'] * len(cols))
        parts = [f'#grid(columns: ({col_fracs}), gutter: space-lg,']
        for col_content in cols:
            parts.append(f'  [{col_content}],')
        parts.append(')')

        result = '\n'.join(parts)
        self._append_to_block(result)
        self._append_to_block('')

    def _flush_table(self):
        """Convert accumulated table rows to Typst table."""
        if not self.table_rows:
            return

        rows = self.table_rows
        self.table_rows = []
        alignments = self.table_alignments
        self.table_alignments = []

        if not rows:
            return

        num_cols = len(rows[0])
        has_header = len(rows) > 1  # first row is header if we have data rows

        # Build column specs
        col_specs = ', '.join(['1fr'] * num_cols)

        parts = []
        parts.append(f'#table(')
        parts.append(f'  columns: ({col_specs}),')
        parts.append(f'  fill: (_, row) => if row == 0 {{ table-header-bg }} else if calc.even(row) {{ table-stripe }} else {{ white }},')
        parts.append(f'  inset: (x: space-md, y: 6pt),')
        parts.append(f'  stroke: none,')

        if has_header:
            header_cells = rows[0]
            header_parts = []
            for cell in header_cells:
                cell_content = self._convert_inline(cell)
                header_parts.append(f'    text(fill: table-header-text, weight: 600, size: font-size-xxs, tracking: 0.5pt)[#upper[{cell_content}]]')
            parts.append(f'  table.header(')
            parts.append(',\n'.join(header_parts))
            parts.append(f'  ),')

            # Data rows
            for row in rows[1:]:
                for cell in row:
                    cell_content = self._convert_inline(cell)
                    parts.append(f'  [{cell_content}],')
        else:
            for row in rows:
                for cell in row:
                    cell_content = self._convert_inline(cell)
                    parts.append(f'  [{cell_content}],')

        parts.append(')')
        result = '\n'.join(parts)
        self._append_to_block(result)
        self._append_to_block('')

    def _emit_metrics(self, lines):
        """Convert metrics block lines to Typst metric-row."""
        entries = []
        for line in lines:
            line = line.strip()
            if not line:
                continue
            for entry in line.split('|'):
                entry = entry.strip()
                if ':' in entry:
                    label, value = entry.split(':', 1)
                    entries.append((label.strip(), value.strip()))

        if not entries:
            return

        items = ', '.join(
            f'(label: "{self._escape_string(label)}", value: "{self._escape_string(value)}")'
            for label, value in entries
        )
        self._append_to_block(f'#metric-row({items})')
        self._append_to_block('')

    def _convert_inline(self, text):
        """Convert inline markdown formatting to Typst."""
        if not text:
            return text

        # 1. Escape Typst special characters (but preserve our convention markers)
        text = self._escape_typst(text)

        # 2. Custom spans: [TEXT]{.class}
        text = re.sub(
            r'\[([^\]]+)\]\{\.([a-zA-Z][\w-]*)\}',
            self._replace_span,
            text
        )

        # 3. HTML spans (from stat-card content): <span class="x">text</span>
        text = re.sub(
            r'<span\s+class="([^"]+)">([^<]+)</span>',
            self._replace_html_span,
            text
        )

        # 4a. Inline images: ![alt](path) or ![alt](path){width=X} — BEFORE links
        def _replace_inline_image(m):
            alt = m.group(1)
            img_path = self._resolve_image_path(m.group(2))
            attrs = m.group(3) or ''
            width_arg = ''
            if attrs:
                w_match = re.search(r'width=(\S+)', attrs)
                if w_match:
                    width_arg = f', width: {w_match.group(1)}'
            return f'#image("{self._escape_string(img_path)}"{width_arg})'
        text = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)(?:\{([^}]*)\})?', _replace_inline_image, text)

        # 4b. Links: [text](url)
        text = re.sub(
            r'\[([^\]]+)\]\(([^)]+)\)',
            lambda m: f'#link("{m.group(2)}")[{m.group(1)}]',
            text
        )

        # 5. Bold: **text** → *text* (use placeholder to avoid italic re-match)
        text = re.sub(r'\*\*([^*]+)\*\*', lambda m: '\x01' + m.group(1) + '\x01', text)

        # 6. Italic: *text* → _text_ (match single * not part of **)
        text = re.sub(r'(?<!\*)\*([^*\x01]+)\*(?!\*)', r'_\1_', text)

        # 7. Restore bold markers
        text = text.replace('\x01', '*')

        # 7. Inline code: `text`
        text = re.sub(r'`([^`]+)`', r'`\1`', text)

        # 8. Em dash
        text = text.replace(' -- ', ' --- ')

        # 9. Escape bare underscore sequences (fill-in blanks like ___)
        text = re.sub(r'_{2,}', lambda m: '\\_' * len(m.group(0)), text)

        return text

    def _escape_typst(self, text):
        """Escape Typst special characters in content text."""
        # Protect [TEXT]{.class} patterns, HTML spans, and images BEFORE escaping
        protected = []
        def _save(m):
            protected.append(m.group(0))
            return f'\x00P{len(protected)-1}\x00'
        text = re.sub(r'!\[[^\]]*\]\([^)]+\)(?:\{[^}]*\})?', _save, text)
        text = re.sub(r'\[[^\]]+\]\{\.[a-zA-Z][\w-]*\}', _save, text)
        text = re.sub(r'<span\s[^>]*>.*?</span>', _save, text)
        # Now escape special characters in unprotected content
        text = text.replace('$', '\\$')
        text = text.replace('@', '\\@')
        text = text.replace('#', '\\#')
        text = text.replace('<', '\\<')
        text = text.replace('>', '\\>')
        # Restore protected patterns (their content is escaped in _replace_span)
        for idx, val in enumerate(protected):
            text = text.replace(f'\x00P{idx}\x00', val)
        return text

    def _escape_string(self, text):
        """Escape text for use inside Typst string literals."""
        text = text.replace('\\', '\\\\')
        text = text.replace('"', '\\"')
        return text

    def _escape_raw(self, text):
        """Escape text for Typst raw string (inside quotes)."""
        text = text.replace('\\', '\\\\')
        text = text.replace('"', '\\"')
        return text

    def _replace_span(self, match):
        """Replace [TEXT]{.classname} with Typst function call."""
        text = match.group(1)
        cls = match.group(2)

        # Escape special chars in span content (was protected during _escape_typst)
        text = text.replace('$', '\\$')
        text = text.replace('@', '\\@')
        text = text.replace('#', '\\#')
        text = text.replace('<', '\\<')
        text = text.replace('>', '\\>')

        # Badge classes
        if cls in BADGE_MAP:
            variant = BADGE_MAP[cls]
            return f'#badge("{variant}")[{text}]'

        # Pill
        if cls == 'pill':
            return f'#pill[{text}]'

        # Market size spans
        if cls in SPAN_MAP:
            func = SPAN_MAP[cls]
            return f'#{func}[{text}]'

        # Chart inline spans
        if cls == 'score-bar':
            # Parse "4/5" or just "4" (default max=5)
            if '/' in text:
                parts = text.split('/')
                return f'#score-bar({parts[0].strip()}, max: {parts[1].strip()})'
            return f'#score-bar({text.strip()})'

        if cls == 'progress-bar':
            # Parse "72%" or "72"
            pct = text.replace('%', '').strip()
            return f'#progress-bar({pct})'

        if cls == 'harvey':
            return f'#harvey({text.strip()})'

        if cls in ('rag-green', 'rag-amber', 'rag-red'):
            variant = cls.split('-', 1)[1]  # green, amber, red
            return f'#rag("{variant}")[{text}]'

        if cls in ('heat-critical', 'heat-high', 'heat-med', 'heat-low'):
            level = cls.split('-', 1)[1]  # critical, high, med, low
            return f'#heat-cell("{level}")[{text}]'

        if cls == 'indicator-pass':
            return f'#indicator("pass")[{text}]'
        if cls == 'indicator-fail':
            return f'#indicator("fail")[{text}]'

        # Callout title
        if cls == 'callout-title':
            return f'*{text}*'

        # Generic span — just bold it
        return f'*{text}*'

    def _replace_html_span(self, match):
        """Replace <span class="x">text</span> with Typst equivalent."""
        cls = match.group(1)
        text = match.group(2)

        if cls == 'number':
            return text
        if cls == 'label':
            return text
        if cls in SPAN_MAP:
            func = SPAN_MAP[cls]
            return f'#{func}[{text}]'
        if cls in BADGE_MAP:
            variant = BADGE_MAP[cls]
            return f'#badge("{variant}")[{text}]'
        return text
