# The atelier method

This document explains the method behind atelier-software for the people who use it: what each rule is, why it works, what breaks without it, and exactly where the plugin enforces it. The skills tell the agent what to do. This page tells you why.

## Why the method exists

Two problems show up as soon as you hand an AI agent a software job bigger than a single reply.

**Agents default to average work.** Given a one-line request such as "add CSV export", an agent fills every gap with the most common choice. The result is plausible, tidy, and generic: the median of everything it has seen, not what you had in mind. The agent did not misunderstand you. It never had enough to understand. Nothing in the request said what "good" meant, so it aimed for "typical".

**More agents without structure break each other's work.** The obvious fix for a big job is to run several agents at once. Without a plan, they edit the same files, write two migrations with the same number, make conflicting assumptions, each report "done" on a piece that does not fit the others, and nobody checks. You end up spending the time you saved untangling what they did. Ten agents that step on each other finish later than one that works alone.

A workshop solves both problems with roles and files. One lead agent talks to you and owns the plan. The plan is written down in measurable terms before anyone starts. Workers get small, clear pieces. A different agent checks every piece against numbers before it moves on. Mistakes that repeat turn into code that blocks them. The 11 principles below are the rules that make this work.

### The roles

| Role | Does | Writes |
| --- | --- | --- |
| lead | Talks to the person, plans, dispatches, closes gates | `.atelier/contract.md`, `.atelier/board.md`, `.atelier/tasks/T-NN.md` |
| worker | Carries out one task card | the work, and `.atelier/handoffs/T-NN.md` |
| reviewer | Measures one finished task against its card | `.atelier/gates/T-NN.md` |
| researcher | Gathers facts before the contract | nothing; it reports to the lead |

The lead is the Claude Code session you talk to. Workers, reviewers and researchers are the plugin's subagents: `atelier-software:worker`, `atelier-software:reviewer` and `atelier-software:researcher`.

### The flow

```
interrogate -> board -> contract + task cards -> approval -> dispatch -> gate -> deliver
                                                               ^          |
                                                               +-- fail --+
```

Each phase ends with a file on disk. The `start` skill walks the phases in this order and does not let the lead skip one.

## The 11 principles

### 1. Research first, then interrogate

**The rule.** Before any work starts, the lead researches what it can find on its own, then questions the person in short rounds. Every question carries a recommended answer. The phase ends when the person confirms a restatement of 5 lines or fewer.

**Why it works.** Research removes the questions the person should never have to answer ("which framework do you use?", "where do migrations live?"). Recommended answers turn a questionnaire into a review: the person can reply "go with your recommendations" and correct only what is wrong. Most people are far better at correcting a concrete proposal than at writing a specification from nothing.

**What goes wrong without it.** The agent guesses, builds on the guess, and you find out at the end. Or it asks 15 open questions at once, you answer 4, and it guesses the other 11 anyway.

**How atelier enforces it.** The `interrogate` skill: research first (rejections, shelf, existing files, similar work, the 3 to 5 biggest risks), through the `atelier-software:researcher` subagent; then rounds of at most 7 numbered questions (3 to 5 for a small job), one decision per question, each with a recommendation; then the restatement. The `start` skill does not move to the board until the person says yes.

### 2. Map the whole job first

**The rule.** Before any piece starts, the lead draws the board: every piece, its dependencies, which pieces run in parallel, and which shared bottlenecks they touch.

**Why it works.** A map shows the problems that are invisible one piece at a time: two pieces that need the same file, a piece nobody owns (usually integration or final assembly), a slow step everything waits on. Fixing these on paper costs minutes. Fixing them after three workers have finished costs a rewrite.

**What goes wrong without it.** Work starts on the obvious piece, the plan grows as it goes, and halfway through you learn that two finished parts cannot be joined. A map drawn after half the work only explains why the pieces do not fit.

**How atelier enforces it.** The `board` skill writes `.atelier/board.md` with three sections: Pieces (a table with depends on, parallel group, bottleneck queue, owner, reviewer, status), Shared bottlenecks, and Order of work. Pieces are sized for one worker in one session (roughly 1 to 3 hours), one owner per file, checkable in under 30 minutes. A typical job has 3 to 12 pieces. `python3 .atelier/bin/atelier.py set-status T-03 in-progress` is refused while any task in the card's `depends_on` is not `done` (`--force` overrides it with a warning), and `status` flags any task in progress while a dependency is not `done`. `status` also flags a board row whose Status differs from the card's status, because the card is the source of truth.

### 3. One lead

**The rule.** The person talks only to the lead. The lead turns the short request into a measurable contract and hands pieces to parallel workers. Workers and reviewers never ask the person anything; they ask the lead.

**Why it works.** One voice keeps one picture of the job. Every decision passes through one place, so it is recorded once and applied everywhere. The person is not interrupted by six agents with six half-informed questions.

**What goes wrong without it.** Each agent builds its own idea of what you want. Two of them ask you the same thing and get different answers on different days. Nobody owns the whole result, so nobody notices the gaps between pieces.

**How atelier enforces it.** The `start` skill makes the agent the lead and states the standing rules. Only the lead writes the contract, the board and the task cards; the `atelier-software:worker` and `atelier-software:reviewer` subagents are told never to edit them. The contract (`.atelier/contract.md`) quotes the request word for word and then turns it into lines a reviewer can check without asking anyone.

### 4. Every task card has four parts and a checkpoint

**The rule.** Every task card carries a goal, constraints (what must never happen), a quality bar with numbers, and examples or references, plus an approval checkpoint ("none" is a valid answer).

**Why it works.** Each part closes one kind of gap. The goal says what exists at the end. Constraints say what must never happen, which is where most real damage comes from. The quality bar makes "good" checkable by someone other than the author. Examples carry taste that words cannot. The checkpoint says where the work stops for the person.

**What goes wrong without it.** "Make the export work well" cannot fail a review, so it never does. A worker with no constraints changes the stored data to make a number fit. A reviewer with no bar falls back on "looks fine to me".

**How atelier enforces it.** `python3 .atelier/bin/atelier.py new-task T-01 "title"` creates the card from the template with these sections, plus Fixed decisions and Left open on purpose. `python3 .atelier/bin/atelier.py check-card T-01` fails if any of the 7 sections is empty (Goal, Constraints, Quality bar, Examples and references, Approval checkpoint, Fixed decisions, Left open on purpose; "none" counts as filled), or if the quality bar holds no number. The `contract` and `dispatch` skills require `check-card` to pass before a card goes out, and `gate` runs the same checks again.

### 5. Do not over-brief workers

**The rule.** A worker gets three things: the fixed decisions, the quality bar, and what is deliberately left open. Not a recipe. Give numbers whenever you can.

**Why it works.** A step-by-step recipe caps quality at the level of whoever wrote it, and the worker stops thinking. A number leaves the route open: "p95 under 200 ms" lets the worker find the best fix; "add an index on `created_at`" does not, and may be wrong. Saying out loud what is left open tells the worker where its judgment is wanted.

**What goes wrong without it.** Long briefs bury the goal. When a step does not match reality, the worker follows it anyway or stalls. A brief full of adjectives ("clean", "modern", "fast") is read differently by every agent.

**How atelier enforces it.** The `dispatch` skill limits the brief to three items: the card path, the contract path, and the instruction to write a handoff note. The `contract` skill shows how to turn vague words into numbers, and treats a card longer than about 60 lines as a recipe in disguise. The `profile-software` skill, which `start` always loads, gives default numbers (coverage of changed lines at least 80%, p95 at most 200 ms, at most 400 changed lines per task) so the lead does not start from a blank page.

### 6. Shared state lives in files

**The rule.** The contract, the board and the task cards are files, and only the lead writes them. A worker writes a handoff note when it finishes. No handoff note means the task is not finished.

**Why it works.** Files outlive sessions. After a crash, a usage limit or a new day, any session can run `status` and pick up from what the files say instead of from what someone remembers. A handoff note also turns "I'm done" into something checkable: what changed, how it measured against the bar, what is still open, how to verify.

**What goes wrong without it.** State lives in chat history and dies with it. Two agents edit the plan and the last write wins. A worker says "finished" in chat, the lead believes it, and the gap is found by the person.

**How atelier enforces it.** Everything lives in `.atelier/`. `python3 .atelier/bin/atelier.py new-handoff T-01 --author NAME` creates the note; `python3 .atelier/bin/atelier.py check-handoff T-01` fails if it is missing, has no author, or has an empty section. A SubagentStop hook blocks a worker that names a task in its final message while that task's handoff note is incomplete. `status` lists any task in `review` without a handoff note.

### 7. Gates at every station exit

**The rule.** One agent does the work; a different agent checks it against the quality bar. Work that fails a gate does not move on.

**Why it works.** An author checking its own work sees what it meant to do, not what it did. A separate reviewer with only the card and the output has nothing to defend. Measuring every line, instead of reading and nodding, catches the gaps a confident handoff note hides.

**What goes wrong without it.** "Tests pass" turns out to mean "the tests I edited pass". Failed work moves to the next station "to save time", the next station builds on it, and one bad piece becomes three.

**How atelier enforces it.** The `gate` skill and the `atelier-software:reviewer` subagent: the reviewer re-measures every quality-bar line itself, runs the tests itself, runs `run-checks`, and writes `.atelier/gates/T-01.md` with `result: pass` or `result: fail`. Then the lead runs `python3 .atelier/bin/atelier.py gate T-01`, which passes only if the card is complete, the handoff note is complete, the reviewer is neither the handoff author nor the card owner and is the reviewer named on the card, the report is not stale, the result is `pass`, every check passes, and no lesson repeats without a check. `new-gate` records a hash of the card's quality bar (`card_hash`) and of the handoff note (`handoff_hash`) in the report; if either changes after the review, the report is stale and the gate fails until the reviewer re-measures and runs `new-gate T-01 --reviewer NAME --force`, which moves the old report to `.atelier/gates/archive/`. Reopening a task (`set-status T-01 in-progress` or `todo`) archives its gate report the same way, so reworked output always gets a new review. Only a passing gate sets `done`; `set-status T-01 done` is refused otherwise. A Stop hook blocks the session from ending while a task is marked `done` without a passing gate.

### 8. The same mistake twice becomes code

**The rule.** The first time a mistake happens, log it. The second time, write an automated check that blocks progress until the mistake is gone.

**Why it works.** A note depends on someone reading it at the right moment. A check runs every time, for every agent, and cannot be skipped. The cost of writing a small script is paid once; the mistake never costs you again.

**What goes wrong without it.** The lessons file grows, nobody reads it, and the third worker makes the same mistake as the first two. Each fix is local; the cause stays.

**How atelier enforces it.** `python3 .atelier/bin/atelier.py lesson TAG "what went wrong"` adds a dated row to `.atelier/lessons.md`. On the second row with the same tag, it exits with code 3 and tells the lead to write a check unless one already exists. A check is any `.py`, `.sh` or executable file in `.atelier/checks/` with `lesson: TAG` in its first 5 lines; it exits 0 when the project is clean. `gate` runs every check and fails while a repeated tag has none, and `status` lists the missing check as a problem. The `lessons` skill has a worked example.

### 9. Cheap draft first, expensive final after approval

**The rule.** Make a cheap draft, show it at an approval checkpoint, and spend on the final only after the person says yes. Tag every approved output and put it on the shelf; start new work from the shelf.

**Why it works.** A draft costs a fraction of the final and catches a wrong direction while it is still cheap to change. The shelf turns approved work into a starting point: reuse is faster, cheaper, and already approved.

**What goes wrong without it.** A full implementation, a migration on real data, or a 40-file refactor is built in a direction the person rejects in the first 5 minutes of review. Approved pieces are regenerated from scratch and come back slightly different each time.

**How atelier enforces it.** The `draft-first` skill: spend about 10% of the final's cost on the draft, offer 2 to 3 directions when taste is unclear, revise in place, and get the person's yes in their own words. The contract template lists three approval checkpoints by default: plan, cheap draft, final. `python3 .atelier/bin/atelier.py shelve TAG PATH "what it is"` adds the approved output to `.atelier/shelf.md` and refuses a path that does not exist. The `interrogate` and `draft-first` skills read the shelf before anything new is made.

### 10. Parallelism is limited

**The rule.** More agents is not faster. Run as many workers as the board's widest parallel group allows, capped at 4 by default. Shared bottlenecks (migrations, a lockfile, the CI build, a deploy, a paid API) go through one queue, one piece at a time.

**Why it works.** Every extra worker adds a brief to write, a handoff to read, a gate to run, and a chance of collision. The lead and the reviewers become the bottleneck long before the workers do. Queues turn collisions into a short wait.

**What goes wrong without it.** Two migrations get the same number. Two lockfile edits refuse to merge. Two end-to-end runs on one machine finish slower than two in a row. Ten workers hit the same rate limit and all stop together. A crash costs ten half-finished pieces instead of four.

**How atelier enforces it.** The `board` skill caps a parallel group at 4 and puts every bottleneck in a named queue on the card's `queue` field. The `dispatch` skill keeps at most 1 `in-progress` card per queue and allows more than 4 workers only when the pieces share no file and no queue, each can be checked alone, and the limits allow it. `profile-software` names the usual queues: `schema`, `deps`, `config`, `build`, `deploy`, `paid-api`.

### 11. Record every rejection; the person has the final word

**The rule.** Every time the person turns something down, log it with the date, in their words. Never trust a chat summary or an agent's report blindly. The person, not a reviewer and not the lead, gives approval.

**Why it works.** A dated rejection log stops the most annoying failure of all: being shown the same rejected idea again next week. Because the log also goes to your home folder, it follows you to the next project. Treating reports as claims keeps the lead checking files instead of repeating summaries.

**What goes wrong without it.** The agent proposes the ORM you rejected on Monday, again on Thursday. A chat summary turns "keep the v1 endpoint" into "replace the v1 endpoint", and a client breaks. A worker reports "612 tests pass" when no command produced that number, and the lead passes it on.

**How atelier enforces it.** `python3 .atelier/bin/atelier.py reject "what the person rejected"` writes a dated row to `.atelier/rejections.md` and `~/.atelier/rejections.md`. The `start`, `interrogate`, `draft-first` and `lessons` skills read both files before any proposal, and the contract turns relevant rejections into "never" lines. The SessionStart hook shows the 10 most recent rejections at the top of every session. The `gate` skill tells the reviewer to treat every number in a handoff note as a claim to re-measure.

## One task's life

The principles meet in the life of a single task card. Every card goes through the same stations, and each station leaves a file behind.

1. **Card.** The lead runs `python3 .atelier/bin/atelier.py new-task T-03 "title"`, fills the card from the board row and the contract, and runs `check-card T-03` until it passes. Status: `todo`.
2. **Dispatch.** When every task in `depends_on` is `done` and its queue is free, the lead runs `set-status T-03 in-progress` (refused while a dependency is not `done`) and sends the `atelier-software:worker` subagent the three-line brief.
3. **Work.** The worker reads the card, the contract, the shelf, the lessons and the rejections, does the work, and measures itself against every bar line as it goes.
4. **Handoff.** The worker runs `new-handoff T-03 --author NAME`, fills every section, and runs `check-handoff T-03`. The lead confirms `check-handoff` passes, then moves the card to `review`. Workers never run `set-status`.
5. **Gate.** The `atelier-software:reviewer` subagent, signing as the reviewer named on the card and never the worker, runs `new-gate T-03 --reviewer NAME`, re-measures every line, runs `run-checks`, and sets `result`. The lead runs `gate T-03`.
6. **Pass or back.** On a pass, the task is `done` and the next card in its queue can start. On a fail, the lead runs `set-status T-03 in-progress`, which moves the gate report to `.atelier/gates/archive/`, sends the worker that report, and logs a lesson if the finding is a kind of mistake seen before. After 3 failed rounds the lead rewrites or splits the card.
7. **Shelf.** If the output is something the person approved, the lead shelves it so the next task starts from it.

Nothing in this cycle depends on memory. A new session, after a crash or the next morning, runs `status` and sees exactly which station every card has reached.

## What the plugin enforces, and what it cannot

The CLI and hooks enforce the parts of the method that can be checked mechanically: a complete card, a complete handoff note, a reviewer who is neither the owner nor the author and is the reviewer named on the card, a gate report that is not stale (the quality bar and the handoff note are unchanged since the review), a passing result, passing checks, no repeated lesson without a check, no task set in progress before its dependencies are done (unless the lead forces it, with a warning), and a board that agrees with the cards (`status` flags drift). They cannot judge whether a quality bar is the right one, whether a reviewer measured honestly, or whether the person really approved. Those stay with the lead and the person. The skills tell the lead how to do them well; the files make it visible when they were skipped.

## The files at a glance

| File | Written by | Holds |
| --- | --- | --- |
| `.atelier/contract.md` | lead | request, goal, constraints, quality bar, references, checkpoints, fixed decisions, left open |
| `.atelier/board.md` | lead | pieces, shared bottlenecks, order of work |
| `.atelier/tasks/T-01.md` | lead | one task card |
| `.atelier/handoffs/T-01.md` | worker | what was done, against the bar, open issues, how to verify |
| `.atelier/gates/T-01.md` | reviewer | measurements, findings, pass or fail, and the hashes of the bar and handoff it reviewed |
| `.atelier/gates/archive/` | the CLI | old gate reports, moved there on a reopen or `new-gate --force` |
| `.atelier/checks/*` | lead | automated checks from repeated lessons |
| `.atelier/lessons.md` | lead | dated mistakes by tag |
| `.atelier/rejections.md` | lead | dated rejections by the person |
| `.atelier/shelf.md` | lead | approved outputs to reuse |
| `.atelier/bin/atelier.py` | `init` | the project's copy of the CLI and templates |

Task statuses:

| Status | Means | Set by |
| --- | --- | --- |
| `todo` | card written, not started | `new-task`; `set-status` (archives any gate report) |
| `in-progress` | a worker holds it, or it came back from a failed gate | `set-status` (refused while a dependency is not `done`; archives any gate report) |
| `review` | handoff note complete, waiting for a gate | `set-status`, by the lead after `check-handoff` passes |
| `done` | gate passed | `gate` only; `set-status` refuses `done` without a passing gate |
| `blocked` | waiting on the person or another task; the reason is on the board | `set-status` |

## When not to use it

The method has a cost: questions, files, a second agent for every check. For a one-line fix, a typo or a question, that cost is waste, and the `start` skill says to skip atelier entirely. For a job that one worker can finish in one session, touching at most 3 files with no shared bottleneck, the `start` skill has a small job fast path: one round of 3 to 5 questions, one card, one gate. The fast path removes paperwork, never the gate.

## Adapting it to your codebase

`profile-software` gives defaults, not laws. Before the first big job in a repository, spend ten minutes fitting them:

1. **Find your numbers.** Write down the 5 to 10 things you actually check in review, and put a number on each: test pass rate, coverage of changed lines, p95 latency, bundle size, lines changed per pull request, new lint or type errors. Replace the profile's defaults with yours in the contract.
2. **Name your bottlenecks.** What can only one worker touch at a time? The migrations folder, the lockfile, the CI config, a shared staging database, a rate-limited API. Each becomes a queue.
3. **Define your cheap draft.** An interface stub, a spike of at most 1 hour, a migration on a copy with 100 rows, a static mock of the screen.
4. **Write your never-list.** The 3 to 7 things that must never happen in this codebase: a dropped column, a skipped test, a secret in a fixture, a change to the public API of a package. They become constraints on every card.
5. **Seed the shelf.** Shelve your best fixtures, stubs and helpers before the first job, so workers start from them.
6. **Let the checks grow.** Do not write checks up front for mistakes you have not seen. Log lessons, and let the second occurrence tell you which checks you need.

Keep the core intact: research before questions, the whole map before work, one lead, measurable cards, light briefs, state in files, an independent gate, checks for repeats, drafts before finals, few workers and real queues, and the person's word as final. Change the numbers.
