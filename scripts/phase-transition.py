#!/usr/bin/env python3
"""Evaluate the current phase gate and transition to the next phase if all criteria pass.

Modes:
  --check <vault_dir>       Dry-run: evaluate gate, report pass/fail, do not modify state
  --transition <vault_dir>  Evaluate gate and transition if all criteria pass (default)
  --force <vault_dir>       Skip gate evaluation and force transition to next phase
  --status <vault_dir>      Show current phase status and gate results

Exit codes:
  0 = transition completed (or gate passes in --check mode)
  1 = gate not passed (criteria unmet)
  2 = error (missing files, invalid config, already at terminal phase)
"""

import json
import sys
import subprocess
import shutil
from pathlib import Path
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# File I/O
# ---------------------------------------------------------------------------

def load_json(path, fallback=None):
    if fallback is None:
        fallback = {}
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return fallback


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


# ---------------------------------------------------------------------------
# Gate evaluation — L0
# ---------------------------------------------------------------------------

def evaluate_l0_gate(vault):
    """Evaluate all 6 L0 gate criteria. Returns list of result dicts."""
    founder = load_json(vault / "founder-profile.json")
    onboarding = load_json(vault / "onboarding-state.json")
    budget = load_json(vault / "economics" / "daily-budget.json")

    results = []

    # 1. profile-complete
    pi = founder.get("personalInfo") or {}
    name = pi.get("name")
    tz = pi.get("timezone")
    style = pi.get("communicationStyle")
    passed = bool(name and tz and style)
    results.append({
        "id": "profile-complete",
        "description": "Founder profile has all required fields populated",
        "status": "PASS" if passed else "FAIL",
        "target": "name, timezone, communicationStyle all non-null",
        "actual": f"name={name!r}, timezone={tz!r}, style={style!r}"
    })

    # 2. skills-identified
    skills = founder.get("skills") or []
    count = len(skills)
    passed = count >= 3
    results.append({
        "id": "skills-identified",
        "description": "At least 3 founder skills documented",
        "status": "PASS" if passed else "FAIL",
        "target": ">= 3 skills",
        "actual": f"{count} skills"
    })

    # 3. availability-set
    avail = founder.get("availability") or {}
    hours = avail.get("weeklyHours") or 0
    quiet = avail.get("quietHours")
    passed = hours > 0 and quiet is not None
    results.append({
        "id": "availability-set",
        "description": "Weekly hours and quiet hours defined",
        "status": "PASS" if passed else "FAIL",
        "target": "weeklyHours > 0 and quietHours non-null",
        "actual": f"weeklyHours={hours}, quietHours={quiet!r}"
    })

    # 4. financial-baseline
    limit = budget.get("dailyLimit", 0)
    risk = (founder.get("financial") or {}).get("riskTolerance")
    passed = limit > 0 and risk is not None
    results.append({
        "id": "financial-baseline",
        "description": "Daily budget confirmed and risk tolerance set",
        "status": "PASS" if passed else "FAIL",
        "target": "dailyLimit > 0 AND riskTolerance non-null",
        "actual": f"dailyLimit={limit}, riskTolerance={risk!r}"
    })

    # 5. vision-defined
    stmt = (founder.get("vision") or {}).get("statement") or ""
    length = len(stmt)
    passed = length > 50
    results.append({
        "id": "vision-defined",
        "description": "Vision statement exists with > 50 characters",
        "status": "PASS" if passed else "FAIL",
        "target": "> 50 characters",
        "actual": f"{length} characters"
    })

    # 6. onboarding-complete
    status = onboarding.get("status")
    passed = status == "complete"
    results.append({
        "id": "onboarding-complete",
        "description": "All 9 onboarding sections marked complete",
        "status": "PASS" if passed else "FAIL",
        "target": "status == 'complete'",
        "actual": f"status={status!r}"
    })

    return results


# ---------------------------------------------------------------------------
# Gate evaluation — L1
# ---------------------------------------------------------------------------

def evaluate_l1_gate(vault):
    """Evaluate L1 gate criteria. Returns list of result dicts."""
    direction = load_json(vault / "business" / "direction.json")
    brand = load_json(vault / "business" / "brand-brief.json")
    research_dir = vault / "research"

    results = []

    # 1. direction-selected
    d = direction.get("direction")
    target_market = direction.get("targetMarket")
    passed = d is not None and target_market is not None
    results.append({
        "id": "direction-selected",
        "description": "Business direction documented with target market",
        "status": "PASS" if passed else "FAIL",
        "target": "direction and targetMarket non-null",
        "actual": f"direction={d!r}, targetMarket={target_market!r}"
    })

    # 2. brand-brief-complete
    brand_name = brand.get("brandName")
    positioning = brand.get("positioning")
    tone = brand.get("tone")
    passed = bool(brand_name and positioning and tone)
    results.append({
        "id": "brand-brief-complete",
        "description": "Brand brief with name, positioning, and tone defined",
        "status": "PASS" if passed else "FAIL",
        "target": "brandName, positioning, tone all non-null",
        "actual": f"brandName={brand_name!r}, positioning={positioning!r}, tone={tone!r}"
    })

    # 3. market-research-done
    report_count = 0
    if research_dir.is_dir():
        report_count = len([f for f in research_dir.iterdir() if f.is_file()])
    passed = report_count >= 1
    results.append({
        "id": "market-research-done",
        "description": "At least one market research report generated",
        "status": "PASS" if passed else "FAIL",
        "target": ">= 1 report file in vault/research/",
        "actual": f"{report_count} report(s)"
    })

    return results


# ---------------------------------------------------------------------------
# Generic gate evaluation dispatcher
# ---------------------------------------------------------------------------

GATE_EVALUATORS = {
    "L0": evaluate_l0_gate,
    "L1": evaluate_l1_gate,
    # L2-L5 evaluators can be added as the system progresses
}


def evaluate_gate(phase, vault):
    """Evaluate the gate for the given phase. Returns (results, all_passed)."""
    evaluator = GATE_EVALUATORS.get(phase)
    if evaluator is None:
        return None, False  # No evaluator for this phase
    results = evaluator(vault)
    all_passed = all(r["status"] == "PASS" for r in results)
    return results, all_passed


# ---------------------------------------------------------------------------
# Phase transition
# ---------------------------------------------------------------------------

def get_phase_info(progression, phase_id):
    """Get phase data from progression.json."""
    return progression.get("phases", {}).get(phase_id)


def create_backup(vault_dir, project_root):
    """Create a backup before phase transition using the existing backup script."""
    backup_script = project_root / "scripts" / "backup.sh"
    if backup_script.exists():
        print("\n  Creating pre-transition backup...")
        result = subprocess.run(
            ["bash", str(backup_script)],
            capture_output=True, text=True, cwd=str(project_root)
        )
        if result.returncode == 0:
            print("  Backup completed successfully.")
            return True
        else:
            print(f"  WARNING: Backup failed: {result.stderr.strip()}")
            return False
    else:
        print("  WARNING: No backup script found. Skipping backup.")
        return False


def execute_transition(vault_dir, progression, current_phase, target_phase, results, project_root):
    """Execute the phase transition: backup, update state, report."""
    vault = Path(vault_dir)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    target_info = get_phase_info(progression, target_phase)
    if target_info is None:
        print(f"  ERROR: Target phase {target_phase} not found in progression.json")
        return False

    # Create backup
    if project_root:
        create_backup(vault_dir, Path(project_root))

    # Load current phase state
    phase_state = load_json(vault / "phase-state.json")

    # Build transition history entry
    transition_entry = {
        "timestamp": now,
        "type": "transition",
        "fromPhase": current_phase,
        "toPhase": target_phase,
        "gateStatus": "PASSED",
        "criteria": [
            {"id": r["id"], "status": r["status"], "actual": r["actual"]}
            for r in results
        ] if results else []
    }

    # Update phase state
    phase_state["currentPhase"] = target_phase
    phase_state["phaseName"] = target_info["name"]
    phase_state["phaseStartDate"] = now
    phase_state["lastGateEvaluation"] = now
    phase_state["gateResults"] = {
        r["id"]: {"status": r["status"], "actual": r["actual"]}
        for r in results
    } if results else {}

    # Append transition to history
    phase_state.setdefault("history", []).append(transition_entry)

    write_json(vault / "phase-state.json", phase_state)
    return True


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def print_gate_report(results, all_passed, phase):
    """Print a formatted gate evaluation report."""
    passed_count = sum(1 for r in results if r["status"] == "PASS")
    total = len(results)

    overall = "PASSED" if all_passed else "OPEN"
    print(f"\n{'=' * 56}")
    print(f"  {phase} Gate Evaluation: {overall} ({passed_count}/{total} criteria met)")
    print(f"{'=' * 56}\n")

    for i, r in enumerate(results, 1):
        icon = "[PASS]" if r["status"] == "PASS" else "[FAIL]"
        print(f"  {i}. {icon} {r['description']}")
        print(f"       Target: {r['target']}")
        print(f"       Actual: {r['actual']}")
        print()

    return all_passed


def print_transition_result(current_phase, target_phase, target_info):
    """Print transition success message."""
    agents = target_info.get("agents", [])
    new_agents = [a for a in agents if a not in ["orchestrator", "core-assistant"]]

    print(f"\n{'=' * 56}")
    print(f"  Phase Transition: {current_phase} -> {target_phase} ({target_info['name']})")
    print(f"{'=' * 56}")
    print(f"\n  Phase: {target_info['name']}")
    print(f"  Description: {target_info['description']}")
    print(f"  Active agents: {', '.join(agents)}")
    if new_agents:
        print(f"  Newly unlocked: {', '.join(new_agents)}")
    print(f"\n{'=' * 56}")


def print_status(vault_dir, progression):
    """Print current phase status."""
    vault = Path(vault_dir)
    phase_state = load_json(vault / "phase-state.json")

    current = phase_state.get("currentPhase", "L0")
    name = phase_state.get("phaseName", "Unknown")
    start = phase_state.get("phaseStartDate", "Unknown")
    last_eval = phase_state.get("lastGateEvaluation", "Never")
    history = phase_state.get("history", [])

    phase_info = get_phase_info(progression, current)
    transition = phase_info.get("transition") if phase_info else None

    print(f"\n{'=' * 56}")
    print(f"  Phase Status")
    print(f"{'=' * 56}")
    print(f"\n  Current phase: {current} ({name})")
    print(f"  Started: {start}")
    print(f"  Last gate evaluation: {last_eval}")
    print(f"  History entries: {len(history)}")

    if transition:
        print(f"  Next phase: {transition['target']}")
    else:
        print(f"  Next phase: (terminal phase)")

    # Show gate results if available
    gate_results = phase_state.get("gateResults", {})
    if gate_results:
        passed = sum(1 for v in gate_results.values() if v.get("status") == "PASS")
        total = len(gate_results)
        print(f"  Gate progress: {passed}/{total} criteria met")

    # Show transition history
    transitions = [h for h in history if h.get("type") == "transition"]
    if transitions:
        print(f"\n  Transition History:")
        for t in transitions:
            print(f"    {t['timestamp']}: {t['fromPhase']} -> {t['toPhase']}")

    print(f"\n{'=' * 56}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

USAGE = """Usage: phase-transition.py <mode> <vault_dir> [options]

Modes:
  --check        Dry-run: evaluate gate criteria, report pass/fail (no changes)
  --transition   Evaluate gate and transition if all pass (default)
  --force        Force transition without gate evaluation
  --status       Show current phase status

Options:
  --config <path>   Path to progression.json (default: config/progression.json)
  --project <path>  Project root for backup script (default: auto-detected)

Exit codes:
  0 = transition completed / gate passed (--check)
  1 = gate not passed (criteria unmet)
  2 = error (bad config, terminal phase, missing evaluator)

Examples:
  python3 scripts/phase-transition.py --check knowledge/
  python3 scripts/phase-transition.py --transition knowledge/
  python3 scripts/phase-transition.py --force knowledge/
  python3 scripts/phase-transition.py --status knowledge/
"""


def parse_args(argv):
    """Parse CLI arguments."""
    args = {
        "mode": "--transition",
        "vault_dir": None,
        "config": None,
        "project": None,
    }

    positional = []
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg in ("--check", "--transition", "--force", "--status"):
            args["mode"] = arg
        elif arg == "--config" and i + 1 < len(argv):
            i += 1
            args["config"] = argv[i]
        elif arg == "--project" and i + 1 < len(argv):
            i += 1
            args["project"] = argv[i]
        elif not arg.startswith("--"):
            positional.append(arg)
        i += 1

    if positional:
        args["vault_dir"] = positional[0]

    return args


def main():
    if len(sys.argv) < 2:
        print(USAGE, file=sys.stderr)
        sys.exit(2)

    args = parse_args(sys.argv[1:])

    # Resolve vault directory
    vault_dir = args["vault_dir"]
    if vault_dir is None:
        print("ERROR: No vault directory specified.", file=sys.stderr)
        print(USAGE, file=sys.stderr)
        sys.exit(2)

    vault = Path(vault_dir)
    if not vault.is_dir():
        print(f"ERROR: Vault directory not found: {vault_dir}", file=sys.stderr)
        sys.exit(2)

    # Resolve config path
    if args["config"]:
        config_path = Path(args["config"])
    else:
        # Auto-detect: look relative to script, then relative to vault
        script_dir = Path(__file__).parent
        project_root = script_dir.parent
        config_path = project_root / "config" / "progression.json"

    if not config_path.exists():
        print(f"ERROR: Progression config not found: {config_path}", file=sys.stderr)
        sys.exit(2)

    progression = load_json(config_path)
    if not progression.get("phases"):
        print(f"ERROR: No phases found in {config_path}", file=sys.stderr)
        sys.exit(2)

    # Resolve project root for backup
    project_root = Path(args["project"]) if args["project"] else config_path.parent.parent

    # Load current phase
    phase_state = load_json(vault / "phase-state.json")
    current_phase = phase_state.get("currentPhase", "L0")
    phase_info = get_phase_info(progression, current_phase)

    if phase_info is None:
        print(f"ERROR: Current phase {current_phase} not found in progression config.", file=sys.stderr)
        sys.exit(2)

    mode = args["mode"]

    # --status: just show current state
    if mode == "--status":
        print_status(vault_dir, progression)
        sys.exit(0)

    # Check for terminal phase
    transition = phase_info.get("transition")
    if transition is None:
        print(f"\n  Phase {current_phase} ({phase_info['name']}) is the terminal phase.")
        print("  No further transitions available.")
        sys.exit(2)

    target_phase = transition["target"]
    target_info = get_phase_info(progression, target_phase)

    # --force: skip gate evaluation
    if mode == "--force":
        print(f"\n  FORCE: Skipping gate evaluation for {current_phase}.")
        success = execute_transition(vault_dir, progression, current_phase, target_phase, [], project_root)
        if success:
            print_transition_result(current_phase, target_phase, target_info)
            sys.exit(0)
        else:
            sys.exit(2)

    # Evaluate gate
    results, all_passed = evaluate_gate(current_phase, vault)

    if results is None:
        print(f"  WARNING: No gate evaluator implemented for phase {current_phase}.")
        print(f"  Use --force to skip gate evaluation.")
        sys.exit(2)

    print_gate_report(results, all_passed, current_phase)

    # --check: just report, don't transition
    if mode == "--check":
        if all_passed:
            print(f"  Ready to transition from {current_phase} to {target_phase} ({target_info['name']}).")
            print(f"  Run with --transition to execute.")
        sys.exit(0 if all_passed else 1)

    # --transition: execute if gate passes
    if not all_passed:
        failing = [r["id"] for r in results if r["status"] != "PASS"]
        print(f"\n  Cannot transition: {len(failing)} criteria unmet.")
        print(f"  Unmet: {', '.join(failing)}")
        sys.exit(1)

    # Gate passed — execute transition
    success = execute_transition(vault_dir, progression, current_phase, target_phase, results, project_root)
    if success:
        print_transition_result(current_phase, target_phase, target_info)
        sys.exit(0)
    else:
        print("  ERROR: Transition failed.")
        sys.exit(2)


if __name__ == "__main__":
    main()
