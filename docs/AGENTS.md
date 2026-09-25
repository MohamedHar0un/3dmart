# 3D Mart: agent team plan

How the build is staffed with Claude agents. **Claude Opus 5.5 is the team lead.** It plans, delegates to subagents, integrates their work and owns quality. The subagent definitions live in `.claude/agents/`, so Claude Code picks them up automatically in this repo.

Read with: `docs/BRIEF.md` (what to build) and `CLAUDE.md` (how the lead works).

---

## 1. How models are chosen

Per-token prices for reference, from Anthropic's price list (input / output, USD per million tokens). Check current pricing before budgeting.

| Model | Price | Relative cost | Use for |
|---|---|---|---|
| Claude Haiku 4.5 | $1 / $5 | 1× | Fast, mechanical, well-specified work: searching, running tests and summarising output, docs from given material, seed data |
| Claude Sonnet 5 | $2 / $10 | 2× | Most implementation: clear tasks with a spec and tests (Laravel modules, Vue pages, Flutter screens, infra code, routine review) |
| Claude Opus 5.5 | $4 / $20 | 4× | The lead, and the few areas where a mistake is expensive or the problem is genuinely hard: data model, money, real-time 3D performance, security review |
| Claude Fable 5.1 | $10 / $50 | 10× | Most capable model. Phase-gate reviews, hard-to-reverse architecture calls, and problems another agent has failed on twice. Never routine work. |

Three rules keep cost down without losing quality:

1. **Cheapest model that reliably passes the task's tests.** Most code is Sonnet 5. Opus is for judgment, not typing.
2. **Effort before model.** Each agent has an effort level (`low` → `xhigh`). Lower effort on a strong model often beats a weaker model. Raise effort for a hard task before switching model.
3. **Keep the lead's context small.** Searching, log reading and test output go to Haiku agents, which return short digests. The lead's context is the most expensive in the system.

---

## 2. The team

| Agent | Model | Effort | Tools | Role |
|---|---|---|---|---|
| **Team lead** (main session) | **Opus 5.5** | high | all | Plans each phase, writes ADRs, splits work into tasks with acceptance criteria, delegates, integrates, merges, answers subagents' questions, talks to the product owner |
| `database-engineer` | Opus 5.5 (`inherit`) | high | all | Schema, migrations, the Postgres extension set, indexes, partitions, exclusion constraints, Arabic search normalization, CloudNativePG image and backups |
| `payments-engineer` | Opus 5.5 (`inherit`) | high | all | Paymob, Fawry, COD, webhooks, refunds, reconciliation, idempotency, totals and VAT, the model-credit ledger |
| `aisle-3d-engineer` | Opus 5.5 (`inherit`) | high | all | `packages/aisle-engine` (Three.js): walking, instancing, LOD, streaming, pick-up, JS bridge, Vue wrapper, performance budgets |
| `security-reviewer` | Opus 5.5 (`inherit`) | xhigh | read-only + Bash | Security review of auth, supplier isolation, webhooks, uploads, secrets, infra exposure, personal data |
| `principal-reviewer` | **Fable 5.1** | high | read-only + Bash | Phase-gate reviews, irreversible architecture decisions, problems another agent failed twice |
| `backend-engineer` | Sonnet 5 | high | all | Laravel domain modules, API endpoints, jobs, events, policies, Horizon, Reverb, scheduler |
| `frontend-engineer` | Sonnet 5 | high | all | Inertia + Vue: shop, supplier portal, admin portal, design system, shelf planner and map editors |
| `flutter-engineer` | Sonnet 5 | high | all | Shopper and staff apps, WebView host for the 3D aisle, maps, push, payments hand-off |
| `devops-engineer` | Sonnet 5 | high | all | Ansible, k3s, Traefik, Cloudflare Tunnel, Terraform, Argo CD, Helm, CI/CD, monitoring, backups, Fastlane |
| `mesh-pipeline-engineer` | Sonnet 5 | high | all | `services/mesh-builder` (OpenCV, parametric meshes, glTF-Transform), n8n workflows, AI-tier provider interface |
| `code-reviewer` | Sonnet 5 | high | read-only + Bash | Reviews every change before merge against the brief's conventions and definition of done |
| `qa-engineer` | Sonnet 5 | medium | all | Missing tests, E2E (Playwright, Flutter integration), property tests, k6 load tests, acceptance checks |
| `localization-specialist` | Sonnet 5 | medium | all | Arabic/English copy, notification templates, store listings, RTL audits |
| `codebase-explorer` | Haiku 4.5 | low | read-only + web | Finds code, maps modules, checks package versions and docs, summarises big files |
| `test-runner` | Haiku 4.5 | low | read-only + Bash | Runs tests, linters and builds; returns a short digest of failures |
| `docs-writer` | Haiku 4.5 | medium | all | ADR formatting, runbooks, READMEs, phase demo notes, changelogs from material the lead provides |
| `seed-data-generator` | Haiku 4.5 | medium | all | Factories and seeders: fictional brands, Arabic/English products, zones, sample orders |

The team has 17 subagents plus the lead:
- Fable 5.1: 1;
- Opus 5.5: 4, plus the lead;
- Sonnet 5: 8;
- Haiku 4.5: 4.

### Why each Opus seat is Opus

- **Database:** schema and migration mistakes are the most expensive to fix later, and the extension and partitioning choices need judgment.
- **Payments:** money correctness under retries, duplicate webhooks and partial refunds. A bug here costs real money and trust.
- **3D engine:** hitting 30 fps on a mid-range Android inside a WebView is a hard performance-engineering problem with many trade-offs.
- **Security review:** missed issues have a high cost; the review is read-only, so it's a small share of total tokens.

### Why Opus agents use `model: inherit`

They run on the same model as the lead. Start the lead on Opus 5.5 and these agents get exactly Opus 5.5, without depending on what the `opus` alias points to on a given account. If you ever run the lead on another model, change these four files to an explicit model.

---

## 3. How the lead runs a phase

```
 Plan ──► Contracts ──► Build (parallel) ──► Review ──► Verify ──► Gate ──► Demo
 lead     lead + DB/    implementers in       code-      test-      principal  docs-
          payments      separate worktrees    reviewer   runner,    reviewer + writer
                                              (+security qa         security
                                              if risky)             reviewer
```

1. **Plan.** The lead reads the phase in `docs/BRIEF.md` §14 and writes a task list in `docs/plan/phase-N.md`. Each task has: an owner agent, inputs, acceptance criteria (named tests), and dependencies.
2. **Contracts first.** Before parallel work starts, the lead (with `database-engineer`, and `payments-engineer` where money is involved) fixes the shared contracts:
   - migrations and ERD for the phase;
   - OpenAPI changes;
   - JS bridge messages;
   - store manifest format.

   Implementers build against these and don't change them without asking.
3. **Build in parallel.** Independent tasks run concurrently, each in its own git worktree (`isolation: worktree`) so agents don't overwrite each other. Typical parallel sets are in §4.
4. **Review every change.** `code-reviewer` reviews every diff. `security-reviewer` also reviews anything touching auth, permissions, supplier data, webhooks, uploads, secrets or infra exposure.
5. **Verify.** `test-runner` runs the full suite and returns a digest. `qa-engineer` fills missing tests and checks acceptance criteria end to end.
6. **Gate.** At the end of the phase, `principal-reviewer` (Fable 5.1) checks each acceptance criterion with evidence and looks for costly design problems. `security-reviewer` does a full pass.
7. **Demo.** `docs-writer` writes `docs/demos/phase-N.md`. The lead merges to `main`, and Argo CD deploys to staging.

### What every subagent returns

Every agent's definition ends with its report format. In short:
- what changed (files);
- tests added and their results (the summary line, not the full log);
- decisions it made and anything it needs the lead to decide;
- risks and follow-ups.

Subagents never talk to the product owner directly; questions go through the lead.

### Escalation ladder

When an agent fails a task (tests still red, reviewer rejects twice):

1. The lead clarifies the task and retries with the same agent at higher effort.
2. The task moves up one model tier (Haiku → Sonnet 5 → Opus 5.5).
3. `principal-reviewer` (Fable 5.1) diagnoses the root cause; the fix goes back to an implementer.
4. The lead writes up the blocker for the product owner.

---

## 4. Who works when

Which agents are active in each phase of `docs/BRIEF.md` §14. **Lead** = decides and integrates; bold = main builders.

| Phase | Parallel build streams | Supporting |
|---|---|---|
| 0: Foundations | **devops-engineer** (cluster, Cloudflare, CI, Argo CD, backups) ‖ **database-engineer** (Postgres image with extensions, first migrations) ‖ **backend-engineer** (Laravel skeleton, modules, health checks) ‖ **flutter-engineer** (app skeleton, flavors) ‖ **aisle-3d-engineer** (package skeleton, build to WebView bundle) | codebase-explorer (version checks), docs-writer (ADR-0001…0005), test-runner; gate: principal-reviewer, security-reviewer (infra) |
| 1: Identity & catalog | **backend-engineer** (auth, roles, catalog, supplier onboarding) ‖ **database-engineer** (search: pg_trgm, full-text, Arabic normalization) ‖ **frontend-engineer** (admin catalog, supplier sign-up) ‖ **flutter-engineer** (sign-in, browse) | localization-specialist, seed-data-generator (catalog), qa-engineer (search test set), code-reviewer, security-reviewer (auth) |
| 2: Commerce core | **backend-engineer** (inventory, zones, slots, cart, orders) ‖ **payments-engineer** (totals, promotions v1, COD) ‖ **database-engineer** (PostGIS zones, stock ledger) ‖ **frontend-engineer** (web shop, admin ops) ‖ **flutter-engineer** (list-view shopping, checkout) | qa-engineer (property tests for stock), code-reviewer, test-runner |
| 3: 3D store | **aisle-3d-engineer** (engine, performance) ‖ **backend-engineer** (planogram, publish → manifests) ‖ **frontend-engineer** (planogram editor, Vue wrapper) ‖ **flutter-engineer** (WebView host, bridge, fallback) ‖ **database-engineer** (partitioned analytics events) | qa-engineer (device performance runs), gate: principal-reviewer on the performance ADR (D3) |
| 4: Payments & delivery | **payments-engineer** (Paymob, Fawry, refunds, COD reconciliation) ‖ **backend-engineer** (tracking, Reverb, notifications) ‖ **flutter-engineer** (staff app, live map) ‖ **devops-engineer** (Reverb scaling, alerts) | security-reviewer (webhooks), qa-engineer (webhook chaos tests), localization-specialist (templates) |
| 5: Suppliers & retail media | **backend-engineer** (ads, attribution, reporting) ‖ **frontend-engineer** (supplier portal complete) ‖ **payments-engineer** (supplier-funded promotions, settlements) ‖ **aisle-3d-engineer** (ads in the scene) ‖ **database-engineer** (booking exclusion constraints, reporting views) | security-reviewer (supplier isolation), qa-engineer, code-reviewer |
| 6: Photo → 3D | **mesh-pipeline-engineer** (Standard tier, n8n, AI-tier interface) ‖ **payments-engineer** (model credits) ‖ **frontend-engineer** (guided upload, review, credits UI) ‖ **backend-engineer** (jobs, callbacks, artist queue) | seed-data-generator (fixture packs), qa-engineer, security-reviewer (upload/SSRF) |
| 7: Hardening & launch | **qa-engineer** (k6 load tests) ‖ **devops-engineer** (pgaudit, runbooks, restore drill, store builds) ‖ **backend-engineer** (data export/deletion, e-receipt hook) ‖ **localization-specialist** (store listings) | security-reviewer (full pass), principal-reviewer (launch gate), docs-writer (runbooks) |

Keep 3–5 build streams running at once. More streams mean more merge conflicts and more lead context spent integrating, with little gain.

---

## 5. Keeping cost and time under control

- **Run the lead at `high` effort** for day-to-day coordination. Raise it to `xhigh` only when writing contracts or resolving a gate.
- **Delegate reading.** Ask `codebase-explorer` "where is X / which files use Y" instead of reading many files in the lead's context. Ask `test-runner` for a digest instead of running suites directly.
- **Batch mechanical work.** Translations, seed data and docs go to the cheaper agents in large batches with a clear spec.
- **Specs up front.** Give each implementer the full task (acceptance criteria, contracts, files to touch) in one message. Clear specs let Sonnet 5 finish in one pass, which is cheaper than an Opus agent guessing.
- **Fable 5.1 only at gates.** One review per phase plus rare escalations. If it's being called more often, tasks are under-specified.
- **Measure.** Record per phase: tasks per agent, first-pass success rate, and escalations. If an agent's first-pass rate is below about 70%, raise its effort; if that doesn't help, move its tasks up a tier.
- **Parallel worktrees** save wall-clock time on independent streams; the price is merge effort, so keep contracts stable.

---

## 6. Starting the team

1. Open the repo in Claude Code and set the main session to Claude Opus 5.5 with `/model`.
2. Check the team is loaded with `/agents`.
3. Paste the kickoff prompt from `docs/BRIEF.md` §0.
4. The lead starts Phase 0 by writing `docs/plan/phase-0.md` and delegating.

To change an agent's model or effort, edit the `model:` / `effort:` line in its file under `.claude/agents/`, and update the table in §2.
