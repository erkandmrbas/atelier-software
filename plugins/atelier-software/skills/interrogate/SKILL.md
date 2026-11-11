---
name: interrogate
description: Researches the job first, then questions the person in short rounds, each question with a recommended answer, until intent is clear and the person confirms a restatement of 5 lines or fewer. Use right after start, before any board, contract, or work, and again whenever a worker's question shows the intent was not clear.
---

# Interrogate: research, then ask

Work started on a wrong guess is the most expensive mistake in a job. This phase makes the intent clear before anything is built. You are the lead; only you talk to the person.

## Step 1: research before you ask

Never ask the person something you could find out yourself. Spend the first part of this phase looking, not asking.

0. **Profile.** `start` loaded `profile-software`. Use its constraints and quality bar defaults as extra questions and recommended answers.
1. **Rejections.** Read `.atelier/rejections.md` and `~/.atelier/rejections.md`. Do not recommend anything listed there.
2. **The shelf.** Read `.atelier/shelf.md`. An approved output that already does 80% of the job beats new work.
3. **What exists.** Look at the existing code, tests, schema, and configuration the job will touch. Note versions, conventions, the test command, and anything fragile (a flaky test, a hand-edited migration).
4. **Similar work.** Look for how this kind of change is usually done, in this repository first: an existing endpoint, module or migration to match, typical numbers, known traps.
5. **Risks.** List the 3 to 5 things most likely to go wrong (data loss, a slow step, a paid call, a shared file, an unclear audience).

Hand steps 3 to 5 to the `atelier-software:researcher` subagent with a brief of what to find and a limit of one page of findings, at most 40 lines.

Write the findings down in your own notes (a few lines each). They feed the recommended answers.

## Step 2: size the job

- **Small job** (one worker, one session, at most 3 files or 1 output): 1 round of 3 to 5 questions.
- **Big job**: rounds of at most 7 questions each. Keep going until you could write the contract without guessing. Most big jobs need 2 or 3 rounds; stop at the first round where every answer matches your recommendation.

## Step 3: ask in rounds

Rules for every question:

1. **Carry a recommended answer.** Write it right after the question, based on your research. The person must be able to reply "go with your recommendations" and get a sensible job.
2. **One decision per question.** No "and also".
3. **Ask about outcomes, not steps.** The person decides what "good" is; you and the workers decide how.
4. **Number the questions** so the person can answer "3: no, use B".
5. **Do not re-ask** what research already answered. State it as an assumption instead.

Over all rounds, cover these 7 topics (a small job may merge several into one question):

1. **Goal**: what exists when this is done.
2. **Audience**: who uses or sees the result.
3. **What must never happen**: the hard limits. These become the "never" lines of the contract.
4. **What "good" means in numbers**: speed, size, length, count, error rate, score. Offer a number in your recommendation.
5. **References they like**: earlier work, files, examples to match or avoid.
6. **Budget, time, and limits**: hours, paid services, dependencies that may or may not be added.
7. **Approval points**: where the person wants to look before work goes on. Recommend at least: plan, cheap draft, final.

## Example round

> Before I plan this, 6 questions. Each has my recommendation; reply "go with your recommendations" or correct by number.
>
> 1. **Goal**: Is the result a new export page, or a change to the existing report page? *Recommended: a new page; the current one is shared by 4 other screens.*
> 2. **Audience**: Who uses it? *Recommended: the finance team, about 20 people, on desktop.*
> 3. **Never**: What must never happen? *Recommended: never change the stored numbers; never send data outside the company network.*
> 4. **Good in numbers**: How fast must an export be? *Recommended: a 10,000-row export finishes in under 5 seconds.*
> 5. **References**: Is there an export you already like? *Recommended: match the column order of the monthly CSV you sent last week.*
> 6. **Approval points**: Where do you want to look? *Recommended: after the plan, after a 100-row draft export, and at the final.*

## Step 4: handle the answers

1. When the person accepts a recommendation, it becomes a fixed decision.
2. When the person rejects something, log it at once: `python3 .atelier/bin/atelier.py reject "what the person rejected"`.
3. When an answer is vague ("fast", "clean", "not too long"), ask one follow-up that offers a number. The `contract` skill shows how.
4. When an answer opens a new question, put it in the next round, not in a long reply.

## Step 5: restate and get a yes

End with a restatement of **5 lines or fewer**:

> Here is what I understood:
> 1. Build a new export page for the finance team (about 20 people, desktop).
> 2. Never change stored numbers; never send data outside the network.
> 3. A 10,000-row export finishes in under 5 seconds; columns match last week's CSV.
> 4. You look at the plan, a 100-row draft, and the final.
> Is that right?

Do not move to the `board` skill until the person says yes. If they correct a line, fix it and restate again.

## Anti-patterns

- Asking 15 questions at once. The person answers 4 and skips the rest.
- Questions without a recommendation. They push your work onto the person.
- Asking about implementation details (which library, which file). Those are yours to decide.
- Starting the board "while waiting" for answers. A wrong guess costs more than the wait.
