// Page setup — 16:9 landscape presentation-style report
#import "colors.typ": *

#let md2pdf-doc(doc-title: none, body) = {
  set page(
    width: page-width,
    height: page-height,
    margin: (left: page-margin-x, right: page-margin-x, top: page-margin-y + header-bar-height + 8pt, bottom: page-margin-y + 32pt),
    numbering: "1",
    number-align: center,
    // Blue header bar + footer via background (full positional control)
    background: context {
      let page-num = here().page()
      if page-num > 1 {
        // --- Blue header bar ---
        // Track H2 headings (most content uses H2 for major sections)
        let h1s = query(heading.where(level: 1).before(here()))
        let h2s = query(heading.where(level: 2).before(here()))
        let section-name = if h2s.len() > 0 {
          h2s.last().body
        } else if h1s.len() > 0 {
          h1s.last().body
        } else {
          none
        }
        place(top + left,
          block(width: page-width, height: header-bar-height, fill: header-bar-bg)[
            #set align(horizon)
            #pad(left: page-margin-x + 4pt, right: page-margin-x + 4pt)[
              #grid(
                columns: (1fr, 1fr),
                align(left, text(11pt, fill: white, weight: 600, font: font-sans)[
                  #if section-name != none { section-name }
                ]),
                align(right, text(9pt, fill: rgb(255, 255, 255, 180), weight: 400, tracking: 0.5pt, font: font-sans)[
                  #if doc-title != none { upper(doc-title) }
                ]),
              )
            ]
          ]
        )

        // --- Footer ---
        place(bottom + left,
          block(width: page-width, height: 28pt)[
            #set align(horizon)
            #pad(left: page-margin-x + 4pt, right: page-margin-x + 4pt)[
              #line(length: 100%, stroke: 0.5pt + color-border)
              #v(4pt)
              #grid(
                columns: (1fr, 1fr),
                align(left, text(7.5pt, fill: color-text-muted, font: font-sans)[
                  #if doc-title != none { doc-title }
                ]),
                align(right, text(8pt, fill: color-text-muted, font: font-sans)[
                  Page #counter(page).display("1")
                ]),
              )
            ]
          ]
        )
      }
    },
    header: none,
    footer: none,
  )

  // Body text — larger for 16:9 readability
  set text(
    font: font-sans,
    size: font-size-base,
    fill: color-text,
    lang: "en",
    number-type: "old-style",
    ligatures: true,
  )

  // Paragraph settings
  set par(
    leading: 0.75em,
    justify: false,
    spacing: 0.9em,
  )

  // --- Heading styles ---

  // H1 = major section title
  show heading.where(level: 1): it => {
    v(space-lg, weak: true)
    block(breakable: false, sticky: true)[
      #text(font-size-h1, font: font-serif, weight: 700, fill: color-text-dark, tracking: -0.8pt)[#it.body]
      #v(space-sm)
      #box(width: 56pt, height: 3pt, fill: color-primary, radius: 2pt)
    ]
    v(space-lg, weak: true)
  }

  // H2 = sub-section title
  show heading.where(level: 2): it => {
    v(space-md, weak: true)
    block(breakable: false, sticky: true)[
      #text(font-size-h2, font: font-sans, weight: 700, fill: color-text-dark, tracking: -0.3pt)[#it.body]
      #v(space-xs)
      #box(width: 40pt, height: 2.5pt, fill: color-primary.lighten(30%), radius: 1.5pt)
    ]
    v(space-md, weak: true)
  }

  show heading.where(level: 3): it => {
    v(space-lg, weak: true)
    block(breakable: false, sticky: true)[
      #text(font-size-h3, font: font-sans, weight: 700, fill: color-text, tracking: -0.2pt)[#it.body]
    ]
    v(space-sm, weak: true)
  }

  show heading.where(level: 4): it => {
    v(space-md, weak: true)
    block(breakable: false, sticky: true)[
      #text(font-size-h4, font: font-sans, weight: 700, fill: rgb("#334155"))[#it.body]
    ]
    v(space-xs, weak: true)
  }

  // Table defaults
  set table(
    stroke: none,
    inset: (x: space-md, y: 7pt),
  )
  show table: set text(number-type: "lining")

  // Link styling
  show link: it => {
    text(fill: color-primary)[#it]
  }

  // Strong styling
  show strong: it => {
    text(weight: 700, fill: color-text-strong)[#it.body]
  }

  // Emphasis styling
  show emph: it => {
    text(fill: color-text-muted, style: "italic")[#it.body]
  }

  // Horizontal rule
  show line: it => {
    v(space-lg, weak: true)
    it
    v(space-lg, weak: true)
  }

  body
}
