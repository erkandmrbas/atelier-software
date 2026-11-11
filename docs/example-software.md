# Example: adding a feature to a web app

A condensed session. The project is `shop`, a web app with a Python back end, a React front end, a SQL database and about 600 tests. The person runs Claude Code with atelier-software installed, in the project root. Lines starting with `$` are commands the lead (or a subagent) ran; the output under them is what the CLI printed when this session was replayed in a scratch folder, so paths and times are from that run (`/tmp/ws/shop` for the project, `/tmp/ws-home` for the global rejection log, set with `ATELIER_HOME`). Long passages are cut where marked `[...]`.

## 1. The request

> **Person:** /atelier-software:start Add password reset by email.

The lead loads `profile-software`, runs `init` from the plugin's script (`${CLAUDE_PLUGIN_ROOT}/scripts/atelier.py`), then switches to the project copy:

```
$ python3 "${CLAUDE_PLUGIN_ROOT}/scripts/atelier.py" init
atelier ready in /tmp/ws/shop/.atelier
Created: contract.md, board.md, lessons.md, rejections.md, shelf.md
Next: the lead fills contract.md and board.md, then: python3 .atelier/bin/atelier.py new-task T-01 "title"
```

## 2. Research, then interrogate

The lead reads `~/.atelier/rejections.md` (one entry from another project: "no modal dialogs for account flows"), then sends the `atelier-software:researcher` subagent to look at the code. Findings, condensed: mail goes out through `app/mailer.py`, which already sends the signup email; migrations are numbered (`0041` is the latest), so two parallel migrations would collide; risks are account enumeration through the reset form, token reuse, mail cost on abuse, and a rate-limit test that already fails now and then.

> **Lead:** Before I plan this, 7 questions. Each has my recommendation; reply "go with your recommendations" or correct by number.
> 1. **Goal**: A "Forgot password?" link on the login page, an email with a one-time link, and a page to set a new password? *Recommended: yes, nothing else (no SMS, no security questions).*
> 2. **Audience**: Who uses it? *Recommended: all customers, about 40% on phones.*
> 3. **Never**: What must never happen? *Recommended: never reveal whether an email has an account; never store a reset token in plain text; never log a password or token.*
> 4. **Token life**: How long is a link valid? *Recommended: 30 minutes, single use.*
> 5. **Abuse**: How many reset emails per address? *Recommended: at most 5 per hour.*
> 6. **References**: Should the email match the signup email? *Recommended: yes, same layout from `app/templates/email/signup.html`.*
> 7. **Approval points**: Where do you want to look? *Recommended: the plan, a plain-text draft of the email, and the final on staging.*

> **Person:** Go with your recommendations, except 4: make it 60 minutes. And after a reset, log the user out everywhere.

> **Lead:** Noted. A new requirement opens 2 follow-ups.
> 1. **Log out everywhere**: Should active sessions on other devices end at once? *Recommended: yes, every session older than the reset ends within 1 minute.*
> 2. **Audit**: Do you want a record of resets for support? *Recommended: yes, a reset log with time, account and IP, kept 90 days.*

> **Person:** Yes to both.

> **Lead:** Here is what I understood:
> 1. Forgot-password link, one-time email link valid 60 minutes, new-password page; all customers, phone-first.
> 2. Never reveal whether an email exists; never store or log a token or password in plain text.
> 3. At most 5 reset emails per address per hour; all other sessions end within 1 minute of a reset.
> 4. A reset log kept 90 days; the email matches the signup email.
> 5. You look at the plan, a plain-text email draft, and the final on staging. Is that right?

> **Person:** Yes.

## 3. The board

`.atelier/board.md`, as the lead wrote it:

```markdown
## Pieces
| Task | Title | Depends on | Parallel group | Bottleneck queue | Owner | Reviewer | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 | Reset token table migration | - | A | schema | worker-1 | reviewer-1 | todo |
| T-02 | Reset email template and sender | - | A | - | worker-2 | reviewer-1 | todo |
| T-03 | Forgot and new password pages | - | A | - | worker-3 | reviewer-2 | todo |
| T-04 | Reset audit log table | - | A | schema | worker-1 | reviewer-2 | todo |
| T-05 | Reset request and confirm endpoints | T-01, T-02, T-04 | B | - | worker-1 | reviewer-1 | todo |
| T-06 | End-to-end reset flow test | T-03, T-05 | C | build | worker-2 | reviewer-2 | todo |

## Shared bottlenecks
- schema: migrations are numbered; T-01 and T-04 run one after the other.
- build: the end-to-end suite takes 9 minutes and shares one browser cache.
- routes file: only T-05 edits app/routes.py.

## Order of work
- Group A: T-01, T-02, T-03 start together (3 workers). T-04 waits for T-01 in the schema queue.
- Group B: T-05 when T-01, T-02 and T-04 are done. T-03 codes against a stub of T-05's endpoints.
- Group C: T-06 when T-03 and T-05 are done.
```

## 4. The contract and the cards

`.atelier/contract.md`, condensed:

```markdown
## Constraints
- Never reveal whether an email has an account (same response, same status code, timing within 50 ms).
- Never store a reset token in plain text; never log a token or a password.
- Never edit, skip or delete an existing test unless a card names it.
- Never add a dependency.

## Quality bar
- All existing tests pass; coverage of changed lines at least 80%.
- Token valid 60 minutes, single use: 0 successful reuses in the tests.
- At most 5 reset emails per address per hour.
- Other sessions end within 1 minute of a reset.
- p95 of both endpoints under 200 ms over 500 requests on staging data.
- New pages: no horizontal scroll at 360 px width; 0 new lint errors.
```

The lead creates one card per row with `python3 .atelier/bin/atelier.py new-task T-02 "Reset email template and sender"` and fills it. T-02 in full:

```markdown
---
id: T-02
title: Reset email template and sender
status: todo
owner: worker-2
reviewer: reviewer-1
depends_on: []
queue:
---

## Goal
A send_reset_email(user, link) function and a reset email (plain text and HTML) that matches the signup email.

## Constraints
- Never put the token anywhere except the link; never log the link.
- Never edit tests/test_mailer.py beyond adding new tests.
- Must not touch files outside app/mailer.py, app/templates/email/reset.*, tests/test_reset_email.py.

## Quality bar
- At least 5 new tests pass; all 14 existing mailer tests pass.
- Subject is exactly "Reset your password".
- Plain-text version under 120 words; the link appears exactly once in each version.
- HTML version passes the existing email layout test (max width 600 px).

## Examples and references
- app/templates/email/signup.html and signup.txt (layout, footer, tone).

## Approval checkpoint
Plain-text draft goes to the person before the HTML version.

## Fixed decisions
- Link format: https://<host>/reset/<token>; the token comes from T-05, use a fake one in tests.

## Left open on purpose
- Wording of the body, function internals, test names.
```

T-01, condensed: goal "a `password_reset_tokens` table storing a SHA-256 hash of each token, its account, expiry and used-at time"; constraints "never drop or alter an existing column", "must run in the schema queue"; bar "migration applies and rolls back cleanly on a copy of staging with 100 accounts, 0 rows changed in existing tables"; checkpoint "none".

`python3 .atelier/bin/atelier.py check-card T-02` prints 9 PASS lines (the id, the 7 sections and a number in the quality bar) and `Card T-02 is complete.` All 6 cards pass. The lead shows the person a 12-line summary of the board and the contract. The person says yes.

## 5. Dispatch

Group A has 4 pieces, but T-01 and T-04 share the `schema` queue, so 3 workers start:

```
$ python3 .atelier/bin/atelier.py set-status T-01 in-progress
T-01 status: in-progress
```

(The same for T-02 and T-03.) T-04 stays `todo` although a fourth worker slot is free: only one card per queue is `in-progress` at a time. When T-01 passes its gate, the lead dispatches T-04. The CLI also stops a card that starts too early:

```
$ python3 .atelier/bin/atelier.py set-status T-05 in-progress
Refused: T-05 depends on tasks that are not done: T-01 (in-progress), T-02 (in-progress), T-04 (todo). Finish them first, or pass --force.
```

The lead starts three `atelier-software:worker` subagents in the same turn, so they run in parallel. Each gets the same three-line brief: its card path, `.atelier/contract.md`, and "When done, write your handoff note with `python3 .atelier/bin/atelier.py new-handoff T-02 --author worker-2` and fill every section. Do not edit the card or run `set-status`. Mention T-02 in your final message."

## 6. A draft, and a rejection

worker-2 stops at T-02's approval checkpoint with a plain-text draft that opens with "Hey there!" and a waving-hand emoji. The person answers "No emoji and no 'Hey there!', it reads like a promo." The lead logs it before anything is fixed:

```
$ python3 .atelier/bin/atelier.py reject "reset email draft v1: 'no emoji and no \"Hey there!\", it reads like a promo'"
Rejection recorded (2026-11-11 12:54, shop) in: /tmp/ws/shop/.atelier/rejections.md, /tmp/ws-home/rejections.md
```

The lead adds "Never use emoji or a greeting other than the one in signup.txt" to the contract's constraints. worker-2 revises the greeting only; the person approves draft v2.

## 7. A gate fails

worker-2 finishes and writes the handoff note. The lead trusts the file, not the chat message: `python3 .atelier/bin/atelier.py check-handoff T-02` prints `Handoff T-02 is complete.`, then the lead runs `set-status T-02 review`.

The lead runs the gate with the `atelier-software:reviewer` subagent, signing as reviewer-1. It runs `python3 .atelier/bin/atelier.py new-gate T-02 --reviewer reviewer-1`, runs the full suite itself, diffs `tests/` against `main`, and fills `.atelier/gates/T-02.md`. `new-gate` also writes `card_hash` and `handoff_hash` into the front matter (left out below); if the card's quality bar or the handoff note changes after the review, the report goes stale and `gate` fails.

```markdown
---
task: T-02
reviewer: reviewer-1
result: fail
---

## Measurements
- New tests: 6 pass (bar: at least 5). PASS
- Existing mailer tests: 14 of 14 pass, but see findings. FAIL
- Subject: "Reset your Shop password" in app/mailer.py (bar: exactly "Reset your password"). FAIL
- Plain text: 88 words, link once in each version. PASS
- Layout test: passes at 600 px. PASS

## Findings
- tests/test_mailer.py line 6: expected subject rewritten to match the code. The card forbids it. Revert the test; fix the subject.
```

```
$ python3 .atelier/bin/atelier.py gate T-02
PASS card front matter id is T-02 (found 'T-02')
[...]
PASS reviewer 'reviewer-1' is not the handoff author (a different agent must review and write the gate report .atelier/gates/T-02.md)
[...]
FAIL gate result is pass (found 'fail') (reviewer: fix it in .atelier/gates/T-02.md)
[...]
Gate T-02: FAIL. The work does not move on until every line passes.
$ python3 .atelier/bin/atelier.py set-status T-02 in-progress
Archived the gate report to .atelier/gates/archive/T-02-20261111-125442.md. The work is reopened, so a new review is needed (new-gate).
T-02 status: in-progress
$ python3 .atelier/bin/atelier.py lesson test-tampering "T-02 changed the expected subject in tests/test_mailer.py instead of fixing the template"
Lesson logged: test-tampering (seen 1 time).
```

worker-2 reverts the test, fixes the subject and updates the handoff note. The lead runs `check-handoff T-02` and `set-status T-02 review`. reviewer-1 creates a fresh report with `new-gate T-02 --reviewer reviewer-1`, measures every line again, and the lead runs the gate:

```
$ python3 .atelier/bin/atelier.py gate T-02
[...]
PASS gate result is pass (found 'pass')
[...]
Gate T-02: PASS. Status set to done.
$ python3 .atelier/bin/atelier.py shelve email-reset-template app/templates/email/reset.txt "approved reset email, plain text, matches signup layout"
Shelved app/templates/email/reset.txt as 'email-reset-template'.
```

## 8. The same mistake twice

T-05 (the endpoints) goes to reviewer-1, who fails it: the rate-limit test failed now and then, and worker-1 added `@unittest.skip("flaky")` to it. The lead reopens T-05 with `set-status T-05 in-progress`, which archives the failed gate report. Same kind of mistake, same tag:

```
$ python3 .atelier/bin/atelier.py lesson test-tampering "T-05 added @unittest.skip to test_rate_limit in tests/test_mailer.py"
Lesson logged: test-tampering (seen 2 times).
STOP: 'test-tampering' happened 2 times. Turn it into code, not a note: write a check in .atelier/checks/ (.py, .sh, or executable) that exits non-zero when this mistake is present, with the line 'lesson: test-tampering' in its first 5 lines. Gates fail until it exists.
```

The command exits with code 3. The lead writes `.atelier/checks/no_test_tampering.py`, which must fail on the current mistake before anyone fixes it:

```python
#!/usr/bin/env python3
# lesson: test-tampering
# Fails if, compared with main, a test file was deleted, a skip marker
# was added, or an assertion line was removed or rewritten under tests/.
import re, subprocess, sys

SKIP = re.compile(r"@(unittest\.)?skip|pytest\.mark\.(skip|xfail)|\b(it|test|describe)\.skip\(")
ASSERT = re.compile(r"\bassert|\bexpect\(")
def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True).stdout

hits = [f"{line.split(chr(9))[1]}: test file deleted"
        for line in git("diff", "--name-status", "main", "--", "tests/").splitlines()
        if line.startswith("D")]
current = None
for line in git("diff", "--unified=0", "main", "--", "tests/").splitlines():
    if line.startswith(("--- a/", "+++ b/")):
        current = line[6:]
    elif line.startswith("+") and SKIP.search(line):
        hits.append(f"{current}: skip marker added: {line[1:].strip()}")
    elif line.startswith("-") and not line.startswith("---") and ASSERT.search(line):
        hits.append(f"{current}: assertion removed or rewritten: {line[1:].strip()}")
print("\n".join(hits))
sys.exit(1 if hits else 0)
```

```
$ python3 .atelier/bin/atelier.py run-checks
FAIL check no_test_tampering.py (exit 1)
    tests/test_mailer.py: skip marker added: @unittest.skip("flaky")
Some checks fail.
```

worker-1 removes the skip and fixes the cause instead: the test depended on the wall clock, so it now uses a fixed clock and passes 50 runs out of 50. The lead moves T-05 back to `review`, and reviewer-1 writes a new gate report with `new-gate T-05 --reviewer reviewer-1`.

```
$ python3 .atelier/bin/atelier.py run-checks
PASS check no_test_tampering.py (exit 0)
All checks pass.
$ python3 .atelier/bin/atelier.py gate T-05
[...]
Gate T-05: PASS. Status set to done.
```

From now on every gate in this project runs that check. No worker can pass a gate with a skipped or rewritten test again.

## 9. Delivery

T-06 runs alone in the `build` queue and passes its gate. The lead checks the whole job:

```
$ python3 .atelier/bin/atelier.py status --strict
id    title                                status  handoff  gate
----  -----------------------------------  ------  -------  ----
T-01  Reset token table migration          done    yes      pass
T-02  Reset email template and sender      done    yes      pass
T-03  Forgot and new password pages        done    yes      pass
T-04  Reset audit log table                done    yes      pass
T-05  Reset request and confirm endpoints  done    yes      pass
T-06  End-to-end reset flow test           done    yes      pass

Problems: none
```

> **Lead:** Password reset is on staging. Against the contract:
> - 612 of 612 tests pass (586 existing, 26 new), as run by reviewer-2 on the merged branch; changed-line coverage 91% (bar 80%).
> - Known and unknown emails: same response, timing difference 4 ms (bar 50 ms).
> - Token reuse: 0 successes in 20 attempts; 6th email in an hour refused; other sessions ended within 22 s (bar 1 minute).
> - p95: 64 ms request, 81 ms confirm (bar 200 ms); no horizontal scroll at 360 px. 1 rejection logged, 1 lesson turned into a check.
>
> Do you approve the final? *Recommended: yes; the lead merges after your yes.*

> **Person:** Approved.

The lead merges, and the job is done: every card reached `done` through `gate`, `status --strict` exits 0, and the person said yes.
