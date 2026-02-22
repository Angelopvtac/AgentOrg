// Component functions — 16:9 presentation-style design system
#import "colors.typ": *

// ===================== SECTION BANNER (full-bleed dark page) =====================

#let section-banner(number: none, title: none, subtitle: none) = {
  pagebreak()
  page(width: page-width, height: page-height, margin: 0pt, numbering: none, header: none, footer: none)[
    // Full dark background
    #block(width: 100%, height: 100%,
      fill: gradient.linear(dark-bg, rgb("#0f2a6b"), angle: 135deg)
    )[
      // Decorative giant number — faded in background
      #if number != none {
        place(right + top, dx: -40pt, dy: 20pt,
          text(font-size-giant, fill: rgb(255, 255, 255, 8), weight: 900, font: font-sans)[#number]
        )
      }

      // Thin cyan accent line at top
      #place(top + left,
        rect(width: 100%, height: 3pt, fill: gradient.linear(color-accent, color-primary, angle: 0deg))
      )

      // Content — left-aligned
      #align(left + horizon, pad(left: 60pt, right: 60pt)[
        // Section number — bold white
        #if number != none {
          text(72pt, fill: white, weight: 900, font: font-sans)[#number]
          v(space-md)
          // Cyan underline
          box(width: 48pt, height: 3pt, fill: color-accent, radius: 2pt)
          v(space-xl)
        }

        // Title — large display serif
        #if title != none {
          text(font-size-display, fill: white, weight: 600, tracking: -1pt, font: font-serif)[
            #title
          ]
        }

        // Subtitle
        #if subtitle != none {
          v(space-lg)
          text(14pt, fill: rgb(255, 255, 255, 160), weight: 400, font: font-sans)[#subtitle]
        }
      ])

      // Footer bar
      #place(bottom + left,
        block(width: 100%, height: 28pt, fill: rgb(0, 0, 0, 40))[
          #set align(horizon)
          #pad(left: 60pt, right: 60pt)[
            #text(7pt, fill: rgb(255, 255, 255, 60), font: font-sans)[]
          ]
        ]
      )
    ]
  ]
}

// ===================== CALLOUT BOXES =====================

#let callout-colors = (
  blue: (bg: callout-blue-bg, border: callout-blue-border, text: callout-blue-text),
  green: (bg: callout-green-bg, border: callout-green-border, text: callout-green-text),
  orange: (bg: callout-orange-bg, border: callout-orange-border, text: callout-orange-text),
  purple: (bg: callout-purple-bg, border: callout-purple-border, text: callout-purple-text),
  red: (bg: callout-red-bg, border: callout-red-border, text: callout-red-text),
)

#let callout(color, title: none, body) = {
  let colors = callout-colors.at(color, default: callout-colors.blue)
  block(
    width: 100%,
    breakable: false,
    above: space-lg,
    below: space-lg,
    radius: radius-lg,
    clip: true,
    stroke: border-width + colors.border.lighten(50%),
  )[
    // Colored top accent bar
    #block(width: 100%, height: 3pt, fill: colors.border, above: 0pt, below: 0pt)
    #block(
      width: 100%,
      inset: (x: space-xl, top: space-lg, bottom: space-lg),
      fill: colors.bg,
    )[
      #set text(fill: colors.text, size: font-size-base)
      #if title != none {
        text(font-size-sm, weight: 700, tracking: 0.8pt, fill: colors.border)[#upper(title)]
        v(space-sm)
      }
      #body
    ]
  ]
}

// ===================== PULL QUOTE =====================

#let pull-quote(body, attribution: none) = {
  v(space-xl)
  block(width: 100%, inset: (left: 32pt, right: 32pt))[
    #place(left, dy: -8pt,
      text(56pt, fill: color-primary.lighten(60%), font: font-serif, weight: 700)["]
    )
    #pad(left: 28pt)[
      #text(16pt, fill: color-text-dark, style: "italic", font: font-serif,
        leading: 0.8em
      )[#body]
      #if attribution != none {
        v(space-md)
        text(8pt, fill: color-text-muted, weight: 600, tracking: 1pt, font: font-sans)[
          --- #upper(attribution)
        ]
      }
    ]
  ]
  v(space-xl)
}

// ===================== KEY INSIGHT =====================

#let key-insight(body) = {
  block(
    width: 100%,
    breakable: false,
    above: space-xl,
    below: space-xl,
    inset: (left: space-2xl + border-accent, top: space-xl, bottom: space-xl, right: space-2xl),
    radius: radius-lg,
    fill: gradient.linear(dark-bg-end, dark-bg-start, angle: 135deg),
    stroke: (left: 3pt + dark-accent),
  )[
    #set text(fill: dark-text, size: font-size-base, style: "italic")
    #show strong: it => text(fill: dark-accent, weight: 700)[#it.body]
    #text(7pt, weight: 700, tracking: 2.5pt, fill: dark-accent, style: "normal", font: font-sans)[KEY INSIGHT]
    #v(space-md)
    #body
  ]
}

// ===================== HIGHLIGHT BOX =====================

#let highlight-box(body) = {
  block(
    width: 100%,
    breakable: false,
    above: space-lg,
    below: space-lg,
    inset: (x: space-xl, y: space-lg),
    radius: radius-lg,
    fill: gradient.linear(rgb("#1e40af"), rgb("#6d28d9"), angle: 135deg),
  )[
    #set text(fill: white, size: font-size-base)
    #show strong: it => text(fill: rgb("#c7d2fe"), weight: 700)[#it.body]
    #show heading.where(level: 3): it => text(font-size-h3, fill: white, weight: 700)[#it.body]
    #show heading.where(level: 4): it => text(font-size-h4, fill: white, weight: 700)[#it.body]
    #body
  ]
}

// ===================== SECTION INTRO =====================

#let section-intro(body) = {
  block(
    width: 100%,
    breakable: false,
    above: space-lg,
    below: space-lg,
    inset: (x: space-xl, y: space-lg),
    radius: radius-lg,
    fill: color-bg-subtle,
    stroke: border-width + color-border,
  )[
    #body
  ]
}

// ===================== SECTION DIVIDER =====================

#let section-divider(body) = {
  v(space-xl)
  align(center)[
    #text(10pt, fill: color-text-light, tracking: 4pt)[#sym.dot.c #h(6pt) #sym.dot.c #h(6pt) #sym.dot.c]
  ]
  v(space-md)
  body
}

// ===================== BADGES =====================

#let badge-styles = (
  high: (bg: badge-high-bg, text: badge-high-text, border: badge-high-border),
  med-high: (bg: badge-med-high-bg, text: badge-med-high-text, border: badge-med-high-border),
  med: (bg: badge-med-bg, text: badge-med-text, border: badge-med-border),
  low: (bg: badge-low-bg, text: badge-low-text, border: badge-low-border),
  green: (bg: badge-high-bg, text: badge-high-text, border: badge-high-border),
  blue: (bg: badge-med-high-bg, text: badge-med-high-text, border: badge-med-high-border),
  orange: (bg: badge-orange-bg, text: badge-orange-text, border: badge-orange-border),
  red: (bg: badge-red-bg, text: badge-red-text, border: badge-red-border),
  gray: (bg: badge-low-bg, text: badge-low-text, border: badge-low-border),
  competition: (bg: badge-low-bg, text: badge-low-text, border: badge-low-border),
)

#let badge(variant, body) = {
  let styles = badge-styles.at(variant, default: badge-styles.gray)
  box(
    inset: (x: 8pt, y: 3pt),
    radius: radius-sm,
    fill: styles.bg,
    stroke: border-width + styles.border,
    baseline: 20%,
  )[
    #text(7pt, fill: styles.text, weight: 700, tracking: 0.3pt)[#upper(body)]
  ]
}

// ===================== METRIC PILLS =====================

#let pill(body) = {
  box(
    inset: (x: space-md, y: 3pt),
    radius: 12pt,
    fill: color-bg-subtle,
    stroke: border-width + color-border,
    baseline: 20%,
  )[
    #text(8pt, fill: rgb("#475569"), weight: 600)[#body]
  ]
}

// ===================== METRIC ROW =====================

#let metric-row(..items) = {
  v(8pt)
  grid(
    columns: items.pos().len(),
    gutter: 8pt,
    ..items.pos().map(item => {
      box(
        inset: (x: space-md, y: space-sm),
        radius: radius-md,
        fill: color-bg-subtle,
        stroke: border-width + color-border,
      )[
        #text(7pt, fill: color-text-muted, weight: 600, tracking: 0.3pt)[#upper(item.label)]
        #linebreak()
        #text(11pt, fill: color-text-dark, weight: 700)[#item.value]
      ]
    })
  )
  v(8pt)
}

// ===================== STAT CARDS =====================

#let stat-card(number-val, label-val) = {
  block(
    width: 100%,
    breakable: false,
    above: space-md,
    below: space-md,
    inset: (x: space-xl, y: space-xl),
    radius: radius-lg,
    fill: gradient.linear(color-primary-bg, rgb("#f0f9ff"), angle: 135deg),
    stroke: border-width + color-primary-border,
  )[
    #align(center)[
      #text(32pt, fill: color-primary-dark, weight: 800, font: font-sans)[#number-val]
      #v(space-sm)
      #text(7.5pt, fill: rgb("#475569"), weight: 600, tracking: 1pt, font: font-sans)[#upper(label-val)]
    ]
  ]
}

#let stat-row(..cards) = {
  v(12pt)
  grid(
    columns: cards.pos().len(),
    gutter: space-md,
    ..cards.pos()
  )
  v(12pt)
}

// ===================== CARDS =====================

#let card(body) = {
  block(
    width: 100%,
    breakable: false,
    above: space-md,
    below: space-md,
    inset: (x: space-xl, y: space-lg),
    radius: radius-lg,
    stroke: border-width + color-border,
  )[
    #body
  ]
}

// ===================== IDEA CARDS =====================

#let idea-card(header-content, body-content) = {
  block(
    width: 100%,
    breakable: true,
    above: space-lg,
    below: space-lg,
    radius: radius-lg,
    stroke: border-width + color-border,
    clip: true,
  )[
    #block(
      width: 100%,
      inset: (x: space-lg, y: space-md),
      fill: color-bg-subtle,
      below: 0pt,
    )[
      #header-content
      #line(length: 100%, stroke: border-width + color-border)
    ]
    #block(
      width: 100%,
      inset: (x: space-lg, y: space-md),
    )[
      #body-content
    ]
  ]
}

// ===================== TEMPLATE CARD =====================

#let template-card(header-content, body-content) = {
  block(
    width: 100%,
    above: space-xl,
    below: space-xl,
    stroke: (left: 3pt + color-primary),
  )[
    #block(
      width: 100%,
      inset: (x: space-xl, y: space-lg),
      radius: radius-md,
      fill: gradient.linear(rgb("#1e293b"), rgb("#334155"), angle: 135deg),
    )[
      #set text(fill: white)
      #show heading: it => text(15pt, fill: white, weight: 700)[#it.body]
      #header-content
    ]
    #block(
      width: 100%,
      inset: (x: space-xl, y: space-lg),
    )[
      #body-content
    ]
  ]
}

// ===================== TEMPLATE NUMBER =====================

#let template-number(body) = {
  text(28pt, fill: color-primary, weight: 800)[#body]
  linebreak()
}

// ===================== MARKET SIZE SPANS =====================

#let market-size-label(body) = {
  text(7.5pt, fill: color-text-muted, weight: 600, tracking: 1.5pt)[#upper(body)]
  linebreak()
}

#let market-size-value(body) = {
  text(22pt, fill: color-primary-dark, weight: 800)[#body]
  linebreak()
}

#let market-cagr(body) = {
  v(2pt)
  text(font-size-sm, fill: color-text-muted)[#body]
}

// ===================== WORKSHEET =====================

#let worksheet(body) = {
  block(
    width: 100%,
    above: space-md,
    below: space-md,
    inset: space-lg,
    radius: radius-md,
    fill: color-bg-subtle,
    stroke: (
      paint: rgb("#cbd5e1"),
      thickness: border-width,
      dash: "dashed",
    ),
  )[
    #body
  ]
}

#let field(label-text, value-text) = {
  grid(
    columns: (140pt, 1fr),
    gutter: space-md,
    text(font-size-sm, fill: rgb("#334155"), weight: 600)[#label-text],
    text(font-size-sm, fill: color-text-light)[#value-text],
  )
  v(space-xs)
  line(length: 100%, stroke: (paint: rgb("#cbd5e1"), thickness: border-width, dash: "dotted"))
  v(6pt)
}

// ===================== SPRINT WEEKS =====================

#let sprint(body) = {
  block(
    width: 100%,
    above: space-md,
    below: space-md,
    inset: (left: space-lg + 3pt, top: space-md, bottom: space-md, right: space-lg),
    fill: color-bg-subtle,
    radius: (right: radius-md),
    stroke: (left: 3pt + color-primary),
  )[
    #show heading.where(level: 4): it => {
      text(font-size-h4, fill: color-primary-dark, weight: 700)[#it.body]
      v(space-xs)
    }
    #body
  ]
}

// ===================== CHECKLIST =====================

#let checklist-box(body) = {
  block(
    width: 100%,
    above: space-md,
    below: space-md,
    inset: (x: space-lg, y: space-md),
    radius: radius-md,
    fill: rgb("#f0fdf4"),
    stroke: border-width + rgb("#bbf7d0"),
  )[
    #body
  ]
}

// ===================== SCORING GUIDE =====================

#let scoring-guide(body) = {
  block(
    width: 100%,
    above: space-md,
    below: space-md,
    inset: (x: space-lg, y: space-md),
    radius: radius-md,
    fill: color-primary-bg,
    stroke: border-width + color-primary-border,
  )[
    #body
  ]
}

// ===================== GO/NO-GO =====================

#let go-no-go(body) = {
  block(
    width: 100%,
    above: space-lg,
    below: space-lg,
    inset: (x: space-xl, y: space-lg),
    radius: radius-lg,
    fill: gradient.linear(dark-bg-end, dark-bg-start, angle: 135deg),
  )[
    #set text(fill: white)
    #body
  ]
}

// ===================== BACK COVER =====================

#let back-cover(body) = {
  pagebreak()
  page(width: page-width, height: page-height, margin: 0pt, numbering: none, header: none, footer: none)[
    #block(width: 100%, height: 100%,
      fill: gradient.linear(dark-bg, rgb("#0f2a6b"), angle: 135deg)
    )[
      // Cyan accent line at top
      #place(top + left,
        rect(width: 100%, height: 3pt, fill: gradient.linear(color-accent, color-primary, angle: 0deg))
      )

      #align(center + horizon)[
        #pad(left: 60pt, right: 60pt)[
          #box(width: 48pt, height: 3pt, fill: color-accent, radius: 2pt)
          #v(space-2xl)
          #set text(fill: rgb(255, 255, 255, 180), size: font-size-base, font: font-sans)
          #body
        ]
      ]
    ]
  ]
}

// ===================== FOOTER =====================

#let report-footer(body) = {
  v(space-xl)
  line(length: 100%, stroke: border-thick + color-border)
  v(space-lg)
  set text(8pt, fill: color-text-light)
  body
}

// ===================== COMPARISON MATRIX =====================

#let comparison-matrix(body) = {
  block(
    width: 100%,
    above: space-lg,
    below: space-lg,
  )[
    #body
  ]
}

// ===================== TOC =====================

#let toc-block(body) = {
  block(
    width: 100%,
    above: space-md,
    below: space-md,
  )[
    // Dot leaders between entry and page number
    #set outline.entry(fill: repeat[.#h(2pt)])
    // Style H1 entries: bold, primary color
    #show outline.entry.where(level: 1): it => {
      v(space-sm)
      text(font-size-base, weight: 700, fill: color-text-dark, font: font-sans)[#it]
    }
    // Style H2 entries: normal weight
    #show outline.entry.where(level: 2): it => {
      text(font-size-sm, weight: 400, fill: color-text, font: font-sans)[#it]
    }
    // Style H3 entries: muted
    #show outline.entry.where(level: 3): it => {
      text(font-size-xs, weight: 400, fill: color-text-muted, font: font-sans)[#it]
    }
    #body
  ]
}
