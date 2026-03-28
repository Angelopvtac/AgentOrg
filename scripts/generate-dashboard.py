#!/usr/bin/env python3
"""Generate the AgentOrg founder dashboard from vault JSON files."""

import json
import sys
from pathlib import Path
from html import escape

def load_json(path, fallback=None):
    """Load JSON file, return fallback on any error."""
    if fallback is None:
        fallback = {}
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return fallback


def evaluate_gate_criteria(criteria, founder, onboarding, budget):
    """Evaluate L0 gate criteria and return list of (description, passed) tuples."""
    results = []
    for c in criteria:
        cid = c.get("id", "")
        desc = c.get("description", "")
        passed = False

        if cid == "profile-complete":
            pi = founder.get("personalInfo") or {}
            passed = bool(pi.get("name") and pi.get("timezone") and pi.get("communicationStyle"))
        elif cid == "skills-identified":
            skills = founder.get("skills") or []
            passed = len(skills) >= 3
        elif cid == "availability-set":
            avail = founder.get("availability") or {}
            passed = bool((avail.get("weeklyHours") or 0) > 0 and avail.get("quietHours"))
        elif cid == "financial-baseline":
            fin = founder.get("financial") or {}
            passed = bool(budget.get("dailyLimit", 0) > 0 and fin.get("riskTolerance"))
        elif cid == "vision-defined":
            vision = founder.get("vision") or {}
            stmt = vision.get("statement") or ""
            passed = len(stmt) > 50
        elif cid == "onboarding-complete":
            passed = onboarding.get("status") == "complete"

        results.append((desc, passed))
    return results


def render_gate_criteria(results):
    """Render gate criteria as HTML list items."""
    items = []
    for desc, passed in results:
        if passed:
            items.append(
                f'<li class="criteria-item pass">'
                f'<span class="criteria-icon pass">&#10003;</span>'
                f'<span class="criteria-desc">{escape(desc)}</span></li>'
            )
        else:
            items.append(
                f'<li class="criteria-item">'
                f'<span class="criteria-icon fail"></span>'
                f'<span class="criteria-desc">{escape(desc)}</span></li>'
            )
    return "\n        ".join(items)


def render_onboarding(sections):
    """Render onboarding section grid."""
    items = []
    for name, data in sections.items():
        status = data.get("status", "pending")
        dot_cls = {"complete": "complete", "in-progress": "in-progress"}.get(status, "pending")
        item_cls = "complete" if status == "complete" else ""
        label = name.replace("-", " ").title()
        items.append(
            f'<div class="onboarding-item {item_cls}">'
            f'<span class="dot {dot_cls}"></span>'
            f'<span class="label">{escape(label)}</span></div>'
        )
    return "\n        ".join(items)


def render_tasks(tasks_data):
    """Render human tasks list."""
    tasks = tasks_data.get("tasks", [])
    stats = tasks_data.get("stats", {})

    if not tasks:
        created = stats.get("totalCreated", 0)
        completed = stats.get("totalCompleted", 0)
        return (
            f'<div class="tasks-empty">No pending tasks<br>'
            f'<span style="font-size: 11px;">Created: {created} | Completed: {completed}</span></div>'
        )

    items = []
    for t in tasks[:10]:
        title = escape(t.get("title", "Untitled"))
        desc = escape(t.get("description", "")[:120])
        pri = t.get("priority", "medium").lower()
        item = f'<div class="task-item"><span class="task-priority {pri}">{pri}</span><div><div class="task-title">{title}</div>'
        if desc:
            item += f'<div class="task-desc">{desc}</div>'
        item += "</div></div>"
        items.append(item)
    return "\n      ".join(items)


def render_knowledge(collection_name, data):
    """Render a knowledge collection."""
    entries = data.get("entries", [])
    count = len(entries)

    header = (
        f'<div class="knowledge-header">'
        f'<div class="card-title" style="margin-bottom: 0;">{collection_name.title()}</div>'
        f'<div class="knowledge-count">{count} entries</div></div>'
    )

    if not entries:
        body = f'<div class="knowledge-empty">No {collection_name} recorded yet</div>'
    else:
        items = []
        for e in entries[-5:]:
            title = escape(e.get("title", e.get("id", "Untitled")))
            date = (e.get("date") or e.get("createdAt") or "")[:10]
            tags = ", ".join(e.get("tags", [])[:3])
            meta_parts = [p for p in [date, tags] if p]
            meta = " &middot; ".join(meta_parts)
            items.append(
                f'<div class="knowledge-entry">'
                f'<div class="knowledge-entry-title">{title}</div>'
                f'<div class="knowledge-entry-meta">{meta}</div></div>'
            )
        body = "\n    ".join(items)

    return f"{header}\n    {body}\n    <div style=\"margin-bottom: 20px;\"></div>"


def main():
    knowledge_dir = Path(sys.argv[1])
    progression_path = Path(sys.argv[2])
    output_file = Path(sys.argv[3])
    generated_at = sys.argv[4]
    generated_display = sys.argv[5]

    # Load all vault data
    phase_state = load_json(knowledge_dir / "phase-state.json")
    onboarding = load_json(knowledge_dir / "onboarding-state.json")
    budget = load_json(knowledge_dir / "economics" / "daily-budget.json")
    treasury = load_json(knowledge_dir / "economics" / "treasury.json")
    tasks_data = load_json(knowledge_dir / "human-tasks.json")
    decisions = load_json(knowledge_dir / "decisions.json")
    insights = load_json(knowledge_dir / "insights.json")
    lessons = load_json(knowledge_dir / "lessons.json")
    briefing = load_json(knowledge_dir / "briefing-state.json")
    founder = load_json(knowledge_dir / "founder-profile.json")
    progression = load_json(progression_path)

    # Phase data
    current_phase = phase_state.get("currentPhase", "L0")
    phase_name = phase_state.get("phaseName", "Onboarding")
    phase_start = (phase_state.get("phaseStartDate") or "Not set")[:10]
    phases_config = progression.get("phases", {})
    phase_desc = phases_config.get(current_phase, {}).get("description", "")

    all_phases = ["L0", "L1", "L2", "L3", "L4", "L5", "L6"]
    phase_idx = all_phases.index(current_phase) if current_phase in all_phases else 0

    # Phase timeline dots
    dots = []
    for i in range(7):
        if i < phase_idx:
            dots.append('<div class="phase-dot completed"></div>')
        elif i == phase_idx:
            dots.append('<div class="phase-dot active"></div>')
        else:
            dots.append('<div class="phase-dot"></div>')
    phase_dots = "\n      ".join(dots)

    # Gate criteria
    criteria = phases_config.get(current_phase, {}).get("gate", {}).get("criteria", [])
    gate_results = evaluate_gate_criteria(criteria, founder, onboarding, budget)
    gate_passed = sum(1 for _, p in gate_results if p)
    gate_total = len(gate_results)
    gate_items = render_gate_criteria(gate_results)

    # Onboarding
    sections = onboarding.get("sections", {})
    ob_completed = sum(1 for s in sections.values() if s.get("status") == "complete")
    ob_total = len(sections)
    ob_items = render_onboarding(sections)

    # Budget
    spent = float(budget.get("spent", 0))
    limit = float(budget.get("dailyLimit", 5))
    pct = (spent / limit * 100) if limit > 0 else 0
    bd = budget.get("breakdown", {})
    t1 = float(bd.get("tier1", 0))
    t2 = float(bd.get("tier2", 0))
    t3 = float(bd.get("tier3", 0))

    if pct >= 100:
        bar_color = "var(--red)"
    elif pct >= 80:
        bar_color = "var(--amber)"
    else:
        bar_color = "var(--accent)"
    bar_width = min(pct, 100)

    # Treasury
    balance = float(treasury.get("balance", 0))
    total_rev = float(treasury.get("totalRevenue", 0))
    total_cost = float(treasury.get("totalCosts", 0))
    rev_ratio = treasury.get("revenueToExpenseRatio", 0)
    balance_cls = "positive" if balance > 0 else ("negative" if balance < 0 else "neutral")

    # Tasks
    tasks_html = render_tasks(tasks_data)

    # Knowledge
    knowledge_html = "\n    ".join([
        render_knowledge("decisions", decisions),
        render_knowledge("insights", insights),
        render_knowledge("lessons", lessons),
    ])

    # Briefing
    last_briefing = briefing.get("lastBriefingSent")
    briefing_count = len(briefing.get("briefingHistory", []))
    if last_briefing:
        briefing_display = f"{last_briefing[:10]} ({briefing_count} total)"
    else:
        briefing_display = f"Never sent ({briefing_count} total)"

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AgentOrg &mdash; Founder Dashboard</title>
<style>
  :root {{
    --bg: #0a0a0b;
    --surface: #141416;
    --surface-2: #1c1c20;
    --border: #27272b;
    --border-subtle: #1e1e22;
    --text: #ececee;
    --text-muted: #8b8b94;
    --text-dim: #56565e;
    --accent: #6366f1;
    --accent-soft: rgba(99, 102, 241, 0.12);
    --green: #22c55e;
    --green-soft: rgba(34, 197, 94, 0.12);
    --amber: #f59e0b;
    --amber-soft: rgba(245, 158, 11, 0.12);
    --red: #ef4444;
    --red-soft: rgba(239, 68, 68, 0.12);
    --radius: 8px;
    --radius-lg: 12px;
  }}

  * {{ margin: 0; padding: 0; box-sizing: border-box; }}

  body {{
    font-family: -apple-system, BlinkMacSystemFont, 'Inter', 'Segoe UI', sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.5;
    min-height: 100vh;
  }}

  .container {{
    max-width: 1120px;
    margin: 0 auto;
    padding: 32px 24px;
  }}

  @media (max-width: 640px) {{
    .container {{ padding: 20px 16px; }}
  }}

  .header {{
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    margin-bottom: 40px;
    flex-wrap: wrap;
    gap: 8px;
  }}

  .header h1 {{
    font-size: 20px;
    font-weight: 600;
    letter-spacing: -0.02em;
  }}

  .header .meta {{
    font-size: 12px;
    color: var(--text-dim);
    font-variant-numeric: tabular-nums;
  }}

  .refresh-hint {{
    font-size: 11px;
    color: var(--text-dim);
    margin-top: 4px;
    font-family: 'SF Mono', 'Fira Code', monospace;
  }}

  /* Phase Banner */
  .phase-banner {{
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 24px;
    margin-bottom: 24px;
  }}

  .phase-label {{
    display: inline-flex;
    align-items: center;
    gap: 8px;
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--accent);
    background: var(--accent-soft);
    padding: 4px 10px;
    border-radius: 4px;
    margin-bottom: 12px;
  }}

  .phase-name {{
    font-size: 28px;
    font-weight: 700;
    letter-spacing: -0.03em;
    margin-bottom: 6px;
  }}

  .phase-desc {{
    font-size: 14px;
    color: var(--text-muted);
    max-width: 600px;
  }}

  .phase-meta {{
    margin-top: 8px;
    font-size: 12px;
    color: var(--text-dim);
  }}

  .phase-timeline {{
    display: flex;
    gap: 2px;
    margin-top: 20px;
  }}

  .phase-dot {{
    height: 4px;
    flex: 1;
    border-radius: 2px;
    background: var(--border);
  }}

  .phase-dot.active {{ background: var(--accent); }}
  .phase-dot.completed {{ background: var(--green); }}

  /* Grid */
  .grid {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    margin-bottom: 24px;
  }}

  @media (max-width: 640px) {{
    .grid {{ grid-template-columns: 1fr; }}
  }}

  .card {{
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 20px;
  }}

  .card-title {{
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-dim);
    margin-bottom: 16px;
  }}

  /* Gate Criteria */
  .criteria-list {{
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }}

  .criteria-item {{
    display: flex;
    align-items: flex-start;
    gap: 10px;
    font-size: 13px;
  }}

  .criteria-icon {{
    flex-shrink: 0;
    width: 18px;
    height: 18px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 10px;
    margin-top: 1px;
  }}

  .criteria-icon.pass {{
    background: var(--green-soft);
    color: var(--green);
  }}

  .criteria-icon.fail {{
    background: var(--surface-2);
    color: var(--text-dim);
    border: 1px solid var(--border);
  }}

  .criteria-desc {{ color: var(--text-muted); }}
  .criteria-item.pass .criteria-desc {{ color: var(--text); }}

  /* Onboarding */
  .onboarding-grid {{
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
  }}

  @media (max-width: 480px) {{
    .onboarding-grid {{ grid-template-columns: repeat(2, 1fr); }}
  }}

  .onboarding-item {{
    background: var(--surface-2);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius);
    padding: 10px 12px;
    font-size: 12px;
    display: flex;
    align-items: center;
    gap: 8px;
  }}

  .onboarding-item .dot {{
    width: 6px;
    height: 6px;
    border-radius: 50%;
    flex-shrink: 0;
  }}

  .dot.pending {{ background: var(--text-dim); }}
  .dot.in-progress {{ background: var(--amber); }}
  .dot.complete {{ background: var(--green); }}

  .onboarding-item .label {{ color: var(--text-muted); }}
  .onboarding-item.complete .label {{ color: var(--text); }}

  /* Budget */
  .budget-stats {{
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 12px;
  }}

  .budget-amount {{
    font-size: 24px;
    font-weight: 700;
    letter-spacing: -0.02em;
    font-variant-numeric: tabular-nums;
  }}

  .budget-limit {{
    font-size: 13px;
    color: var(--text-dim);
    font-variant-numeric: tabular-nums;
  }}

  .budget-bar-container {{
    background: var(--surface-2);
    border-radius: 4px;
    height: 8px;
    margin-bottom: 16px;
    overflow: hidden;
  }}

  .budget-bar {{
    height: 100%;
    border-radius: 4px;
    min-width: 0;
  }}

  .budget-breakdown {{
    display: flex;
    gap: 16px;
    padding-top: 12px;
    border-top: 1px solid var(--border-subtle);
    flex-wrap: wrap;
  }}

  .budget-tier {{
    font-size: 12px;
    color: var(--text-dim);
    font-variant-numeric: tabular-nums;
  }}

  .budget-tier span {{ color: var(--text-muted); }}

  /* Treasury */
  .treasury-row {{
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    padding: 8px 0;
  }}

  .treasury-row + .treasury-row {{
    border-top: 1px solid var(--border-subtle);
  }}

  .treasury-label {{
    font-size: 13px;
    color: var(--text-muted);
  }}

  .treasury-value {{
    font-size: 14px;
    font-weight: 600;
    font-variant-numeric: tabular-nums;
  }}

  .treasury-value.positive {{ color: var(--green); }}
  .treasury-value.negative {{ color: var(--red); }}
  .treasury-value.neutral {{ color: var(--text); }}

  /* Tasks */
  .tasks-empty {{
    text-align: center;
    padding: 24px 16px;
    color: var(--text-dim);
    font-size: 13px;
  }}

  .task-item {{
    display: flex;
    align-items: flex-start;
    gap: 10px;
    padding: 10px 0;
    font-size: 13px;
  }}

  .task-item + .task-item {{
    border-top: 1px solid var(--border-subtle);
  }}

  .task-priority {{
    flex-shrink: 0;
    font-size: 10px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    padding: 2px 6px;
    border-radius: 3px;
    margin-top: 2px;
  }}

  .task-priority.critical {{ background: var(--red-soft); color: var(--red); }}
  .task-priority.high {{ background: var(--amber-soft); color: var(--amber); }}
  .task-priority.medium {{ background: var(--accent-soft); color: var(--accent); }}
  .task-priority.low {{ background: var(--surface-2); color: var(--text-dim); }}

  .task-title {{ color: var(--text); }}
  .task-desc {{ color: var(--text-dim); font-size: 12px; margin-top: 2px; }}

  /* Knowledge */
  .knowledge-section {{ margin-bottom: 24px; }}

  .knowledge-header {{
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    margin-bottom: 12px;
  }}

  .knowledge-count {{
    font-size: 12px;
    color: var(--text-dim);
    font-variant-numeric: tabular-nums;
  }}

  .knowledge-empty {{
    background: var(--surface);
    border: 1px dashed var(--border);
    border-radius: var(--radius);
    padding: 20px;
    text-align: center;
    color: var(--text-dim);
    font-size: 13px;
  }}

  .knowledge-entry {{
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 14px 16px;
    margin-bottom: 8px;
  }}

  .knowledge-entry-title {{
    font-size: 13px;
    font-weight: 500;
    margin-bottom: 4px;
  }}

  .knowledge-entry-meta {{
    font-size: 11px;
    color: var(--text-dim);
  }}

  /* Briefing */
  .briefing-status {{
    font-size: 13px;
    color: var(--text-muted);
  }}

  .briefing-status .value {{
    color: var(--text);
    font-weight: 500;
  }}

  /* Full-width card */
  .card.full {{ grid-column: 1 / -1; }}

  /* Footer */
  .footer {{
    margin-top: 40px;
    padding-top: 20px;
    border-top: 1px solid var(--border-subtle);
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 11px;
    color: var(--text-dim);
  }}
</style>
</head>
<body>
<div class="container">

  <header class="header">
    <div>
      <h1>AgentOrg</h1>
      <div class="refresh-hint">bash scripts/generate-dashboard.sh</div>
    </div>
    <div class="meta">{escape(generated_display)}</div>
  </header>

  <div class="phase-banner">
    <div class="phase-label">Phase {escape(current_phase)}</div>
    <div class="phase-name">{escape(phase_name)}</div>
    <div class="phase-desc">{escape(phase_desc)}</div>
    <div class="phase-meta">Started {escape(phase_start)}</div>
    <div class="phase-timeline">
      {phase_dots}
    </div>
  </div>

  <div class="grid">

    <div class="card">
      <div class="card-title">Gate Progress &mdash; {gate_passed}/{gate_total} criteria met</div>
      <ul class="criteria-list">
        {gate_items}
      </ul>
    </div>

    <div class="card">
      <div class="card-title">Onboarding &mdash; {ob_completed}/{ob_total} sections complete</div>
      <div class="onboarding-grid">
        {ob_items}
      </div>
    </div>

    <div class="card">
      <div class="card-title">Daily Budget</div>
      <div class="budget-stats">
        <div class="budget-amount">${spent:.2f}</div>
        <div class="budget-limit">of ${limit:.2f} limit</div>
      </div>
      <div class="budget-bar-container">
        <div class="budget-bar" style="width: {bar_width:.1f}%; background: {bar_color};"></div>
      </div>
      <div class="budget-breakdown">
        <div class="budget-tier">T1 Triage <span>${t1:.2f}</span></div>
        <div class="budget-tier">T2 Execution <span>${t2:.2f}</span></div>
        <div class="budget-tier">T3 Strategic <span>${t3:.2f}</span></div>
      </div>
    </div>

    <div class="card">
      <div class="card-title">Treasury</div>
      <div class="treasury-row">
        <span class="treasury-label">Balance</span>
        <span class="treasury-value {balance_cls}">${balance:.2f}</span>
      </div>
      <div class="treasury-row">
        <span class="treasury-label">Total Revenue</span>
        <span class="treasury-value neutral">${total_rev:.2f}</span>
      </div>
      <div class="treasury-row">
        <span class="treasury-label">Total Costs</span>
        <span class="treasury-value neutral">${total_cost:.2f}</span>
      </div>
      <div class="treasury-row">
        <span class="treasury-label">Revenue / Expense</span>
        <span class="treasury-value neutral">{rev_ratio}x</span>
      </div>
    </div>

    <div class="card full">
      <div class="card-title">Human Tasks</div>
      {tasks_html}
    </div>

  </div>

  <div class="knowledge-section">
    {knowledge_html}
  </div>

  <div class="card" style="margin-bottom: 24px;">
    <div class="card-title">Daily Briefing</div>
    <div class="briefing-status">Last sent: <span class="value">{escape(briefing_display)}</span></div>
  </div>

  <footer class="footer">
    <span>AgentOrg v0.3.0 &middot; Phase {escape(current_phase)}</span>
    <span>{escape(generated_at)}</span>
  </footer>

</div>
</body>
</html>"""

    output_file.write_text(html)


if __name__ == "__main__":
    main()
