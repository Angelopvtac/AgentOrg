import Database from 'better-sqlite3';
import { mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { homedir } from 'node:os';
import type {
  Player,
  EngEvent,
  EventType,
  Session,
  AchievementUnlock,
  Streak,
  StreakType,
  SkillProgress,
} from '../types.js';

const DEFAULT_DB_PATH = join(homedir(), '.config', 'gamify', 'gamify.db');

export class GamifyStore {
  private db: Database.Database;

  constructor(dbPath: string = DEFAULT_DB_PATH) {
    mkdirSync(dirname(dbPath), { recursive: true });
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.db.pragma('foreign_keys = ON');
    this.initSchema();
  }

  initSchema(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        total_xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        title TEXT DEFAULT 'Apprentice',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        total_xp INTEGER DEFAULT 0,
        event_count INTEGER DEFAULT 0,
        started_at TEXT NOT NULL,
        ended_at TEXT
      );

      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        type TEXT NOT NULL,
        xp_awarded INTEGER NOT NULL,
        metadata TEXT DEFAULT '{}',
        timestamp TEXT NOT NULL,
        session_id INTEGER REFERENCES sessions(id)
      );

      CREATE TABLE IF NOT EXISTS achievement_unlocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL REFERENCES players(id),
        achievement_id TEXT NOT NULL,
        unlocked_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(player_id, achievement_id)
      );

      CREATE TABLE IF NOT EXISTS streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL REFERENCES players(id),
        type TEXT NOT NULL,
        current_count INTEGER DEFAULT 0,
        longest_count INTEGER DEFAULT 0,
        last_activity_date TEXT NOT NULL,
        freezes_used INTEGER DEFAULT 0,
        freezes_available INTEGER DEFAULT 2,
        freeze_reset_date TEXT NOT NULL,
        started_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(player_id, type)
      );

      CREATE TABLE IF NOT EXISTS skill_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL REFERENCES players(id),
        skill TEXT NOT NULL,
        xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 0,
        UNIQUE(player_id, skill)
      );
    `);
  }

  getPlayer(): Player | null {
    const row = this.db.prepare('SELECT * FROM players LIMIT 1').get() as Record<string, unknown> | undefined;
    return row ? mapPlayer(row) : null;
  }

  createPlayer(name: string): Player {
    const stmt = this.db.prepare('INSERT INTO players (name) VALUES (?)');
    const result = stmt.run(name);
    const row = this.db.prepare('SELECT * FROM players WHERE id = ?').get(result.lastInsertRowid) as Record<string, unknown>;
    return mapPlayer(row);
  }

  updatePlayerXp(playerId: number, totalXp: number, level: number, title: string): void {
    this.db.prepare(
      'UPDATE players SET total_xp = ?, level = ?, title = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?'
    ).run(totalXp, level, title, playerId);
  }

  insertEvent(event: EngEvent): number {
    const stmt = this.db.prepare(
      'INSERT INTO events (source, type, xp_awarded, metadata, timestamp, session_id) VALUES (?, ?, ?, ?, ?, ?)'
    );
    const result = stmt.run(
      event.source,
      event.type,
      event.xpAwarded,
      JSON.stringify(event.metadata),
      event.timestamp,
      event.sessionId ?? null,
    );
    return Number(result.lastInsertRowid);
  }

  getEvents(opts?: { since?: string; type?: EventType; limit?: number }): EngEvent[] {
    let sql = 'SELECT * FROM events WHERE 1=1';
    const params: unknown[] = [];

    if (opts?.since) {
      sql += ' AND timestamp >= ?';
      params.push(opts.since);
    }
    if (opts?.type) {
      sql += ' AND type = ?';
      params.push(opts.type);
    }
    sql += ' ORDER BY timestamp DESC';
    if (opts?.limit) {
      sql += ' LIMIT ?';
      params.push(opts.limit);
    }

    const rows = this.db.prepare(sql).all(...params) as Record<string, unknown>[];
    return rows.map(mapEvent);
  }

  getEventCount(type?: EventType): number {
    if (type) {
      const row = this.db.prepare('SELECT COUNT(*) as count FROM events WHERE type = ?').get(type) as { count: number };
      return row.count;
    }
    const row = this.db.prepare('SELECT COUNT(*) as count FROM events').get() as { count: number };
    return row.count;
  }

  getEventCountSince(type: EventType, since: string): number {
    const row = this.db.prepare(
      'SELECT COUNT(*) as count FROM events WHERE type = ? AND timestamp >= ?'
    ).get(type, since) as { count: number };
    return row.count;
  }

  createSession(title: string): Session {
    const now = new Date().toISOString();
    const stmt = this.db.prepare('INSERT INTO sessions (title, started_at) VALUES (?, ?)');
    const result = stmt.run(title, now);
    return {
      id: Number(result.lastInsertRowid),
      title,
      totalXp: 0,
      eventCount: 0,
      startedAt: now,
    };
  }

  endSession(id: number, totalXp: number, eventCount: number): void {
    this.db.prepare(
      'UPDATE sessions SET total_xp = ?, event_count = ?, ended_at = ? WHERE id = ?'
    ).run(totalXp, eventCount, new Date().toISOString(), id);
  }

  getActiveSession(): Session | null {
    const row = this.db.prepare(
      'SELECT * FROM sessions WHERE ended_at IS NULL ORDER BY id DESC LIMIT 1'
    ).get() as Record<string, unknown> | undefined;
    return row ? mapSession(row) : null;
  }

  unlockAchievement(playerId: number, achievementId: string): void {
    this.db.prepare(
      'INSERT OR IGNORE INTO achievement_unlocks (player_id, achievement_id) VALUES (?, ?)'
    ).run(playerId, achievementId);
  }

  getUnlockedAchievements(playerId: number): AchievementUnlock[] {
    const rows = this.db.prepare(
      'SELECT * FROM achievement_unlocks WHERE player_id = ? ORDER BY unlocked_at DESC'
    ).all(playerId) as Record<string, unknown>[];
    return rows.map(mapAchievementUnlock);
  }

  isAchievementUnlocked(playerId: number, achievementId: string): boolean {
    const row = this.db.prepare(
      'SELECT 1 FROM achievement_unlocks WHERE player_id = ? AND achievement_id = ?'
    ).get(playerId, achievementId);
    return !!row;
  }

  getStreak(playerId: number, type: StreakType): Streak | null {
    const row = this.db.prepare(
      'SELECT * FROM streaks WHERE player_id = ? AND type = ?'
    ).get(playerId, type) as Record<string, unknown> | undefined;
    return row ? mapStreak(row) : null;
  }

  upsertStreak(streak: Streak): void {
    this.db.prepare(`
      INSERT INTO streaks (player_id, type, current_count, longest_count, last_activity_date, freezes_used, freezes_available, freeze_reset_date)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(player_id, type) DO UPDATE SET
        current_count = excluded.current_count,
        longest_count = excluded.longest_count,
        last_activity_date = excluded.last_activity_date,
        freezes_used = excluded.freezes_used,
        freezes_available = excluded.freezes_available,
        freeze_reset_date = excluded.freeze_reset_date
    `).run(
      streak.playerId,
      streak.type,
      streak.currentCount,
      streak.longestCount,
      streak.lastActivityDate,
      streak.freezesUsed,
      streak.freezesAvailable,
      streak.freezeResetDate,
    );
  }

  getSkillProgress(playerId: number): SkillProgress[] {
    const rows = this.db.prepare(
      'SELECT * FROM skill_progress WHERE player_id = ? ORDER BY xp DESC'
    ).all(playerId) as Record<string, unknown>[];
    return rows.map(mapSkillProgress);
  }

  upsertSkillProgress(playerId: number, skill: string, xp: number, level: number): void {
    this.db.prepare(`
      INSERT INTO skill_progress (player_id, skill, xp, level)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(player_id, skill) DO UPDATE SET xp = excluded.xp, level = excluded.level
    `).run(playerId, skill, xp, level);
  }

  close(): void {
    this.db.close();
  }
}

function mapPlayer(row: Record<string, unknown>): Player {
  return {
    id: row.id as number,
    name: row.name as string,
    totalXp: row.total_xp as number,
    level: row.level as number,
    title: row.title as string,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapEvent(row: Record<string, unknown>): EngEvent {
  return {
    id: row.id as number,
    source: row.source as EngEvent['source'],
    type: row.type as EventType,
    xpAwarded: row.xp_awarded as number,
    metadata: JSON.parse(row.metadata as string),
    timestamp: row.timestamp as string,
    sessionId: row.session_id as number | undefined,
  };
}

function mapSession(row: Record<string, unknown>): Session {
  return {
    id: row.id as number,
    title: row.title as string,
    totalXp: row.total_xp as number,
    eventCount: row.event_count as number,
    startedAt: row.started_at as string,
    endedAt: row.ended_at as string | undefined,
  };
}

function mapAchievementUnlock(row: Record<string, unknown>): AchievementUnlock {
  return {
    id: row.id as number,
    playerId: row.player_id as number,
    achievementId: row.achievement_id as string,
    unlockedAt: row.unlocked_at as string,
  };
}

function mapStreak(row: Record<string, unknown>): Streak {
  return {
    id: row.id as number,
    playerId: row.player_id as number,
    type: row.type as StreakType,
    currentCount: row.current_count as number,
    longestCount: row.longest_count as number,
    lastActivityDate: row.last_activity_date as string,
    freezesUsed: row.freezes_used as number,
    freezesAvailable: row.freezes_available as number,
    freezeResetDate: row.freeze_reset_date as string,
    startedAt: row.started_at as string,
  };
}

function mapSkillProgress(row: Record<string, unknown>): SkillProgress {
  return {
    id: row.id as number,
    playerId: row.player_id as number,
    skill: row.skill as string,
    xp: row.xp as number,
    level: row.level as number,
  };
}
