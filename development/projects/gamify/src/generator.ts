import {
  type SessionReport,
  type Theme,
  DEFAULT_THEME,
} from "./types.js";

export function generateReport(report: SessionReport): string {
  const t: Theme = { ...DEFAULT_THEME, ...report.theme };
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(report.title)}</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600&display=swap');
  :root{--bg:${t.bg};--bg-card:${t.bgCard};--bg-card-hover:#181825;--border:#1e1e2e;--text:${t.text};--text-dim:${t.textDim};--text-bright:#fff;--cyan:${t.cyan};--blue:${t.blue};--purple:${t.purple};--green:${t.green};--yellow:${t.yellow};--peach:${t.peach};--red:${t.red};--pink:${t.pink};--teal:${t.teal}}
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:'Inter',-apple-system,sans-serif;background:var(--bg);color:var(--text);min-height:100vh;overflow-x:hidden}
  body::before{content:'';position:fixed;inset:0;background:radial-gradient(ellipse 80% 50% at 50% -20%,${t.blue}08 0%,transparent 60%),radial-gradient(ellipse 60% 40% at 80% 100%,${t.purple}08 0%,transparent 50%);pointer-events:none;z-index:0}
  .container{max-width:1100px;margin:0 auto;padding:0 24px;position:relative;z-index:1}
  .hero{text-align:center;padding:80px 0 60px}
  .hero-badge{display:inline-flex;align-items:center;gap:8px;background:linear-gradient(135deg,${t.blue}15,${t.purple}15);border:1px solid ${t.blue}30;border-radius:100px;padding:8px 20px;font-size:13px;font-weight:500;color:var(--blue);margin-bottom:32px;letter-spacing:.5px}
  .hero-badge .dot{width:8px;height:8px;border-radius:50%;background:var(--green);animation:pulse-dot 2s ease-in-out infinite}
  @keyframes pulse-dot{0%,100%{opacity:1;box-shadow:0 0 0 0 ${t.green}40}50%{opacity:.7;box-shadow:0 0 0 6px ${t.green}00}}
  .hero h1{font-size:clamp(42px,6vw,72px);font-weight:900;line-height:1.05;letter-spacing:-2px;margin-bottom:20px}
  .hero h1 .gradient{background:linear-gradient(135deg,var(--cyan),var(--blue),var(--purple));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
  .hero .subtitle{font-size:20px;color:var(--text-dim);font-weight:300;max-width:600px;margin:0 auto;line-height:1.6}
  .hero .date{display:inline-block;margin-top:28px;font-family:'JetBrains Mono',monospace;font-size:14px;color:var(--text-dim);background:var(--bg-card);border:1px solid var(--border);border-radius:8px;padding:8px 16px}
  .stats-bar{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:16px;margin-bottom:64px}
  .stat{background:var(--bg-card);border:1px solid var(--border);border-radius:16px;padding:24px;text-align:center;transition:all .3s ease}
  .stat:hover{transform:translateY(-2px);box-shadow:0 8px 32px ${t.blue}10}
  .stat .number{font-size:36px;font-weight:800;font-family:'JetBrains Mono',monospace;line-height:1;margin-bottom:6px}
  .stat .label{font-size:13px;color:var(--text-dim);font-weight:500;text-transform:uppercase;letter-spacing:1px}
  .section{margin-bottom:64px}
  .section-header{display:flex;align-items:center;gap:12px;margin-bottom:28px}
  .section-header .icon{width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0}
  .section-header h2{font-size:28px;font-weight:700;letter-spacing:-.5px}
  .tests-banner{background:linear-gradient(135deg,${t.green}08,${t.green}03);border:1px solid ${t.green}25;border-radius:16px;padding:32px;text-align:center;margin-bottom:64px}
  .tests-banner .big-check{font-size:48px;margin-bottom:12px}
  .tests-banner h3{font-size:24px;font-weight:700;color:var(--green);margin-bottom:8px;font-family:'JetBrains Mono',monospace}
  .tests-banner p{color:var(--text-dim);font-size:14px}
  .tests-banner .test-pills{display:flex;justify-content:center;gap:8px;margin-top:16px;flex-wrap:wrap}
  .tests-banner .pill{background:${t.green}10;border:1px solid ${t.green}20;border-radius:100px;padding:6px 14px;font-size:12px;font-family:'JetBrains Mono',monospace;color:var(--green)}
  .features{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:16px}
  .feature{background:var(--bg-card);border:1px solid var(--border);border-radius:16px;padding:24px;display:flex;gap:16px;align-items:flex-start;transition:all .3s ease}
  .feature:hover{background:var(--bg-card-hover)}
  .feature .emoji{font-size:28px;flex-shrink:0;width:48px;height:48px;display:flex;align-items:center;justify-content:center;background:#ffffff05;border-radius:12px}
  .feature h4{font-size:15px;font-weight:600;margin-bottom:4px;color:var(--text-bright)}
  .feature p{font-size:13.5px;color:var(--text-dim);line-height:1.5}
  .arch-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}
  .arch-card{background:var(--bg-card);border:1px solid var(--border);border-radius:16px;padding:28px;transition:all .3s ease;position:relative;overflow:hidden}
  .arch-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;border-radius:16px 16px 0 0}
  .arch-card:hover{transform:translateY(-2px);box-shadow:0 12px 40px #00000040}
  .arch-card.v-0::before{background:linear-gradient(90deg,var(--blue),var(--cyan))}
  .arch-card.v-1::before{background:linear-gradient(90deg,var(--purple),var(--pink))}
  .arch-card.v-2::before{background:linear-gradient(90deg,var(--green),var(--teal))}
  .arch-card.v-3::before{background:linear-gradient(90deg,var(--yellow),var(--peach))}
  .arch-card.v-4::before{background:linear-gradient(90deg,var(--red),var(--pink))}
  .arch-card h3{font-size:18px;font-weight:700;margin-bottom:4px}
  .arch-card .path{font-family:'JetBrains Mono',monospace;font-size:12px;color:var(--text-dim);margin-bottom:16px}
  .arch-card ul{list-style:none;padding:0}
  .arch-card li{font-size:14px;color:var(--text-dim);padding:4px 0 4px 20px;position:relative}
  .arch-card li::before{content:'›';position:absolute;left:4px;color:var(--text-dim);opacity:.4}
  .flow{background:var(--bg-card);border:1px solid var(--border);border-radius:16px;padding:36px}
  .flow-steps{display:flex;flex-direction:column}
  .flow-step{display:flex;gap:20px;align-items:flex-start;position:relative;padding-bottom:28px}
  .flow-step:last-child{padding-bottom:0}
  .flow-step::before{content:'';position:absolute;left:19px;top:40px;bottom:0;width:2px;background:var(--border)}
  .flow-step:last-child::before{display:none}
  .flow-step .step-num{width:40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'JetBrains Mono',monospace;font-size:14px;font-weight:700;flex-shrink:0;border:2px solid var(--border);background:var(--bg);z-index:1}
  .flow-step:nth-child(1) .step-num{color:var(--cyan);border-color:var(--cyan)}
  .flow-step:nth-child(2) .step-num{color:var(--blue);border-color:var(--blue)}
  .flow-step:nth-child(3) .step-num{color:var(--purple);border-color:var(--purple)}
  .flow-step:nth-child(4) .step-num{color:var(--green);border-color:var(--green)}
  .flow-step:nth-child(5) .step-num{color:var(--yellow);border-color:var(--yellow)}
  .flow-step:nth-child(6) .step-num{color:var(--peach);border-color:var(--peach)}
  .flow-step:nth-child(7) .step-num{color:var(--pink);border-color:var(--pink)}
  .flow-step:nth-child(8) .step-num{color:var(--teal);border-color:var(--teal)}
  .flow-step .step-content h4{font-size:15px;font-weight:600;color:var(--text-bright);margin-bottom:4px}
  .flow-step .step-content p{font-size:13.5px;color:var(--text-dim);line-height:1.5}
  .file-tree{background:var(--bg-card);border:1px solid var(--border);border-radius:16px;padding:28px 32px;font-family:'JetBrains Mono',monospace;font-size:13.5px;line-height:2;overflow-x:auto;white-space:pre}
  .file-tree .dir{color:var(--blue);font-weight:600}
  .file-tree .file{color:var(--text-dim)}
  .file-tree .new{color:var(--green)}
  .file-tree .comment{color:var(--text-dim);opacity:.5}
  .stack-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px}
  .stack-item{background:var(--bg-card);border:1px solid var(--border);border-radius:12px;padding:16px 20px;display:flex;align-items:center;gap:12px;transition:all .2s ease}
  .stack-item:hover{background:var(--bg-card-hover)}
  .stack-item .tech-icon{font-size:22px;width:36px;text-align:center;flex-shrink:0}
  .stack-item .tech-name{font-size:14px;font-weight:600;color:var(--text-bright)}
  .stack-item .tech-role{font-size:12px;color:var(--text-dim)}
  .roadmap{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px}
  .phase{background:var(--bg-card);border:1px solid var(--border);border-radius:14px;padding:20px;text-align:center;position:relative;transition:all .3s ease}
  .phase:hover{transform:translateY(-2px)}
  .phase.active{border-color:var(--green);box-shadow:0 0 24px ${t.green}10}
  .phase.active::after{content:'NOW';position:absolute;top:-10px;right:12px;background:var(--green);color:var(--bg);font-size:10px;font-weight:800;padding:2px 8px;border-radius:6px;letter-spacing:1px}
  .phase .phase-num{font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--text-dim);margin-bottom:8px;text-transform:uppercase;letter-spacing:1px}
  .phase .phase-icon{font-size:28px;margin-bottom:8px}
  .phase .phase-name{font-size:14px;font-weight:700;color:var(--text-bright);margin-bottom:4px}
  .phase .phase-desc{font-size:12px;color:var(--text-dim);line-height:1.4}
  .quote-section{text-align:center;padding:60px 0 80px}
  .quote-section blockquote{font-size:28px;font-weight:300;font-style:italic;color:var(--text-dim);max-width:700px;margin:0 auto 16px;line-height:1.5}
  .quote-section blockquote em{background:linear-gradient(135deg,var(--cyan),var(--purple));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;font-weight:600;font-style:normal}
  .quote-section .attr{font-size:14px;color:var(--text-dim);opacity:.5}
  footer{text-align:center;padding:40px 0;border-top:1px solid var(--border);color:var(--text-dim);font-size:13px}
  footer .logo-text{font-family:'JetBrains Mono',monospace;font-weight:700;font-size:15px;margin-bottom:8px;color:var(--text)}
  @keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
  .hero,.stats-bar,.section,.tests-banner,.quote-section{animation:fadeUp .6s ease-out backwards}
  .stats-bar{animation-delay:.1s}
  @media(max-width:640px){.hero{padding:48px 0 40px}.file-tree{font-size:12px;padding:20px}.arch-grid{grid-template-columns:1fr}.roadmap{grid-template-columns:repeat(2,1fr)}}
</style>
</head>
<body>
<div class="container">

${renderHero(report)}
${renderStats(report.stats)}
${report.tests ? renderTests(report.tests) : ""}
${report.features ? renderFeatures(report.features) : ""}
${report.architecture ? renderArchitecture(report.architecture) : ""}
${report.flow ? renderFlow(report.flow) : ""}
${report.fileTree ? renderFileTree(report.fileTree) : ""}
${report.techStack ? renderTechStack(report.techStack) : ""}
${report.roadmap ? renderRoadmap(report.roadmap) : ""}
${report.quote ? renderQuote(report.quote) : ""}

</div>

${report.footer ? renderFooter(report.footer) : ""}

</body>
</html>`;
}

function esc(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function renderHero(r: SessionReport): string {
  return `<div class="hero">
  <div class="hero-badge"><span class="dot"></span>${esc(r.badge ?? "Mission Complete")}</div>
  <h1><span class="gradient">${esc(r.title)}</span></h1>
  <p class="subtitle">${esc(r.subtitle)}</p>
  <div class="date">${esc(r.date)}</div>
</div>`;
}

function renderStats(stats: SessionReport["stats"]): string {
  const items = stats
    .map(
      (s) =>
        `<div class="stat"><div class="number" style="color:${s.color ?? "var(--cyan)"}">${esc(String(s.value))}</div><div class="label">${esc(s.label)}</div></div>`
    )
    .join("\n");
  return `<div class="stats-bar">${items}</div>`;
}

function renderTests(t: SessionReport["tests"] & {}): string {
  const pills = t.suites
    .map((s) => `<span class="pill">${esc(s)} &#10003;</span>`)
    .join("");
  const allGreen = t.passed === t.total;
  return `<div class="tests-banner">
  <div class="big-check">${allGreen ? "&#10003;" : "&#9888;"}</div>
  <h3>${allGreen ? "ALL SYSTEMS GREEN" : `${t.passed}/${t.total} PASSING`}</h3>
  <p>${t.passed}/${t.total} tests passing${t.duration ? ` in ${esc(t.duration)}` : ""}</p>
  <div class="test-pills">${pills}</div>
</div>`;
}

function renderFeatures(features: SessionReport["features"] & {}): string {
  const cards = features
    .map(
      (f) =>
        `<div class="feature"><div class="emoji">${f.emoji}</div><div><h4>${esc(f.title)}</h4><p>${esc(f.description)}</p></div></div>`
    )
    .join("\n");
  return `<div class="section">
  <div class="section-header"><div class="icon" style="background:linear-gradient(135deg,var(--cyan)20,var(--blue)20)">&#9889;</div><h2>What Was Achieved</h2></div>
  <div class="features">${cards}</div>
</div>`;
}

function renderArchitecture(modules: SessionReport["architecture"] & {}): string {
  const cards = modules
    .map(
      (m, i) =>
        `<div class="arch-card v-${i % 5}"><h3>${esc(m.name)}</h3><div class="path">${esc(m.path)}</div><ul>${m.items.map((it) => `<li><strong>${esc(it.file)}</strong> — ${esc(it.description)}</li>`).join("")}</ul></div>`
    )
    .join("\n");
  return `<div class="section">
  <div class="section-header"><div class="icon" style="background:linear-gradient(135deg,var(--purple)20,var(--pink)20)">&#9881;&#65039;</div><h2>Architecture</h2></div>
  <div class="arch-grid">${cards}</div>
</div>`;
}

function renderFlow(steps: SessionReport["flow"] & {}): string {
  const items = steps
    .map(
      (s, i) =>
        `<div class="flow-step"><div class="step-num">${i + 1}</div><div class="step-content"><h4>${esc(s.title)}</h4><p>${esc(s.description)}</p></div></div>`
    )
    .join("\n");
  return `<div class="section">
  <div class="section-header"><div class="icon" style="background:linear-gradient(135deg,var(--green)20,var(--teal)20)">&#128260;</div><h2>How It Works</h2></div>
  <div class="flow"><div class="flow-steps">${items}</div></div>
</div>`;
}

function renderFileTree(entries: SessionReport["fileTree"] & {}): string {
  const lines = entries
    .map((e) => {
      const cls = e.type;
      return `<span class="${cls}">${esc(e.line)}</span>`;
    })
    .join("\n");
  return `<div class="section">
  <div class="section-header"><div class="icon" style="background:linear-gradient(135deg,var(--yellow)20,var(--peach)20)">&#128193;</div><h2>Files</h2></div>
  <div class="file-tree">${lines}</div>
</div>`;
}

function renderTechStack(items: SessionReport["techStack"] & {}): string {
  const cards = items
    .map(
      (t) =>
        `<div class="stack-item"><div class="tech-icon">${t.icon}</div><div><div class="tech-name">${esc(t.name)}</div><div class="tech-role">${esc(t.role)}</div></div></div>`
    )
    .join("\n");
  return `<div class="section">
  <div class="section-header"><div class="icon" style="background:linear-gradient(135deg,var(--blue)20,var(--cyan)20)">&#128295;</div><h2>Tech Stack</h2></div>
  <div class="stack-grid">${cards}</div>
</div>`;
}

function renderRoadmap(phases: SessionReport["roadmap"] & {}): string {
  const cards = phases
    .map(
      (p) =>
        `<div class="phase${p.active ? " active" : ""}"><div class="phase-num">${esc(p.phase)}</div><div class="phase-icon">${p.icon}</div><div class="phase-name">${esc(p.name)}</div><div class="phase-desc">${esc(p.description)}</div></div>`
    )
    .join("\n");
  return `<div class="section">
  <div class="section-header"><div class="icon" style="background:linear-gradient(135deg,var(--red)20,var(--pink)20)">&#128640;</div><h2>Roadmap</h2></div>
  <div class="roadmap">${cards}</div>
</div>`;
}

function renderQuote(q: NonNullable<SessionReport["quote"]>): string {
  const text = q.highlight
    ? esc(q.text).replace(
        esc(q.highlight),
        `<em>${esc(q.highlight)}</em>`
      )
    : esc(q.text);
  return `<div class="quote-section">
  <blockquote>${text}</blockquote>
  ${q.attribution ? `<div class="attr">— ${esc(q.attribution)}</div>` : ""}
</div>`;
}

function renderFooter(f: NonNullable<SessionReport["footer"]>): string {
  return `<footer><div class="container"><div class="logo-text">${esc(f.project)} ${esc(f.version)}</div>Built by ${esc(f.author)} &middot; ${new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}</div></footer>`;
}
