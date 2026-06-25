#!/usr/bin/env bash
#
# Galatea 循环引擎
# 每轮以全新上下文执行单轮指令，直到收敛（出现 .done）、达到轮数上限、
# 停滞熔断、或连续失败停机。撞用量上限时指数退避。
# 任何方式结束时，跑一次 finalize-prompt 生成过程总览 run-report.md。
#
# 用法:
#   bash engine/loop.sh <目标专属目录> [最大轮数]
#
# 环境变量:
#   GALATEA_MAX_ITERATIONS        最大轮数，0=不限（默认 0；命令行第二参数优先）
#   GALATEA_NO_PROGRESS_THRESHOLD 连续无进展多少轮触发熔断（默认 5）
#   GALATEA_MAX_FAILS             连续失败多少次停机（默认 8）
#   GALATEA_CLAUDE_FLAGS          传给 claude 的 flag（默认 --dangerously-skip-permissions）
#   GALATEA_NOTIFY_CMD            关键事件通知命令（见 notify.sh）
#
# <目标专属目录> 下需有 iterate-prompt.md、finalize-prompt.md（Phase 0 生成）、
# rubric.md、state.md、log.md。建议跑在常驻环境 / tmux 里，断连不影响。
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/circuit_breaker.sh"
source "$SCRIPT_DIR/notify.sh"

GOAL_DIR="${1:?用法: bash engine/loop.sh <目标专属目录> [最大轮数]}"
MAX_ITERATIONS="${2:-${GALATEA_MAX_ITERATIONS:-0}}"
PROMPT_FILE="$GOAL_DIR/iterate-prompt.md"
FINALIZE_FILE="$GOAL_DIR/finalize-prompt.md"
DONE_FILE="$GOAL_DIR/.done"
PENDING_FILE="$GOAL_DIR/pending.md"
LOG_DIR="$GOAL_DIR/logs"

[ -f "$PROMPT_FILE" ] || { echo "缺少 $PROMPT_FILE（应在 Phase 0 结束时生成）"; exit 1; }
mkdir -p "$LOG_DIR" "$GOAL_DIR/.galatea"
cb_init "$GOAL_DIR"

CLAUDE_FLAGS="${GALATEA_CLAUDE_FLAGS:---dangerously-skip-permissions}"
MIN_BACKOFF=60; MAX_BACKOFF=1800; backoff=$MIN_BACKOFF
MAX_FAILS="${GALATEA_MAX_FAILS:-8}"; fails=0
round=0

pending_lines() { [ -f "$PENDING_FILE" ] && wc -l < "$PENDING_FILE" || echo 0; }
head_now() { git -C "$GOAL_DIR" rev-parse HEAD 2>/dev/null || echo none; }

# 统一收尾：记停止原因 → 通知 → 跑 finalize 生成 run-report.md → 退出
finalize() {
  local reason_code="$1" reason_msg="$2"
  echo "$reason_msg" > "$GOAL_DIR/.galatea/stop_reason"
  echo ">>> 结束（$reason_code）：$reason_msg"
  galatea_notify "$reason_code" "$reason_msg"
  if [ -f "$FINALIZE_FILE" ]; then
    echo ">>> 生成运行总览 run-report.md ..."
    claude -p "$(cat "$FINALIZE_FILE")" $CLAUDE_FLAGS 2>&1 | tee "$LOG_DIR/finalize.log" || true
  else
    echo "（无 finalize-prompt.md，跳过 run-report 生成）"
  fi
  exit 0
}

echo "Galatea 启动: $GOAL_DIR (max_iter=$MAX_ITERATIONS, 熔断阈值=$CB_NO_PROGRESS_THRESHOLD)"
while :; do
  [ -f "$DONE_FILE" ] && finalize converged "Galatea 达标收敛: $GOAL_DIR"
  if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$round" -ge "$MAX_ITERATIONS" ]; then
    finalize stopped "达到最大轮数 $MAX_ITERATIONS: $GOAL_DIR"
  fi

  round=$((round + 1))
  echo "===== 第 $round 轮 $(date '+%F %T') ====="
  head_before="$(head_now)"
  pend_before="$(pending_lines)"
  logf="$LOG_DIR/round-$(printf '%04d' "$round").log"

  if claude -p "$(cat "$PROMPT_FILE")" $CLAUDE_FLAGS 2>&1 | tee "$logf"; then
    fails=0; backoff=$MIN_BACKOFF
  else
    fails=$((fails + 1))
    echo "本轮失败（多为用量上限，第 $fails 次），退避 ${backoff}s。"
    [ "$fails" -ge "$MAX_FAILS" ] && finalize failed "连续失败 $MAX_FAILS 次停机: $GOAL_DIR"
    sleep "$backoff"
    backoff=$(( backoff * 2 > MAX_BACKOFF ? MAX_BACKOFF : backoff * 2 ))
    continue
  fi

  # 进展信号：本轮是否产生新 commit（仅在改动通过裁判时才 commit）
  progress=0; [ "$(head_now)" != "$head_before" ] && progress=1

  # 需决策通知：pending.md 增长
  if [ "$(pending_lines)" -gt "$pend_before" ]; then
    galatea_notify needs-decision "Galatea 有新待决策项，见 $PENDING_FILE"
  fi

  # 停滞熔断：连续无进展达阈值
  if ! cb_record "$GOAL_DIR" "$progress"; then
    finalize circuit-open "停滞熔断停机（连续 $(cb_count "$GOAL_DIR") 轮无进展）: $GOAL_DIR"
  fi
  sleep 10
done
