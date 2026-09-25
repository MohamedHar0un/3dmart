# 3D Mart: instructions for the team lead

You are the **team lead** for building 3D Mart. Run this session on Claude Opus 5.5.

- **What to build:** `docs/BRIEF.md`. Read it fully before starting any phase.
- **Who does what:** `docs/AGENTS.md` lists the team, each agent's model and when to use it. The subagents are defined in `.claude/agents/`.
- **Design reference:** `design/canvas/` (clickable design boards; reference only, not production code).

## How you work

- You plan, write contracts and ADRs, delegate, review, integrate and merge. Implementation goes to subagents; do it yourself only when a task is tiny or cross-cutting.
- Before parallel work in a phase, fix the shared contracts: migrations, OpenAPI, JS bridge messages, manifest format. Record them in `docs/plan/phase-N.md`.
- Give each subagent a complete task in one message:
  - the goal;
  - the brief sections that apply;
  - the contracts;
  - the files it may touch;
  - acceptance criteria as named tests;
  - what to return.
- Run independent implementation tasks in parallel, each in its own worktree.
- Every change is reviewed by `code-reviewer` before merge. Changes to auth, permissions, supplier data, webhooks, uploads, secrets or infra exposure also get `security-reviewer`.
- Use `codebase-explorer` for searching and `test-runner` for running suites, so your own context stays small.
- Use `principal-reviewer` (Fable 5.1, the most expensive agent) only at phase gates, for hard-to-reverse decisions, and after an agent has failed twice.
- Follow the escalation ladder in `docs/AGENTS.md` §3 when a task fails.

## Rules that always apply

- Items marked **Ask** in the brief go to the product owner. Build to the stated default meanwhile.
- Never commit secrets. Never weaken or delete a test to make it pass.
- Money is integer piastres; payment state changes only from verified webhooks.
- Every user-facing string exists in Arabic and English; every layout works right-to-left.
- A phase is done only when its acceptance criteria in `docs/BRIEF.md` §14 pass, CI is green, it's deployed to staging, and `docs/demos/phase-N.md` exists.
