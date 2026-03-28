#!/usr/bin/env python3
"""Simulate the AgentOrg onboarding flow and evaluate L0 gate criteria.

Modes:
  --populate <vault_dir>   Write realistic completed-onboarding data to vault
  --evaluate <vault_dir>   Evaluate L0 gate criteria against current vault state
  --simulate <vault_dir>   Populate + evaluate in one shot (default)
  --partial <vault_dir>    Populate partial onboarding data (5/9 sections, 3/6 gate)
  --reset <vault_dir>      Reset vault to fresh-install empty state

Exit codes:
  0 = success (all criteria pass in evaluate/simulate mode)
  1 = gate not passed (one or more criteria failed)
  2 = error (missing files, invalid JSON, bad arguments)
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Realistic onboarding data — a plausible founder completing L0
# ---------------------------------------------------------------------------

FOUNDER_COMPLETE = {
    "personalInfo": {
        "name": "Elena Marchetti",
        "timezone": "Europe/Rome",
        "location": "Milan, Italy",
        "communicationStyle": "concise",
        "language": "en"
    },
    "skills": [
        "product strategy",
        "data analysis",
        "content writing",
        "UX research",
        "Python development"
    ],
    "availability": {
        "weeklyHours": 15,
        "preferredDays": ["Monday", "Wednesday", "Friday"],
        "quietHours": {"start": "22:00", "end": "08:00"},
        "responseExpectation": "within-4-hours"
    },
    "financial": {
        "dailyBudget": 5.00,
        "riskTolerance": "moderate",
        "investmentCapacity": 150.00,
        "revenueGoal": 1000.00
    },
    "goals": {
        "primary": "Launch a micro-SaaS for freelance writers",
        "timeline": "3 months",
        "successMetric": "10 paying subscribers",
        "interests": ["AI writing tools", "freelance economy", "content automation"]
    },
    "preferences": {
        "decisionStyle": "data-driven",
        "updateFrequency": "daily",
        "notificationChannels": ["discord"],
        "emojiUse": False
    },
    "vision": {
        "statement": "Build an AI-powered writing assistant that helps freelance writers pitch to publications more effectively, starting with automated pitch letter generation and market research. The goal is to reduce the time freelancers spend on pitching by 80% while improving their acceptance rates.",
        "values": ["writer empowerment", "quality over quantity", "ethical AI use"],
        "constraints": ["bootstrap only", "no VC funding", "single founder"],
        "iterationCount": 2
    }
}

ONBOARDING_COMPLETE = {
    "status": "complete",
    "startedAt": "2026-03-15T10:00:00Z",
    "completedAt": "2026-03-27T16:45:00Z",
    "lastUpdated": "2026-03-27T16:45:00Z",
    "sections": {
        "welcome": {"status": "complete", "completedAt": "2026-03-15T10:05:00Z"},
        "personal": {"status": "complete", "completedAt": "2026-03-15T10:20:00Z"},
        "skills": {"status": "complete", "completedAt": "2026-03-15T10:35:00Z"},
        "availability": {"status": "complete", "completedAt": "2026-03-16T09:00:00Z"},
        "financial": {"status": "complete", "completedAt": "2026-03-16T09:15:00Z"},
        "goals": {"status": "complete", "completedAt": "2026-03-20T14:00:00Z"},
        "preferences": {"status": "complete", "completedAt": "2026-03-20T14:30:00Z"},
        "vision": {"status": "complete", "completedAt": "2026-03-27T16:30:00Z"},
        "review": {"status": "complete", "completedAt": "2026-03-27T16:45:00Z"}
    },
    "currentSection": None
}

BUDGET_ACTIVE = {
    "dailyLimit": 5.00,
    "currency": "USD",
    "currentDate": "2026-03-27",
    "spent": 1.87,
    "breakdown": {"tier1": 0.08, "tier2": 1.44, "tier3": 0.35},
    "alerts": {"warnAt": 0.80, "pauseAt": 1.00, "killSwitchAt": 2.00},
    "history": [
        {"date": "2026-03-26", "spent": 2.12},
        {"date": "2026-03-25", "spent": 1.45}
    ]
}

PHASE_STATE_L0 = {
    "currentPhase": "L0",
    "phaseName": "Onboarding",
    "phaseStartDate": "2026-03-15T00:00:00Z",
    "lastGateEvaluation": None,
    "gateResults": {},
    "history": []
}

# Partial onboarding — 5 of 9 sections done, 3 of 6 gate criteria met
FOUNDER_PARTIAL = {
    "personalInfo": {
        "name": "Elena Marchetti",
        "timezone": "Europe/Rome",
        "location": "Milan, Italy",
        "communicationStyle": "concise",
        "language": "en"
    },
    "skills": ["product strategy", "data analysis", "content writing"],
    "availability": {
        "weeklyHours": None,
        "preferredDays": [],
        "quietHours": None,
        "responseExpectation": None
    },
    "financial": {
        "dailyBudget": None,
        "riskTolerance": None,
        "investmentCapacity": None,
        "revenueGoal": None
    },
    "goals": {
        "primary": "Launch a micro-SaaS",
        "timeline": None,
        "successMetric": None,
        "interests": []
    },
    "preferences": {
        "decisionStyle": None,
        "updateFrequency": None,
        "notificationChannels": [],
        "emojiUse": False
    },
    "vision": {
        "statement": None,
        "values": [],
        "constraints": [],
        "iterationCount": 0
    }
}

ONBOARDING_PARTIAL = {
    "status": "in-progress",
    "startedAt": "2026-03-15T10:00:00Z",
    "completedAt": None,
    "lastUpdated": "2026-03-20T14:00:00Z",
    "sections": {
        "welcome": {"status": "complete", "completedAt": "2026-03-15T10:05:00Z"},
        "personal": {"status": "complete", "completedAt": "2026-03-15T10:20:00Z"},
        "skills": {"status": "complete", "completedAt": "2026-03-15T10:35:00Z"},
        "availability": {"status": "complete", "completedAt": "2026-03-16T09:00:00Z"},
        "financial": {"status": "complete", "completedAt": "2026-03-16T09:15:00Z"},
        "goals": {"status": "in-progress", "completedAt": None},
        "preferences": {"status": "pending", "completedAt": None},
        "vision": {"status": "pending", "completedAt": None},
        "review": {"status": "pending", "completedAt": None}
    },
    "currentSection": "goals"
}

# Fresh-install empty state
FOUNDER_EMPTY = {
    "personalInfo": {
        "name": None, "timezone": None, "location": None,
        "communicationStyle": None, "language": "en"
    },
    "skills": [],
    "availability": {
        "weeklyHours": None, "preferredDays": [],
        "quietHours": None, "responseExpectation": None
    },
    "financial": {
        "dailyBudget": None, "riskTolerance": None,
        "investmentCapacity": None, "revenueGoal": None
    },
    "goals": {
        "primary": None, "timeline": None,
        "successMetric": None, "interests": []
    },
    "preferences": {
        "decisionStyle": None, "updateFrequency": None,
        "notificationChannels": [], "emojiUse": False
    },
    "vision": {
        "statement": None, "values": [], "constraints": [],
        "iterationCount": 0
    }
}

ONBOARDING_EMPTY = {
    "status": "not-started",
    "startedAt": None,
    "completedAt": None,
    "lastUpdated": None,
    "sections": {
        "welcome": {"status": "pending", "completedAt": None},
        "personal": {"status": "pending", "completedAt": None},
        "skills": {"status": "pending", "completedAt": None},
        "availability": {"status": "pending", "completedAt": None},
        "financial": {"status": "pending", "completedAt": None},
        "goals": {"status": "pending", "completedAt": None},
        "preferences": {"status": "pending", "completedAt": None},
        "vision": {"status": "pending", "completedAt": None},
        "review": {"status": "pending", "completedAt": None}
    },
    "currentSection": None
}

BUDGET_EMPTY = {
    "dailyLimit": 5.00,
    "currency": "USD",
    "currentDate": None,
    "spent": 0.00,
    "breakdown": {"tier1": 0.00, "tier2": 0.00, "tier3": 0.00},
    "alerts": {"warnAt": 0.80, "pauseAt": 1.00, "killSwitchAt": 2.00},
    "history": []
}

PHASE_STATE_EMPTY = {
    "currentPhase": "L0",
    "phaseName": "Onboarding",
    "phaseStartDate": "2026-02-23T00:00:00Z",
    "lastGateEvaluation": None,
    "gateResults": {},
    "history": []
}


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
# Populate vault
# ---------------------------------------------------------------------------

def populate_vault(vault_dir, mode="complete"):
    """Write onboarding data to vault files."""
    vault = Path(vault_dir)

    if mode == "complete":
        founder = FOUNDER_COMPLETE
        onboarding = ONBOARDING_COMPLETE
        budget = BUDGET_ACTIVE
        phase = PHASE_STATE_L0
    elif mode == "partial":
        founder = FOUNDER_PARTIAL
        onboarding = ONBOARDING_PARTIAL
        budget = BUDGET_ACTIVE
        phase = PHASE_STATE_L0
    elif mode == "reset":
        founder = FOUNDER_EMPTY
        onboarding = ONBOARDING_EMPTY
        budget = BUDGET_EMPTY
        phase = PHASE_STATE_EMPTY
    else:
        print(f"ERROR: Unknown populate mode: {mode}", file=sys.stderr)
        return False

    write_json(vault / "founder-profile.json", founder)
    write_json(vault / "onboarding-state.json", onboarding)
    write_json(vault / "economics" / "daily-budget.json", budget)
    write_json(vault / "phase-state.json", phase)

    label = {"complete": "completed", "partial": "partial (5/9)", "reset": "empty"}[mode]
    print(f"Populated vault with {label} onboarding data: {vault}")
    return True


# ---------------------------------------------------------------------------
# Evaluate L0 gate
# ---------------------------------------------------------------------------

def evaluate_l0_gate(vault_dir):
    """Evaluate all 6 L0 gate criteria. Returns (results, all_passed)."""
    vault = Path(vault_dir)

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

    all_passed = all(r["status"] == "PASS" for r in results)
    return results, all_passed


def print_gate_report(results, all_passed):
    """Print a formatted gate evaluation report."""
    passed_count = sum(1 for r in results if r["status"] == "PASS")
    total = len(results)

    overall = "PASSED" if all_passed else "OPEN"
    print(f"\n{'=' * 56}")
    print(f"  L0 Gate Evaluation: {overall} ({passed_count}/{total} criteria met)")
    print(f"{'=' * 56}\n")

    for i, r in enumerate(results, 1):
        icon = "[PASS]" if r["status"] == "PASS" else "[FAIL]"
        print(f"  {i}. {icon} {r['description']}")
        print(f"       Target: {r['target']}")
        print(f"       Actual: {r['actual']}")
        print()

    if all_passed:
        print("  >> All criteria met. Ready to transition to L1 (Discovery).")
    else:
        failing = [r["id"] for r in results if r["status"] != "PASS"]
        print(f"  >> {len(failing)} criteria unmet: {', '.join(failing)}")

    print(f"\n{'=' * 56}")
    return all_passed


def update_phase_state_with_evaluation(vault_dir, results, all_passed):
    """Write gate evaluation results back to phase-state.json."""
    vault = Path(vault_dir)
    phase_state = load_json(vault / "phase-state.json")

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    overall = "PASSED" if all_passed else "OPEN"

    phase_state["lastGateEvaluation"] = now
    phase_state["gateResults"] = {
        r["id"]: {"status": r["status"], "actual": r["actual"]}
        for r in results
    }

    # Append to history
    history_entry = {
        "timestamp": now,
        "phase": "L0",
        "status": overall,
        "criteria": [
            {"id": r["id"], "status": r["status"], "actual": r["actual"]}
            for r in results
        ]
    }
    phase_state.setdefault("history", []).append(history_entry)

    write_json(vault / "phase-state.json", phase_state)
    print(f"\n  Gate evaluation saved to {vault / 'phase-state.json'}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

USAGE = """Usage: simulate-onboarding.py <mode> <vault_dir> [--no-save]

Modes:
  --populate   Write completed onboarding data to vault files
  --partial    Write partial onboarding data (5/9 sections, 3/6 gate criteria)
  --evaluate   Evaluate L0 gate criteria against current vault state
  --simulate   Populate completed data + evaluate (default)
  --reset      Reset vault files to fresh-install empty state

Options:
  --no-save    Don't write evaluation results to phase-state.json

Examples:
  python3 scripts/simulate-onboarding.py --simulate knowledge/
  python3 scripts/simulate-onboarding.py --evaluate knowledge/ --no-save
  python3 scripts/simulate-onboarding.py --partial /tmp/test-vault
  python3 scripts/simulate-onboarding.py --reset knowledge/
"""


def main():
    if len(sys.argv) < 3:
        print(USAGE, file=sys.stderr)
        sys.exit(2)

    mode = sys.argv[1]
    vault_dir = sys.argv[2]
    no_save = "--no-save" in sys.argv

    if not Path(vault_dir).is_dir():
        # For populate/partial/reset, create the directory structure
        if mode in ("--populate", "--partial", "--reset", "--simulate"):
            Path(vault_dir).mkdir(parents=True, exist_ok=True)
            (Path(vault_dir) / "economics").mkdir(parents=True, exist_ok=True)
        else:
            print(f"ERROR: Vault directory not found: {vault_dir}", file=sys.stderr)
            sys.exit(2)

    if mode == "--populate":
        if not populate_vault(vault_dir, "complete"):
            sys.exit(2)

    elif mode == "--partial":
        if not populate_vault(vault_dir, "partial"):
            sys.exit(2)

    elif mode == "--reset":
        if not populate_vault(vault_dir, "reset"):
            sys.exit(2)

    elif mode == "--evaluate":
        results, all_passed = evaluate_l0_gate(vault_dir)
        print_gate_report(results, all_passed)
        if not no_save:
            update_phase_state_with_evaluation(vault_dir, results, all_passed)
        sys.exit(0 if all_passed else 1)

    elif mode == "--simulate":
        if not populate_vault(vault_dir, "complete"):
            sys.exit(2)
        results, all_passed = evaluate_l0_gate(vault_dir)
        print_gate_report(results, all_passed)
        if not no_save:
            update_phase_state_with_evaluation(vault_dir, results, all_passed)
        sys.exit(0 if all_passed else 1)

    else:
        print(f"ERROR: Unknown mode: {mode}", file=sys.stderr)
        print(USAGE, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
