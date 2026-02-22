import { XP_TABLE, xpForLevel, titleForLevel } from '../types.js';
import type { EventType } from '../types.js';

export function calculateXp(eventType: EventType, metadata?: Record<string, unknown>): number {
  const base = XP_TABLE[eventType];

  if (eventType === 'test.coverage_increase' && metadata?.delta !== undefined) {
    return Math.floor(base * (metadata.delta as number));
  }

  if (eventType === 'manual.custom' && metadata?.xp !== undefined) {
    return metadata.xp as number;
  }

  return base;
}

export function calculateLevel(totalXp: number): {
  level: number;
  title: string;
  currentLevelXp: number;
  nextLevelXp: number;
  progress: number;
} {
  let level = 1;
  while (xpForLevel(level + 1) <= totalXp) {
    level++;
  }

  const currentLevelXp = xpForLevel(level);
  const nextLevelXp = xpForLevel(level + 1);
  const progress = nextLevelXp > currentLevelXp
    ? (totalXp - currentLevelXp) / (nextLevelXp - currentLevelXp)
    : 0;

  return {
    level,
    title: titleForLevel(level),
    currentLevelXp,
    nextLevelXp,
    progress: Math.max(0, Math.min(1, progress)),
  };
}
