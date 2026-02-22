---
title: md2pdf Component Showcase
subtitle: A complete demonstration of every available component
cover: true
edition: "v1.0 — February 2026"
stats:
  - value: "15+"
    label: "Components"
  - value: "3"
    label: "Themes"
  - value: "0"
    label: "Raw HTML"
tagline: "Pure markdown authoring — professional PDF output"
---

## Typography

This is body text demonstrating the **base typography** settings. The design system uses *Inter* as the primary font with a comfortable reading size and generous line height.

### Headings

All four heading levels (H1–H4) are styled with appropriate weight, size, and spacing. H2 headings include a subtle bottom border for visual separation.

#### This is an H4 heading

Regular paragraph text follows with proper spacing.

---

## Callouts

::: blue Important Note
This is a **blue callout** — perfect for informational notes, tips, or important context that readers shouldn't miss.
:::

::: green
This is a **green callout** without a title — great for success messages, positive outcomes, or best practices.
:::

::: orange Caution
An **orange callout** for warnings or things to watch out for. Use these to highlight risks or caveats.
:::

::: purple Pro Tip
A **purple callout** — ideal for expert advice, pro tips, or advanced techniques.
:::

::: red Warning
A **red callout** for critical warnings, breaking changes, or serious issues that need immediate attention.
:::

---pagebreak---

## Key Insight

::: key-insight
The most successful AI startups in 2026 aren't building better models — they're building **better workflows** around existing models. The moat is in the **application layer**, not the model layer.
:::

## Highlight Box

::: highlight
This is a **highlight box** with a gradient purple background. Use it for the most important takeaways or premium content callouts that need maximum visual impact.
:::

---

## Badges & Pills

Inline badges work inside any text: [HIGH]{.badge-high} [MEDIUM]{.badge-med} [GROWING]{.badge-blue} [RISK]{.badge-red} [NEUTRAL]{.badge-gray}

Metric pills for quick data points: [TAM: $1.8B]{.pill} [CAGR: 34%]{.pill} [Series A]{.pill}

---

## Metrics

::: metrics
TAM: $1.8B | CAGR: 34% | Funding: $450M
Competitors: 12 | Win Rate: 68%
:::

---

## Stat Cards

::: stat-row

::: stat-card
<span class="number">$202B</span>
<span class="label">AI Market Size</span>
:::

::: stat-card
<span class="number">50+</span>
<span class="label">Companies Profiled</span>
:::

::: stat-card
<span class="number">34%</span>
<span class="label">Average CAGR</span>
:::

:::

---pagebreak---

## Columns

:::: columns

::: col
**Left Column**

This is the left column content. Columns are great for comparing two items side by side or for creating more efficient use of horizontal space.

- Feature A
- Feature B
- Feature C
:::

::: col
**Right Column**

This is the right column content. Both columns flex equally to fill the available width.

- Benefit X
- Benefit Y
- Benefit Z
:::

::::

---

## Tables

| Company | Sector | Funding | Conviction |
|---------|--------|---------|------------|
| Acme AI | Healthcare | $45M | [HIGH]{.badge-high} |
| DataFlow | Finance | $28M | [MED-HIGH]{.badge-med-high} |
| NeuralOps | DevTools | $12M | [MEDIUM]{.badge-med} |
| CloudMind | Enterprise | $67M | [HIGH]{.badge-high} |

---

## Cards

::: card
**This is a card component** — a bordered box with rounded corners. Cards are useful for grouping related content together, like a company profile, a tool recommendation, or a step in a process.

Key features:
- Clean border styling
- Rounded corners
- Avoids page breaks inside
:::

---pagebreak---

## Section Intro

::: section-intro
### AI Infrastructure & Developer Tools

The picks-and-shovels of the AI gold rush — platforms that help others build, deploy, and monitor AI applications.

<span class="market-size-label">Total Addressable Market</span>
<span class="market-size-value">$87.5 Billion by 2028</span>
<span class="market-cagr">Growing at 32% CAGR from $24.1B in 2024</span>
:::

---

## Worksheet

::: worksheet
>> Company Name
> (enter company name)

>> Target Market
> (describe your target market)

>> Value Proposition
> (what unique value do you provide?)

>> Revenue Model
> (how will you make money?)

>> Key Metrics to Track
> (list 3-5 key metrics)
:::

---

## Sprint Planning

::: sprint
#### Week 1-2: Foundation

- Set up development environment
- Define core API endpoints
- Build initial data models
- Create basic UI wireframes
:::

::: sprint
#### Week 3-4: Core Features

- Implement authentication flow
- Build main dashboard
- Add data visualization layer
- Write integration tests
:::

---

## Code Blocks

Inline code: `const x = 42;`

```python
def fibonacci(n):
    """Generate Fibonacci sequence up to n."""
    a, b = 0, 1
    while a < n:
        yield a
        a, b = b, a + b
```

---

## Blockquotes

> "The best way to predict the future is to invent it."
> — Alan Kay

---

## Lists

**Unordered:**
- First item with **bold** text
- Second item with *italic* text
- Third item with `inline code`
  - Nested item A
  - Nested item B

**Ordered:**
1. Research the market
2. Validate the idea
3. Build an MVP
4. Launch and iterate

---

::: footer
**md2pdf v1.0** — Generated with the md2pdf design system.

This is a demonstration document. All components shown are authored in pure markdown with zero raw HTML divs or spans in the source.
:::
