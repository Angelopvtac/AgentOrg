// Chart & visualization components for md2pdf
#import "colors.typ": *

// ===================== SCORE BAR =====================
// Horizontal filled capsule bar with value label.
// value: current score, max: maximum score (default 5)
#let score-bar(value, max: 5) = {
  let ratio = value / max
  let bar-color = if ratio >= 0.7 { chart-bar-high } else if ratio >= 0.4 { chart-bar-mid } else { chart-bar-low }
  box(baseline: 20%, inset: (x: 2pt, y: 1pt))[
    #box(width: 60pt, height: 8pt, radius: 4pt, fill: chart-track, clip: true)[
      #box(width: ratio * 60pt, height: 8pt, radius: 4pt, fill: bar-color)
    ]
    #h(4pt)
    #text(font-size-xs, fill: color-text-muted, weight: 600)[#str(value)/#str(max)]
  ]
}

// ===================== PROGRESS BAR =====================
// Full-width percentage bar with centered label.
#let progress-bar(percent) = {
  let ratio = percent / 100
  let bar-color = if ratio >= 0.7 { chart-bar-high } else if ratio >= 0.4 { chart-bar-mid } else { chart-bar-low }
  box(baseline: 20%, width: 100pt, height: 12pt, radius: 6pt, fill: chart-track, clip: true)[
    #box(width: ratio * 100pt, height: 12pt, radius: 6pt, fill: bar-color)
    #place(center + horizon)[
      #text(6pt, fill: color-text-dark, weight: 700)[#str(percent)%]
    ]
  ]
}

// ===================== HARVEY BALLS =====================
// 0-4 fill levels using Unicode circles.
#let harvey(level) = {
  let symbol = if level == 0 { "○" } else if level == 1 { "◔" } else if level == 2 { "◑" } else if level == 3 { "◕" } else { "●" }
  box(baseline: 20%)[
    #text(10pt, fill: color-text-dark)[#symbol]
  ]
}

// ===================== RAG INDICATORS =====================
// Colored dot + label pill. variant: "green", "amber", or "red"
#let rag(variant, body) = {
  let dot-color = if variant == "green" { rag-green } else if variant == "amber" { rag-amber } else { rag-red }
  let bg = if variant == "green" { rag-green-bg } else if variant == "amber" { rag-amber-bg } else { rag-red-bg }
  box(
    baseline: 20%,
    inset: (x: 6pt, y: 2pt),
    radius: radius-sm,
    fill: bg,
  )[
    #box(width: 6pt, height: 6pt, radius: 3pt, fill: dot-color)
    #h(4pt)
    #text(font-size-xs, fill: dot-color, weight: 600)[#body]
  ]
}

// ===================== HEATMAP CELLS =====================
// Colored background cell for risk/score tables.
// level: "critical", "high", "med", or "low"
#let heat-cell(level, body) = {
  let bg = if level == "critical" { heat-critical-bg } else if level == "high" { heat-high-bg } else if level == "med" { heat-med-bg } else { heat-low-bg }
  let fg = if level == "critical" { heat-critical-text } else if level == "high" { heat-high-text } else if level == "med" { heat-med-text } else { heat-low-text }
  box(
    baseline: 20%,
    inset: (x: 6pt, y: 2pt),
    radius: radius-sm,
    fill: bg,
  )[
    #text(font-size-sm, fill: fg, weight: 700)[#body]
  ]
}

// ===================== INDICATOR PILLS =====================
// Pass/fail checkmark or X pill.
// variant: "pass" or "fail"
#let indicator(variant, body) = {
  let bg = if variant == "pass" { indicator-pass-bg } else { indicator-fail-bg }
  let fg = if variant == "pass" { indicator-pass-text } else { indicator-fail-text }
  let icon = if variant == "pass" { "✓" } else { "✗" }
  box(
    baseline: 20%,
    inset: (x: 6pt, y: 2pt),
    radius: radius-sm,
    fill: bg,
  )[
    #text(font-size-xs, fill: fg, weight: 700)[#icon #body]
  ]
}

// ===================== HORIZONTAL BAR CHART =====================
// items: array of (label: str, value: number)
// max: scale maximum
#let bar-chart(items, max: 5) = {
  block(
    width: 100%,
    breakable: false,
    above: space-md,
    below: space-md,
    inset: space-lg,
    radius: radius-lg,
    fill: color-bg-subtle,
    stroke: border-width + color-border,
  )[
    #for item in items {
      let ratio = item.value / max
      let bar-color = if ratio >= 0.8 { chart-bar-high } else if ratio >= 0.5 { chart-bar-mid } else { chart-bar-low }
      grid(
        columns: (auto, 1fr, 24pt),
        gutter: space-sm,
        align(right + horizon)[
          #text(font-size-xs, fill: color-text-dark, weight: 500)[#item.label]
        ],
        box(width: 100%, height: 14pt, radius: 7pt, fill: chart-track, clip: true)[
          #box(width: ratio * 100%, height: 14pt, radius: 7pt, fill: bar-color)
        ],
        align(left + horizon)[
          #text(font-size-sm, fill: color-text-muted, weight: 700)[#str(item.value)]
        ],
      )
      v(4pt)
    }
  ]
}

// ===================== FUNNEL DIAGRAM =====================
// stages: array of (label: str, value: str, percent: str)
#let funnel-chart(stages) = {
  block(
    width: 100%,
    above: space-md,
    below: space-md,
    inset: space-lg,
    radius: radius-lg,
    fill: color-bg-subtle,
    stroke: border-width + color-border,
  )[
    #let n = stages.len()
    #for (i, stage) in stages.enumerate() {
      let width-pct = 100% - (i * 20%)
      let shade = funnel-start.lighten(i * 20%)
      align(center)[
        #box(
          width: width-pct,
          inset: (x: space-lg, y: space-sm),
          radius: radius-md,
          fill: shade,
        )[
          #text(font-size-sm, fill: white, weight: 700)[#stage.label]
          #h(6pt)
          #text(font-size-xs, fill: white.darken(10%))[#stage.value]
          #h(4pt)
          #text(font-size-xs, fill: white.darken(20%), weight: 500)[#stage.percent]
        ]
      ]
      if i < n - 1 { v(3pt) }
    }
  ]
}

// ===================== QUADRANT CHART (2x2) =====================
// x-label, y-label: axis labels
// quadrants: array of 4 (label: str, desc: str) — Q1 (top-right), Q2 (top-left), Q3 (bottom-left), Q4 (bottom-right)
// points: array of (label: str, x: float 0-1, y: float 0-1)
#let quadrant-chart(x-label: "X Axis", y-label: "Y Axis", quadrants: (), points: ()) = {
  let size = 200pt
  let half = size / 2
  block(
    width: 100%,
    above: space-md,
    below: space-md,
    inset: space-lg,
    radius: radius-lg,
    fill: color-bg-subtle,
    stroke: border-width + color-border,
  )[
    #align(center)[
      // Y-axis label (top)
      #text(font-size-xs, fill: quadrant-label, weight: 600)[↑ #y-label]
      #v(4pt)

      #box(width: size, height: size)[
        // Quadrant backgrounds
        #place(top + left)[#box(width: half, height: half, fill: quadrant-q2)]
        #place(top + right)[#box(width: half, height: half, fill: quadrant-q1)]
        #place(bottom + left)[#box(width: half, height: half, fill: quadrant-q3)]
        #place(bottom + right)[#box(width: half, height: half, fill: quadrant-q4)]

        // Grid lines
        #place(top + left, dx: half, dy: 0pt)[#line(start: (0pt, 0pt), end: (0pt, size), stroke: border-width + quadrant-grid)]
        #place(top + left, dx: 0pt, dy: half)[#line(start: (0pt, 0pt), end: (size, 0pt), stroke: border-width + quadrant-grid)]

        // Outer border
        #place(top + left)[#box(width: size, height: size, stroke: border-width + quadrant-grid)]

        // Quadrant labels
        #if quadrants.len() >= 1 {
          place(top + right, dx: -4pt, dy: 4pt)[#text(6pt, fill: quadrant-label, weight: 600)[#quadrants.at(0).label]]
        }
        #if quadrants.len() >= 2 {
          place(top + left, dx: 4pt, dy: 4pt)[#text(6pt, fill: quadrant-label, weight: 600)[#quadrants.at(1).label]]
        }
        #if quadrants.len() >= 3 {
          place(bottom + left, dx: 4pt, dy: -4pt)[#text(6pt, fill: quadrant-label, weight: 600)[#quadrants.at(2).label]]
        }
        #if quadrants.len() >= 4 {
          place(bottom + right, dx: -4pt, dy: -4pt)[#text(6pt, fill: quadrant-label, weight: 600)[#quadrants.at(3).label]]
        }

        // Data points
        #for pt in points {
          let px = pt.x * size
          let py = (1 - pt.y) * size
          place(top + left, dx: px - 4pt, dy: py - 4pt)[
            #circle(radius: 4pt, fill: color-primary, stroke: 1pt + white)
          ]
          place(top + left, dx: px + 6pt, dy: py - 5pt)[
            #text(6pt, fill: color-text-dark, weight: 600)[#pt.label]
          ]
        }
      ]

      #v(4pt)
      // X-axis label (bottom)
      #text(font-size-xs, fill: quadrant-label, weight: 600)[#x-label →]
    ]
  ]
}

// ===================== TIMELINE =====================
// items: array of (period: str, title: str, desc: str)
#let timeline-chart(items) = {
  block(
    width: 100%,
    breakable: false,
    above: space-md,
    below: space-md,
    inset: space-lg,
    radius: radius-lg,
    fill: color-bg-subtle,
    stroke: border-width + color-border,
  )[
    #for (i, item) in items.enumerate() {
      grid(
        columns: (12pt, 80pt, 1fr),
        gutter: space-sm,
        // Dot + line column
        align(center)[
          #circle(radius: 5pt, fill: timeline-dot, stroke: 1.5pt + white)
          #if i < items.len() - 1 {
            v(2pt)
            line(start: (0pt, 0pt), end: (0pt, 14pt), stroke: 1.5pt + timeline-line)
          }
        ],
        // Period
        align(left + horizon)[
          #text(font-size-xs, fill: color-primary-dark, weight: 700)[#item.period]
        ],
        // Title + description
        [
          #text(font-size-sm, fill: color-text-dark, weight: 600)[#item.title]
          #if item.desc != "" {
            linebreak()
            text(font-size-xs, fill: color-text-muted)[#item.desc]
          }
        ],
      )
      if i < items.len() - 1 { v(4pt) }
    }
  ]
}
