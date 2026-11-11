---
name: board
description: Maps the whole job before any work starts, splitting it into pieces sized for one worker, with dependencies, parallel groups, shared bottleneck queues, owners, and reviewers, and writes .atelier/board.md. Use after interrogate and before contract, and whenever the scope changes enough to add or remove a piece.
---

# Board: map the whole job first

No piece of work starts until the whole job is on the board. A map drawn after half the work is done only explains why the pieces do not fit. You are the lead; only you write `.atelier/board.md`.

## Step 1: list everything the job produces

1. Read the restatement the person approved in the `interrogate` phase.
2. Write down every output the job must produce: endpoints, screens, modules, migrations, tests, docs, config changes.
3. Add the hidden work: setup, fixtures and seed data, integration, wiring routes, the end-to-end test, the final check. Hidden work is where boards usually fail.

## Step 2: cut it into pieces

Each piece becomes one task card and goes to one worker. Size pieces with these rules:

1. **One worker, one session.** A piece must be finishable by one worker in one sitting, roughly 1 to 3 hours of focused work. If it needs more, split it.
2. **One owner per file.** Two pieces never write the same file. If two pieces must change one file, either merge them or put that file in a queue.
3. **Gate-sized.** A reviewer must be able to check the piece against its quality bar in under 30 minutes. If the check would take longer, the piece is too big.
4. **A clear exit.** Every piece produces something you can point at: a file, a passing test, a working endpoint.
5. **Not too small.** A piece shorter than about 15 minutes costs more in briefing and gating than it saves. Merge it into a neighbour.

A typical job has 3 to 12 pieces. More than 15 means you are planning steps, not pieces.

## Step 3: dependencies and parallel groups

1. For each piece, write which pieces must be `done` before it can start (`depends_on`).
2. Group pieces with no dependency between them into **parallel groups**: A, B, C, in order.
3. Check for cycles. If T-03 waits for T-05 and T-05 waits for T-03, the cut is wrong; redraw it.
4. Cap a parallel group at 4 workers by default (the `dispatch` skill says when you may raise it). More agents is not faster: each extra worker adds briefing, merging, and gating for you.

## Step 4: shared bottlenecks and queues

A bottleneck is anything only one worker may touch at a time: a database migration, a lockfile, a shared config file, the CI build, a deploy, a paid or rate-limited API.

1. List every bottleneck under "Shared bottlenecks".
2. Give each one a **queue** name (for example `schema`, `deps`, `build`, `deploy`; `profile-software` lists the usual ones).
3. Put that name in the `queue` field of every piece that uses it.
4. Work in one queue runs one at a time, in board order, even when the pieces are in the same parallel group.

## Step 5: owners and reviewers

1. Name an owner (worker) and a reviewer for every piece, with distinct names such as `worker-1` and `reviewer-1`. These go into the card's `owner:` and `reviewer:` fields; the worker and reviewer sign their files with them.
2. The reviewer must never be the owner. Workers run as `atelier-software:worker` subagents and reviewers as separate `atelier-software:reviewer` subagents.
3. One reviewer may check several pieces; one worker may own several pieces in different groups.

## Step 6: write the file

Write `.atelier/board.md` using its template sections: Pieces, Shared bottlenecks, Order of work. Keep the Status column in step with the task cards; the card is the source of truth. Run `python3 .atelier/bin/atelier.py status` to see integrity problems; it lists any row whose Status differs from its card (board drift).

Then move to the `contract` skill, which turns each row into a task card.

## Worked example

Request: "Add CSV export to the reports page."

```markdown
## Pieces

| Task | Title | Depends on | Parallel group | Bottleneck queue | Owner | Reviewer | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 | Export query and row streaming | - | A | - | worker-1 | reviewer-1 | todo |
| T-02 | CSV writer with column order | - | A | - | worker-2 | reviewer-1 | todo |
| T-03 | Export button and progress UI | - | A | - | worker-3 | reviewer-2 | todo |
| T-04 | Wire endpoint to writer and UI | T-01, T-02, T-03 | B | build | worker-1 | reviewer-2 | todo |
| T-05 | Load test, 10,000 rows | T-04 | C | build | worker-2 | reviewer-1 | todo |

## Shared bottlenecks
- build: the CI build runs one job at a time; T-04 and T-05 queue on it.
- routes file: only T-04 edits the routes file.

## Order of work
- Group A (T-01, T-02, T-03) runs in parallel: 3 workers.
- Group B (T-04) starts when all of A is done.
- Group C (T-05) starts when T-04 is done.
```

## Anti-patterns

- **Too many agents.** Ten workers on a five-piece job means ten briefs, ten gates, and a merge mess. Match workers to the widest parallel group, 4 at most by default (see `dispatch` for when to raise it).
- **Two workers on one file.** They overwrite each other or produce conflicts only you can untangle. One file, one owner.
- **A board of steps.** "Open file, add function, run tests" is a recipe, not a board. Pieces are outcomes.
- **Forgetting integration.** Three perfect parts with no piece to join them is not a finished job.
- **A bottleneck with no queue.** Two workers each add migration `0042`, or both edit the lockfile, and neither change merges cleanly.
- **Drawing the board after work starts.** Stop the work, draw the board, then resume.
