// Cover page — 16:9 landscape presentation style
#import "colors.typ": *

#let cover-page(
  title: "",
  subtitle: none,
  edition: none,
  author: none,
  stats: (),
  tagline: none,
) = {
  set page(width: page-width, height: page-height, margin: 0pt, numbering: none, footer: none, header: none)

  block(width: 100%, height: 100%, fill: dark-bg, breakable: false)[
    // Background image — full bleed
    #place(
      image("cover-bg.jpg", width: 100%, height: 100%, fit: "cover")
    )

    // Dark gradient overlay
    #place(
      rect(width: 100%, height: 100%,
        fill: gradient.linear(
          rgb(10, 26, 63, 220),
          rgb(10, 26, 63, 140),
          rgb(10, 26, 63, 200),
          angle: 0deg
        )
      )
    )

    // Decorative accent line — thin cyan stripe at top
    #place(top + left,
      rect(width: 100%, height: 4pt, fill: gradient.linear(color-accent, color-primary, angle: 0deg))
    )

    // Content — left 60% of slide
    #place(left + horizon, dx: 60pt, dy: 0pt,
      block(width: 55%)[
        // Edition label
        #if edition != none {
          text(8pt, fill: color-accent, weight: 600, tracking: 3pt, font: font-sans)[
            #upper(edition)
          ]
          v(space-xl)
        }

        // Title — massive display
        #text(48pt, fill: white, weight: 800, tracking: -1.5pt, font: font-serif)[
          #title
        ]
        #v(space-lg)

        // Cyan accent bar
        #box(width: 64pt, height: 3.5pt, fill: color-accent, radius: 2pt)
        #v(space-lg)

        // Subtitle
        #if subtitle != none {
          set par(leading: 0.7em)
          text(15pt, fill: rgb(255, 255, 255, 200), weight: 400, font: font-sans)[
            #subtitle
          ]
          v(space-2xl)
        }

        // Stat cards — horizontal row
        #if stats.len() > 0 {
          grid(
            columns: stats.len(),
            gutter: 12pt,
            ..stats.map(stat => {
              box(
                width: 1fr,
                inset: (x: space-lg, y: space-lg),
                radius: radius-lg,
                stroke: border-width + rgb(255, 255, 255, 30),
                fill: rgb(255, 255, 255, 8),
              )[
                #text(26pt, fill: color-accent, weight: 800, font: font-sans)[#stat.value]
                #v(space-xs)
                #text(7pt, fill: rgb(255, 255, 255, 140), weight: 600, tracking: 1pt, font: font-sans)[
                  #upper(stat.label)
                ]
              ]
            })
          )
          v(space-xl)
        }

        // Tagline
        #if tagline != none {
          text(font-size-sm, fill: rgb(255, 255, 255, 120), style: "italic", font: font-sans)[
            #tagline
          ]
        }

        // Author
        #if author != none {
          v(space-xl)
          text(8pt, fill: rgb(255, 255, 255, 100), weight: 600, tracking: 1.5pt, font: font-sans)[
            #upper(author)
          ]
        }
      ]
    )
  ]
}
