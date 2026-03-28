#!/usr/bin/env python3
"""Apply a business-type template to pre-seed L1 discovery data in the vault.

Usage:
  --list                          List available templates
  --apply <template_id> <vault>   Apply template to vault directory
  --preview <template_id>         Show template details without applying
  --reset <vault>                 Reset L1 business data to empty state

Exit codes:
  0 = success
  1 = template not found or validation error
  2 = error (missing files, invalid JSON, bad arguments)
"""

import json
import sys
import shutil
from pathlib import Path
from datetime import datetime, timezone


def load_json(path):
    """Load a JSON file, return None if missing or invalid."""
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def save_json(path, data):
    """Write data as formatted JSON."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def get_templates_dir(project_root):
    """Return the templates directory path."""
    return Path(project_root) / "templates"


def list_templates(project_root):
    """List all available templates."""
    templates_dir = get_templates_dir(project_root)
    if not templates_dir.exists():
        print("No templates directory found.")
        return []

    templates = []
    for d in sorted(templates_dir.iterdir()):
        if not d.is_dir():
            continue
        manifest = load_json(d / "template.json")
        if manifest:
            templates.append(manifest)

    return templates


def preview_template(project_root, template_id):
    """Show detailed template information."""
    templates_dir = get_templates_dir(project_root)
    template_dir = templates_dir / template_id

    if not template_dir.exists():
        print(f"Template '{template_id}' not found.")
        print(f"Available: {', '.join(t['id'] for t in list_templates(project_root))}")
        return False

    manifest = load_json(template_dir / "template.json")
    if not manifest:
        print(f"Invalid template manifest in {template_dir}")
        return False

    print(f"\n{'=' * 60}")
    print(f"  {manifest['name']}")
    print(f"{'=' * 60}")
    print(f"\n  {manifest['description']}\n")
    print(f"  Target Phase: {manifest['targetPhase']}")
    print(f"  Suggested Goal: {manifest['suggestedGoal']}")
    print(f"\n  Suggested Skills:")
    for skill in manifest.get("suggestedSkills", []):
        print(f"    - {skill}")

    # Show direction summary
    direction_data = load_json(template_dir / "direction.json")
    if direction_data and direction_data.get("direction"):
        d = direction_data["direction"]
        print(f"\n  Business Direction:")
        print(f"    Name: {d.get('name', 'N/A')}")
        print(f"    Market: {d.get('market', 'N/A')}")
        print(f"    Revenue Model: {d.get('revenueModel', 'N/A')}")

    # Show brand summary
    brand_data = load_json(template_dir / "brand-brief.json")
    if brand_data and brand_data.get("brandName"):
        print(f"\n  Brand:")
        print(f"    Name: {brand_data['brandName']}")
        print(f"    Tagline: {brand_data.get('tagline', 'N/A')}")

    print(f"\n  Files that will be written:")
    for f in manifest.get("files", []):
        print(f"    - {f}")

    print()
    return True


def apply_template(project_root, template_id, vault_dir):
    """Apply a template to the vault directory."""
    templates_dir = get_templates_dir(project_root)
    template_dir = templates_dir / template_id
    vault = Path(vault_dir)

    if not template_dir.exists():
        print(f"Template '{template_id}' not found.")
        available = list_templates(project_root)
        if available:
            print(f"Available: {', '.join(t['id'] for t in available)}")
        return False

    manifest = load_json(template_dir / "template.json")
    if not manifest:
        print(f"Invalid template manifest.")
        return False

    if not vault.exists():
        print(f"Vault directory not found: {vault}")
        return False

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    files_written = []

    # Apply direction.json
    direction_src = load_json(template_dir / "direction.json")
    if direction_src:
        direction_src["selectedAt"] = now
        save_json(vault / "business" / "direction.json", direction_src)
        files_written.append("business/direction.json")
        print(f"  [WRITE] business/direction.json")

    # Apply brand-brief.json
    brand_src = load_json(template_dir / "brand-brief.json")
    if brand_src:
        brand_src["createdAt"] = now
        save_json(vault / "business" / "brand-brief.json", brand_src)
        files_written.append("business/brand-brief.json")
        print(f"  [WRITE] business/brand-brief.json")

    # Apply market-research.json → vault/research/
    research_src = load_json(template_dir / "market-research.json")
    if research_src:
        research_src["generatedAt"] = now
        research_src["templateSource"] = template_id
        filename = f"market-scan-{template_id}.json"
        save_json(vault / "research" / filename, research_src)
        files_written.append(f"research/{filename}")
        print(f"  [WRITE] research/{filename}")

    if files_written:
        print(f"\n  Template '{manifest['name']}' applied successfully.")
        print(f"  {len(files_written)} files written to {vault}")
        print(f"\n  L1 gate progress after template application:")

        # Check L1 gate criteria
        direction = load_json(vault / "business" / "direction.json")
        brand = load_json(vault / "business" / "brand-brief.json")
        research_dir = vault / "research"
        research_files = [f for f in research_dir.iterdir()
                         if f.suffix == ".json" and f.name != ".gitkeep"] if research_dir.exists() else []

        criteria = [
            ("direction-selected",
             bool(direction and direction.get("direction")),
             "Business direction documented"),
            ("brand-brief-complete",
             bool(brand and brand.get("brandName") and brand.get("tagline") and brand.get("voice")),
             "Brand brief with name, tagline, voice"),
            ("market-research-done",
             len(research_files) > 0,
             f"Market research reports ({len(research_files)} found)"),
        ]

        all_pass = True
        for cid, passed, desc in criteria:
            status = "\033[0;32mPASS\033[0m" if passed else "\033[0;31mFAIL\033[0m"
            if not passed:
                all_pass = False
            print(f"    [{status}] {cid}: {desc}")

        if all_pass:
            print(f"\n  All L1 gate criteria satisfied.")
            print(f"  Run 'bash scripts/phase-transition.sh --check' to verify.")
        else:
            print(f"\n  Some L1 criteria still need manual completion.")

    return True


def reset_business_data(vault_dir):
    """Reset L1 business data to empty state."""
    vault = Path(vault_dir)

    # Reset direction
    save_json(vault / "business" / "direction.json", {
        "collection": "business-direction",
        "description": "Selected business direction from L1 discovery phase",
        "direction": None,
        "selectedAt": None,
        "alternatives": []
    })
    print("  [RESET] business/direction.json")

    # Reset brand brief
    save_json(vault / "business" / "brand-brief.json", {
        "collection": "brand-brief",
        "description": "Brand identity brief generated after direction selection",
        "brandName": None,
        "tagline": None,
        "voice": None,
        "audience": None,
        "createdAt": None
    })
    print("  [RESET] business/brand-brief.json")

    # Remove research reports (but keep .gitkeep)
    research_dir = vault / "research"
    if research_dir.exists():
        removed = 0
        for f in research_dir.iterdir():
            if f.suffix == ".json" and f.name != ".gitkeep":
                f.unlink()
                removed += 1
        print(f"  [RESET] research/ ({removed} reports removed)")

    print("\n  L1 business data reset to empty state.")


def main():
    args = sys.argv[1:]

    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    mode = args[0]

    # Determine project root
    project_flag_idx = None
    project_root = None
    for i, arg in enumerate(args):
        if arg == "--project" and i + 1 < len(args):
            project_flag_idx = i
            project_root = args[i + 1]
            break

    if not project_root:
        # Default to script's parent directory's parent
        project_root = str(Path(__file__).resolve().parent.parent)

    if mode == "--list":
        templates = list_templates(project_root)
        if not templates:
            print("No templates found.")
            sys.exit(1)
        print(f"\nAvailable business templates ({len(templates)}):\n")
        for t in templates:
            print(f"  {t['id']:20s} {t['name']}")
            print(f"  {'':20s} {t['description'][:80]}")
            print()
        sys.exit(0)

    elif mode == "--preview":
        if len(args) < 2:
            print("Usage: --preview <template_id>")
            sys.exit(2)
        template_id = args[1]
        success = preview_template(project_root, template_id)
        sys.exit(0 if success else 1)

    elif mode == "--apply":
        if len(args) < 2:
            print("Usage: --apply <template_id> [vault_dir]")
            sys.exit(2)
        template_id = args[1]
        vault_dir = args[2] if len(args) > 2 and not args[2].startswith("--") else str(Path(project_root) / "knowledge")
        print(f"\n  Applying template: {template_id}")
        print(f"  Vault: {vault_dir}\n")
        success = apply_template(project_root, template_id, vault_dir)
        sys.exit(0 if success else 1)

    elif mode == "--reset":
        vault_dir = args[1] if len(args) > 1 and not args[1].startswith("--") else str(Path(project_root) / "knowledge")
        print(f"\n  Resetting L1 business data in: {vault_dir}\n")
        reset_business_data(vault_dir)
        sys.exit(0)

    else:
        print(f"Unknown mode: {mode}")
        print("Use --list, --preview, --apply, or --reset")
        sys.exit(2)


if __name__ == "__main__":
    main()
