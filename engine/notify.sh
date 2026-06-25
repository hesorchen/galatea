#!/usr/bin/env bash
#
# Galatea 通知（可插拔）
#
# 无人值守时，循环在「收敛达标 / 需你决策 / 停滞熔断 / 连续失败停机」等关键节点
# 通过你指定的命令通知你。默认不设则静默跳过，零依赖。
#
# 接入方式：设环境变量 GALATEA_NOTIFY_CMD 指向一个命令，它会被这样调用：
#   "$GALATEA_NOTIFY_CMD" <event> <message>
# event 取值：converged | needs-decision | circuit-open | failed | stopped
#
# 示例（邮件，自行替换为你的通道；不要把密钥写进脚本）：
#   cat > ~/galatea-notify.sh <<'EOF'
#   #!/usr/bin/env bash
#   # $1=event  $2=message
#   curl -s --url "smtps://smtp.example.com:465" --ssl-reqd \
#     --mail-from "$MAIL_FROM" --mail-rcpt "$MAIL_TO" \
#     --user "$MAIL_USER:$MAIL_PASS" \
#     -T <(printf 'Subject: [galatea] %s\n\n%s\n' "$1" "$2") >/dev/null
#   EOF
#   chmod +x ~/galatea-notify.sh
#   export GALATEA_NOTIFY_CMD=~/galatea-notify.sh
#

galatea_notify() {
  local event="$1" msg="$2"
  [ -n "${GALATEA_NOTIFY_CMD:-}" ] || return 0
  "$GALATEA_NOTIFY_CMD" "$event" "$msg" 2>/dev/null || true
}
