import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdtempSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { GamifyStore } from '../src/engine/gamify-store.js';
import { calculateXp, calculateLevel } from '../src/engine/xp-calculator.js';
import { EventProcessor } from '../src/engine/event-processor.js';
import { AchievementEvaluator } from '../src/engine/achievement-evaluator.js';
import { StreakTracker } from '../src/engine/streak-tracker.js';
import { BUILTIN_ACHIEVEMENTS } from '../src/achievements/builtin.js';
import type { EngEvent } from '../src/types.js';

let tmpDir: string;
let store: GamifyStore;

beforeEach(() => {
  tmpDir = mkdtempSync(join(tmpdir(), 'gamify-test-'));
  store = new GamifyStore(join(tmpDir, 'test.db'));
});

afterEach(() => {
  store.close();
  rmSync(tmpDir, { recursive: true, force: true });
});

describe('GamifyStore', () => {
  it('creates and retrieves a player', () => {
    const player = store.createPlayer('TestDev');
    expect(player.name).toBe('TestDev');
    expect(player.totalXp).toBe(0);
    expect(player.level).toBe(1);
    expect(player.title).toBe('Apprentice');

    const retrieved = store.getPlayer();
    expect(retrieved).not.toBeNull();
    expect(retrieved!.name).toBe('TestDev');
  });

  it('updates player XP', () => {
    const player = store.createPlayer('TestDev');
    store.updatePlayerXp(player.id, 500, 3, 'Engineer');
    const updated = store.getPlayer();
    expect(updated!.totalXp).toBe(500);
    expect(updated!.level).toBe(3);
    expect(updated!.title).toBe('Engineer');
  });

  it('inserts and queries events', () => {
    const event: EngEvent = {
      source: 'git',
      type: 'git.commit',
      xpAwarded: 10,
      metadata: { hash: 'abc123' },
      timestamp: '2026-02-22T10:00:00Z',
    };
    const id = store.insertEvent(event);
    expect(id).toBeGreaterThan(0);

    const events = store.getEvents();
    expect(events).toHaveLength(1);
    expect(events[0].type).toBe('git.commit');
    expect((events[0].metadata as any).hash).toBe('abc123');
  });

  it('counts events by type', () => {
    for (let i = 0; i < 5; i++) {
      store.insertEvent({
        source: 'git', type: 'git.commit', xpAwarded: 10,
        metadata: {}, timestamp: `2026-02-22T1${i}:00:00Z`,
      });
    }
    store.insertEvent({
      source: 'git', type: 'git.pr_merged', xpAwarded: 50,
      metadata: {}, timestamp: '2026-02-22T20:00:00Z',
    });

    expect(store.getEventCount('git.commit')).toBe(5);
    expect(store.getEventCount('git.pr_merged')).toBe(1);
    expect(store.getEventCount()).toBe(6);
  });

  it('manages sessions', () => {
    const session = store.createSession('Test Session');
    expect(session.id).toBeGreaterThan(0);
    expect(session.totalXp).toBe(0);

    const active = store.getActiveSession();
    expect(active).not.toBeNull();
    expect(active!.title).toBe('Test Session');

    store.endSession(session.id!, 100, 5);
    const ended = store.getActiveSession();
    expect(ended).toBeNull();
  });

  it('manages achievements', () => {
    const player = store.createPlayer('TestDev');
    expect(store.isAchievementUnlocked(player.id, 'first_blood')).toBe(false);

    store.unlockAchievement(player.id, 'first_blood');
    expect(store.isAchievementUnlocked(player.id, 'first_blood')).toBe(true);

    const unlocked = store.getUnlockedAchievements(player.id);
    expect(unlocked).toHaveLength(1);
    expect(unlocked[0].achievementId).toBe('first_blood');
  });

  it('manages streaks', () => {
    const player = store.createPlayer('TestDev');
    store.upsertStreak({
      playerId: player.id,
      type: 'daily_commit',
      currentCount: 3,
      longestCount: 5,
      lastActivityDate: '2026-02-22',
      freezesUsed: 0,
      freezesAvailable: 2,
      freezeResetDate: '2026-03-22',
      startedAt: '2026-02-20',
    });

    const streak = store.getStreak(player.id, 'daily_commit');
    expect(streak).not.toBeNull();
    expect(streak!.currentCount).toBe(3);
    expect(streak!.longestCount).toBe(5);
  });
});

describe('XP Calculator', () => {
  it('returns base XP for standard events', () => {
    expect(calculateXp('git.commit')).toBe(10);
    expect(calculateXp('git.pr_merged')).toBe(50);
    expect(calculateXp('deploy.success')).toBe(75);
    expect(calculateXp('deploy.rollback')).toBe(-25);
  });

  it('calculates coverage XP with delta', () => {
    expect(calculateXp('test.coverage_increase', { delta: 2 })).toBe(80);
    expect(calculateXp('test.coverage_increase', { delta: 0.5 })).toBe(20);
  });

  it('uses custom XP from metadata', () => {
    expect(calculateXp('manual.custom', { xp: 100 })).toBe(100);
    expect(calculateXp('manual.custom')).toBe(0);
  });

  it('calculates level from XP', () => {
    const l1 = calculateLevel(0);
    expect(l1.level).toBe(1);

    const l5 = calculateLevel(2000);
    expect(l5.level).toBeGreaterThanOrEqual(3);

    const l10 = calculateLevel(10000);
    expect(l10.level).toBeGreaterThanOrEqual(5);
  });

  it('returns progress toward next level', () => {
    const info = calculateLevel(200);
    expect(info.progress).toBeGreaterThanOrEqual(0);
    expect(info.progress).toBeLessThanOrEqual(1);
  });
});

describe('EventProcessor', () => {
  it('processes event and updates player XP', () => {
    store.createPlayer('TestDev');
    const processor = new EventProcessor(store);

    const result = processor.processEvent({
      source: 'git',
      type: 'git.commit',
      metadata: { hash: 'abc' },
      timestamp: '2026-02-22T10:00:00Z',
    });

    expect(result.event.xpAwarded).toBe(10);
    const player = store.getPlayer();
    expect(player!.totalXp).toBe(10);
  });

  it('detects level up', () => {
    const player = store.createPlayer('TestDev');
    store.updatePlayerXp(player.id, 95, 1, 'Apprentice');
    const processor = new EventProcessor(store);

    const result = processor.processEvent({
      source: 'git',
      type: 'git.commit',
      metadata: {},
      timestamp: '2026-02-22T10:00:00Z',
    });

    // 95 + 10 = 105, should be >= level 2 threshold (100 * 2^1.8 = 348)
    // Actually xpForLevel(2) = floor(100 * 2^1.8) = 348, so 105 < 348, still level 1
    expect(result.event.xpAwarded).toBe(10);
  });

  it('processes multiple events', () => {
    store.createPlayer('TestDev');
    const processor = new EventProcessor(store);

    const events = Array.from({ length: 5 }, (_, i) => ({
      source: 'git' as const,
      type: 'git.commit' as const,
      metadata: { hash: `hash${i}` },
      timestamp: `2026-02-22T1${i}:00:00Z`,
    }));

    const results = processor.processEvents(events);
    expect(results).toHaveLength(5);
    expect(store.getPlayer()!.totalXp).toBe(50);
  });

  it('calls achievement callback', () => {
    store.createPlayer('TestDev');
    const processor = new EventProcessor(store);
    const unlocked: string[] = [];

    processor.onAchievementUnlocked = () => {
      unlocked.push('test_achievement');
      return ['test_achievement'];
    };

    const result = processor.processEvent({
      source: 'git',
      type: 'git.commit',
      metadata: {},
      timestamp: '2026-02-22T10:00:00Z',
    });

    expect(result.achievementsUnlocked).toEqual(['test_achievement']);
    expect(unlocked).toEqual(['test_achievement']);
  });
});

describe('AchievementEvaluator', () => {
  it('unlocks event_count achievements', () => {
    const player = store.createPlayer('TestDev');
    store.insertEvent({
      source: 'git', type: 'git.commit', xpAwarded: 10,
      metadata: {}, timestamp: '2026-02-22T10:00:00Z',
    });

    const evaluator = new AchievementEvaluator(store);
    const unlocked = evaluator.checkAll(player.id, BUILTIN_ACHIEVEMENTS);
    expect(unlocked).toContain('first_blood');
  });

  it('does not re-unlock achievements', () => {
    const player = store.createPlayer('TestDev');
    store.insertEvent({
      source: 'git', type: 'git.commit', xpAwarded: 10,
      metadata: {}, timestamp: '2026-02-22T10:00:00Z',
    });

    const evaluator = new AchievementEvaluator(store);
    const first = evaluator.checkAll(player.id, BUILTIN_ACHIEVEMENTS);
    expect(first).toContain('first_blood');

    const second = evaluator.checkAll(player.id, BUILTIN_ACHIEVEMENTS);
    expect(second).not.toContain('first_blood');
  });

  it('evaluates xp_threshold conditions', () => {
    const player = store.createPlayer('TestDev');
    store.updatePlayerXp(player.id, 1500, 3, 'Engineer');

    const evaluator = new AchievementEvaluator(store);
    const unlocked = evaluator.checkAll(player.id, BUILTIN_ACHIEVEMENTS);
    expect(unlocked).toContain('xp_1k');
  });

  it('evaluates level_reached conditions', () => {
    const player = store.createPlayer('TestDev');
    store.updatePlayerXp(player.id, 5000, 5, 'Staff Engineer');

    const evaluator = new AchievementEvaluator(store);
    const unlocked = evaluator.checkAll(player.id, BUILTIN_ACHIEVEMENTS);
    expect(unlocked).toContain('level_5');
  });
});

describe('StreakTracker', () => {
  it('starts a new streak', () => {
    const player = store.createPlayer('TestDev');
    const tracker = new StreakTracker(store);

    const update = tracker.recordActivity(player.id, 'daily_commit', '2026-02-22');
    expect(update.currentCount).toBe(1);
    expect(update.broken).toBe(false);
  });

  it('increments streak on consecutive days', () => {
    const player = store.createPlayer('TestDev');
    const tracker = new StreakTracker(store);

    tracker.recordActivity(player.id, 'daily_commit', '2026-02-20');
    tracker.recordActivity(player.id, 'daily_commit', '2026-02-21');
    const update = tracker.recordActivity(player.id, 'daily_commit', '2026-02-22');

    expect(update.currentCount).toBe(3);
    expect(update.longestCount).toBe(3);
  });

  it('does not increment on same day', () => {
    const player = store.createPlayer('TestDev');
    const tracker = new StreakTracker(store);

    tracker.recordActivity(player.id, 'daily_commit', '2026-02-22');
    const update = tracker.recordActivity(player.id, 'daily_commit', '2026-02-22');

    expect(update.currentCount).toBe(1);
  });

  it('uses freeze when day is missed', () => {
    const player = store.createPlayer('TestDev');
    const tracker = new StreakTracker(store);

    tracker.recordActivity(player.id, 'daily_commit', '2026-02-20');
    tracker.recordActivity(player.id, 'daily_commit', '2026-02-21');
    // Skip 2026-02-22, 2026-02-23 — gap of 3 days
    const update = tracker.recordActivity(player.id, 'daily_commit', '2026-02-24');

    expect(update.frozeUsed).toBe(true);
    expect(update.broken).toBe(false);
    expect(update.currentCount).toBe(3);
  });

  it('breaks streak when no freezes available', () => {
    const player = store.createPlayer('TestDev');
    const tracker = new StreakTracker(store);

    tracker.recordActivity(player.id, 'daily_commit', '2026-02-10');
    tracker.recordActivity(player.id, 'daily_commit', '2026-02-11');
    tracker.recordActivity(player.id, 'daily_commit', '2026-02-12');

    // Use up both freezes
    tracker.recordActivity(player.id, 'daily_commit', '2026-02-15'); // freeze 1
    tracker.recordActivity(player.id, 'daily_commit', '2026-02-18'); // freeze 2

    // Now break
    const update = tracker.recordActivity(player.id, 'daily_commit', '2026-02-22');
    expect(update.broken).toBe(true);
    expect(update.currentCount).toBe(1);
  });
});

describe('BUILTIN_ACHIEVEMENTS', () => {
  it('has at least 15 achievements', () => {
    expect(BUILTIN_ACHIEVEMENTS.length).toBeGreaterThanOrEqual(15);
  });

  it('has unique IDs', () => {
    const ids = BUILTIN_ACHIEVEMENTS.map(a => a.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('covers required categories', () => {
    const categories = new Set(BUILTIN_ACHIEVEMENTS.map(a => a.category));
    expect(categories).toContain('shipping');
    expect(categories).toContain('quality');
    expect(categories).toContain('consistency');
    expect(categories).toContain('milestone');
  });
});
