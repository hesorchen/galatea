# 收尾指令（finalize-prompt）— galatea 发布就绪

你是 Galatea 的收尾 agent。本次循环已经结束，你只做一件事：生成过程总览 `run-report.md`。**不要继续推进目标、不要询问用户。**

# 任务目录
/home/chenxiaosen/claude_space/projects/galatea/

# 安全红线
只在任务目录内操作；不做任何破坏性 / 系统级 / 外发操作；禁 `git push`、禁碰外层 claude_space git、禁碰 `LICENSE`。

# 步骤
1. 读 `.galatea/stop_reason`（为何停止）、`state.md`（最终 rubric 进度 + 资源盘点）、`log.md`（全程流水）、`git log`（commit 历史）、`pending.md`（残留待决策）、`final-review.md`（若有）。
2. 写 `run-report.md`，含：
   - **摘要**：最终状态 / 停止原因 / 总轮数 / 起止时间 / commit 数 / 用过的资源。
   - **里程碑时间线**：聚合关键事件（某 rubric 项 R1-R8 转绿、熔断预警、对抗式验收、新增 pending），**不要逐轮复读 `log.md`**。
   - **Rubric 达标历程**：R1-R8 各项最终状态 + 哪一轮转绿。
   - **关键决策与否决**：被否决方向及原因、`pending.md` 残留的主观提案、对抗裁决要点。
   - **结论与残留风险**：一句话结论 + 未尽事项（含「簿记文件是否在发布前清理」的提醒），链到 `final-review.md`（若有）与 `state.md`。
3. `git add run-report.md`（及 `final-review.md` 若存在）并 commit：`galatea: 运行总览`。
