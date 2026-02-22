import { describe, it, expect } from "vitest";
import { generateReport } from "../src/generator.js";
import type { SessionReport } from "../src/types.js";

const minimal: SessionReport = {
  title: "Test Report",
  subtitle: "A minimal test",
  date: "2026-02-22",
  stats: [{ value: 42, label: "Things", color: "var(--cyan)" }],
};

describe("generateReport", () => {
  it("returns valid HTML with doctype", () => {
    const html = generateReport(minimal);
    expect(html).toMatch(/^<!DOCTYPE html>/);
    expect(html).toContain("</html>");
  });

  it("includes title and subtitle", () => {
    const html = generateReport(minimal);
    expect(html).toContain("Test Report");
    expect(html).toContain("A minimal test");
  });

  it("renders stats", () => {
    const html = generateReport(minimal);
    expect(html).toContain("42");
    expect(html).toContain("Things");
  });

  it("uses custom badge text", () => {
    const html = generateReport({ ...minimal, badge: "Ship It" });
    expect(html).toContain("Ship It");
  });

  it("renders tests banner when passed", () => {
    const html = generateReport({
      ...minimal,
      tests: { total: 15, passed: 15, suites: ["unit", "integration"], duration: "321ms" },
    });
    expect(html).toContain("ALL SYSTEMS GREEN");
    expect(html).toContain("unit");
    expect(html).toContain("integration");
    expect(html).toContain("321ms");
  });

  it("shows warning when tests partially pass", () => {
    const html = generateReport({
      ...minimal,
      tests: { total: 10, passed: 7, suites: ["unit"] },
    });
    expect(html).toContain("7/10 PASSING");
  });

  it("renders features section", () => {
    const html = generateReport({
      ...minimal,
      features: [{ emoji: "🧠", title: "Memory", description: "3-tier recall" }],
    });
    expect(html).toContain("Memory");
    expect(html).toContain("3-tier recall");
  });

  it("renders architecture cards", () => {
    const html = generateReport({
      ...minimal,
      architecture: [
        {
          name: "Core",
          path: "src/core/",
          variant: "core",
          items: [{ file: "config.ts", description: "Configuration" }],
        },
      ],
    });
    expect(html).toContain("Core");
    expect(html).toContain("src/core/");
    expect(html).toContain("config.ts");
  });

  it("renders flow steps with numbering", () => {
    const html = generateReport({
      ...minimal,
      flow: [
        { title: "Start", description: "Begin here" },
        { title: "End", description: "Finish here" },
      ],
    });
    expect(html).toContain("Start");
    expect(html).toContain("End");
    expect(html).toContain(">1<");
    expect(html).toContain(">2<");
  });

  it("renders file tree", () => {
    const html = generateReport({
      ...minimal,
      fileTree: [
        { line: "src/", type: "dir" },
        { line: "├── index.ts", type: "new" },
        { line: "# entry point", type: "comment" },
      ],
    });
    expect(html).toContain('class="dir"');
    expect(html).toContain('class="new"');
    expect(html).toContain('class="comment"');
  });

  it("renders tech stack", () => {
    const html = generateReport({
      ...minimal,
      techStack: [{ icon: "⚡", name: "TypeScript", role: "Language" }],
    });
    expect(html).toContain("TypeScript");
    expect(html).toContain("Language");
  });

  it("renders roadmap with active phase", () => {
    const html = generateReport({
      ...minimal,
      roadmap: [
        { phase: "Phase 1", icon: "🧠", name: "Brain", description: "Memory", active: true },
        { phase: "Phase 2", icon: "🎤", name: "Voice", description: "STT/TTS" },
      ],
    });
    expect(html).toContain('class="phase active"');
    expect(html).toContain("Brain");
    expect(html).toContain("Voice");
  });

  it("renders quote with highlight", () => {
    const html = generateReport({
      ...minimal,
      quote: {
        text: "A companion intelligence that knows you.",
        highlight: "companion intelligence",
        attribution: "ROADMAP.md",
      },
    });
    expect(html).toContain("<em>companion intelligence</em>");
    expect(html).toContain("ROADMAP.md");
  });

  it("renders footer", () => {
    const html = generateReport({
      ...minimal,
      footer: { project: "JARVIS", version: "v0.1.0", author: "Angelo" },
    });
    expect(html).toContain("JARVIS");
    expect(html).toContain("v0.1.0");
    expect(html).toContain("Angelo");
  });

  it("escapes HTML in user content", () => {
    const html = generateReport({
      ...minimal,
      title: '<script>alert("xss")</script>',
    });
    expect(html).not.toContain("<script>");
    expect(html).toContain("&lt;script&gt;");
  });

  it("omits sections that are not provided", () => {
    const html = generateReport(minimal);
    expect(html).not.toContain("Architecture");
    expect(html).not.toContain("Roadmap");
    expect(html).not.toContain("How It Works");
    expect(html).not.toContain("ALL SYSTEMS GREEN");
  });
});
