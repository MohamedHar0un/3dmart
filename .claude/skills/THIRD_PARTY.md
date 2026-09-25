# Third-party skills

Vendored so every session (local or cloud) has the same skills without installing anything. Refresh with `scripts/update-skills.sh`, which re-copies these exact sources; bump the pinned commits there on purpose, and review the diff before committing.

| Skill | Source | Pinned commit | Licence |
|---|---|---|---|
| `impeccable` | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) (`.claude/skills/impeccable`, skill v4.4.0) | `9d715cc4f5564a990ca8345abfdd5df6dc9b41c8` | Apache-2.0 (`impeccable/LICENSE`) |
| `skill-finder`, `writing-plans`, `executing-plans`, `systematic-debugging`, `cto-review`, `github-actions-templates` | [ckorhonen/claude-skills](https://github.com/ckorhonen/claude-skills) | `39896345ef47beced8bbfeece5e772f0d978b8c6` | MIT (`LICENSE-ckorhonen-claude-skills`) |
| `security-threat-model`, `security-best-practices` | same repo | same commit | Apache-2.0 (`LICENSE.txt` in each folder) |

Local changes: removed the Codex-only `agents/openai.yaml` from the two security skills. Nothing else is modified.

The `impeccable` launcher (`impeccable/scripts/impeccable`) downloads its engine binary from the project's GitHub releases on first run and checks it against a published SHA-256. Sessions without network access need the binary preinstalled (see the skill's own README notes).
