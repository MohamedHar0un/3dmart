#!/usr/bin/env bash
# Re-copy the vendored third-party skills from their pinned commits.
# Change a commit below on purpose, run this, review `git diff .claude/skills`, then commit.
set -euo pipefail

IMPECCABLE_REPO=https://github.com/pbakaus/impeccable.git
IMPECCABLE_COMMIT=9d715cc4f5564a990ca8345abfdd5df6dc9b41c8
CK_REPO=https://github.com/ckorhonen/claude-skills.git
CK_COMMIT=39896345ef47beced8bbfeece5e772f0d978b8c6
CK_SKILLS=(skill-finder writing-plans executing-plans systematic-debugging security-threat-model security-best-practices cto-review github-actions-templates)

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST="$ROOT/.claude/skills"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fetch() { # repo commit dir
  git init -q "$3"
  git -C "$3" remote add origin "$1"
  git -C "$3" fetch -q --depth 1 origin "$2"
  git -C "$3" checkout -q FETCH_HEAD
}

fetch "$IMPECCABLE_REPO" "$IMPECCABLE_COMMIT" "$TMP/impeccable"
rm -rf "$DEST/impeccable"
cp -r "$TMP/impeccable/.claude/skills/impeccable" "$DEST/impeccable"
cp "$TMP/impeccable/LICENSE" "$DEST/impeccable/LICENSE"
if [ -f "$TMP/impeccable/NOTICE.md" ]; then cp "$TMP/impeccable/NOTICE.md" "$DEST/impeccable/NOTICE.md"; fi

fetch "$CK_REPO" "$CK_COMMIT" "$TMP/ck"
for s in "${CK_SKILLS[@]}"; do
  rm -rf "${DEST:?}/$s"
  cp -r "$TMP/ck/skills/$s" "$DEST/$s"
done
rm -rf "$DEST/security-threat-model/agents" "$DEST/security-best-practices/agents"
cp "$TMP/ck/LICENSE" "$DEST/LICENSE-ckorhonen-claude-skills"

echo "Skills refreshed. Review with: git diff --stat .claude/skills"
