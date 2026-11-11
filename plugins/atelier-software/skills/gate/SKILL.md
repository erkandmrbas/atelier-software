---
name: gate
description: Runs an independent review of finished work: a different agent measures every quality-bar line of the task card, writes a gate report, and only a pass lets the task move on. Use when a task card reaches review, before marking anything done, or whenever a worker claims a piece is finished.
---

# Gate

One agent works. A different agent checks. Work that fails a gate goes back, never forward.

## When to run a gate

- A card is in `review` and its handoff note passes `python3 .atelier/bin/atelier.py check-handoff T-01`.
- Before any output is shown to the person as finished.
- Before work leaves one station for the next (stub to implementation, branch to merge, merge to deploy).

## Rules

1. The reviewer must not be the author. Not the same subagent, not the lead if the lead wrote it. It must be the reviewer named on the card; `gate` fails for anyone else.
2. Measure, do not eyeball. Every quality-bar line gets a measured value: a count, a size, a time, an exit code, a command output.
3. Never accept "tests pass" from a handoff note. Run the tests yourself and record the result.
4. Check only against the card. The reviewer does not invent new requirements; it may note them as findings for the lead.
5. One failed line fails the gate. There is no "mostly pass".

## Steps

### 1. Pick the reviewer

1. Run the gate with the `atelier-software:reviewer` subagent. It starts with no memory of the work.
2. The reviewer's name is the card's `reviewer` field, written by the lead at dispatch (workers never edit cards). The reviewer signs the gate report with that name.

### 2. Brief the reviewer

Give only:

1. The task card path: `.atelier/tasks/T-01.md`.
2. The handoff note path: `.atelier/handoffs/T-01.md`.
3. This instruction: "Measure every quality-bar line yourself. Write the gate report with `python3 .atelier/bin/atelier.py new-gate T-01 --reviewer <reviewer from the card>`. Set result to pass only if every line passes."

### 3. Measure

The reviewer:

1. Reads the card's Quality bar section and makes one line per bar item.
2. Runs the commands in the handoff note's "How to verify", then runs its own measurements too. The worker's numbers are claims, not results.
3. Runs `python3 .atelier/bin/atelier.py run-checks` to see every automated check from past lessons.
4. Records each value and pass or fail in the Measurements section.
5. Lists what must change in Findings. On a pass, writes "none".
6. Sets `result: pass` or `result: fail` in the front matter.

### 4. Close the gate

The lead runs:

```
python3 .atelier/bin/atelier.py gate T-01
```

This command passes only when the card is complete (all 7 sections and a number in the bar), the handoff note is complete, the gate report is by the reviewer named on the card (never the owner or the author) with `result: pass`, the report is not stale, every check in `.atelier/checks/` passes, and no lesson tag repeats without a check. On success it marks the task `done`.

### Stale reports

`new-gate` writes `card_hash` and `handoff_hash` into the report: hashes of the card's Quality bar section and of the handoff note. If either file changes after the review, `gate` and `set-status done` fail with "the card's quality bar changed after this review" or "the handoff note changed after this review". A report missing either hash fails too. The reviewer then re-measures and starts a new report:

```
python3 .atelier/bin/atelier.py new-gate T-01 --reviewer reviewer-1 --force
```

`--force` moves the old report to `.atelier/gates/archive/`. Without it, `new-gate` refuses to overwrite an existing report. Never edit the hashes by hand.

### 5. On a fail

1. Keep the card out of `done`. Run `python3 .atelier/bin/atelier.py set-status T-01 in-progress`. This moves the failed gate report to `.atelier/gates/archive/` (so does `todo`); the worker reads it there.
2. Send the same worker (or a fresh one, if the first is gone) the card path, the archived gate report path that `set-status` printed, and: "Fix every finding, then update your handoff note."
3. Do not pass the work forward to the next station "to save time". Nothing downstream may build on failed work.
4. If the same kind of finding shows up again on another task, log it with `python3 .atelier/bin/atelier.py lesson TAG "..."` (see the `lessons` skill).
5. After the fix, the lead runs `check-handoff`, then `set-status T-01 review`, and the card's reviewer writes a new report with `new-gate` and measures everything again. A reviewer different from the author is still required; the same reviewer may check again.

Stop after 3 failed rounds on one card. The card is probably wrong or too large. The lead rewrites or splits it.

## Watch for gamed results

A worker under pressure may make the numbers pass without making the work good. Look for:

- tests that were edited, skipped, or deleted to go green;
- assertions loosened (a tolerance raised from 1% to 50%);
- a quality bar reinterpreted (for example "under 200 ms" measured on an empty input);
- checks in `.atelier/checks/` that were changed or removed;
- outputs that match the example by copying it instead of meeting the goal;
- a handoff note that reports numbers no command produced.

Compare file changes against the card's constraints. If tests or checks changed, the gate fails unless the card asked for it. Only the lead may change a quality bar, and only with the person's approval. A bar changed after the review makes the gate report stale, so the reviewer measures again against the new bar.

## Sample gate report

```
---
task: T-04
reviewer: reviewer-2
result: fail
card_hash: 4b1f0c9a7e21
handoff_hash: 9d03e6b5a118
---

# Gate: T-04

## Measurements
- Page weight under 300 KB: measured 412 KB (du -k dist/index.html dist/assets/*). FAIL
- Accessibility audit score at least 90: measured 94. PASS
- 0 console errors on load: measured 0 in headless run. PASS
- All 18 unit tests pass: ran `python3 -m unittest`, 18 passed, 0 failed. PASS
- run-checks: 3 checks, 3 passed. PASS

## Findings
- Page weight is 112 KB over the bar. hero.png alone is 230 KB; serve a compressed version.
- tests/test_layout.py changed in this task although the card did not ask for it. Revert or explain; the lead decides.
```

## Checklist

- [ ] Reviewer is not the author and is the one named on the card.
- [ ] The report was made with `new-gate` after the last change to the bar and the handoff note.
- [ ] Every quality-bar line has a measured value.
- [ ] Tests were run by the reviewer, not taken from the handoff note.
- [ ] `run-checks` was run.
- [ ] No test, check, or bar was weakened.
- [ ] `gate T-01` was run by the lead; on a fail the work went back, not forward.
