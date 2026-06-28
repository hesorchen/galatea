#!/usr/bin/env bash
# Galatea run launcher — generated in Phase 0 from the user's explicit backend/model choice.
# Do not infer or rewrite backend/model in Phase 1.
set -euo pipefail

cd "<GOAL_DIR>"
mkdir -p "<GOAL_DIR>/logs"

# Optional: only include PATH changes the user explicitly requested.
# export PATH=/path/to/bin:$PATH

export GALATEA_AGENT_BACKEND="<claude-or-codex>"

# Claude backend example:
# export GALATEA_CLAUDE_FLAGS='--dangerously-skip-permissions --model <USER_MODEL>'

# Codex backend example:
# export GALATEA_CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox --model <USER_MODEL>'

export GALATEA_MAX_ITERATIONS="<MAX_ITERATIONS>"
export GALATEA_NO_PROGRESS_THRESHOLD="<NO_PROGRESS_THRESHOLD>"
export GALATEA_MAX_FAILS="<MAX_FAILS>"

nohup bash "<GALATEA_SKILL_DIR>/engine/loop.sh" \
  "<GOAL_DIR>" "<MAX_ITERATIONS>" \
  > "<GOAL_DIR>/logs/engine.log" 2>&1 &
