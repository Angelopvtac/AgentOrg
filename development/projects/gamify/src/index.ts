export { generateReport } from "./generator.js";
export type {
  SessionReport,
  Stat,
  TestResults,
  Feature,
  ArchModule,
  FlowStep,
  FileTreeEntry,
  TechItem,
  Phase,
  Theme,
} from "./types.js";
export { DEFAULT_THEME } from "./types.js";

// Engine exports
export { GamifyStore } from './engine/gamify-store.js';
export { calculateXp, calculateLevel } from './engine/xp-calculator.js';
export { EventProcessor } from './engine/event-processor.js';
export type { ProcessResult } from './engine/event-processor.js';
export { AchievementEvaluator } from './engine/achievement-evaluator.js';
export { StreakTracker } from './engine/streak-tracker.js';
export type { StreakUpdate } from './engine/streak-tracker.js';
export { BUILTIN_ACHIEVEMENTS } from './achievements/builtin.js';
export { GitAdapter } from './adapters/git.js';
