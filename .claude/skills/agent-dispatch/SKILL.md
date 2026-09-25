---
name: agent-dispatch
description: How the 3D Mart team lead hands a task to a subagent and reports agent progress to the product owner. Use every time you delegate to a subagent, when a subagent returns, and when posting a progress update, so dispatches, status lines and updates always have the same shape.
---

# Agent dispatch and progress reporting

The product owner follows the build through your messages. Every dispatch, return and update uses the formats below, in this order, with no extra chatter.

## 1. Before dispatching: post a dispatch line

One line per agent, posted in the same message as the Agent tool calls:

```
▶ <agent-name> (<model>, <effort>) · <task id> · <what it's doing, ≤ 12 words>
```

Example: `▶ database-engineer (Opus 5.5, high) · P1-T03 · Arabic search normalization and trigram indexes`

## 2. The task message you send the agent

Send one complete message. Use exactly these headings:

```
## Task <id>: <title>
Goal: <one or two sentences>
Brief: docs/BRIEF.md §<sections>
Contracts: <migrations / OpenAPI paths / bridge messages it must follow; "none">
Files you may touch: <paths or globs>
Files you must not touch: <paths, or "anything outside the list above">
Acceptance: <named tests that must pass>
Skills to use: <e.g. impeccable (shape, then audit + polish), systematic-debugging; "none">
Return: the report format in your agent definition, starting with a one-line status.
```

## 3. When an agent returns: post a result line

```
✓ <agent-name> · <task id> · <outcome, ≤ 15 words> · tests: <passed>/<total>
✗ <agent-name> · <task id> · <what failed, ≤ 15 words> · next: <retry at higher effort | escalate to <agent/model> | ask owner>
```

Then update `docs/plan/status.md` (section 5).

## 4. Progress update (at each milestone, and at least once per working session)

```
### Phase <N> · <date> · <x>/<y> tasks done

| Agent | Task | Status | Note |
|---|---|---|---|
| backend-engineer | P1-T01 Auth API | ✓ done | 42/42 tests |
| frontend-engineer | P1-T04 Admin catalog | ⏳ running | in review |
| flutter-engineer | P1-T06 Sign-in | ✗ blocked | waiting on OTP contract change |

Blockers: <none | list>
Needs you: <none | the plan or design item awaiting approval>
```

Status symbols: `⏳ running`, `🔍 in review`, `✓ done`, `✗ blocked`, `↑ escalated`.

## 5. Status file

Keep `docs/plan/status.md` as the single source of truth: the latest progress table above, plus a log of dispatch and result lines (newest first). Commit it with the work.

## Rules

- Never leave an agent running without a dispatch line, or returned without a result line.
- Report facts from the agent's report (test counts, files); don't embellish.
- Keep "Needs you" for the two things the product owner reviews: phase plans and design direction. Everything else you decide.
