// Design tokens — presentation-style 16:9 design system

// --- Page: 16:9 Landscape ---
#let page-width = 33.87cm   // 13.33in — standard 16:9
#let page-height = 19.05cm  // 7.5in
#let page-margin-x = 1.6cm
#let page-margin-y = 1.4cm

// --- Colors: Primary (monochromatic blue) ---
#let color-primary = rgb("#1d4ed8")
#let color-primary-dark = rgb("#0f2a6b")
#let color-primary-light = rgb("#60a5fa")
#let color-primary-bg = rgb("#eff6ff")
#let color-primary-border = rgb("#bfdbfe")

// --- Colors: Accent (electric cyan — for thin lines/highlights) ---
#let color-accent = rgb("#00d4ff")
#let color-accent-light = rgb("#67e8f9")
#let color-accent-bg = rgb("#ecfeff")

// --- Colors: Text ---
#let color-text = rgb("#1e293b")
#let color-text-dark = rgb("#0f172a")
#let color-text-muted = rgb("#64748b")
#let color-text-light = rgb("#94a3b8")
#let color-text-strong = rgb("#0f172a")

// --- Colors: Backgrounds ---
#let color-bg = white
#let color-bg-subtle = rgb("#f8fafc")
#let color-bg-muted = rgb("#f1f5f9")

// --- Colors: Dark panels (section dividers, sidebars) ---
#let dark-bg = rgb("#0a1a3f")
#let dark-bg-start = rgb("#0f172a")
#let dark-bg-end = rgb("#1e3a5f")
#let dark-text = rgb("#e2e8f0")
#let dark-accent = rgb("#60a5fa")

// --- Colors: Borders ---
#let color-border = rgb("#e2e8f0")
#let color-border-light = rgb("#f1f5f9")

// --- Colors: Header bar ---
#let header-bar-bg = rgb("#1d4ed8")
#let header-bar-text = white

// --- Colors: Callouts ---
#let callout-blue-bg = rgb("#e8f0fe")
#let callout-blue-border = rgb("#1d4ed8")
#let callout-blue-text = rgb("#1e3a5f")

#let callout-green-bg = rgb("#e6f4ea")
#let callout-green-border = rgb("#16a34a")
#let callout-green-text = rgb("#14532d")

#let callout-orange-bg = rgb("#fef3e2")
#let callout-orange-border = rgb("#d97706")
#let callout-orange-text = rgb("#7c2d12")

#let callout-purple-bg = rgb("#f0e6ff")
#let callout-purple-border = rgb("#7c3aed")
#let callout-purple-text = rgb("#3b0764")

#let callout-red-bg = rgb("#fde8e8")
#let callout-red-border = rgb("#dc2626")
#let callout-red-text = rgb("#7f1d1d")

// --- Colors: Badges ---
#let badge-high-bg = rgb("#dcfce7")
#let badge-high-text = rgb("#15803d")
#let badge-high-border = rgb("#86efac")

#let badge-med-high-bg = rgb("#dbeafe")
#let badge-med-high-text = rgb("#1d4ed8")
#let badge-med-high-border = rgb("#93c5fd")

#let badge-med-bg = rgb("#fef3c7")
#let badge-med-text = rgb("#92400e")
#let badge-med-border = rgb("#fcd34d")

#let badge-low-bg = rgb("#f1f5f9")
#let badge-low-text = rgb("#475569")
#let badge-low-border = rgb("#cbd5e1")

#let badge-orange-bg = rgb("#fff7ed")
#let badge-orange-text = rgb("#c2410c")
#let badge-orange-border = rgb("#fdba74")

#let badge-red-bg = rgb("#fee2e2")
#let badge-red-text = rgb("#dc2626")
#let badge-red-border = rgb("#fca5a5")

// --- Colors: Cover Page ---
#let cover-gradient-start = rgb("#0f172a")
#let cover-gradient-mid = rgb("#1e3a5f")
#let cover-gradient-end = rgb("#1e40af")
#let cover-text = white
#let cover-subtitle = rgb("#93c5fd")
#let cover-stat-bg = rgb(255, 255, 255, 20)
#let cover-stat-border = rgb(255, 255, 255, 38)
#let cover-stat-number = rgb("#60a5fa")
#let cover-stat-label = rgb("#94a3b8")
#let cover-tagline = rgb("#94a3b8")
#let cover-divider-start = rgb("#3b82f6")
#let cover-divider-end = rgb("#8b5cf6")

// --- Colors: Table ---
#let table-header-bg = rgb("#0f172a")
#let table-header-text = white
#let table-stripe = rgb("#f8fafc")

// --- Colors: Charts & Visualizations ---
#let chart-track = rgb("#e2e8f0")
#let chart-bar-high = rgb("#22c55e")
#let chart-bar-mid = rgb("#f59e0b")
#let chart-bar-low = rgb("#ef4444")
#let chart-bar-default = color-primary

#let rag-green = rgb("#22c55e")
#let rag-green-bg = rgb("#f0fdf4")
#let rag-amber = rgb("#f59e0b")
#let rag-amber-bg = rgb("#fffbeb")
#let rag-red = rgb("#ef4444")
#let rag-red-bg = rgb("#fef2f2")

#let heat-critical-bg = rgb("#fecaca")
#let heat-critical-text = rgb("#991b1b")
#let heat-high-bg = rgb("#fed7aa")
#let heat-high-text = rgb("#9a3412")
#let heat-med-bg = rgb("#fef3c7")
#let heat-med-text = rgb("#92400e")
#let heat-low-bg = rgb("#dcfce7")
#let heat-low-text = rgb("#166534")

#let indicator-pass-bg = rgb("#dcfce7")
#let indicator-pass-text = rgb("#15803d")
#let indicator-fail-bg = rgb("#fee2e2")
#let indicator-fail-text = rgb("#dc2626")

#let quadrant-grid = rgb("#e2e8f0")
#let quadrant-label = rgb("#64748b")
#let quadrant-q1 = rgb("#eff6ff")
#let quadrant-q2 = rgb("#f0fdf4")
#let quadrant-q3 = rgb("#f8fafc")
#let quadrant-q4 = rgb("#fffbeb")

#let funnel-start = color-primary
#let funnel-end = rgb("#60a5fa")

#let timeline-dot = color-primary
#let timeline-line = rgb("#cbd5e1")

// --- Typography ---
#let font-serif = ("Noto Serif Display", "Noto Serif", "Georgia", "Times New Roman")
#let font-sans = ("Inter", "Noto Sans", "DejaVu Sans")
#let font-display = ("Inter Display", "Inter", "Noto Sans")
#let font-mono = ("JetBrains Mono", "Fira Code", "DejaVu Sans Mono")

// Presentation-scale type sizes
#let font-size-base = 11pt
#let font-size-lg = 13pt
#let font-size-sm = 9.5pt
#let font-size-xs = 8.5pt
#let font-size-xxs = 7.5pt

// Display headings — presentation scale
#let font-size-display = 54pt    // section divider titles
#let font-size-giant = 160pt     // section numbers "01"
#let font-size-h1 = 36pt         // page titles
#let font-size-h2 = 22pt         // sub-sections
#let font-size-h3 = 15pt         // content headings
#let font-size-h4 = 12pt         // minor headings

#let line-height-base = 1.6em
#let line-height-tight = 1.15em
#let line-height-snug = 1.45em

// --- Spacing (presentation scale) ---
#let space-xs = 4pt
#let space-sm = 6pt
#let space-md = 10pt
#let space-lg = 16pt
#let space-xl = 24pt
#let space-2xl = 32pt
#let space-3xl = 48pt
#let space-4xl = 64pt
#let space-5xl = 80pt

// --- Borders ---
#let radius-sm = 4pt
#let radius-md = 6pt
#let radius-lg = 10pt
#let radius-xl = 14pt
#let border-width = 1pt
#let border-thick = 1.5pt
#let border-accent = 3pt

// --- Header bar ---
#let header-bar-height = 52pt

// --- Sidebar ---
#let sidebar-width = 28%
