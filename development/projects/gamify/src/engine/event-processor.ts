import type { EngEvent, StreakType } from '../types.js';
import type { GamifyStore } from './gamify-store.js';
import { calculateXp, calculateLevel } from './xp-calculator.js';

export interface ProcessResult {
  event: EngEvent;
  newLevel?: number;
  newTitle?: string;
  achievementsUnlocked: string[];
  streakUpdate?: { type: StreakType; count: number };
}

export class EventProcessor {
  private store: GamifyStore;

  onAchievementUnlocked?: (playerId: number, event: EngEvent) => string[];
  onStreakUpdate?: (playerId: number, event: EngEvent) => { type: StreakType; count: number } | undefined;
  onLevelUp?: (playerId: number, newLevel: number, newTitle: string) => void;

  constructor(store: GamifyStore) {
    this.store = store;
  }

  processEvent(event: Omit<EngEvent, 'id' | 'xpAwarded'>): ProcessResult {
    const xp = calculateXp(event.type, event.metadata);

    const fullEvent: EngEvent = {
      ...event,
      xpAwarded: xp,
    };

    const eventId = this.store.insertEvent(fullEvent);
    fullEvent.id = eventId;

    const result: ProcessResult = {
      event: fullEvent,
      achievementsUnlocked: [],
    };

    const player = this.store.getPlayer();
    if (!player) return result;

    const newTotalXp = player.totalXp + xp;
    const levelInfo = calculateLevel(newTotalXp);

    if (levelInfo.level > player.level) {
      result.newLevel = levelInfo.level;
      result.newTitle = levelInfo.title;
      this.onLevelUp?.(player.id, levelInfo.level, levelInfo.title);
    }

    this.store.updatePlayerXp(player.id, newTotalXp, levelInfo.level, levelInfo.title);

    if (this.onAchievementUnlocked) {
      const unlocked = this.onAchievementUnlocked(player.id, fullEvent);
      result.achievementsUnlocked = unlocked;
    }

    if (this.onStreakUpdate) {
      const streakInfo = this.onStreakUpdate(player.id, fullEvent);
      if (streakInfo) {
        result.streakUpdate = streakInfo;
      }
    }

    return result;
  }

  processEvents(events: Omit<EngEvent, 'id' | 'xpAwarded'>[]): ProcessResult[] {
    return events.map(e => this.processEvent(e));
  }
}
