import { execSync } from 'node:child_process';
import { GamifyStore } from '../engine/gamify-store.js';
import { EventProcessor } from '../engine/event-processor.js';
import { GitAdapter } from '../adapters/git.js';
import { AchievementEvaluator } from '../engine/achievement-evaluator.js';
import { StreakTracker } from '../engine/streak-tracker.js';
import { BUILTIN_ACHIEVEMENTS } from '../achievements/builtin.js';
import { calculateLevel } from '../engine/xp-calculator.js';

const BOLD = '\x1b[1m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const RESET = '\x1b[0m';

export async function cmdInit(args: string[]): Promise<void> {
  const nameIdx = args.indexOf('--name');
  let name: string;
  if (nameIdx !== -1 && args[nameIdx + 1]) {
    name = args[nameIdx + 1];
  } else {
    try {
      name = execSync('git config user.name', { encoding: 'utf-8' }).trim();
    } catch {
      name = 'Developer';
    }
  }

  const store = new GamifyStore();
  const existing = store.getPlayer();
  if (existing) {
    console.log(`${YELLOW}Player ${BOLD}${existing.name}${RESET}${YELLOW} already exists. Use 'gamify status' to check progress.${RESET}`);
    store.close();
    return;
  }

  const player = store.createPlayer(name);
  store.close();
  console.log(`${GREEN}Player ${BOLD}${player.name}${RESET}${GREEN} initialized! Start earning XP.${RESET}`);
}

export async function cmdSync(args: string[]): Promise<void> {
  const sinceIdx = args.indexOf('--since');
  let since: Date;
  if (sinceIdx !== -1 && args[sinceIdx + 1]) {
    since = new Date(args[sinceIdx + 1]);
  } else {
    since = new Date();
    since.setDate(since.getDate() - 30);
  }

  const store = new GamifyStore();
  const player = store.getPlayer();
  if (!player) {
    console.error(`${YELLOW}No player found. Run 'gamify init' first.${RESET}`);
    store.close();
    process.exit(1);
  }

  const processor = new EventProcessor(store);
  const achievementEvaluator = new AchievementEvaluator(store);
  const streakTracker = new StreakTracker(store);

  const git = new GitAdapter();
  if (!(await git.isAvailable())) {
    console.error(`${YELLOW}Not a git repository. Run from a git project directory.${RESET}`);
    store.close();
    process.exit(1);
  }

  const events = await git.collect(since);
  if (events.length === 0) {
    console.log(`${CYAN}No new events since ${since.toISOString().slice(0, 10)}.${RESET}`);
    store.close();
    return;
  }

  let totalXpEarned = 0;
  const allUnlocked: string[] = [];
  const streakUpdates: string[] = [];

  const results = processor.processEvents(events);

  for (const result of results) {
    totalXpEarned += result.event.xpAwarded;

    // Record streak activity
    const streakUpdate = streakTracker.recordActivity(
      player.id,
      'daily_commit',
      result.event.timestamp,
    );
    if (streakUpdate.message) {
      streakUpdates.push(streakUpdate.message);
    }
  }

  // Check achievements after all events processed
  const unlocked = achievementEvaluator.checkAll(player.id, BUILTIN_ACHIEVEMENTS);
  for (const id of unlocked) {
    const def = BUILTIN_ACHIEVEMENTS.find(a => a.id === id);
    if (def) {
      totalXpEarned += def.xpReward;
      // Award achievement XP to player
      const updatedPlayer = store.getPlayer()!;
      const levelInfo = calculateLevel(updatedPlayer.totalXp + def.xpReward);
      store.updatePlayerXp(player.id, updatedPlayer.totalXp + def.xpReward, levelInfo.level, levelInfo.title);
      allUnlocked.push(def.name);
    }
  }

  console.log(`\n${BOLD}Sync complete${RESET}`);
  console.log(`${CYAN}Events collected:${RESET} ${events.length}`);
  console.log(`${GREEN}XP earned:${RESET} +${totalXpEarned}`);

  if (allUnlocked.length > 0) {
    console.log(`\n${YELLOW}Achievements unlocked:${RESET}`);
    for (const name of allUnlocked) {
      console.log(`  ${GREEN}★${RESET} ${name}`);
    }
  }

  if (streakUpdates.length > 0) {
    console.log('');
    for (const msg of streakUpdates) {
      console.log(`${CYAN}${msg}${RESET}`);
    }
  }

  const updatedPlayer = store.getPlayer()!;
  const levelInfo = calculateLevel(updatedPlayer.totalXp);
  console.log(`\n${BOLD}Level ${levelInfo.level}${RESET} — ${updatedPlayer.title} (${updatedPlayer.totalXp} XP)`);

  store.close();
}

export async function cmdStatus(_args: string[]): Promise<void> {
  const store = new GamifyStore();
  const player = store.getPlayer();
  if (!player) {
    console.error(`${YELLOW}No player found. Run 'gamify init' first.${RESET}`);
    store.close();
    process.exit(1);
  }

  const levelInfo = calculateLevel(player.totalXp);
  const recentEvents = store.getEvents({ limit: 5 });
  const achievements = store.getUnlockedAchievements(player.id);
  const dailyStreak = store.getStreak(player.id, 'daily_commit');

  // Progress bar
  const barWidth = 20;
  const filled = Math.round(levelInfo.progress * barWidth);
  const bar = '█'.repeat(filled) + '░'.repeat(barWidth - filled);
  const pct = Math.round(levelInfo.progress * 100);

  console.log(`\n${BOLD}${player.name}${RESET}`);
  console.log(`${CYAN}Level ${levelInfo.level}${RESET} — ${player.title}`);
  console.log(`${GREEN}[${bar}]${RESET} ${pct}% to level ${levelInfo.level + 1}`);
  console.log(`Total XP: ${BOLD}${player.totalXp}${RESET} (need ${levelInfo.nextLevelXp} for next level)`);

  if (dailyStreak) {
    console.log(`\n${YELLOW}Streaks${RESET}`);
    console.log(`  Daily commits: ${BOLD}${dailyStreak.currentCount}${RESET} day${dailyStreak.currentCount !== 1 ? 's' : ''} (best: ${dailyStreak.longestCount})`);
  }

  if (recentEvents.length > 0) {
    console.log(`\n${YELLOW}Recent Activity${RESET}`);
    for (const event of recentEvents) {
      const date = event.timestamp.slice(0, 10);
      const meta = event.metadata as { message?: string };
      const desc = meta.message ?? event.type;
      console.log(`  ${CYAN}${date}${RESET} ${event.type} (+${event.xpAwarded} XP) ${desc}`);
    }
  }

  console.log(`\n${YELLOW}Achievements:${RESET} ${achievements.length} unlocked`);

  store.close();
}

export async function cmdAchievements(args: string[]): Promise<void> {
  const showAll = args.includes('--all');

  const store = new GamifyStore();
  const player = store.getPlayer();
  if (!player) {
    console.error(`${YELLOW}No player found. Run 'gamify init' first.${RESET}`);
    store.close();
    process.exit(1);
  }

  const unlocked = store.getUnlockedAchievements(player.id);
  const unlockedIds = new Set(unlocked.map(u => u.achievementId));

  console.log(`\n${BOLD}Achievements${RESET} (${unlocked.length}/${BUILTIN_ACHIEVEMENTS.length})\n`);

  for (const def of BUILTIN_ACHIEVEMENTS) {
    const isUnlocked = unlockedIds.has(def.id);
    if (!isUnlocked && !showAll) continue;

    const status = isUnlocked ? `${GREEN}★${RESET}` : `${YELLOW}○${RESET}`;
    const rarity = def.rarity.toUpperCase();
    console.log(`  ${status} ${BOLD}${def.icon} ${def.name}${RESET} [${rarity}]`);
    console.log(`    ${def.description}`);
    if (isUnlocked) {
      const unlock = unlocked.find(u => u.achievementId === def.id);
      if (unlock) {
        console.log(`    ${CYAN}Unlocked: ${unlock.unlockedAt.slice(0, 10)}${RESET}`);
      }
    } else {
      console.log(`    ${YELLOW}+${def.xpReward} XP${RESET}`);
    }
    console.log('');
  }

  store.close();
}
