import type {
  AchievementCondition,
  AchievementDef,
  AchievementUnlock,
  EventType,
  Player,
  Streak,
  StreakType,
} from '../types.js';

interface AchievementStore {
  getEventCount(type?: EventType): number;
  getEventCountSince(type: EventType, since: string): number;
  getPlayer(): Player | null;
  getUnlockedAchievements(playerId: number): AchievementUnlock[];
  isAchievementUnlocked(playerId: number, achievementId: string): boolean;
  unlockAchievement(playerId: number, achievementId: string): void;
  getStreak(playerId: number, type: StreakType): Streak | null;
}

export class AchievementEvaluator {
  private store: AchievementStore;

  constructor(store: AchievementStore) {
    this.store = store;
  }

  checkAll(playerId: number, definitions: AchievementDef[]): string[] {
    const unlocked: string[] = [];

    for (const def of definitions) {
      if (this.store.isAchievementUnlocked(playerId, def.id)) continue;
      if (this.evaluateCondition(playerId, def.condition)) {
        this.store.unlockAchievement(playerId, def.id);
        unlocked.push(def.id);
      }
    }

    return unlocked;
  }

  evaluateCondition(playerId: number, condition: AchievementCondition): boolean {
    switch (condition.type) {
      case 'event_count': {
        const count = this.store.getEventCount(condition.eventType);
        return count >= (condition.count ?? 0);
      }

      case 'event_count_in_window': {
        if (!condition.eventType || !condition.windowDays) return false;
        const since = new Date();
        since.setDate(since.getDate() - condition.windowDays);
        const count = this.store.getEventCountSince(condition.eventType, since.toISOString());
        return count >= (condition.count ?? 0);
      }

      case 'streak': {
        const streak = this.store.getStreak(playerId, (condition.eventType ?? 'daily_activity') as StreakType);
        if (!streak) return false;
        return streak.currentCount >= (condition.count ?? 0);
      }

      case 'xp_threshold': {
        const player = this.store.getPlayer();
        if (!player) return false;
        return player.totalXp >= (condition.threshold ?? 0);
      }

      case 'level_reached': {
        const player = this.store.getPlayer();
        if (!player) return false;
        return player.level >= (condition.level ?? 0);
      }

      case 'compound': {
        const subs = condition.conditions ?? [];
        if (condition.logic === 'or') {
          return subs.some(c => this.evaluateCondition(playerId, c));
        }
        return subs.every(c => this.evaluateCondition(playerId, c));
      }

      case 'session_stat':
      case 'custom':
        return false;

      default:
        return false;
    }
  }
}
