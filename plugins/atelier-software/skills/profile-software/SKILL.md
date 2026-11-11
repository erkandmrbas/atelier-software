---
name: profile-software
description: Ready-made quality bars, constraints, gates, bottleneck queues and a sample task card for software work (features, refactors, migrations, bug hunts). The start skill loads it at the beginning of every job, so the lead fills the contract, board and task cards with tested defaults instead of starting from a blank page; reviewers use it to know what to measure on a code task.
---

# Profile: software

This profile adds software defaults to the core skills. `start` loads it at the beginning of every job; it works together with `interrogate`, `board`, `contract` and `gate` and does not replace them. Every number below is a default to tune: copy it into the contract, then change it to fit the project.

## When it applies

- Always: `start` loads it before `interrogate`.
- The lead is writing the contract, mapping the board or writing task cards.
- A reviewer needs to know what to measure on a code task.

## Constraints to copy into the contract

Phrase each one as "never ..." and keep the ones that apply.

- Never edit, skip or delete a test to make it pass unless the task card says so by name. Workers sometimes fake a green run instead of fixing the code; the reviewer diffs the test folder to catch it.
- Never touch a file outside the worker's row in the file-ownership map.
- Never change a migration, lockfile, schema or shared config outside its queue.
- Never add a dependency that is not listed under Fixed decisions.
- Never commit secrets, tokens or real customer data, including in fixtures.
- Never lower a lint rule, a coverage threshold or a type-check setting to get through a gate.
- Never push, merge or deploy; the lead does that after the final approval checkpoint.

## Quality bar defaults

Every line holds a number or a pass/fail test. These are defaults to tune.

| Bar | Default | How the reviewer measures it |
| --- | --- | --- |
| Test suite | 100% of existing tests pass | Reviewer runs the full suite itself |
| Coverage of changed lines | at least 80% | Coverage tool limited to the diff |
| New lint errors | 0 | Linter on changed files, compared with the base branch |
| New type errors | 0 | Type checker on the whole project |
| p95 latency of touched endpoints | at most 200 ms, and no worse than base + 10% | Load script with at least 500 requests |
| Front-end bundle size | growth at most 5 KB gzipped per task | Build output compared with base |
| Lines changed per task | at most 400 (excluding generated files) | `git diff --stat` |
| Files changed per task | at most 15 | `git diff --name-only` |
| Functions | at most 50 lines each in new code | Linter rule or a short script |
| Public interfaces | 100% of new public functions have a docstring or type signature | Grep or linter |

A task that cannot meet a bar is split, or the lead changes the bar in the contract and records why. A worker never decides that alone.

## File-ownership map

Two workers editing the same file at the same time is the most common cause of lost work. Put this table on the board before dispatch.

| Path or glob | Owner task | Notes |
| --- | --- | --- |
| `src/billing/**` | T-02 | |
| `src/api/invoices.py` | T-03 | |
| `tests/billing/**` | T-02 | |
| `migrations/**` | queue: schema | One at a time |
| `package-lock.json`, `poetry.lock` | queue: deps | One at a time |

Steps:

1. List every file each task will likely touch before dispatch.
2. If two tasks need the same file, either merge the tasks, chain them with `depends_on`, or give the file to a queue.
3. Write the owned paths into each task card under Fixed decisions.
4. The reviewer fails any task whose diff leaves its owned paths.

## Bottleneck queues

These resources take one worker at a time. Give each a queue name and set `queue:` on the task card.

- **schema**: database migrations and schema files. Migration numbers collide when two run in parallel.
- **deps**: lockfiles and dependency manifests. Two lockfile edits never merge cleanly.
- **config**: shared config (CI files, environment templates, build config, feature flags).
- **build**: full builds and end-to-end runs that take more than 5 minutes or share a cache.
- **deploy**: anything that touches a shared environment.
- **paid-api**: calls to an external service that costs money or has a rate limit.

Run at most 4 workers in parallel on one repository by default; see `dispatch` for when to raise it. More workers means more merge conflicts and more review load, not more speed.

## Gates

The reviewer is the `atelier-software:reviewer` subagent, never the worker. On every code task it:

1. Reads the task card and the handoff note.
2. Runs the test suite itself. It never trusts the pass count in the handoff note.
3. Diffs the test folder against the base. Any removed, skipped or weakened assertion fails the gate unless the card allows it.
4. Checks the diff stays inside the owned paths.
5. Measures every quality-bar line and writes one line per bar in the gate report.
6. Runs `python3 .atelier/bin/atelier.py run-checks`.
7. Writes the result into `.atelier/gates/T-NN.md`; the lead then runs `python3 .atelier/bin/atelier.py gate T-NN`.

## Cheap drafts

Draft cheap, show it at the approval checkpoint, then build the real thing.

- **Spike**: throwaway code, at most 1 hour, that answers one question ("can the library stream 10 MB files?"). Delete it after; keep the answer in the handoff note.
- **Interface stub**: function signatures, types and endpoint shapes with `raise NotImplementedError` bodies. Lets parallel workers code against a stable interface.
- **Mock data**: 5 to 20 fixture records that cover the edge cases. Lets the front end and the back end start at the same time.
- **Screenshot or text mock**: for UI, a static page or an ASCII layout before any state logic.

Shelve approved stubs, fixtures and helpers so later tasks start from them:

```
python3 .atelier/bin/atelier.py shelve fixtures-invoice tests/fixtures/invoices.json "20 invoice records covering refunds and zero totals"
```

## Sample task card: a feature

```markdown
---
id: T-03
title: Export invoices as CSV
status: todo
owner: worker-1
reviewer: reviewer-1
depends_on: [T-01]
queue:
---

# T-03: Export invoices as CSV

## Goal
Add GET /api/invoices/export that returns the caller's invoices for a date range as a CSV download.

## Constraints
- Never edit or delete an existing test.
- Never touch files outside src/api/invoices.py, src/export/csv.py and tests/api/test_invoice_export.py.
- Never load more than 1,000 rows into memory at once.

## Quality bar
- All existing tests pass; at least 6 new tests pass.
- Coverage of changed lines at least 80%.
- 0 new lint errors, 0 new type errors.
- p95 latency at most 800 ms for 10,000 invoices.
- At most 300 changed lines.

## Examples and references
- Match the style of the existing GET /api/orders/export.
- Fixture: tests/fixtures/invoices.json (on the shelf).

## Approval checkpoint
none

## Fixed decisions
- CSV columns: id, date, customer, total, currency.
- Dates in ISO 8601.

## Left open on purpose
- Streaming method and helper names.
```

## Common lesson tags

When the same tag shows up twice, `lesson` exits 3 until a check carries `lesson: TAG` in its first 5 lines. Log with:

```
python3 .atelier/bin/atelier.py lesson test-tampering "T-04 removed an assertion instead of fixing the parser"
```

| Tag | What went wrong | Example check in `.atelier/checks/` |
| --- | --- | --- |
| test-tampering | A test was deleted, skipped or weakened | Fail if `git diff --diff-filter=D` lists a test file, or new `skip`/`xfail` markers appear |
| out-of-lane | A worker edited a file it did not own | Compare `git diff --name-only` with the ownership map |
| lockfile-drift | Lockfile changed without a manifest change | Fail if the lockfile changed and the manifest did not |
| migration-clash | Two migrations share a number | Fail on duplicate migration prefixes |
| secret-leak | A key or token was committed | Grep the diff for key patterns |
| debug-leftover | Print statements or breakpoints left in | Grep changed lines for `print(`, `console.log`, `debugger` |
| todo-left | A TODO shipped as if finished | Fail on new `TODO` or `FIXME` lines in the diff |
| oversized-pr | A task grew past the line limit | Fail if changed lines exceed 400 |
| fake-green | Handoff claimed tests passed but they did not | Run the suite and compare with the handoff |

A check is a small script whose first 5 lines say which lesson it carries, for example:

```sh
#!/bin/sh
# lesson: debug-leftover
! git diff --unified=0 HEAD | grep -E '^\+.*(console\.log|debugger|breakpoint\(\))'
```
