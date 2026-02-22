#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { execSync } from "node:child_process";
import { generateReport } from "./generator.js";
import type { SessionReport } from "./types.js";
import { cmdInit, cmdSync, cmdStatus, cmdAchievements } from "./cli/commands.js";

const HELP = `
gamify — Developer Achievement Engine

Commands:
  gamify init [--name <name>]    Initialize player profile
  gamify sync [--since <date>]   Collect events from git + adapters
  gamify status                  Show level, XP, streaks
  gamify achievements [--all]    List achievements

Legacy:
  gamify <input.json> [out.html] [--open]   Generate HTML report

Options:
  --help, -h    Show this help
`;

const COMMANDS: Record<string, (args: string[]) => Promise<void>> = {
  init: cmdInit,
  sync: cmdSync,
  status: cmdStatus,
  achievements: cmdAchievements,
};

async function main() {
  const args = process.argv.slice(2);

  if (args.includes("--help") || args.includes("-h") || args.length === 0) {
    console.log(HELP);
    process.exit(0);
  }

  const first = args[0];

  // Route to new commands
  if (first in COMMANDS) {
    await COMMANDS[first](args.slice(1));
    return;
  }

  // Legacy: file path input (ends in .json or is stdin marker)
  if (first === "-" || first.endsWith(".json") || first.endsWith(".JSON")) {
    legacyReport(args);
    return;
  }

  // Unknown command
  console.error(`Unknown command: ${first}`);
  console.log(HELP);
  process.exit(1);
}

function legacyReport(args: string[]) {
  const open = args.includes("--open");
  const positional = args.filter((a) => !a.startsWith("--"));
  const inputPath = positional[0];
  const outputPath = resolve(positional[1] ?? "./report.html");

  let json: string;
  if (inputPath === "-") {
    json = readFileSync(0, "utf-8");
  } else {
    json = readFileSync(resolve(inputPath), "utf-8");
  }

  let report: SessionReport;
  try {
    report = JSON.parse(json) as SessionReport;
  } catch (err) {
    console.error(`Error: Invalid JSON — ${(err as Error).message}`);
    process.exit(1);
  }

  const html = generateReport(report);
  writeFileSync(outputPath, html);
  console.log(`Generated: ${outputPath}`);

  if (open) {
    const browsers = [
      "brave-browser",
      "google-chrome",
      "firefox",
      "xdg-open",
      "open",
    ];
    for (const browser of browsers) {
      try {
        execSync(`which ${browser}`, { stdio: "ignore" });
        execSync(`${browser} ${outputPath}`, { stdio: "ignore" });
        break;
      } catch {
        continue;
      }
    }
  }
}

main();
