import { execSync } from 'node:child_process';
import type { EngEvent, MetricAdapter, EventType } from '../types.js';

export class GitAdapter implements MetricAdapter {
  name = 'git';
  private repoPath: string;

  constructor(repoPath: string = process.cwd()) {
    this.repoPath = repoPath;
  }

  async isAvailable(): Promise<boolean> {
    try {
      execSync('git rev-parse --git-dir', {
        cwd: this.repoPath,
        stdio: 'ignore',
      });
      return true;
    } catch {
      return false;
    }
  }

  async collect(since: Date): Promise<EngEvent[]> {
    const sinceStr = since.toISOString();
    let logOutput: string;
    try {
      logOutput = execSync(
        `git log --format="%H|%aI|%s|%an" --after="${sinceStr}"`,
        { cwd: this.repoPath, encoding: 'utf-8', maxBuffer: 10 * 1024 * 1024 },
      ).trim();
    } catch {
      return [];
    }

    if (!logOutput) return [];

    const lines = logOutput.split('\n').filter(Boolean);
    const seen = new Set<string>();
    const events: EngEvent[] = [];

    for (const line of lines) {
      const [hash, dateStr, ...rest] = line.split('|');
      const message = rest.slice(0, -1).join('|');
      const author = rest[rest.length - 1];

      if (!hash || seen.has(hash)) continue;
      seen.add(hash);

      const isMerge = this.isMergeCommit(hash, message);
      const files = this.getCommitFiles(hash);
      const touchesTests = files.some(f =>
        /test|spec|\.(test|spec)\./i.test(f),
      );

      let eventType: EventType;
      if (isMerge) {
        eventType = 'git.pr_merged';
      } else if (touchesTests) {
        eventType = 'git.commit_with_tests';
      } else {
        eventType = 'git.commit';
      }

      events.push({
        source: 'git',
        type: eventType,
        xpAwarded: 0,
        timestamp: dateStr,
        metadata: { hash, message, author, files },
      });
    }

    return events.sort(
      (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
    );
  }

  private isMergeCommit(hash: string, subject: string): boolean {
    if (subject.startsWith('Merge')) return true;
    try {
      const parents = execSync(`git rev-list --parents -1 ${hash}`, {
        cwd: this.repoPath,
        encoding: 'utf-8',
      }).trim();
      // First token is the commit itself, rest are parents
      return parents.split(/\s+/).length > 2;
    } catch {
      return false;
    }
  }

  private getCommitFiles(hash: string): string[] {
    try {
      const output = execSync(
        `git diff-tree --no-commit-id --name-only -r ${hash}`,
        { cwd: this.repoPath, encoding: 'utf-8' },
      ).trim();
      return output ? output.split('\n') : [];
    } catch {
      return [];
    }
  }
}
