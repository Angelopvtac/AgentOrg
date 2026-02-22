import type { Streak, StreakType } from '../types.js';

interface StreakStore {
  getStreak(playerId: number, type: StreakType): Streak | null;
  upsertStreak(streak: Streak): void;
}

export interface StreakUpdate {
  type: StreakType;
  currentCount: number;
  longestCount: number;
  frozeUsed: boolean;
  broken: boolean;
  message?: string;
}

const MAX_FREEZES = 2;
const FREEZE_RESET_DAYS = 30;
const GRACE_PERIOD_DAYS = 1;
const REST_REMINDER_DAYS = 14;

export class StreakTracker {
  private store: StreakStore;

  constructor(store: StreakStore) {
    this.store = store;
  }

  recordActivity(playerId: number, type: StreakType, date: string): StreakUpdate {
    let streak = this.store.getStreak(playerId, type);
    const today = date.slice(0, 10);

    if (!streak) {
      streak = {
        playerId,
        type,
        currentCount: 1,
        longestCount: 1,
        lastActivityDate: today,
        freezesUsed: 0,
        freezesAvailable: MAX_FREEZES,
        freezeResetDate: this.addDays(today, FREEZE_RESET_DAYS),
        startedAt: today,
      };
      this.store.upsertStreak(streak);
      return {
        type,
        currentCount: 1,
        longestCount: 1,
        frozeUsed: false,
        broken: false,
      };
    }

    // Reset freezes if reset date has passed
    if (today >= streak.freezeResetDate) {
      streak.freezesUsed = 0;
      streak.freezesAvailable = MAX_FREEZES;
      streak.freezeResetDate = this.addDays(today, FREEZE_RESET_DAYS);
    }

    const gap = daysBetween(streak.lastActivityDate, today);

    // Same day
    if (gap === 0) {
      return {
        type,
        currentCount: streak.currentCount,
        longestCount: streak.longestCount,
        frozeUsed: false,
        broken: false,
        message: checkRestReminder(streak),
      };
    }

    let frozeUsed = false;
    let broken = false;
    let message: string | undefined;

    if (gap <= 1 + GRACE_PERIOD_DAYS) {
      // Next day or within grace period — streak continues
      streak.currentCount++;
      if (streak.currentCount > streak.longestCount) {
        streak.longestCount = streak.currentCount;
      }
    } else {
      // Missed days
      if (streak.freezesAvailable > 0) {
        streak.freezesAvailable--;
        streak.freezesUsed++;
        streak.currentCount++;
        frozeUsed = true;
        if (streak.currentCount > streak.longestCount) {
          streak.longestCount = streak.currentCount;
        }
      } else {
        broken = true;
        if (streak.currentCount > streak.longestCount) {
          streak.longestCount = streak.currentCount;
        }
        if (streak.currentCount > 1) {
          message = `Your ${streak.currentCount}-day streak was your longest yet!`;
        }
        streak.currentCount = 1;
        streak.startedAt = today;
      }
    }

    streak.lastActivityDate = today;
    this.store.upsertStreak(streak);

    return {
      type,
      currentCount: streak.currentCount,
      longestCount: streak.longestCount,
      frozeUsed,
      broken,
      message: message ?? checkRestReminder(streak),
    };
  }

  private addDays(date: string, days: number): string {
    const d = new Date(date);
    d.setDate(d.getDate() + days);
    return d.toISOString().slice(0, 10);
  }
}

export function daysBetween(date1: string, date2: string): number {
  const d1 = new Date(date1.slice(0, 10));
  const d2 = new Date(date2.slice(0, 10));
  return Math.round(Math.abs(d2.getTime() - d1.getTime()) / (1000 * 60 * 60 * 24));
}

function checkRestReminder(streak: Streak): string | undefined {
  if (streak.currentCount >= REST_REMINDER_DAYS) {
    return `${streak.currentCount} days strong — remember to take breaks when you need them.`;
  }
  return undefined;
}
