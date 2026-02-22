---
title: Charts & Visualization Test
subtitle: "Testing all inline and block-level chart components"
cover: true
edition: "Test Edition"
stats:
  - value: "12"
    label: "Components"
  - value: "6"
    label: "Inline Types"
  - value: "4"
    label: "Block Charts"
---

## Inline Components

### Score Bars

| Item | Score |
|------|-------|
| Quality | [5/5]{.score-bar} |
| Speed | [4/5]{.score-bar} |
| Value | [3/5]{.score-bar} |
| Support | [2/5]{.score-bar} |
| Docs | [1/5]{.score-bar} |

### Progress Bars

| Metric | Progress |
|--------|----------|
| Phase 1 | [95%]{.progress-bar} |
| Phase 2 | [72%]{.progress-bar} |
| Phase 3 | [45%]{.progress-bar} |
| Phase 4 | [20%]{.progress-bar} |

### Harvey Balls

| Feature | Maturity |
|---------|----------|
| Empty | [0]{.harvey} |
| Quarter | [1]{.harvey} |
| Half | [2]{.harvey} |
| Three-quarter | [3]{.harvey} |
| Full | [4]{.harvey} |

### RAG Indicators

| System | Status |
|--------|--------|
| Production | [HEALTHY]{.rag-green} |
| Staging | [DEGRADED]{.rag-amber} |
| Dev | [DOWN]{.rag-red} |

### Heatmap Cells

| Risk Area | Score |
|-----------|-------|
| Platform risk | [20]{.heat-critical} |
| Market timing | [12]{.heat-high} |
| Competition | [6]{.heat-med} |
| Regulatory | [2]{.heat-low} |

### Indicator Pills

| Criteria | Result |
|----------|--------|
| Revenue > $1M ARR | [PASS]{.indicator-pass} |
| Team of 3+ | [PASS]{.indicator-pass} |
| Patent filed | [FAIL]{.indicator-fail} |
| SOC2 certified | [FAIL]{.indicator-fail} |

---pagebreak---

## Block-Level Charts

### Horizontal Bar Chart

::: bar-chart max=10
Customer Satisfaction: 9
Product Quality: 8
Market Fit: 7
Team Strength: 8
Revenue Growth: 6
:::

### Funnel Diagram

::: funnel
Total Addressable Market: $5B | 100%
Serviceable Market: $1.2B | 24%
Obtainable Market: $120M | 2.4%
Year 1 Target: $12M | 0.24%
:::

### Quadrant Chart

::: quadrant x-axis="Market Coverage" y-axis="AI-Native"
Q1 YOUR TARGET: High coverage, high AI-native
Q2 Niche Players: Low coverage, high AI-native
Q3 Weak Position: Low coverage, low AI-native
Q4 Incumbents: High coverage, low AI-native
---
Company A: 0.8, 0.9
Company B: 0.3, 0.7
Company C: 0.7, 0.2
Company D: 0.2, 0.3
You: 0.6, 0.85
:::

### Timeline

::: timeline
Week 1-2: Problem Validation | Customer interviews, pain discovery
Week 3-4: Solution Design | Prototyping, landing page tests
Week 5-6: MVP Build | Core feature development, design partners
Week 7-8: Launch | Beta release, first paying customers
Week 9-12: Growth | Iteration, marketing, hiring
:::

---pagebreak---

## Mixed Usage in Context

::: card

### Project Health Dashboard

| Area | Score | Status | Trend |
|------|-------|--------|-------|
| Engineering | [4/5]{.score-bar} | [ON TRACK]{.rag-green} | [3]{.harvey} |
| Sales | [3/5]{.score-bar} | [CAUTION]{.rag-amber} | [2]{.harvey} |
| Support | [5/5]{.score-bar} | [ON TRACK]{.rag-green} | [4]{.harvey} |
| Marketing | [2/5]{.score-bar} | [AT RISK]{.rag-red} | [1]{.harvey} |

:::

::: key-insight

All 12 visualization components render correctly when combined with existing md2pdf components like callouts, cards, worksheets, and scoring guides.

:::
