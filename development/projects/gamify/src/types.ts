// ─── Gamification Engine Types ──────────────────────────────────────────────

export interface Player {
  id: number;
  name: string;
  totalXp: number;
  level: number;
  title: string;
  createdAt: string;
  updatedAt: string;
}

export interface EngEvent {
  id?: number;
  source: EventSource;
  type: EventType;
  xpAwarded: number;
  metadata: Record<string, unknown>;
  timestamp: string;
  sessionId?: number;
}

export type EventSource = 'git' | 'test' | 'ci' | 'deploy' | 'agent' | 'manual';

export type EventType =
  | 'git.commit'
  | 'git.commit_with_tests'
  | 'git.pr_merged'
  | 'git.pr_reviewed'
  | 'git.branch_created'
  | 'test.suite_pass'
  | 'test.suite_fail'
  | 'test.coverage_increase'
  | 'ci.build_first_try'
  | 'ci.build_fail'
  | 'deploy.success'
  | 'deploy.rollback'
  | 'agent.session_complete'
  | 'agent.efficient_session'
  | 'manual.custom';

export const XP_TABLE: Record<EventType, number> = {
  'git.commit': 10,
  'git.commit_with_tests': 25,
  'git.pr_merged': 50,
  'git.pr_reviewed': 30,
  'git.branch_created': 5,
  'test.suite_pass': 20,
  'test.suite_fail': 0,
  'test.coverage_increase': 40,
  'ci.build_first_try': 25,
  'ci.build_fail': 0,
  'deploy.success': 75,
  'deploy.rollback': -25,
  'agent.session_complete': 30,
  'agent.efficient_session': 50,
  'manual.custom': 0,
};

/** Level curve: xp = 100 * N^1.8 */
export function xpForLevel(level: number): number {
  return Math.floor(100 * Math.pow(level, 1.8));
}

export const TITLES = [
  'Apprentice',           // 0
  'Junior Engineer',      // 1
  'Engineer',             // 2
  'Senior Engineer',      // 3
  'Staff Engineer',       // 4
  'Principal Engineer',   // 5
  'Distinguished',        // 6
  'Fellow',               // 7
  'Architect',            // 8
  'Legendary Architect',  // 9
  'Code Titan',           // 10
] as const;

export function titleForLevel(level: number): string {
  const idx = Math.min(Math.floor(level / 2), TITLES.length - 1);
  return TITLES[idx];
}

export interface Session {
  id?: number;
  title: string;
  totalXp: number;
  eventCount: number;
  startedAt: string;
  endedAt?: string;
}

export type AchievementCategory =
  | 'shipping'
  | 'quality'
  | 'efficiency'
  | 'consistency'
  | 'mastery'
  | 'collaboration'
  | 'exploration'
  | 'milestone';

export type AchievementRarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';

export type ConditionType =
  | 'event_count'
  | 'event_count_in_window'
  | 'streak'
  | 'xp_threshold'
  | 'level_reached'
  | 'session_stat'
  | 'compound'
  | 'custom';

export interface AchievementCondition {
  type: ConditionType;
  eventType?: EventType;
  count?: number;
  windowDays?: number;
  threshold?: number;
  level?: number;
  stat?: string;
  operator?: '>=' | '>' | '==' | '<' | '<=';
  conditions?: AchievementCondition[];
  logic?: 'and' | 'or';
}

export interface AchievementDef {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: AchievementCategory;
  rarity: AchievementRarity;
  xpReward: number;
  condition: AchievementCondition;
}

export interface AchievementUnlock {
  id?: number;
  playerId: number;
  achievementId: string;
  unlockedAt: string;
}

export type StreakType = 'daily_commit' | 'daily_activity' | 'weekly_activity';

export interface Streak {
  id?: number;
  playerId: number;
  type: StreakType;
  currentCount: number;
  longestCount: number;
  lastActivityDate: string;
  freezesUsed: number;
  freezesAvailable: number;
  freezeResetDate: string;
  startedAt: string;
}

export interface SkillProgress {
  id?: number;
  playerId: number;
  skill: string;
  xp: number;
  level: number;
}

/** Adapter interface for metric collection */
export interface MetricAdapter {
  name: string;
  isAvailable(): Promise<boolean>;
  collect(since: Date): Promise<EngEvent[]>;
}

// ─── Report Types (Original — preserved for backward compat) ────────────────

export interface SessionReport {
  /** Big hero title (e.g. "Jarvis is Alive.") */
  title: string;
  /** Subtitle under the hero */
  subtitle: string;
  /** Badge text above the title (e.g. "Mission Complete") */
  badge?: string;
  /** Date string shown below subtitle */
  date: string;

  /** Top-level stat counters */
  stats: Stat[];

  /** Test results banner */
  tests?: TestResults;

  /** Feature cards */
  features?: Feature[];

  /** Architecture module cards */
  architecture?: ArchModule[];

  /** Step-by-step flow diagram */
  flow?: FlowStep[];

  /** Monospace file tree (pre-formatted with ANSI-style markers) */
  fileTree?: FileTreeEntry[];

  /** Tech stack pills */
  techStack?: TechItem[];

  /** Roadmap phases */
  roadmap?: Phase[];

  /** Closing quote */
  quote?: { text: string; highlight?: string; attribution?: string };

  /** Footer line */
  footer?: { project: string; version: string; author: string };

  /** Color theme override */
  theme?: Partial<Theme>;
}

export interface Stat {
  value: string | number;
  label: string;
  color?: string;
}

export interface TestResults {
  total: number;
  passed: number;
  suites: string[];
  duration?: string;
}

export interface Feature {
  emoji: string;
  title: string;
  description: string;
}

export interface ArchModule {
  name: string;
  path: string;
  variant: string;
  items: Array<{ file: string; description: string }>;
}

export interface FlowStep {
  title: string;
  description: string;
}

export interface FileTreeEntry {
  /** e.g. "├── package.json" — the tree line with prefix */
  line: string;
  /** "dir" | "file" | "new" | "comment" */
  type: "dir" | "file" | "new" | "comment";
}

export interface TechItem {
  icon: string;
  name: string;
  role: string;
}

export interface Phase {
  phase: string;
  icon: string;
  name: string;
  description: string;
  active?: boolean;
}

export interface Theme {
  bg: string;
  bgCard: string;
  text: string;
  textDim: string;
  accent: string;
  green: string;
  blue: string;
  purple: string;
  cyan: string;
  yellow: string;
  peach: string;
  pink: string;
  teal: string;
  red: string;
}

export const DEFAULT_THEME: Theme = {
  bg: "#0a0a0f",
  bgCard: "#12121a",
  text: "#e4e4ef",
  textDim: "#7f849c",
  accent: "#89b4fa",
  green: "#a6e3a1",
  blue: "#89b4fa",
  purple: "#cba6f7",
  cyan: "#89dceb",
  yellow: "#f9e2af",
  peach: "#fab387",
  pink: "#f5c2e7",
  teal: "#94e2d5",
  red: "#f38ba8",
};
