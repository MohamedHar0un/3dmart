---
name: phase-gate
description: Run the end-of-phase gate for 3D Mart. Use when all tasks of a phase are done and you (the team lead) are deciding whether the phase is complete and can move to the next one.
---

# Phase gate

A phase is complete only when every step below passes. Run them in order and record results in `docs/demos/phase-<N>.md`.

1. **Tasks:** every task in `docs/plan/phase-<N>.md` is `✓ done` in `docs/plan/status.md`.
2. **Tests and checks:** dispatch `test-runner` for the full suite (backend, frontend, mobile, engine). All green; record the summary lines.
3. **Acceptance criteria:** for each criterion of the phase in `docs/BRIEF.md` §14, map it to evidence: named tests, command output, measured numbers. Mark each met / not met.
4. **Security:** dispatch `security-reviewer` on the phase's full diff (`git diff <phase-start-tag>..HEAD`). No open Critical or High findings.
5. **Design quality (phases with UI):** run the `impeccable` skill's `audit` on each new surface (web: desktop and mobile widths, Arabic and English; Flutter: the native audit reference). Fix everything above cosmetic, then `polish` once.
6. **Principal review:** dispatch `principal-reviewer` (Fable 5.1) with the acceptance table, test summary, security result and the diff range. Address every issue it ranks as expensive to fix later, or record why not in an ADR.
7. **Staging:** the phase is deployed to staging by Argo CD and the demo steps work there.
8. **Demo note:** dispatch `docs-writer` to write `docs/demos/phase-<N>.md` (what was built, how to try it on staging, acceptance table, known issues).
9. **Tag:** tag the merge commit `phase-<N>-done` and post the progress update from the `agent-dispatch` skill.

If any step fails, the phase stays open: create tasks for the gaps, dispatch them, and re-run the failed steps only.
