#!/usr/bin/env bash
#
# Galatea 停滞熔断
# 当循环连续多轮无进展时停机，避免空转烧光预算。
# 纯 bash，状态存在 <目标专属目录>/.galatea/ 下，无外部依赖。
#
# 进展的定义：本轮产生了新的 git commit。
# Galatea 只在改动通过裁判时才 commit，所以「有 commit」== 真进展，
# 反复折腾却没有任何东西通过裁判 == 无进展 == 应当熔断。
#

CB_NO_PROGRESS_THRESHOLD="${GALATEA_NO_PROGRESS_THRESHOLD:-5}"

_cb_file() { echo "$1/.galatea/no_progress"; }

cb_init() {
  mkdir -p "$1/.galatea"
  [ -f "$(_cb_file "$1")" ] || echo 0 > "$(_cb_file "$1")"
}

# cb_record <目标目录> <是否有进展:1/0>
# 返回 0=可继续，1=已触发熔断（连续无进展达阈值）
cb_record() {
  local gd="$1" progress="$2" f n
  f="$(_cb_file "$gd")"
  n=$(cat "$f" 2>/dev/null || echo 0)
  if [ "$progress" = "1" ]; then n=0; else n=$((n + 1)); fi
  echo "$n" > "$f"
  [ "$n" -ge "$CB_NO_PROGRESS_THRESHOLD" ] && return 1
  return 0
}

cb_count() { cat "$(_cb_file "$1")" 2>/dev/null || echo 0; }
