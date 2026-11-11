# Changelog

All notable changes to atelier-software are listed here. Versions follow semantic versioning.

## 0.1.0 (2026-11-11)

Initial release: a Claude Code plugin for running software projects (features, refactors, migrations, bug hunts) like a workshop.

### Method
- The 11 principles: research and interrogate first, map the whole job, one lead, four-part task cards with an approval checkpoint, minimal briefs, shared state in files, independent gates, repeated mistakes become checks, cheap draft before expensive final, limited parallelism with bottleneck queues, and dated rejections with the person's word as final.

### Skills
- `start` (`/atelier-software:start`): makes the session the lead, always loads `profile-software`, sets up `.atelier/`, walks the phases in order, small job fast path, resume after a crash.
- `interrogate`: research first, then rounds of at most 7 numbered questions (3 to 5 for a small job), each with a recommended answer; ends with a restatement of 5 lines or fewer.
- `board`: maps the whole job into pieces, dependencies, parallel groups (capped at 4 workers), queues, owners and reviewers.
- `contract`: turns the request into `.atelier/contract.md` and one task card per piece, with vague words turned into numbers.
- `dispatch`: three-line briefs to `atelier-software:worker` subagents started in one turn, at most 4 workers by default, one `in-progress` card per queue, status tracked in files.
- `gate`: the `atelier-software:reviewer` subagent measures every quality-bar line; failed work goes back, never forward; stop after 3 failed rounds.
- `draft-first`: shelf first, a draft at about 10% of the final's cost, approval in the person's words, revise in place, shelve approved outputs.
- `lessons`: stable lesson tags, a check on the second occurrence, rejections logged in the person's words.
- `profile-software`: constraints, quality bar defaults, file-ownership map, queues (`schema`, `deps`, `config`, `build`, `deploy`, `paid-api`), cheap drafts, sample card and lesson tags for code work.

### Subagents
- `atelier-software:worker`: carries out one task card and writes the handoff note.
- `atelier-software:reviewer`: measures one task against its card and writes the gate report.
- `atelier-software:researcher`: gathers facts for the lead; writes no files.

### CLI (`scripts/atelier.py`, Python 3.9+ standard library only)
- Commands: `init`, `new-task`, `new-handoff`, `new-gate`, `set-status`, `check-card`, `check-handoff`, `gate`, `run-checks`, `status`, `lesson`, `reject`, `shelve`, `hook`.
- `set-status` refuses `done` unless the gate passes; only `gate` marks a task done.
- `set-status T-01 in-progress` refuses while any `depends_on` task is not done and names each one; `--force` overrides it with a warning.
- Reopening a task (`set-status` to `in-progress` or `todo`) moves its gate report to `.atelier/gates/archive/`, so reworked output gets a new review.
- `check-card` requires all 7 card sections (Goal, Constraints, Quality bar, Examples and references, Approval checkpoint, Fixed decisions, Left open on purpose) and a number in the quality bar.
- `gate` requires a complete card, a complete handoff note, a passing gate report by a reviewer who is neither the author nor the owner and is the reviewer named on the card, a report that is not stale, passing checks, and no repeated lesson without a check.
- `new-gate` records `card_hash` and `handoff_hash` (hashes of the card's quality bar and of the handoff note); `gate` and `set-status done` fail when either changed after the review. `new-gate --force` archives the old report into `.atelier/gates/archive/` and starts a new one.
- `status` flags board drift: a row in `board.md` whose Status differs from the card.
- FAIL lines name the file to fix and, where it applies, who fixes it (lead, worker or reviewer).
- `lesson` exits with code 3 on the second occurrence of a tag that no check carries.
- `reject` writes a dated entry to `.atelier/rejections.md` and `~/.atelier/rejections.md`.
- Each project gets its own copy of the CLI and templates in `.atelier/bin/`.

### Hooks
- SessionStart: board summary, integrity problems and the 10 most recent rejections.
- Stop: blocks while a task is marked done without a passing gate, or a lesson repeats without a check.
- SubagentStop: blocks a worker that names a task without a complete handoff note.

### Templates
- Contract, board, task card, handoff note, gate report, lessons, rejections, shelf.

### Packaging and docs
- Claude Code marketplace (`.claude-plugin/marketplace.json`) and plugin manifest (`plugins/atelier-software/.claude-plugin/plugin.json`), both named `atelier-software`.
- Docs: the method, install, a worked example (password reset in a web app), FAQ, contributing guide.
- CI: repository lint, unit tests and an end-to-end smoke test on Python 3.9 and 3.12.
