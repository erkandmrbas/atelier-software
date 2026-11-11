---
name: draft-first
description: Makes a cheap draft first and spends on the expensive final only after the person approves it at a checkpoint, revises in place instead of rebuilding, tags every output and shelves approved ones for reuse. Use before any slow, costly, or hard-to-undo step: a full implementation, a migration on real data, a large refactor, paid API calls, a deploy, or picking a UI or API design.
---

# Draft first

A draft costs a fraction of the final and catches a wrong direction early.

## Look at the shelf first

Before you make anything new:

1. Open `.atelier/shelf.md`.
2. Look for an approved output with a matching tag: a component, a module, a fixture set, a test helper, an interface stub, a migration pattern.
3. If one fits, start from it. Reuse beats regeneration: it is faster, cheaper, and already approved.
4. Read `.atelier/rejections.md` and `~/.atelier/rejections.md` too, so the draft does not repeat what the person already turned down.

## The loop

1. **Draft cheap.** Spend no more than about 10% of the final's cost or time on the draft.
2. **Show it at the approval checkpoint.** Stop and ask the person. Do not start the final while you wait.
3. **Revise in place.** Change only what the person asked to change.
4. **Approve.** The person says yes in their own words. A worker or reviewer saying "looks good" is not approval.
5. **Make the final** from the approved draft, with the same choices.
6. **Gate the final** (see the `gate` skill).
7. **Shelve** the approved final. Every output, draft or final, already carries a tag from the moment it was made.

## What a cheap draft looks like

| Work | Cheap draft | Expensive final |
| --- | --- | --- |
| Feature | interface and stubs, one path working end to end | full implementation with tests |
| Unknown library or approach | a spike of at most 1 hour that answers one question | the real integration |
| Database | migration run on mock data or a copy with 100 rows | migration on the real database |
| Refactor | 1 module converted, with the pattern written down | all 40 modules converted |
| UI | static mock or ASCII layout, 2 to 3 directions | one direction, wired to state, styled |
| API design | endpoint shapes and example payloads | handlers, validation, tests |
| Bug hunt | a failing test that reproduces the bug | the fix, with the test passing |
| Paid API | 1 call on 1 sample | the full batch |

## Offer directions, not one guess

When the person's taste matters and is not yet clear:

1. Make 2-3 distinct directions. Not 1 (no choice), not 10 (no focus).
2. Make each one clearly different, so the choice teaches you something.
3. Recommend one and say why in one sentence.
4. After the person picks, drop the others. Do not blend all three unless asked.
5. Log what they turned down with `python3 .atelier/bin/atelier.py reject "..."` (see the `lessons` skill).

## Revise in place

When the person asks for one change:

1. Change that one thing.
2. Keep everything already approved exactly as it was.
3. Do not regenerate the whole output to fix one part. A full rebuild can break 9 approved parts while fixing 1.
4. If the change cannot be made in part (a generated client, a regenerated lockfile), say so, and keep every input the same except for the asked-for part.
5. Show the change next to the previous version so the person can compare.

## Approval checkpoints

Put the checkpoint on the task card's Approval checkpoint section, and in the contract's Approval checkpoints list. The usual three:

1. Plan (board and contract).
2. Cheap draft.
3. Final.

At each one, stop. Show the output and what it cost. Ask a yes or no question with your recommended answer.

## Tag and shelve

Every output gets a tag the moment it is made, in its file name, branch name or handoff note (for example `export-api-draft2`). Only approved outputs go on the shelf with `shelve`, so the next task starts from them:

```
python3 .atelier/bin/atelier.py shelve export-api src/api/export.py "approved streaming CSV export endpoint, 10,000 rows under 5 s"
```

1. Use a short, stable tag that a later search would find (`export-api`, `invoice-fixtures`, `auth-module`).
2. Point to the real path of the approved file, not a draft.
3. Describe what it is in under 15 words.
4. Shelve only what the person approved. Drafts and rejected directions stay off the shelf.

## Checklist

- [ ] Shelf and rejections read before starting.
- [ ] Draft cost about 10% of the final or less.
- [ ] The person approved the draft in their own words before the final began.
- [ ] Revisions changed only what was asked.
- [ ] Final passed the gate.
- [ ] Every output tagged when made; the approved final shelved.
