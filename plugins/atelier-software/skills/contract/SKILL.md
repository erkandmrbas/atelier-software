---
name: contract
description: Turns the person's short request into a measurable contract in .atelier/contract.md, then writes one task card per board piece with goal, never-constraints, a numeric quality bar, examples, an approval checkpoint, fixed decisions, and what is left open. Use after board and before dispatch; every card must pass check-card before it goes to a worker.
---

# Contract: from a short request to measurable cards

The person gives you a sentence. Workers and reviewers need lines they can check. This skill turns the first into the second, twice: once for the whole job (the contract) and once per piece (the task cards). You are the lead; only you write these files.

## Step 1: write the contract

Fill `.atelier/contract.md`, section by section:

1. **Request**: the person's words, quoted exactly.
2. **Goal**: what exists when the job is done, in 1 or 2 sentences.
3. **Constraints**: what must never happen, each line starting with "Never" or "Must not".
4. **Quality bar**: how you will know it is good. Every line holds a number or a pass/fail test.
5. **Examples and references**: what the person likes, earlier work, files to match. Check `.atelier/shelf.md` first.
6. **Approval checkpoints**: at least plan, cheap draft, and final.
7. **Fixed decisions**: everything the person approved during `interrogate`. Workers do not reopen these.
8. **Left open on purpose**: choices you trust the workers to make.

Every line in the contract must be something a reviewer can check without asking you.

## Step 2: turn vague words into numbers

A quality bar without numbers cannot be gated. For every vague word, offer the person a number and get it confirmed.

| The person says | The bar says |
| --- | --- |
| "faster" | p95 response time under 200 ms on the staging data set |
| "small change" | at most 400 changed lines and 15 files per task |
| "doesn't break anything" | 100% of existing tests pass; 0 new lint or type errors |
| "reliable" | 0 failures in 50 consecutive runs |
| "readable" | functions at most 50 lines; 100% of new public functions typed |
| "small" | bundle under 150 KB gzipped |
| "looks good on phones" | no horizontal scroll at 360 px width |
| "well tested" | line coverage of changed lines at least 80% |

How to find the number:

1. Measure what exists now. "Faster" means faster than today's measured value.
2. Propose a number in your recommendation and let the person correct it.
3. When no number fits, write a pass/fail test: "a person who has not seen the project can export a file in under 3 clicks".

## Step 3: phrase constraints as "never"

Constraints say what must never happen, not what should happen.

- Weak: "Be careful with the database." Strong: "Never run a migration that drops a column."
- Weak: "Keep the style consistent." Strong: "Never add a dependency that is not listed under Fixed decisions."
- Weak: "Avoid breaking things." Strong: "Must not change the public API of any function exported from `lib/`."

Every rejection logged in `.atelier/rejections.md` that applies to this job becomes a "never" line.

## Step 4: one task card per piece

For every row on the board:

1. Create the card: `python3 .atelier/bin/atelier.py new-task T-01 "Export query and row streaming"`.
2. Fill the front matter: `owner`, `reviewer`, `depends_on`, `queue`, matching the board. Owner and reviewer are distinct names such as `worker-1` and `reviewer-1`.
3. Fill all 7 sections: Goal, Constraints, Quality bar, Examples and references, Approval checkpoint, Fixed decisions, Left open on purpose. No section may be empty: write "none" in Fixed decisions or Left open on purpose when there is nothing. `check-card` checks all 7.
4. Copy the contract lines that apply to this piece, and narrow them. A card's bar must be checkable on this piece alone.
5. Run `python3 .atelier/bin/atelier.py check-card T-01`. It must pass before the card is dispatched. Fix and re-run until it does.

## The minimal brief rule

A worker gets three things: the **fixed decisions**, the **quality bar**, and **what is left open on purpose**. It does not get a step-by-step recipe.

- A recipe caps quality at the level of the person who wrote it, and the worker stops thinking.
- A recipe hides the goal. When a step does not fit reality, the worker cannot adapt.
- A card longer than about 60 lines is usually a recipe in disguise. Cut it.

Give numbers instead of instructions. "p95 under 200 ms" leaves the worker free to find the best route; "add an index on `created_at`" does not, and may be wrong.

## Bad card vs good card

Bad:

```markdown
## Goal
Make the export work well.

## Constraints
Be careful with performance.

## Quality bar
Should be fast and correct.

## Examples and references
-

## Approval checkpoint
-

## Fixed decisions
1. Open reports/export.py. 2. Add a function called stream_rows.
3. Use a loop with a batch size of 500. 4. Call it from the view. 5. Run the tests.

## Left open on purpose
-
```

Problems: no number in the bar, a constraint that cannot fail, a recipe where fixed decisions belong, nothing left open, no checkpoint. `check-card` rejects it.

Good:

```markdown
## Goal
Stream report rows to the CSV writer without loading the whole result into memory.

## Constraints
- Never change the stored report data.
- Never hold more than 1,000 rows in memory at once.
- Must not edit the routes file (T-04 owns it).

## Quality bar
- A 10,000-row export finishes in under 5 seconds on the staging data set.
- Peak memory under 100 MB for 100,000 rows.
- 0 rows lost or duplicated, checked by count and checksum against the source query.

## Examples and references
- Column order of `samples/monthly.csv`.

## Approval checkpoint
None; the person sees the 100-row draft after T-04.

## Fixed decisions
- Python standard library `csv` module; no new dependencies.
- Output encoding UTF-8 with a header row.

## Left open on purpose
- Batch size, query shape, and function names.
```

## Before you move on

1. Every card passes `check-card`.
2. The board and the cards agree: run `python3 .atelier/bin/atelier.py status`.
3. Show the person the contract and the board at the approval checkpoint. No dispatch before their yes.
