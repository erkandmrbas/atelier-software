# FAQ

### What kind of work is it for?

Software jobs too big for one reply or one session: a feature that touches the back end, the front end and the schema; a refactor across 40 files; a database or framework migration; a bug hunt that needs several hypotheses tested in parallel. The core skills (`start`, `interrogate`, `board`, `contract`, `dispatch`, `gate`, `draft-first`, `lessons`) carry the method, and `start` always loads `profile-software`, which adds the defaults for code: never-constraints, quality bar numbers, a file-ownership map and the usual queues (`schema`, `deps`, `config`, `build`, `deploy`, `paid-api`).

### Does it need Claude Code?

Yes. atelier-software is a Claude Code plugin. It relies on Claude Code subagents (`atelier-software:worker`, `atelier-software:reviewer`, `atelier-software:researcher`) and on three hooks (SessionStart, Stop, SubagentStop) that make some rules automatic. The CLI underneath is a single Python 3.9+ script with no dependencies, and it refuses `done` without a passing gate whatever calls it. See [install.md](install.md).

### How many agents should I run?

As many as the widest parallel group on the board, capped at 4 by default. The `dispatch` skill allows more, up to 8 in a single dispatch, only when the pieces share no file and no queue, each can be checked on its own, and your rate limits allow it. More agents is not faster: every extra worker adds a brief, a handoff note, a gate and a chance of collision, and the lead and reviewers become the bottleneck. Four focused workers with clean cards usually finish before ten who fight over the same lockfile.

### What if a worker says "done" but there is no handoff note?

Then it is not done. Run `python3 .atelier/bin/atelier.py check-handoff T-03`. If the note is missing, has no author, or has an empty section, the command fails and the worker goes back to finish it. The SubagentStop hook catches this automatically: a worker whose final message names a task that is `in-progress` or `review` without a complete handoff note is blocked from stopping and told which command to run.

### Can a task be marked done by hand?

No. `set-status T-03 done` is refused unless the full gate passes, and `gate T-03` is the command that sets `done`. If someone edits the card's front matter directly, `status` lists it as a problem ("marked done but its gate does not pass"), `status --strict` exits 1, and the Stop hook will not let the session end until it is fixed.

### What happens to a gate report when the work changes?

It goes stale. `new-gate` records a hash of the card's quality bar and of the handoff note in the report (`card_hash`, `handoff_hash`). If either changes after the review, `gate` fails with "the card's quality bar changed after this review" or "the handoff note changed after this review", and the reviewer must measure again and run `python3 .atelier/bin/atelier.py new-gate T-03 --reviewer NAME --force`; `--force` moves the old report to `.atelier/gates/archive/`. Reopening a task with `set-status T-03 in-progress` (or `todo`) archives its gate report on the spot, so reworked output always gets a fresh review.

### Can a task start before its dependencies are done?

Not by accident. `set-status T-03 in-progress` is refused while any task in the card's `depends_on` is not `done`, and the message names each one with its status. The lead can pass `--force` to override it; the CLI then prints a warning. `status` also lists any task in progress before its dependencies are done, and any board row whose Status no longer matches the card.

### Does it cost more tokens?

Per job, usually somewhat more on planning and checking, and less on rework. The questions, the board, the cards and the gates all cost tokens. What they save is the expensive part: work built on a wrong guess, a migration run on the real database in the wrong shape, three workers redoing a piece that did not fit, and the same mistake made five times. The brief rule helps too: workers get a card path and three lines, not a page of instructions. For tiny jobs the overhead is not worth it; see the next question.

### Can I use it for a small job?

Yes, with the small job fast path in the `start` skill. It applies when one worker can finish in one session, the job touches at most 3 files, and there is no shared bottleneck. You get one round of 3 to 5 questions, a short contract, one card and one gate. The fast path removes paperwork, never the gate. For a one-line fix, a typo or a quick question, skip atelier entirely.

### Where is the state kept? Can I commit it?

Everything for a project lives in `.atelier/` at the project root: contract, board, task cards, handoff notes, gate reports, checks, lessons, rejections, shelf, and the project's own copy of the CLI in `.atelier/bin/`. Your rejection log also has a global copy at `~/.atelier/rejections.md`, so it follows you between projects.

Committing `.atelier/` is your choice. Commit it if you want the plan, the gate reports and the checks reviewed and versioned with the work, or shared with teammates; the checks in particular are worth keeping. Add it to `.gitignore` if you consider it scratch state. Either way, never put secrets in it.

### How do I write a check?

When `lesson TAG "..."` exits with code 3, the same kind of mistake has happened twice. Write a small script in `.atelier/checks/`:

1. A `.py` or `.sh` file, or any executable file.
2. The line `lesson: TAG` in its first 5 lines, usually as a comment.
3. Exit 0 when the project is clean; exit non-zero and print the file and line of each hit when the mistake is present.
4. Keep it fast (under 1 second on a normal project) and to one pattern.

Then run `python3 .atelier/bin/atelier.py run-checks` and confirm it fails on the current mistake and passes after the fix. From then on every `gate` runs it. The `lessons` skill has a full example, and [example-software.md](example-software.md) shows one written during a real job.

### What does the person actually have to do?

Answer the question rounds (or reply "go with your recommendations"), confirm the 5-line restatement, say yes or no at each approval checkpoint (by default: plan, cheap draft, final), and say what they dislike when they dislike it. Everything else is the lead's job. The person talks only to the lead, never to workers or reviewers.

### What happens after a crash or a usage limit?

Start a new session in the same project. The SessionStart hook prints the board summary and recent rejections; then run `/atelier-software:start`, which sees that `.atelier/` exists and resumes (or run `python3 .atelier/bin/atelier.py status` yourself). The lead resumes from the files: cards `in-progress` without a complete handoff note are restarted from the card, cards in `review` get a gate, and queues are re-checked so only one card per queue runs. Nothing depends on remembering the old chat.

### Can the reviewer be the same agent as the worker?

No. `gate` fails if the gate report's `reviewer` matches the handoff note's `author` or the card's `owner`, and it also fails unless the reviewer is the one named on the card's `reviewer:` line. The lead runs every gate with the `atelier-software:reviewer` subagent, which has no memory of the work. Give each worker and reviewer a distinct name so the check can tell them apart.

### Does atelier depend on any paid service or model?

No. The CLI uses the Python standard library only, and the skills name no product, model or paid service. The software profile, for example, says "the test runner", "the linter" and "the type checker", not a brand. Use whatever tools your project already has.
